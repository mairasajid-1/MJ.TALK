import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { getOrgId } from "@/lib/get-org";
import { prisma } from "@/lib/prisma";

/** GET /api/knowledge-base?chatbotId=... — list articles */
export async function GET(req: NextRequest) {
  try {
    const user = await requireAuth();
    const orgId = await getOrgId(user.id);
    if (!orgId) return NextResponse.json({ error: "No org" }, { status: 403 });

    const { searchParams } = new URL(req.url);
    const chatbotId = searchParams.get("chatbotId");
    const category = searchParams.get("category");

    // 1. Try Prisma first if DATABASE_URL is available
    if (process.env.DATABASE_URL) {
      try {
        const where: Record<string, unknown> = { org_id: orgId };
        if (chatbotId) where.chatbot_id = chatbotId;
        if (category && category !== "all") where.category = category;

        const articles = await prisma.kbArticle.findMany({
          where,
          orderBy: { created_at: "desc" },
        });

        return NextResponse.json({ articles });
      } catch (prismaErr) {
        console.warn("Prisma GET kb_articles fallback to Supabase:", prismaErr);
      }
    }

    // 2. Supabase fallback
    const supabase = createServiceClient();
    let query = supabase
      .from("kb_articles")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: false });

    if (chatbotId) query = query.eq("chatbot_id", chatbotId);
    if (category && category !== "all") query = query.eq("category", category);

    const { data, error } = await query;
    if (error) {
      if (error.message?.includes("category")) {
        const fallbackQuery = supabase
          .from("kb_articles")
          .select("id, chatbot_id, org_id, title, content, is_published, created_at, updated_at")
          .eq("org_id", orgId)
          .order("created_at", { ascending: false });

        const { data: fbData } = await fallbackQuery;
        const normalized = (fbData || []).map((art: any) => ({ ...art, category: "general" }));
        return NextResponse.json({ articles: normalized });
      }
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ articles: data ?? [] });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Unauthorized" }, { status: 401 });
  }
}

/** POST /api/knowledge-base — create article */
export async function POST(req: NextRequest) {
  try {
    const user = await requireAuth();
    const orgId = await getOrgId(user.id);
    if (!orgId) return NextResponse.json({ error: "No org" }, { status: 403 });

    const body = await req.json();
    const { chatbotId, title, content, category = "general", tags = [], isPublished = true } = body;

    if (!chatbotId || !title?.trim() || !content?.trim()) {
      return NextResponse.json({ error: "chatbotId, title, content required" }, { status: 400 });
    }

    const supabase = createServiceClient();

    // Verify chatbot belongs to org
    const { data: bot } = await supabase
      .from("chatbots")
      .select("id")
      .eq("id", chatbotId)
      .eq("org_id", orgId)
      .maybeSingle();

    if (!bot) return NextResponse.json({ error: "Chatbot not found" }, { status: 404 });

    // 1. Try Prisma first if DATABASE_URL is available
    if (process.env.DATABASE_URL) {
      try {
        const article = await prisma.kbArticle.create({
          data: {
            chatbot_id: chatbotId,
            org_id: orgId,
            title: title.trim(),
            content: content.trim(),
            category: category,
            tags: Array.isArray(tags) ? tags : [],
            is_published: isPublished,
            created_by: user.id,
          },
        });
        return NextResponse.json({ article }, { status: 201 });
      } catch (prismaErr) {
        console.warn("Prisma POST kb_articles fallback to Supabase:", prismaErr);
      }
    }

    // 2. Try Supabase insert
    const insertPayload: Record<string, unknown> = {
      chatbot_id: chatbotId,
      org_id: orgId,
      title: title.trim(),
      content: content.trim(),
      category,
      tags: Array.isArray(tags) ? tags : [],
      is_published: isPublished,
      created_by: user.id,
    };

    const { data, error } = await supabase
      .from("kb_articles")
      .insert(insertPayload)
      .select()
      .single();

    if (error) {
      // If schema cache missing category column, delete category key and retry
      if (error.message?.includes("category")) {
        delete insertPayload.category;
        const { data: fbData, error: fbError } = await supabase
          .from("kb_articles")
          .insert(insertPayload)
          .select()
          .single();

        if (fbError) return NextResponse.json({ error: fbError.message }, { status: 500 });
        return NextResponse.json({ article: { ...fbData, category: "general" } }, { status: 201 });
      }
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ article: data }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Unauthorized" }, { status: 401 });
  }
}
