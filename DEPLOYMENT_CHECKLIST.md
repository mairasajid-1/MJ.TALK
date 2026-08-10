# Deployment Checklist

## ✅ Widget Redesign Complete

The MJ.TALK widget has been completely redesigned to professional standards. Follow this checklist to deploy it.

---

## Pre-Deployment Checks

### 1. Local Testing ✓
```bash
npm run dev
```
- [ ] Server starts without errors
- [ ] Visit `http://localhost:3000/widget/YOUR_BOT_ID`
- [ ] Widget renders correctly
- [ ] All interactions work (open, close, send message, minimize)
- [ ] No console errors

### 2. Code Quality ✓
- [x] TypeScript compilation passes
- [x] No ESLint errors
- [x] No console warnings
- [x] All imports resolved

### 3. Environment Variables
Check `.env.local` has:
- [ ] `NEXT_PUBLIC_SUPABASE_URL` set
- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY` set
- [ ] `OPENAI_API_KEY` set (for AI responses)
- [ ] Other required keys configured

---

## Database Setup

### Migration Status
According to `DATABASE_MIGRATION_STATUS.md`, you need to:

1. [ ] **Apply migration** `003_complete_database_schema.sql`
   - Go to Supabase Dashboard → SQL Editor
   - Copy content from `supabase/migrations/003_complete_database_schema.sql`
   - Execute it
   - Verify no errors

2. [ ] **Verify tables exist**:
   - chatbots (with new columns)
   - conversations
   - messages
   - profiles
   - agent_status
   - typing_indicators
   - kb_articles
   - purchase_requests

3. [ ] **Test database connection**:
   - Create a test chatbot in dashboard
   - Send a test message through widget
   - Verify it saves to database

---

## Vercel Deployment

### Option 1: Git Push (Recommended)
```bash
# Commit changes
git add .
git commit -m "Redesign widget to professional minimal style"

# Push to GitHub
git push origin main
```

Vercel will automatically:
- Detect the push
- Build the project
- Deploy to production
- Provide deployment URL

### Option 2: Manual Deploy
```bash
# Install Vercel CLI if not already
npm i -g vercel

# Deploy
vercel --prod
```

### Verify Deployment
- [ ] Deployment succeeds without errors
- [ ] Check Vercel dashboard for build logs
- [ ] Visit production URL
- [ ] Test widget at `https://your-domain.vercel.app/widget/YOUR_BOT_ID`

---

## Environment Variables on Vercel

Make sure Vercel has these set:

1. Go to Vercel Dashboard → Project → Settings → Environment Variables

