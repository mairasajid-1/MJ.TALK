import { NextResponse } from "next/server";

export async function GET() {
  const checks = {
    environment: "OK",
    supabase: "CHECKING",
    timestamp: new Date().toISOString()
  };

  // Check environment variables
  const requiredEnvVars = [
    'NEXT_PUBLIC_SUPABASE_URL',
    'NEXT_PUBLIC_SUPABASE_ANON_KEY', 
    'SUPABASE_SERVICE_ROLE_KEY'
  ];

  const missing = requiredEnvVars.filter(key => !process.env[key]);
  const placeholders = requiredEnvVars.filter(key => {
    const value = process.env[key];
    return value && (value.includes('your_') || value.includes('_here'));
  });

  if (missing.length > 0) {
    checks.environment = `MISSING: ${missing.join(', ')}`;
  } else if (placeholders.length > 0) {
    checks.environment = `PLACEHOLDER: ${placeholders.join(', ')}`;
  }

  // Try Supabase connection
  try {
    const { createServiceClient } = await import("@/lib/supabase/server");
    const supabase = createServiceClient();
    
    // Simple health check query
    const { error } = await supabase.from('organizations').select('id').limit(1);
    
    if (error) {
      checks.supabase = `ERROR: ${error.message}`;
    } else {
      checks.supabase = "OK";
    }
  } catch (error: any) {
    checks.supabase = `CONFIG_ERROR: ${error.message}`;
  }

  const hasErrors = checks.environment !== "OK" || checks.supabase !== "OK";
  const status = hasErrors ? 503 : 200;

  return NextResponse.json({
    status: hasErrors ? "SETUP_REQUIRED" : "HEALTHY",
    checks
  }, { status });
}