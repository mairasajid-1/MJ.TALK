# MJ.TALK Troubleshooting Guide

## 🚨 Common Issues

### Issue 1: "Failed to fetch" or 400/401 errors on signup

**Cause:** Supabase credentials are missing or using placeholder values.

**Fix:**
1. Open `SETUP.md` and follow the setup steps
2. Visit `/debug/config` to check configuration status
3. Verify `.env.local` has real Supabase credentials (not placeholder values)
4. Restart your development server after updating `.env.local`

### Issue 2: Signup form shows "Setup required" message

**Cause:** Server cannot connect to Supabase because credentials aren't configured.

**Fix:**
1. Check `.env.local` for placeholder values like `your_supabase_url_here`
2. Get your actual Supabase credentials:
   - Go to https://app.supabase.com
   - Select your project → Settings → API
   - Copy the actual values
3. Replace placeholder values in `.env.local`
4. Restart the dev server: `npm run dev`

### Issue 3: Network error when trying to create an account

**Cause:** Possible CORS issue or environment variable not set correctly.

**Fix:**
```bash
# Clear node modules and reinstall
rm -r node_modules
npm install

# Clear .next build cache
rm -r .next

# Restart dev server
npm run dev
```

### Issue 4: "Supabase configuration required" error

**Cause:** The application detected placeholder environment variables.

**Fix:**
1. Open `.env.local`
2. Look for lines with `your_` or `_here` in the values
3. Replace these with actual values from your Supabase project
4. Example:
   ```env
   # Before (wrong):
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url_here
   
   # After (correct):
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   ```

---

## 🔍 Debugging Steps

### Step 1: Check Environment Configuration

Open `http://localhost:3000/debug/config` in your browser. This page shows:
- ✅ What's configured correctly
- ❌ What's missing
- ⚠️ What has warnings

### Step 2: Check Browser Console

Open Developer Tools (F12) and look at the Console tab for error messages:
- `401 Unauthorized` → Auth issue, check credentials
- `503 Service Unavailable` → Server configuration error
- `Network error` → Connection issue

### Step 3: Check Server Logs

When running `npm run dev`, look at the terminal output for error messages.

### Step 4: Verify Supabase Project

1. Go to https://app.supabase.com
2. Select your project
3. Check Status → All systems operational
4. Check Auth → Users (should show your test account if you've signed up)

---

## 📋 Configuration Checklist

Required before signup works:

- [ ] Have a Supabase project created
- [ ] Retrieved Project URL from Settings → API
- [ ] Retrieved Anonymous Key from Settings → API
- [ ] Retrieved Service Role Key from Settings → API
- [ ] Updated `.env.local` with real values
- [ ] No placeholder values in `.env.local`
- [ ] Restarted dev server after updating `.env.local`
- [ ] Can access `/debug/config` and see green checks

---

## 🆘 Still Having Issues?

### Check These Files

1. **`.env.local`** - Contains your Supabase credentials
   - Should NOT have placeholder values
   - Should NOT be in git (it's in .gitignore)
   
2. **`src/lib/supabase/server.ts`** - Server-side Supabase client
   - Has validation that checks credentials
   - Throws errors if credentials are missing

3. **`src/lib/supabase/client.ts`** - Client-side Supabase client
   - Used for sign-in/sign-up operations

### Run Diagnostics

```bash
# Check if Next.js can find environment variables
npm run build

# Look for configuration errors during build
# Fix any errors and try again

# Restart dev server
npm run dev
```

### Contact Support

If you're still stuck:
1. Visit `http://localhost:3000/debug/config`
2. Screenshot or copy the configuration status
3. Contact support with:
   - The configuration status
   - Error message from browser console
   - Your `.env.local` file (WITHOUT secret values)

---

## ℹ️ Quick Reference

### Environment Variables Required for Signup

| Variable | Source | Example |
|----------|--------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase Settings → API | `https://xyz.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase Settings → API | `eyJhbGc...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Settings → API | `eyJhbGc...` |

### Optional but Recommended

| Variable | Purpose |
|----------|---------|
| `OPENROUTER_API_KEY` | AI features |
| `RESEND_API_KEY` | Email support |
| `STRIPE_SECRET_KEY` | Billing features |

---

## 🔗 Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)
- [Project Setup Guide](SETUP.md)

