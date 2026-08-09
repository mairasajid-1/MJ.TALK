import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// Check if Supabase is properly configured
function validateSupabaseConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  const missing: string[] = [];
  const placeholder: string[] = [];

  if (!url) missing.push('NEXT_PUBLIC_SUPABASE_URL');
  else if (url.includes('your_') || url.includes('_here')) placeholder.push('NEXT_PUBLIC_SUPABASE_URL');

  if (!anonKey) missing.push('NEXT_PUBLIC_SUPABASE_ANON_KEY'); 
  else if (anonKey.includes('your_') || anonKey.includes('_here')) placeholder.push('NEXT_PUBLIC_SUPABASE_ANON_KEY');

  if (!serviceKey) missing.push('SUPABASE_SERVICE_ROLE_KEY');
  else if (serviceKey.includes('your_') || serviceKey.includes('_here')) placeholder.push('SUPABASE_SERVICE_ROLE_KEY');

  if (missing.length > 0 || placeholder.length > 0) {
    throw new Error(`Supabase configuration required. Missing: [${missing.join(', ')}]. Placeholders: [${placeholder.join(', ')}]`);
  }

  return { url, anonKey, serviceKey };
}

export async function createClient() {
  const config = validateSupabaseConfig();
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
