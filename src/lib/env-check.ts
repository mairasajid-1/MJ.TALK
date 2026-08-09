// Environment Configuration Checker
// This will help identify missing required environment variables

export function checkEnvironment() {
  const required = {
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
  };

  const missing: string[] = [];
  const placeholder: string[] = [];

  for (const [key, value] of Object.entries(required)) {
    if (!value) {
      missing.push(key);
    } else if (value.includes('your_') || value.includes('_here')) {
      placeholder.push(key);
    }
  }

  if (missing.length > 0 || placeholder.length > 0) {
    console.error('🚨 CONFIGURATION REQUIRED');
    console.error('─────────────────────────');
    
    if (missing.length > 0) {
      console.error('❌ Missing environment variables:');
      missing.forEach(key => console.error(`   • ${key}`));
    }
    
    if (placeholder.length > 0) {
      console.error('❌ Placeholder values detected (need real values):');
      placeholder.forEach(key => console.error(`   • ${key}: ${required[key as keyof typeof required]}`));
    }
    
    console.error('\n📋 TO FIX:');
    console.error('1. Go to https://app.supabase.com');
    console.error('2. Select your project → Settings → API');
    console.error('3. Copy the Project URL and Keys');
    console.error('4. Update .env.local with real values');
    console.error('5. Restart your development server');
    
    return false;
  }

  console.log('✅ Environment configuration looks good');
  return true;
}

// Auto-check in development
if (process.env.NODE_ENV === 'development') {
  checkEnvironment();
}