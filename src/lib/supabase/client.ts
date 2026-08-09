import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

let _client: SupabaseClient | null = null;

// Check if Supabase is properly configured
function validateSupabaseConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error('Supabase configuration missing. Please check your environment variables.');
  }

  if (url.includes('your_') || url.includes('_here') || anonKey.includes('your_') || anonKey.includes('_here')) {
    throw new Error('Supabase configuration contains placeholder values. Please update .env.local with actual credentials.');
  }

  return { url, anonKey };
}

export function createClient(): SupabaseClient {
  // Guard — never run on the server
  if (typeof window === "undefined") {
    // Return a throw-away instance that won't crash
    // (should never actually be called server-side after our fixes)
    return createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
  }

  // Validate configuration
  const config = validateSupabaseConfig();

  // Singleton so we only ever create one Realtime connection
  if (!_client) {
    _client = createBrowserClient(config.url, config.anonKey);
  }

  return _client;
}
