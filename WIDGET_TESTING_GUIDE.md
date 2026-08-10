# Widget Testing Guide

## Quick Test on Your Portfolio

1. **Add this code to your portfolio HTML** (before closing `</body>` tag):

```html
<script>
  window.SupportAIConfig = {
    chatbotId: "YOUR_CHATBOT_ID_HERE",
    apiUrl: "https://mj-talk.vercel.app"
  };
</script>
<script src="https://mj-talk.vercel.app/widget.js"></script>
```

2. **Replace `YOUR_CHATBOT_ID_HERE`** with your actual chatbot ID from the dashboard

3. **Open your portfolio** in a browser

---

## What to Test

### Visual Appearance ✨
- [ ] Launcher button appears in bottom-right (white circle with gray icon)
- [ ] Button has subtle shadow, no bright colors
- [ ] Click opens chat smoothly (no jarring animation)
- [ ] Chat window is 380px × 600px with clean white background
- [ ] Header has gray text, no colored gradient
- [ ] Messages use gray tones (dark gray for user, white+border for bot)
- [ ] Input bar at bottom is clean with no emoji/attachment buttons
- [ ] Send button is solid dark gray (not gradient)
- [ ] Overall vibe feels professional like Intercom/Linear

### Transparency ✨
- [ ] No white box around the widget
- [ ] Widget blends naturally on dark background
- [ ] Only the actual chat window has white background
- [ ] Launcher button background is white (intentional)

### Functionality
- [ ] Click launcher → chat opens
- [ ] Type message → sends successfully
- [ ] Bot responds (may take a few seconds)
- [ ] Click minimize → shows minimized pill
- [ ] Click pill → reopens chat
- [ ] Click reset → clears conversation
- [ ] Click X → closes widget
- [ ] Sound toggle works (if bot responds)

### Pre-Chat Form (if enabled)
- [ ] Form appears when opening for first time
- [ ] Clean white/gray styling
- [ ] Can submit name & email
- [ ] After submit, chat starts normally

### Edge Cases
- [ ] Works on mobile viewport (full screen on small screens)
- [ ] Refresh page → conversation persists
- [ ] Multiple messages → scrolls smoothly
- [ ] Long messages → wrap properly, don't break layout
- [ ] Fast typing → textarea expands/contracts correctly

---

## Keyboard Shortcuts

- **Enter**: Send message
- **Shift + Enter**: New line in message
- **Esc**: Close widget (native browser behavior)

---

## Browser Compatibility

Test in:
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox
- ✅ Safari (desktop & mobile)

---

## Expected Visual States

### 1. Closed State
- White circular button in bottom-right
- Gray MessageCircle icon
- Subtle shadow

### 2. Opening Animation
- Smooth slide-up from bottom-right
- Gentle scale effect
- Duration: ~300ms

### 3. Open State - Header
- White background
- Bot name in gray-900
- Status indicator (small dot)
- Gray icon buttons (sound, minimize, reset, close)

### 4. Open State - Messages
- Off-white background (#fafafa)
- User messages: dark gray bubble, white text
- Bot messages: white bubble, gray text, subtle border
- Timestamps in light gray

### 5. Open State - Input
- White background
- Gray-bordered textarea
- Dark gray send button
- "Powered by MJ.TALK" footer in light gray

### 6. Minimized State
- White rounded pill
- Bot icon + name
- Unread count badge (if any)

---

## Common Issues & Solutions

### Issue: Widget not appearing
**Solution**: Check browser console for errors, verify chatbotId is correct

### Issue: White box around widget on dark background
**Solution**: Already fixed! Transparency is built-in

### Issue: Colors look different
**Solution**: Clear browser cache, hard refresh (Ctrl+Shift+R)

### Issue: API errors
**Solution**: Check that MJ.TALK backend is running on Vercel

### Issue: Messages not sending
**Solution**: 
1. Check database is configured (see DATABASE_MIGRATION_STATUS.md)
2. Verify Supabase credentials in Vercel environment variables
3. Check Vercel deployment logs

---

## Developer Testing (Local)

If testing locally before deploying:

1. **Start dev server**:
   ```bash
   npm run dev
   ```

2. **Update embed script** to point to localhost:
   ```javascript
   window.SupportAIConfig = {
     chatbotId: "your-bot-id",
     apiUrl: "http://localhost:3000"
   };
   ```

3. **Test widget at**: `http://localhost:3000/widget/your-bot-id`

---

## Performance Check

The widget should:
- Load in < 2 seconds
- Open/close instantly (no lag)
- Scroll smoothly with many messages
- Not impact host page performance
- Work on 3G connection (throttle in DevTools to test)

---

## Accessibility Check

- [ ] Can tab through all buttons
- [ ] Focus indicators visible
- [ ] Can use keyboard to send messages
- [ ] Screen reader announces widget state
- [ ] Color contrast meets WCAG AA standards

---

## Next Steps After Testing

1. ✅ If everything works → You're done! Widget is production-ready
2. 🔧 If colors need tweaking → Edit widget-app.tsx color values
3. 🐛 If bugs found → Report them and I'll fix
4. 📝 If features needed → Document requirements for next iteration

---

## Quick Visual Reference

**Professional SaaS Chat Widget Checklist:**
- ✅ Clean, minimal design
- ✅ Muted gray color palette
- ✅ No gradients or bright colors
- ✅ Subtle shadows and borders
- ✅ Smooth, understated animations
- ✅ Consistent spacing and typography
- ✅ Professional status indicators
- ✅ Clean input area (no clutter)
- ✅ Transparent embedding
- ✅ Responsive on all devices

**Avoid:**
- ❌ Bright, saturated colors
- ❌ Gradient backgrounds everywhere
- ❌ Overly rounded corners
- ❌ Playful emoji pickers
- ❌ Flashy animations
- ❌ AI-generated template vibes

---

**Status**: Widget redesign complete and ready for production testing! 🚀
