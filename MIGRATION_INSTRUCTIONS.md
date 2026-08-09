# Database Migration & Deployment Instructions

## Overview
The database schema needs to be updated to support all application features. This migration adds missing columns, creates new tables, and implements proper triggers and functions.

---

## STEP 1: Apply Database Migration to Supabase

### Option A: Using Supabase Dashboard (Recommended for single migrations)

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `lzubrcmdawuujszeoxea`
3. Navigate to **SQL Editor**
4. Click **New Query**
5. Copy the entire contents of: `supabase/migrations/003_complete_database_schema.sql`
6. Paste into the SQL editor
7. Click **Run** button
8. Wait for completion (should complete in ~5-10 seconds)
9. Verify success: All queries should complete with no errors

### Option B: Using Supabase CLI (If installed)

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref lzubrcmdawuujszeoxea

# Push migrations
supabase db push
```

---

## STEP 2: Verify Database Schema

Run these queries in Supabase SQL Editor to verify all columns exist:

### Check Chatbots Table
```sql
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'chatbots' 
ORDER BY ordinal_position;
```

Expected columns:
- id, org_id, name, avatar_url, greeting, model, temperature (original)
- **description, system_prompt, status, widget_color, pre_chat_form_enabled, escalation_keyword, allowed_domains** (NEW - CRITICAL)
- created_at, updated_at

### Check Conversations Table
```sql
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'conversations' 
ORDER BY ordinal_position;
```

Expected NEW columns:
- session_id, page_url, browser_info
- priority, source, subject
- last_message_at, escalation_requested_at, assigned_at, closed_at

### Check Messages Table
```sql
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'messages' 
ORDER BY ordinal_position;
```

Expected NEW columns:
- message_type, is_seen, delivery_status, metadata

### Check New Tables Exist
```sql
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

Should include:
- profiles, agent_status, typing_indicators, kb_articles, purchase_requests (all NEW)
- All original tables (organizations, team_members, chatbots, conversations, messages, notifications, etc.)

---

## STEP 3: Update Vercel Environment Variables

These credentials must match your NEW Supabase project.

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select project: **mj-talk**
3. Go to **Settings** → **Environment Variables**
4. Update/Create these variables for **Production**, **Preview**, and **Development**:

| Key | Value |
|-----|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://lzubrcmdawuujszeoxea.supabase.com` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6dWJyY21kYXd1dWpzemVveGVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyNjk1MzYsImV4cCI6MjEwMTg0NTUzNn0._aGr2K9KHF_Oxa5a9TaHNDt-U7fzCy7YY96e5fDg5lY` |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6dWJyY21kYXd1dWpzemVveGVhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NjI2OTUzNiwiZXhwIjoyMTAxODQ1NTM2fQ.xd0U3UMRv5Bejulw6lZAzM-ATNnz_86yfSCG9suJwV0` |

5. Click **Save** after each variable
6. Vercel will automatically rebuild and redeploy with new environment variables

---

## STEP 4: Verify Deployment

1. Wait for Vercel to complete the redeploy (watch the deployment status)
2. Once deployment is "Ready", visit: https://mj-talk.vercel.app
3. Test the following:

### Test Signup
- Create a new account
- Verify user is created in `auth.users`
- Check `profiles` table for new user profile

### Test Dashboard Access
- Login with your account
- Verify `/dashboard` loads without 401 errors

### Test Chatbot Creation
- Navigate to **Chatbots** → **New Chatbot**
- Fill in form with:
  - Name: "Test Bot"
  - Description: "Test Description"
  - System Prompt: (default or custom)
  - Status: "Active"
  - Widget Color: Any color
  - Pre-chat Form: Toggle ON/OFF
  - Escalation Keyword: "ESCALATE"
  - Allowed Domains: (leave empty or add domains)
- Click **Create**
- Verify chatbot appears in list

### Test Conversation Features
- Create a test conversation via API or widget
- Send a message
- Verify `last_message_at` updates in database
- Check notifications table for new notification entry

---

## STEP 5: Monitor for Errors

### Check Vercel Deployment Logs
1. Go to Vercel Dashboard
2. Select **mj-talk** project
3. Click on latest deployment
4. Review **Logs** tab for any errors

### Check Supabase Activity
1. Go to Supabase Dashboard
2. Navigate to **Monitoring** → **Logs**
3. Check for any database errors

### Test API Endpoints
```bash
# Test health check
curl https://mj-talk.vercel.app/api/status

# Test auth (you'll need real credentials)
curl https://mj-talk.vercel.app/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Troubleshooting

### Issue: "Column X does not exist" error
**Solution**: 
- Verify migration was executed successfully in Supabase SQL Editor
- Re-run the migration query
- Check that all queries in the migration completed without errors

### Issue: "relation 'X' does not exist" error
**Solution**:
- A table wasn't created
- Run just the table creation portions of the migration again

### Issue: RLS policy errors
**Solution**:
- Clear browser cache
- Clear cookies
- Logout and login again
- Check Supabase RLS policies were created (check in SQL Editor with: `SELECT * FROM pg_policies;`)

### Issue: Vercel build fails after env var update
**Solution**:
- Ensure all three variables are set (NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY)
- Redeploy from Vercel Dashboard: Settings → Deployments → Redeploy

---

## Next Steps After Successful Migration

1. **Populate Knowledge Base Articles** (if needed)
   - Create KB articles for your chatbots
   - Tag them with categories

2. **Test Advanced Features**
   - Escalation workflow
   - Conversation assignment
   - AI session tracking
   - Purchase request creation

3. **Monitor Production**
   - Check logs regularly
   - Monitor database performance
   - Watch for any missing column errors

---

## Rollback Plan (If Something Goes Wrong)

If the migration causes issues, you can:

1. **Quick Rollback**: Delete tables created and remove columns added
   ```sql
   -- This will drop all new tables (WARNING: destructive)
   DROP TABLE IF EXISTS purchase_requests;
   DROP TABLE IF EXISTS kb_articles;
   DROP TABLE IF EXISTS typing_indicators;
   DROP TABLE IF EXISTS agent_status;
   DROP TABLE IF EXISTS profiles;
   ```

2. **Full Rollback**: Create a new Supabase project from the previous backup

3. **Partial Rollback**: Keep the migration but revert Vercel env vars to old project credentials

---

## Questions?

- Check the Supabase logs for detailed error messages
- Review the migration file: `supabase/migrations/003_complete_database_schema.sql`
- Consult TypeScript types in: `src/types/index.ts`
