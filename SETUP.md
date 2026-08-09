# MJ.TALK Setup Guide

## 🚨 REQUIRED: Supabase Configuration

Your application is currently showing authentication errors because Supabase credentials are not configured.

### Step 1: Get Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project (or create a new one)
3. Navigate to **Settings** → **API**
4. Copy these values:
   - **Project URL** (something like `https://your-project.supabase.co`)
   - **anon public** key (starts with `eyJ...`)
   - **service_role** key (also starts with `eyJ...`)

### Step 2: Update Environment Variables

Edit `.env.local` and replace the placeholder values:

```env
# Replace these placeholder values with your actual Supabase credentials:
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...your-anon-key...
SUPABASE_SERVICE_ROLE_KEY=eyJ...your-service-role-key...
```

### Step 3: Apply Database Schema

Run the migrations in Supabase Dashboard → SQL Editor:

1. **`001_phase1_enhanced_schema.sql`** - Core schema
2. **`002_phase3_realtime.sql`** - Real-time features  
3. **`003_phase5_ai_hybrid.sql`** - AI functionality
4. **`004_phase8_rbac.sql`** - Role-based access control
5. **`005_fix_realtime_rls.sql`** - Real-time security fixes
6. **`007_fix_rls_recursion.sql`** - RLS recursion fix ⚠️ **IMPORTANT**

### Step 4: Restart Development Server

After updating `.env.local`:

```bash
npm run dev
```

## Current Issues (Will be fixed after setup):

- ❌ Failed to load resource: `/api/auth/signup:1` (401)
- ❌ Failed to load resource: `/api/auth/me` (401) 
- ❌ Authentication errors preventing login

## Optional Configuration

### AI Features (OpenRouter)
```env
OPENROUTER_API_KEY=your_openrouter_key_here
```

### Email Support (Resend)
```env
RESEND_API_KEY=your_resend_key_here
```

### Billing (Stripe)
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## Need Help?

If you're still seeing errors after configuration:

1. Check browser console for specific error messages
2. Verify Supabase project is active and accessible
3. Ensure all migration files were run successfully
4. Check that environment variables don't have typos

The app includes automatic environment validation that will guide you through missing configuration.