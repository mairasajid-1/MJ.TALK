import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { conversationId, role, content } = body;

    if (!conversationId || !role || !content) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    if (!["user", "assistant", "admin"].includes(role)) {
      return NextResponse.json({ error: "Invalid role" }, { status: 400 });
    }

    const supabase = createServiceClient();

    // Map role to sender_type for database compatibility
    // Database might use either 'role' or 'sender_type' column
    const roleMapping: Record<string, string> = {
      user: "visitor",
      assistant: "ai",
      admin: "agent"
    };

    // Try with 'role' column first (new schema)
    let { data: message, error } = await supabase
      .from("messages")
      .insert({ 
        conversation_id: conversationId, 
        role: role,  // Try new schema first
        content 
      })
      .select()
      .single();

    // If that fails, try with sender_type column (old schema)
    if (error && error.message.includes("sender_type")) {
      const result = await supabase
        .from("messages")
        .insert({ 
          conversation_id: conversationId, 
          sender_type: roleMapping[role],  // Map to old schema values
          content 
        })
        .select()
        .single();
      
      message = result.data;
      error = result.error;
    }

    if (error) {
      console.error("Message insert error:", error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ message }, { headers: CORS_HEADERS });
  } catch (error) {
    console.error("Messages API error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

export async function OPTIONS() {
  return new NextResponse(null, { status: 200, headers: CORS_HEADERS });
}
