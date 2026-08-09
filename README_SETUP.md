# 🚀 MJ.TALK - Quick Start Guide

Welcome to MJ.TALK! This is an AI-powered live chat and support platform. Get started in 5 minutes.

## ⚡ Quick Start (5 minutes)

### 1️⃣ Clone & Install
```bash
git clone https://github.com/mairasajid-1/MJ.TALK.git
cd MJ.TALK
npm install
```

### 2️⃣ Get Supabase Credentials
1. Go to https://app.supabase.com
2. Create a new project (or use existing one)
3. Go to Settings → API
4. Copy these 3 values:
   - **Project URL** (e.g., `https://xyz.supabase.co`)
   - **anon public key** (starts with `eyJ...`)
   - **service_role key** (starts with `eyJ...`)

### 3️⃣ Configure Environment
Edit `.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...your-anon-key...
SUPABASE_SERVICE_ROLE_KEY=eyJ...your-service-role-key...

# Optional
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 4️⃣ Apply Database Schema
1. Go to Supabase Dashboard → SQL Editor
2. Run these files in order:
   - `supabase/migrations/001_phase1_enhanced_schema.sql`
   - `supabase/migrations/002_phase3_realtime.sql`
   - `supabase/migrations/003_phase5_ai_hybrid.sql`
   - `supabase/migrations/004_phase8_rbac.sql`
   - `supabase/migrations/005_fix_realtime_rls.sql`
   - `supabase/migrations/007_fix_rls_recursion.sql` ⚠️ **Important!**

### 5️⃣ Start Development Server
```bash
npm run dev
```

Visit http://localhost:3000 in your browser!

---

## 📋 What to Try

### Create Account
1. Go to `/signup`
2. Enter your details
3. Should see success message

### Admin Dashboard
1. After signup, you're in the dashboard
2. Create a chatbot
3. Get embed code for your website

### Debug Configuration
- Visit http://localhost:3000/debug/config
- Should show all green ✅ checks

---

## 🆘 Common Issues

### "Failed to fetch" or 400 errors?
→ Check `.env.local` - make sure you have real Supabase credentials (not placeholders)

### "Setup required" message?
→ Visit `/debug/config` to see what's missing

### Can't sign up?
→ Check browser console (F12) for error messages

**See `TROUBLESHOOTING.md` for detailed help**

---

## 📚 Documentation

- **Setup Guide:** `SETUP.md` - Detailed configuration
- **Troubleshooting:** `TROUBLESHOOTING.md` - Common issues & fixes
- **Deployment:** `DEPLOYMENT.md` - Deploy to Vercel
- **RLS Migration:** `supabase/migrations/007_fix_rls_recursion.sql` - Database security

---

## 🛠️ Development Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Run linter
npm run lint

# Format code
npm run format

# Type check
npm run type-check
```

---

## 🔍 Project Structure

```
src/
├── app/                    # Next.js app directory
│   ├── (auth)/            # Login/signup pages
│   ├── dashboard/         # User dashboard
│   ├── api/               # API routes
│   ├── debug/config       # Configuration status page
│   └── layout.tsx         # Root layout
├── components/            # Reusable components
├── lib/                   # Utilities & helpers
│   ├── supabase/         # Supabase clients
│   └── api-error-handler.ts  # Error handling
└── hooks/                # Custom React hooks

supabase/
├── migrations/           # Database migrations
└── fix-rls-policies.sql  # RLS policy fixes
```

---

## 🌐 Deployment

### Vercel (Recommended)
```bash
# Connect GitHub repo to Vercel
# Auto-deploys on push to main branch
```

See `DEPLOYMENT.md` for full instructions.

---

## 📞 Support

- **Configuration Help:** `/debug/config`
- **Status Check:** `/api/status`
- **Email:** support@yourdomain.com

---

## 🎯 Next Steps

1. ✅ Setup complete?
2. → Create your first chatbot
3. → Get the embed code
4. → Add to your website
5. → Test with live customers

---

## 📝 Features

- ✨ AI-powered support chatbot
- 👥 Live chat with human agents
- 📊 Analytics & insights
- 💳 Billing integration (Stripe)
- 🔒 Enterprise security (RLS)
- ⚡ Real-time updates
- 📱 Mobile responsive
- 🎨 Customizable theme

---

**Ready? Start at http://localhost:3000/signup**

For questions, see our docs or contact support!