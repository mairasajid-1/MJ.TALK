# MJ.TALK Deployment Guide

## 🚀 Current Setup

Your application is already connected to:
- **GitHub Repository:** https://github.com/mairasajid-1/MJ.TALK
- **Vercel Project:** mj-talk (auto-deployed from main branch)

## 📋 Pre-Deployment Checklist

Before deploying to production, ensure:

### Environment Variables (Vercel)

Set these in Vercel Dashboard → Settings → Environment Variables:

```
# Supabase (Required)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# AI Features (Required for chat)
OPENROUTER_API_KEY=your_openrouter_key

# Email Support (Optional)
RESEND_API_KEY=your_resend_key

# Billing (Optional)
STRIPE_SECRET_KEY=your_stripe_secret
STRIPE_WEBHOOK_SECRET=your_webhook_secret
STRIPE_PREMIUM_PRICE_ID=price_...
STRIPE_PREMIUM_YEARLY_PRICE_ID=price_...

# App Configuration
NEXT_PUBLIC_APP_URL=https://your-deployment-url.vercel.app
NEXT_PUBLIC_SUPPORT_EMAIL=support@yourdomain.com
NEXT_PUBLIC_SUPER_ADMIN_EMAIL=your-email@domain.com
```

### Database Setup

1. **Apply all migrations** to your Supabase project:
   - `001_phase1_enhanced_schema.sql`
   - `002_phase3_realtime.sql`
   - `003_phase5_ai_hybrid.sql`
   - `004_phase8_rbac.sql`
   - `005_fix_realtime_rls.sql`
   - `007_fix_rls_recursion.sql` ⚠️ **Important!**

2. **Enable RLS (Row Level Security)** on all tables

3. **Test authentication** before going live

## 🔄 Deployment Process

### Automatic Deployment
- Every push to `main` branch triggers automatic deployment to Vercel
- Vercel builds and deploys automatically
- Check Vercel Dashboard for build status

### Manual Deployment
```bash
# Push to GitHub (triggers Vercel)
git push origin main

# OR deploy directly to Vercel
vercel --prod
```

## ✅ Post-Deployment Verification

After deployment, verify:

1. **Health Check**
   ```
   Visit: https://your-app.vercel.app/api/status
   Should return: { "status": "HEALTHY", "checks": {...} }
   ```

2. **Configuration Status**
   ```
   Visit: https://your-app.vercel.app/debug/config
   All checks should be green
   ```

3. **Authentication**
   - Try signing up at `/signup`
   - Try logging in at `/login`
   - Verify email confirmation works

4. **Dashboard Access**
   - After login, verify you can access `/dashboard`
   - Check that chatbots are accessible

## 🔐 Security Checklist

- [ ] NEVER commit `.env.local` to git (it's in .gitignore)
- [ ] All sensitive keys in Vercel Environment Variables (not in code)
- [ ] Database has RLS policies enabled
- [ ] Supabase auth is configured correctly
- [ ] CORS settings allow your domain
- [ ] Rate limiting is configured (if needed)
- [ ] HTTPS enforced
- [ ] Admin email is set to your account

## 📊 Monitoring

### Vercel Dashboard
- Check deployment logs
- Monitor performance metrics
- View error logs
- Check function durations

### Supabase Dashboard
- Monitor database usage
- Check auth logs
- Review real-time connections
- Monitor RLS policy execution

## 🐛 Troubleshooting Deployment Issues

### Build Fails
1. Check Vercel build logs
2. Ensure all environment variables are set
3. Run `npm run build` locally to reproduce
4. Check for TypeScript errors: `npm run type-check`

### 503 Service Unavailable
1. Verify Supabase credentials in Vercel env vars
2. Check Supabase project status
3. Review `/api/status` endpoint
4. Check database connection logs

### Authentication Not Working
1. Verify `NEXT_PUBLIC_SUPABASE_URL` is set
2. Verify `NEXT_PUBLIC_SUPABASE_ANON_KEY` is set
3. Test with `/debug/config` page
4. Check browser console for errors
5. Verify RLS policies are enabled

### Cookies/Session Issues
1. Ensure NEXT_PUBLIC_APP_URL matches deployment domain
2. Check cookie settings in Supabase
3. Verify SameSite cookie policies
4. Clear browser cookies and try again

## 🔗 Useful Links

- [Vercel Dashboard](https://vercel.com/dashboard)
- [GitHub Repository](https://github.com/mairasajid-1/MJ.TALK)
- [Supabase Project](https://app.supabase.com)
- [Project SETUP Guide](SETUP.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

## 📝 Release Notes

### Latest Release
- ✅ Added Supabase configuration validation
- ✅ Added debug dashboard at `/debug/config`
- ✅ Added system health check at `/api/status`
- ✅ Improved error handling and user feedback
- ✅ Added comprehensive troubleshooting guides

## 🆘 Need Help?

1. Check `/debug/config` for configuration issues
2. Review error logs in browser console
3. Check Vercel deployment logs
4. See `TROUBLESHOOTING.md` for common issues
5. Contact support at `support@yourdomain.com`

---

**Last Updated:** August 9, 2026