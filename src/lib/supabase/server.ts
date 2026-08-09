import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// Check if Supabase is properly configured
// Returns null if not configured (for build-time safety)
function validateSupabaseConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  // During build, missing env vars are OK — they'll be checked at runtime
  if (!url || !anonKey || !serviceKey) {
    return null;
  }

  const missing: string[] = [];
  const placeholder: string[] = [];

  if (url.includes('your_') || url.includes('_here')) placeholder.push('NEXT_PUBLIC_SUPABASE_URL');
  if (anonKey.includes('your_') || anonKey.includes('_here')) placeholder.push('NEXT_PUBLIC_SUPABASE_ANON_KEY');
  if (serviceKey.includes('your_') || serviceKey.includes('_here')) placeholder.push('SUPABASE_SERVICE_ROLE_KEY');

  if (placeholder.length > 0) {
    throw new Error(`Supabase configuration contains placeholders: [${placeholder.join(', ')}]`);
  }

  return { url, anonKey, serviceKey };
}

export async function createClient() {
  const config = validateSupabaseConfig();
  if (!config) {
    throw new Error('Supabase credentials not configured. Please update .env.local');
  }

  const cookieStore = await cookies();

  return createServerClient(
    config.url,
    config.anonKey,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Called from a Server Component — safe to ignore
          }
        },
      },
    }
  );
}

export function createServiceClient() {
  const config = validateSupabaseConfig();
  if (!config) {
    throw new Error('Supabase credentials not configured. Please update .env.local');
  }
  
  return createServerClient(
    config.url,
    config.serviceKey,
    {
      cookies: {
        getAll() {
          return [];
        },
        setAll() {},
      },
    }
  );
}
