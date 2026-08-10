# Quick Fix Reference

## What Was Fixed

### ✅ Widget Not Opening
**Problem:** Button appears, but clicking doesn't open chat window
**Root Cause:** Missing `<html>` and `<body>` tags in widget layout
**Fixed In:** `src/app/widget/layout.tsx`

### ✅ CSS Not Applied  
**Problem:** Widget looks unstyled, Tailwind classes not working
**Root Cause:** Missing font import and className bindings
**Fixed In:** `src/app/widget/layout.tsx`

### ✅ Navbar Links Not Clickable
**Problem:** Transparent widget blocks clicks on page elements
**Root Cause:** Iframe has `pointer-events: all`
**Fixed In:** `public/widget.js` and `src/components/widget/widget-app.tsx`

### ✅ Removed Unnecessary Buttons
**Removed:** Sound toggle and minimize button
**Fixed In:** `src/components/widget/widget-app.tsx`

---

## Test Commands

```bash
# Start dev server
npm run dev

# Visit widget directly
open http://localhost:3000/widget/YOUR_CHATBOT_ID

# Deploy
git add .
git commit -m "Fix all widget issues"
git push
```

---

## Embed Code for Your Portfolio

```html
<!-- Place before closing </body> tag -->
<script>
  window.SupportAIConfig = {
    chatbotId: "YOUR_CHATBOT_ID",
    apiUrl: "https://your-domain.vercel.app"
  };
</script>
<script src="https://your-domain.vercel.app/widget.js"></script>
```

---

## Expected Behavior After Fix

1. Widget button appears (white circle, bottom-right)
2. All page elements clickable (navbar, links, buttons)
3. Click widget button → chat window opens
4. Chat window styled properly (white, clean, professional)
5. Messages can be sent and received
6. Dashboard receives messages in real-time

---

## If Still Not Working

### Widget not appearing at all:
1. Check chatbotId is correct
2. Check chatbot is "active" in dashboard
3. Check browser console for errors
4. Verify apiUrl matches your Vercel domain

### Widget appears but no styles:
1. Hard refresh: Ctrl+Shift+R (Cmd+Shift+R)
2. Clear browser cache
3. Check browser console for CSS errors
4. Restart dev server

### Widget appears but won't open:
1. Check browser console for JavaScript errors
2. Verify database migration applied
3. Check Supabase credentials in Vercel env vars
4. Test on different browser

### Navbar still blocked:
1. Make sure latest code deployed
2. Clear browser cache
3. Check `pointer-events: none` is set on iframe
4. Verify widget.js loaded from correct domain

---

## Support Checklist

Before asking for help, verify:

- [ ] Latest code pulled/deployed
- [ ] Browser cache cleared
- [ ] Dev server restarted
- [ ] No console errors
- [ ] Tested on different browser
- [ ] Correct chatbotId used
- [ ] Chatbot is active in dashboard
- [ ] Database migration applied
- [ ] Supabase env vars set in Vercel

---

## Files Modified (Complete List)

1. `src/app/widget/layout.tsx` — Added HTML structure, fonts
2. `src/components/widget/widget-app.tsx` — Removed buttons, added pointer-events
3. `public/widget.js` — Fixed pointer-events on iframe

---

**Status:** All fixes complete ✅  
**Ready to deploy:** Yes  
**Next step:** `git push` and test on live site
