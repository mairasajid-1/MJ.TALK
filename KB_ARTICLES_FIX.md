# Knowledge Base Articles Fix

## Problem
Unable to publish KB articles. Error: **"Could not find the 'category' column of 'kb_articles' in the schema cache"**

## Root Cause
The `kb_articles` table in your database is missing the `category` column. This happens when:
1. Table was created from an older migration
2. Migration `003_complete_database_schema.sql` wasn't fully applied
3. Schema cache is out of sync

## Solution

### Step 1: Apply Database Migration (REQUIRED!)

**This MUST be done in Supabase SQL Editor:**

1. Open **Supabase Dashboard** (https://supabase.com/dashboard)
2. Go to **SQL Editor**
3. Open the file: `supabase/migrations/009_fix_kb_articles_category.sql`
4. Copy ALL content
5. Paste into SQL Editor
6. Click **"Run"**
7. Wait for success messages

**Expected output:**
```
✅ SUCCESS: kb_articles table has category column
✅ Knowledge Base articles can now be published
✅ Migration 009 completed successfully
```

### Step 2: Refresh Dashboard

After running the migration:
1. Go back to your MJ.TALK dashboard
2. Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)
3. Navigate to Knowledge Base
4. Try creating/publishing an article again

---

## What the Migration Does

### 1. Creates kb_articles Table (if missing)
```sql
CREATE TABLE IF NOT EXISTS kb_articles (
  id UUID PRIMARY KEY,
  chatbot_id UUID NOT NULL,
  org_id UUID NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT DEFAULT 'general',  -- ✅ THIS COLUMN
  tags TEXT[],
  is_published BOOLEAN DEFAULT TRUE,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. Adds Missing Columns
- `category` - Type of article (general, account, payment, etc.)
- `tags` - Array of tags for filtering
- `is_published` - Whether article is published
- `created_by` - User who created the article

### 3. Adds Category Constraint
```sql
CHECK (category IN (
  'general', 'account', 'payment', 
  'refund', 'technical', 'setup', 'faq'
))
```

### 4. Creates Indexes
For better performance:
- chatbot_id index
- org_id index
- category index
- is_published index
- created_at index (DESC)

### 5. Sets Up RLS Policies
- View: Users can see published articles in their org
- Manage: Org owners and team members can CRUD articles

### 6. Adds Update Trigger
Auto-updates `updated_at` timestamp on changes

---

## Verification

### After Migration, Check:

1. **Table Exists:**
   ```sql
   SELECT * FROM information_schema.tables 
   WHERE table_name = 'kb_articles';
   ```
   Should return 1 row ✅

2. **Category Column Exists:**
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'kb_articles' 
     AND column_name = 'category';
   ```
   Should return: category | text ✅

3. **Can Insert Article:**
   ```sql
   -- Test insert (replace UUIDs with real ones)
   INSERT INTO kb_articles (chatbot_id, org_id, title, content, category)
   VALUES (
     'your-chatbot-id',
     'your-org-id',
     'Test Article',
     'Test content',
     'general'
   );
   ```
   Should succeed ✅

---

## Testing in Dashboard

After migration is applied:

### Test 1: Create Article
1. Go to Dashboard → Chatbots
2. Select a chatbot → Knowledge Base tab
3. Click "+ New Article"
4. Fill in:
   - Title: "Test Article"
   - Content: "This is a test"
   - Category: Select one (general, technical, etc.)
   - Published: Toggle ON
5. Click "Create Article"
6. **Expected:** Article created successfully ✅

### Test 2: View Articles
1. Articles list should show your new article
2. Category badge visible
3. Published status visible
4. Can click to edit

### Test 3: Edit Article
1. Click on article
2. Modify content
3. Save changes
4. **Expected:** Changes saved successfully ✅

### Test 4: Publish/Unpublish
1. Toggle "Published" switch
2. **Expected:** Status changes immediately ✅

---

## Category Options

The migration supports these categories:

1. **general** - General information
2. **account** - Account-related questions
3. **payment** - Payment and billing
4. **refund** - Refund policies and requests
5. **technical** - Technical issues and troubleshooting
6. **setup** - Setup and installation guides
7. **faq** - Frequently asked questions

---

## Troubleshooting

### Issue: "Table doesn't exist"
**Solution:** Migration didn't run. Check Supabase SQL Editor for errors.

### Issue: "Category constraint violation"
**Solution:** Using invalid category value. Must be one of the 7 options above.

### Issue: "Permission denied"
**Solution:** RLS policies not set up. Run migration again.

### Issue: "Column still missing"
**Solution:** 
1. Check migration ran successfully
2. Refresh dashboard (Ctrl+Shift+R)
3. Check browser console for errors
4. Verify Supabase connection

### Issue: "Org not found"
**Solution:** User not assigned to an organization. Complete onboarding first.

---

## API Endpoints

After fix, these endpoints will work:

### GET /api/knowledge-base
**Query params:**
- `chatbotId` - Filter by chatbot
- `category` - Filter by category

**Response:**
```json
{
  "articles": [
    {
      "id": "uuid",
      "title": "Article Title",
      "content": "Article content...",
      "category": "general",
      "is_published": true,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### POST /api/knowledge-base
**Body:**
```json
{
  "chatbotId": "uuid",
  "title": "Article Title",
  "content": "Article content",
  "category": "general",
  "tags": ["tag1", "tag2"],
  "isPublished": true
}
```

**Response:**
```json
{
  "article": {
    "id": "uuid",
    "title": "Article Title",
    // ... full article data
  }
}
```

### PUT /api/knowledge-base/[id]
**Body:** Same as POST

### DELETE /api/knowledge-base/[id]
**Response:** `{ success: true }`

---

## Files Involved

### Migration
- `supabase/migrations/009_fix_kb_articles_category.sql` ✅ NEW

### API Routes
- `src/app/api/knowledge-base/route.ts` ✅ Already correct
- `src/app/api/knowledge-base/[id]/route.ts` ✅ Already correct

### Dashboard Pages
- `src/app/dashboard/(main)/chatbots/page.tsx` - Lists chatbots with KB tab
- Knowledge Base components (if they exist)

---

## Prevention

To avoid this in future:

1. **Always run migrations in order** (000 → 001 → 002 → etc.)
2. **Verify each migration succeeds** before moving to next
3. **Check migration logs** for errors
4. **Test database structure** after migrations
5. **Keep migrations in version control**

---

## Quick Fix Summary

**Problem:** Can't publish KB articles (category column missing)

**Solution:**
1. Open Supabase SQL Editor
2. Run `009_fix_kb_articles_category.sql`
3. Refresh dashboard
4. Try publishing again

**Time:** 2-3 minutes

**Result:** ✅ KB articles work perfectly

---

## Next Steps After Fix

1. ✅ Publish test article to verify
2. ✅ Add real content to knowledge base
3. ✅ Configure chatbot to use KB articles
4. ✅ Test AI responses include KB context

---

**Status:** Migration ready, waiting for you to run it in Supabase!
**Critical:** Run the migration before trying to publish articles again!
