-- =====================================================
-- Complete Schema Fix - Add all missing columns
-- This ensures the database matches the application requirements
-- =====================================================

-- =====================================================
-- STEP 1: Add ALL missing columns to chatbots
-- =====================================================
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS system_prompt TEXT;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS welcome_message TEXT;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS allowed_domains TEXT[];
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS initial_questions TEXT[];
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS escalation_keyword TEXT;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS pre_chat_form_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS collect_visitor_name BOOLEAN DEFAULT TRUE;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS collect_visitor_email BOOLEAN DEFAULT TRUE;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS collect_visitor_phone BOOLEAN DEFAULT FALSE;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS theme_color TEXT DEFAULT '#1dbfa0';
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS header_title TEXT;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS footer_branding_text TEXT;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS sound_notifications BOOLEAN DEFAULT TRUE;
ALTER TABLE chatbots ADD COLUMN IF NOT EXISTS show_powered_by BOOLEAN DEFAULT TRUE;

-- =====================================================
-- STEP 2: Add missing columns to conversations
-- =====================================================
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'medium';
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'widget';
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS subject TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS escalation_requested_at TIMESTAMPTZ;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;

-- Add constraints for priority
ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_priority_check;
ALTER TABLE conversations ADD CONSTRAINT conversations_priority_check 
  CHECK (priority IN ('low','medium','high'));

-- Add constraints for source
ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_source_check;
ALTER TABLE conversations ADD CONSTRAINT conversations_source_check 
  CHECK (source IN ('widget','manual','ai_handoff','human_request'));

-- =====================================================
-- STEP 3: Add missing columns to messages
-- =====================================================
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_seen BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT 'sent';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Add constraints for message_type
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_message_type_check;
ALTER TABLE messages ADD CONSTRAINT messages_message_type_check 
  CHECK (message_type IN ('text','image','file','system'));

-- Add constraints for delivery_status
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_delivery_status_check;
ALTER TABLE messages ADD CONSTRAINT messages_delivery_status_check 
  CHECK (delivery_status IN ('pending','sent','delivered','failed'));

-- =====================================================
-- STEP 4: Add missing columns to notifications
-- =====================================================
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS action_url TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- Add constraints for priority
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_priority_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_priority_check 
  CHECK (priority IN ('low','normal','high','urgent'));

-- =====================================================
-- STEP 5: Create missing tables (profiles, agent_status)
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT UNIQUE NOT NULL,
  full_name   TEXT,
  role        TEXT NOT NULL DEFAULT 'customer'
                CHECK (role IN ('customer','agent','admin','super_admin')),
  status      TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active','inactive','suspended')),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agent_status (
  agent_id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  online_status        TEXT NOT NULL DEFAULT 'offline'
                         CHECK (online_status IN ('online','away','busy','offline')),
  last_active          TIMESTAMPTZ DEFAULT NOW(),
  active_chat_count    INT DEFAULT 0,
  max_concurrent_chats INT DEFAULT 5,
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 6: Add missing columns to chat_events
-- =====================================================
ALTER TABLE chat_events ADD COLUMN IF NOT EXISTS event_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- =====================================================
-- STEP 7: Add missing columns to ai_sessions
-- =====================================================
ALTER TABLE ai_sessions ADD COLUMN IF NOT EXISTS detected_intent TEXT;
ALTER TABLE ai_sessions ADD COLUMN IF NOT EXISTS ai_confidence_score NUMERIC(3,2);
ALTER TABLE ai_sessions ADD COLUMN IF NOT EXISTS escalated_to_human BOOLEAN DEFAULT FALSE;
ALTER TABLE ai_sessions ADD COLUMN IF NOT EXISTS escalation_reason TEXT;
ALTER TABLE ai_sessions ADD COLUMN IF NOT EXISTS ai_summary TEXT;

-- =====================================================
-- STEP 8: Add missing columns to conversation_notes
-- =====================================================
-- Already exists with basic columns, but ensure it has all needed columns
-- (no additional columns needed based on original schema)

-- =====================================================
-- STEP 9: Enable RLS on new tables
-- =====================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_status ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 10: Create basic RLS policies for new tables
-- =====================================================

-- Profiles: Users can read their own profile + org members
CREATE POLICY "profiles_self_select" ON profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "profiles_org_select" ON profiles FOR SELECT
  USING (id IN (
    SELECT user_id FROM team_members 
    WHERE org_id IN (SELECT org_id FROM team_members WHERE user_id = auth.uid())
  ));

-- Agent Status: Users can read status of their org's agents
CREATE POLICY "agent_status_select" ON agent_status FOR SELECT
  USING (agent_id IN (
    SELECT user_id FROM team_members 
    WHERE org_id IN (SELECT org_id FROM team_members WHERE user_id = auth.uid())
  ));

-- =====================================================
-- COMPLETE! All columns and tables are now in place.
-- =====================================================
