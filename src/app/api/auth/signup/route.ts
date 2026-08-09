import { NextRequest, NextResponse } from "next/server";

// Check environment configuration first
function checkConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  const errors: string[] = [];

  if (!url || url.includes('your_') || url.includes('_here')) {
    errors.push('NEXT_PUBLIC_SUPABASE_URL is missing or has placeholder value');
  }
  if (!anonKey || anonKey.includes('your_') || anonKey.includes('_here')) {
    errors.push('NEXT_PUBLIC_SUPABASE_ANON_KEY is missing or has placeholder value');
  }
  if (!serviceKey || serviceKey.includes('your_') || serviceKey.includes('_here')) {
    errors.push('SUPABASE_SERVICE_ROLE_KEY is missing or has placeholder value');
  }

  return { isConfigured: errors.length === 0, errors };
}

export async function POST(req: NextRequest) {
  try {
    const { isConfigured, errors } = checkConfig();
    
    if (!isConfigured) {
      console.error('Supabase not configured:', errors);
      return NextResponse.json(
        { 
          error: "Setup required",
          details: "Supabase credentials not configured",
          missingConfig: errors 
        }, 
        { status: 503 }
      );
    }

    const { createServiceClient } = await import("@/lib/supabase/server");
    const { email, password, orgName } = await req.json();

    if (!email || !password || !orgName) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json({ error: "Please enter a valid email address" }, { status: 400 });
    }

    if (password.length < 8) {
      return NextResponse.json({ error: "Password must be at least 8 characters" }, { status: 400 });
    }

    const serviceClient = createServiceClient();

    // Check if user already exists
    const { data: existingUsers } = await serviceClient.auth.admin.listUsers();
    const existingUser = existingUsers?.users?.find(
      (u) => u.email?.toLowerCase() === email.toLowerCase()
    );

    if (existingUser) {
      // If they exist but are NOT confirmed (stuck from old flow), fix them:
      // update password + confirm + sign them in
      if (!existingUser.email_confirmed_at) {
        await serviceClient.auth.admin.updateUserById(existingUser.id, {
          password,
          email_confirm: true,
        });
        // Make sure org row exists
        const { data: orgRow } = await serviceClient
          .from("organizations")
          .select("id")
          .eq("owner_id", existingUser.id)
          .single();

        if (!orgRow) {
          await serviceClient.from("organizations").insert({
            name: orgName.trim(),
            owner_id: existingUser.id,
          });
        }
        return NextResponse.json({ success: true, emailConfirmRequired: false });
      }
      // Fully confirmed account already exists
      return NextResponse.json(
        { error: "An account with this email already exists. Please sign in." },
        { status: 400 }
      );
    }

    // Create brand-new user — email_confirm: true bypasses broken Supabase SMTP
    const { data: authData, error: signUpError } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { org_name: orgName.trim() },
    });

    if (signUpError || !authData.user) {
      return NextResponse.json(
        { error: signUpError?.message ?? "Failed to create account" },
        { status: 400 }
      );
    }

    // Create organization row
    const { error: orgError } = await serviceClient.from("organizations").insert({
      name: orgName.trim(),
      owner_id: authData.user.id,
    });

    if (orgError && !orgError.message.includes("duplicate")) {
      await serviceClient.auth.admin.deleteUser(authData.user.id);
      return NextResponse.json(
        { error: "Failed to create organization: " + orgError.message },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true, emailConfirmRequired: false });
  } catch (err) {
    console.error("Signup error:", err);
    const message = err instanceof Error ? err.message : "Internal server error";
    
    // Check if it's a configuration error
    if (message.includes("Supabase configuration") || message.includes("undefined")) {
      return NextResponse.json(
        { 
          error: "Setup required",
          details: "Please check your Supabase environment variables",
          debugInfo: message
        }, 
        { status: 503 }
      );
    }
    
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
