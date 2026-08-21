import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { getOrgId } from "@/lib/get-org";
import { prisma } from "@/lib/prisma";

/** PATCH /api/knowledge-base/[id]  — update article */
export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const user = await requireAuth();
    const orgId = await getOrgId(user.id);
    if (!orgId) return NextResponse.json({ error: "No org" }, { status: 403 });

    const body = await req.json();
    const { title, content, category, tags, isPublished } = body;

    // 1. Try Prisma first if DATABASE_URL is available
    if (process.env.DATABASE_URL) {
      try {
        const updateData: Record<string, unknown> = {};
        if (title !== undefined) updateData.title = title.trim();
        if (content !== undefined) updateData.content = content.trim();
        if (category !== undefined) updateData.category = category;
        if (tags !== undefined) updateData.tags = tags;
        if (isPublished !== undefined) updateData.is_published = isPublished;

        const article = await prisma.kbArticle.update({
          where: { id },
          data: updateData,
        });
        return NextResponse.json({ article });
      } catch (prismaErr) {
        console.warn("Prisma PATCH kb_articles fallback to Supabase:", prismaErr);
      }
    }

    // 2. Supabase fallback with dynamic column error retry loop
    const supabase = createServiceClient();
    const updateData: Record<string, unknown> = {};
    if (title !== undefined) updateData.title = title.trim();
    if (content !== undefined) updateData.content = content.trim();
    if (category !== undefined) updateData.category = category;
    if (tags !== undefined) updateData.tags = tags;
    if (isPublished !== undefined) updateData.is_published = isPublished;

    let attempts = 0;
    while (attempts < 5) {
      attempts++;
      const { data, error } = await supabase
        .from("kb_articles")
        .update(updateData)
        .eq("id", id)
        .eq("org_id", orgId)
        .select()
        .single();

      if (!error) {
        if (!data) return NextResponse.json({ error: "Not found" }, { status: 404 });
        return NextResponse.json({ article: { category: category || "general", ...data } });
      }

      const missingMatch = error.message?.match(/Could not find the '([^']+)' column/i);
      if (missingMatch && missingMatch[1] && missingMatch[1] in updateData) {
        const missingCol = missingMatch[1];
        console.warn(`Supabase schema cache missing column '${missingCol}', stripping and retrying update...`);
        delete updateData[missingCol];
        continue;
      }

      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ error: "Could not update article after retries" }, { status: 500 });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Unauthorized" }, { status: 401 });
  }
}

/** DELETE /api/knowledge-base/[id]  — delete article */
export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const user = await requireAuth();
    const orgId = await getOrgId(user.id);
    if (!orgId) return NextResponse.json({ error: "No org" }, { status: 403 });

    // 1. Try Prisma first if DATABASE_URL is available
    if (process.env.DATABASE_URL) {
      try {
        await prisma.kbArticle.delete({
          where: { id },
        });
        return NextResponse.json({ success: true });
      } catch (prismaErr) {
        console.warn("Prisma DELETE kb_articles fallback to Supabase:", prismaErr);
      }
    }

    // 2. Supabase fallback
    const supabase = createServiceClient();
    const { error } = await supabase
      .from("kb_articles")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Unauthorized" }, { status: 401 });
  }
}
