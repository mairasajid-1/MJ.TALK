# ⚡ MJ.TALK Quick Reference Card

## 🎯 Status
- ✅ Code Complete & Pushed
- ⏳ Awaiting: Environment Variables in Vercel
- Repository: https://github.com/mairasajid-1/MJ.TALK

---

## 🚀 3-Step Deployment

### Step 1️⃣: Set Vercel Env Vars (5 min)
```
https://vercel.com/dashboard → mj-talk → Settings → Environment Variables

Required:
NEXT_PUBLIC_SUPABASE_URL=https://your.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
NEXT_PUBLIC_APP_URL=https://mj-talk.vercel.app
```

### Step 2️⃣: Apply DB Migrations (10 min)
```
https://app.supabase.com → SQL Editor → Run these 6 files:

1. 001_phase1_enhanced_schema.sql
2. 002_phase3_realtime.sql
3. 003_phase5_ai_hybrid.sql
4. 004_phase8_rbac.sql
5. 005_fix_realtime_rls.sql
6. 007_fix_rls_recursion.sql ⚠️ IMPORTANT
```

### Step 3️⃣: Verify (5 min)
```
Wait 2-3 min for Vercel build, then check:

✅ https://mj-talk.vercel.app/api/status → {status: "HEALTHY"}
✅ https://mj-talk.vercel.app/debug/config → All green
✅ https://mj-talk.vercel.app/signup → Try create account
```

---

## 🔧 Local Development

```bash
# Setup
npm install
# Update .env.local with real Supabase credentials
npm run dev

# Visit
http://localhost:3000                  # App
http://localhost:3000/debug/config     # Status
http://localhost:3000/api/status       # Health check
http://localhost:3000/signup           # Test signup
```

---

## 📚 Key Documents

| Doc | When | Read Time |
|-----|------|-----------|
| `README_SETUP.md` | First time | 3 min |
| `ACTION_ITEMS.md` | Ready to deploy | 5 min |
| `DEPLOYMENT.md` | Detailed help | 10 min |
| `TROUBLESHOOTING.md` | Something broke | Varies |

---

## 🐛 Troubleshooting

### "401 errors"
→ Check Supabase credentials in .env.local/Vercel

### "/api/status returns 503"
→ Environment variables not set in Vercel

### "Signup returns 400"
→ Visit `/debug/config` to see exact issue

### "Build failed on Vercel"
→ Check Vercel build logs
→ Ensure all environment variables set

---

## 🔗 Quick Links

```
GitHub:   https://github.com/mairasajid-1/MJ.TALK
Vercel:   https://vercel.com/dashboard/mj-talk
Supabase: https://app.supabase.com

Dev:      http://localhost:3000
Live:     https://mj-talk.vercel.app
Config:   [same]/debug/config
Status:   [same]/api/status
```

---

## ✅ Checklist

- [ ] Read `ACTION_ITEMS.md`
- [ ] Set Vercel env vars (Step 1)
- [ ] Apply migrations (Step 2)
- [ ] Verify deployment (Step 3)
- [ ] Test signup
- [ ] Test login
- [ ] Monitor errors

---

## 🎯 What's New

✨ **Added Features:**
- `/debug/config` - Configuration status
- `/api/status` - Health check
- Better error messages
- Full documentation

🔧 **Fixed Issues:**
- 401 auth errors
- 400 bad request errors
- Missing config guidance

---

## 📊 File Structure

```
📁 supabase/migrations/      ← DB migrations (run in order)
📁 src/app/
  ├─ debug/config/          ← Configuration dashboard
  ├─ api/status/            ← Health check endpoint
  ├─ (auth)/signup          ← Signup page (improved)
  └─ ...other pages
📁 src/lib/
  ├─ supabase/              ← Supabase clients
  ├─ env-check.ts           ← Validation
  └─ api-error-handler.ts   ← Error handling
```

---

## ⏱️ Timeline

- **10 minutes ago:** Code pushed to GitHub
- **Now:** You're here reading this
- **5 minutes:** Set environment variables
- **10 minutes:** Apply migrations
- **5 minutes:** Verify deployment
- **20 minutes total:** Live on Vercel! 🎉

---

## 🆘 Need Help?

1. **Configuration:** Visit `/debug/config` page
2. **Common Issues:** See `TROUBLESHOOTING.md`
3. **Deployment:** See `DEPLOYMENT.md`
4. **Quick Start:** See `README_SETUP.md`

---

**Status:** ✅ Ready to Deploy  
**Time to Live:** ~20 minutes  
**Next Step:** Follow the 3-step deployment above  

Go! 🚀