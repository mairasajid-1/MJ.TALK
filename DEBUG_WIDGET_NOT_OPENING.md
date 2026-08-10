# Debug: Widget Not Opening

## Symptoms
- Widget button appears on portfolio ✅
- Button is clickable (cursor changes) ✅
- Nothing happens when clicked ❌
- No chat window opens ❌

## Possible Causes & Solutions

### 1. Browser Cache (Most Likely)
**Problem:** Browser is using old JavaScript/CSS files

**Solutions:**
```
Option A: Hard Refresh
- Windows/Linux: Ctrl + Shift + R
- Mac: Cmd + Shift + R

Option B: Clear Cache
- Open Developer Tools (F12)
- Right-click refresh button
- Select "Empty Cache and Hard Reload"

Option C: Incognito/Private Mode
- Test in incognito window
- This bypasses cache completely
```

### 2. Code Not Deployed
**Problem:** Latest changes not on production

**Check:**
1. Go to Vercel Dashboard
2. Check last deployment time
3. Verify build succeeded
4. Check deployment logs for errors

**Solution:**
```bash
# Force redeploy
git add .
git commit -m "Force redeploy widget fixes"
git push
```

### 3. Wrong URL in Embed Code
**Problem:** apiUrl pointing to wrong domain

**Check your embed code:**
```html
<script>
  window.SupportAIConfig = {
    chatbotId: "YOUR_CHATBOT_ID",
    apiUrl: "https://your-domain.vercel.app"  // ← CHECK THIS
  };
</script>
<script src="https://your-domain.vercel.app/widget.js"></script>
```

**Make sure:**
- apiUrl matches your Vercel domain
- No typos in domain name
- HTTPS (not HTTP)
- No trailing slash

### 4. Chatbot Not Active
**Problem:** Chatbot status is "inactive"

**Check:**
1. Go to MJ.TALK Dashboard
2. Open Chatbots page
3. Verify your chatbot shows "active" badge
4. If inactive, click Configure and set status to active

### 5. JavaScript Errors
**Problem:** Console errors blocking execution

**Check:**
1. Open browser Developer Tools (F12)
2. Go to Console tab
3. Refresh page
4. Look for red error messages

**Common errors:**
- "chatbotId is required" → Check embed code
- "Failed to fetch" → API/database issue
- "Cannot read property" → Code error
- CORS errors → Server configuration issue

### 6. Iframe Not Loading
**Problem:** Iframe src not loading properly

**Check:**
1. Open Developer Tools (F12)
2. Go to Elements/Inspector tab
3. Find `<iframe id="supportai-widget-iframe">`
4. Check if `src` attribute is correct
5. Try opening iframe src URL directly in new tab

**Expected src:**
```
https://your-domain.vercel.app/widget/YOUR_CHATBOT_ID
```

If this URL doesn't load, that's the problem.

### 7. Pointer Events Issue
**Problem:** Button not clickable due to CSS

**Check:**
1. Open Developer Tools (F12)
2. Right-click the widget button
3. Select "Inspect Element"
4. Look at computed styles
5. Check `pointer-events` value

**Should see:**
```css
/* On button wrapper div */
pointer-events: auto;  ← Should be "auto"

/* On iframe */
pointer-events: none;  ← Should be "none"
```

If pointer-events is "none" on the button, that's the problem.

---

## Step-by-Step Debug Process

### Step 1: Open Developer Tools
```
Press F12 (or right-click → Inspect)
```

### Step 2: Check Console for Errors
```
1. Go to Console tab
2. Refresh page (F5)
3. Look for red error messages
4. Take screenshot of any errors
```

### Step 3: Check Network Tab
```
1. Go to Network tab
2. Refresh page (F5)
3. Look for failed requests (red)
4. Check if widget.js loads successfully
5. Check if iframe HTML loads
```

### Step 4: Inspect Iframe
```
1. Go to Elements/Inspector tab
2. Find: <iframe id="supportai-widget-iframe">
3. Check src attribute
4. Right-click iframe → "This Frame" → "Open in new tab"
5. See if widget loads in new tab
```