2. Add/verify:
   - [ ] `NEXT_PUBLIC_SUPABASE_URL`
   - [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - [ ] `SUPABASE_SERVICE_ROLE_KEY` (for admin operations)
   - [ ] `OPENAI_API_KEY`
   - [ ] `STRIPE_SECRET_KEY` (if using payments)
   - [ ] `STRIPE_WEBHOOK_SECRET` (if using payments)
   - [ ] `NEXT_PUBLIC_APP_URL` (your Vercel URL)

3. After adding/changing variables:
   - [ ] Redeploy from Vercel dashboard

---

## Production Testing

### 1. Widget Functionality
Visit: `https://your-domain.vercel.app/widget/YOUR_BOT_ID`

- [ ] Widget loads
- [ ] Launcher button appears (white circle, gray icon)
- [ ] Click opens chat window
- [ ] Chat window is properly styled (white, clean, minimal)
- [ ] Can type and send messages
- [ ] Bot responds (may take a few seconds)
- [ ] Messages are styled correctly:
  - [ ] User: dark gray bubble
  - [ ] Bot: white bubble with gray border
- [ ] Typing indicator appears
- [ ] Minimize button works
- [ ] Reset button clears conversation
- [ ] Close button hides widget
- [ ] Sound toggle works
- [ ] No console errors

### 2. Embedding on Portfolio

Copy from `EMBED_CODE.html`:

```html
<script>
  window.SupportAIConfig = {
    chatbotId: "YOUR_CHATBOT_ID_HERE",
    apiUrl: "https://your-domain.vercel.app"
  };
</script>
<script src="https://your-domain.vercel.app/widget.js"></script>
```

Test on portfolio:
- [ ] Widget appears in bottom-right
- [ ] No white box around widget (transparent)
- [ ] Works on dark background
- [ ] Opens/closes smoothly
- [ ] Messages send and receive
- [ ] Looks professional and minimal
- [ ] Mobile responsive

### 3. Cross-Browser Testing
- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari (desktop)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

### 4. Performance
- [ ] Widget loads in < 2 seconds
- [ ] No layout shift when loading
- [ ] Smooth 60fps animations
- [ ] Doesn't block page load

---

## Post-Deployment

### 1. Monitor
- [ ] Check Vercel logs for errors
- [ ] Monitor Supabase database for test conversations
- [ ] Check browser console on embedded page

### 2. Analytics (Optional)
- [ ] Set up Vercel Analytics
- [ ] Monitor widget usage
- [ ] Track conversation metrics

### 3. Backup
- [ ] Ensure database is backed up (Supabase handles this)
- [ ] Keep migration files in version control
- [ ] Document any custom configuration

---

## Rollback Plan (If Needed)

If something goes wrong:

1. **Revert deployment** on Vercel:
   - Go to Deployments tab
   - Find previous working deployment
   - Click "..." → "Promote to Production"

2. **Revert code locally**:
   ```bash
   git log  # Find previous commit
   git revert HEAD  # Or specific commit hash
   git push
   ```

3. **Check database**:
   - If migration caused issues, restore from backup
   - Contact Supabase support if needed

---

## Common Issues & Solutions

### Issue: Widget not appearing
**Causes:**
- Wrong chatbot ID
- CORS issues
- Script path incorrect

**Solutions:**
- Double-check chatbot ID in dashboard
- Verify `apiUrl` in embed script
- Check browser console for errors

### Issue: White box on dark background
**Status:** ✅ Already fixed in redesign
- Transparency is built-in
- Should work out of the box

### Issue: Messages not sending
**Causes:**
- Database not set up
- Environment variables missing
- API errors

**Solutions:**
- Run migration `003_complete_database_schema.sql`
- Verify all env vars on Vercel
- Check Vercel function logs

### Issue: Bot not responding
**Causes:**
- OpenAI API key missing/invalid
- API rate limit hit
- Chatbot not configured

**Solutions:**
- Verify `OPENAI_API_KEY` on Vercel
- Check OpenAI account status
- Configure chatbot in dashboard (system prompt, etc.)

### Issue: Styling looks wrong
**Causes:**
- Browser cache
- Build didn't complete
- CSS not loading

**Solutions:**
- Hard refresh: Ctrl+Shift+R (Cmd+Shift+R on Mac)
- Clear browser cache
- Rebuild on Vercel

---

## Success Criteria

Widget is successfully deployed when:
- ✅ Loads on portfolio site
- ✅ Looks professional and minimal
- ✅ All interactions work
- ✅ Messages send and receive
- ✅ No errors in console
- ✅ Works on mobile
- ✅ Works across browsers
- ✅ Transparent on dark backgrounds

---

## Documentation References

- `WIDGET_REDESIGN_COMPLETE.md` — Full design documentation
- `WIDGET_TESTING_GUIDE.md` — How to test thoroughly
- `VISUAL_CHANGES.md` — Before/after visual comparison
- `REDESIGN_SUMMARY.md` — Executive summary
- `EMBED_CODE.html` — Copy-paste embed code
- `DATABASE_MIGRATION_STATUS.md` — Database setup status

---

## Support

If you encounter issues:

1. Check Vercel deployment logs
2. Check browser console errors
3. Verify environment variables
4. Test database connection
5. Review documentation files above

---

## Timeline

- [x] **Design phase**: Complete
- [x] **Code changes**: Complete
- [x] **Local testing**: Ready
- [ ] **Database migration**: User action required
- [ ] **Vercel deployment**: User action required
- [ ] **Production testing**: After deployment
- [ ] **Portfolio integration**: After testing

---

## Next Action Required

👉 **YOU NEED TO DO:**

1. **Apply database migration**:
   - Open Supabase Dashboard
   - Go to SQL Editor
   - Run `003_complete_database_schema.sql`

2. **Deploy to Vercel**:
   ```bash
   git add .
   git commit -m "Redesign widget to professional minimal style"
   git push
   ```

3. **Test production URL**:
   - Visit widget page
   - Verify styling and functionality

4. **Embed on portfolio**:
   - Copy code from `EMBED_CODE.html`
   - Paste before `</body>` tag
   - Test live

---

**Status**: Code ready ✅ | Database pending ⏳ | Deployment pending ⏳

*Checklist created August 10, 2026*