### Step 5: Test Iframe Directly
```
Open in browser:
https://your-domain.vercel.app/widget/YOUR_CHATBOT_ID

Expected: Should see widget button
If you see 404 or error: Database/deployment issue
```

---

## Quick Fixes to Try

### Fix 1: Clear Everything
```
1. Clear browser cache completely
2. Close all browser tabs
3. Restart browser
4. Open portfolio in incognito mode
5. Test widget
```

### Fix 2: Redeploy
```bash
git add .
git commit -m "Redeploy widget"
git push
```
Wait 2 minutes for Vercel build, then test.

### Fix 3: Check Database
```
1. Go to Supabase Dashboard
2. Table Editor → chatbots
3. Find your chatbot
4. Verify:
   - status = "active"
   - widget_color has a value
   - name is set
```

### Fix 4: Update Embed Code
```html
<!-- Remove old script tags from your portfolio -->
<!-- Add fresh embed code -->
<script>
  window.SupportAIConfig = {
    chatbotId: "PASTE_CHATBOT_ID_HERE",
    apiUrl: "https://PASTE_VERCEL_URL_HERE"
  };
</script>
<script src="https://PASTE_VERCEL_URL_HERE/widget.js"></script>
```

---

## Test Checklist

Before asking for help, verify:

- [ ] Hard refreshed browser (Ctrl+Shift+R)
- [ ] Tested in incognito mode
- [ ] Checked browser console for errors
- [ ] Verified Vercel deployment succeeded
- [ ] Checked chatbot is "active" in database
- [ ] Confirmed apiUrl matches Vercel domain
- [ ] Tested widget URL directly in browser
- [ ] Inspected iframe src attribute
- [ ] Checked pointer-events on button

---

## Expected Behavior

### When Working Correctly:
1. Widget button appears (colored circle)
2. Hover → cursor changes to pointer
3. Click → chat window slides up from bottom
4. Chat window shows:
   - Header with bot name
   - "Hi! 👋..." welcome message
   - Input field at bottom
   - All properly styled

### When Not Working:
1. Button appears but nothing happens on click
2. OR button appears but cursor doesn't change
3. OR button doesn't appear at all
4. OR error message in console

---

## Get Your Correct URLs

### Chatbot ID
```
1. Go to MJ.TALK Dashboard
2. Chatbots page
3. Click "Embed" button
4. Copy the long ID (starts with letters and numbers)
```

### Vercel URL
```
1. Go to Vercel Dashboard
2. Select your project
3. Copy domain from "Domains" section
4. Format: your-project-name.vercel.app
```

---

## Common Mistakes

### ❌ Wrong:
```html
<script>
  window.SupportAIConfig = {
    chatbotId: "12345",  // Too short
    apiUrl: "http://localhost:3000"  // Wrong for production
  };
</script>
```

### ✅ Correct:
```html
<script>
  window.SupportAIConfig = {
    chatbotId: "abc123-def456-ghi789-jkl012",  // Full UUID
    apiUrl: "https://mj-talk.vercel.app"  // Your actual domain
  };
</script>
```

---

## Still Not Working?

### Share These Details:
1. Browser console errors (screenshot)
2. Network tab (screenshot of failed requests)
3. Iframe src URL
4. Vercel deployment status
5. Chatbot status from database
6. Exact embed code you're using

### Where to Check:
- Console errors → JavaScript issues
- Network tab → Loading/API issues  
- Elements tab → HTML/CSS issues
- Vercel logs → Server/build issues

---

## Most Likely Solution

**90% of the time it's browser cache!**

Try this first:
1. Close all browser tabs
2. Clear browser cache completely
3. Restart browser
4. Open portfolio in incognito mode
5. Test widget

If it works in incognito → cache problem ✅
If it still doesn't work → deployment/code problem ❌

---

**Status:** Diagnostic guide complete
**Next Step:** Try browser cache clearing first
