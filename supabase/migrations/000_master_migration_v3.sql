-- =====================================================
-- MASTER MIGRATION V3 - Complete Database Setup
-- Simplified for Supabase SQL Editor compatibility
-- =====================================================

-- =====================================================
-- STEP 1: Create Core Tables (Safe - no drops)
-- =====================================================

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team members table
CREATE TABLE IF NOT EXISTS team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'agent',
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

-- Chatbots table
CREATE TABLE IF NOT EXISTS chatbots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  greeting TEXT,
  model TEXT DEFAULT 'gpt-4-turbo',
  temperature FLOAT DEFAULT 0.7,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chatbot_id UUID NOT NULL REFERENCES chatbots(id) ON DELETE CASCADE,
  visitor_name TEXT,
  visitor_email TEXT,
  assigned_agent_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'open',
  flagged BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('visitor', 'agent', 'ai')),
  sender_id UUID REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('new_chat','new_message','escalated','flagged','idle','assigned','mention')),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  priority TEXT DEFAULT 'normal',
  action_url TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversation notes table
CREATE TABLE IF NOT EXISTS conversation_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI sessions table
CREATE TABLE IF NOT EXISTS ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  model TEXT,
  tokens_used INT,
  cost NUMERIC,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat events table
CREATE TABLE IF NOT EXISTS chat_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KB articles table
CREATE TABLE IF NOT EXISTS kb_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 2: Create Indexes
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_organizations_owner ON organizations(owner_id);
CREATE INDEX IF NOT EXISTS idx_team_members_org ON team_members(org_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_chatbots_org ON chatbots(org_id);
CREATE INDEX IF NOT EXISTS idx_conversations_chatbot ON conversations(chatbot_id);
CREATE INDEX IF NOT EXISTS idx_conversations_agent ON conversations(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_org ON notifications(org_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(target_user_id);
CREATE INDEX IF NOT EXISTS idx_ai_sessions_conversation ON ai_sessions(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_events_conversation ON chat_events(conversation_id);
CREATE INDEX IF NOT EXISTS idx_kb_articles_org ON kb_articles(org_id);

-- =====================================================
-- STEP 3: Enable Realtime
-- =====================================================

ALTER TABLE conversations REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE notifications REPLICA IDENTITY FULL;
ALTER TABLE organizations REPLICA IDENTITY FULL;
ALTER TABLE team_members REPLICA IDENTITY FULL;

-- =====================================================
-- STEP 4: Enable Row Level Security
-- =====================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chatbots ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE kb_articles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 5: Create Utility Functions
-- =====================================================

CREATE OR REPLACE FUNCTION public.my_org_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.organizations WHERE owner_id = auth.uid()
  UNION ALL
  SELECT org_id FROM public.team_members
  WHERE user_id = auth.uid() AND accepted_at IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION public.my_owned_org_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.organizations WHERE owner_id = auth.uid();
$$;

-- =====================================================
-- STEP 6: Create Timestamp Update Function
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Create triggers for timestamp updates
DROP TRIGGER IF EXISTS update_organizations_timestamp ON organizations;
CREATE TRIGGER update_organizations_timestamp 
  BEFORE UPDATE ON organizations
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS update_conversations_timestamp ON conversations;
CREATE TRIGGER update_conversations_timestamp 
  BEFORE UPDATE ON conversations
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS update_messages_timestamp ON messages;
CREATE TRIGGER update_messages_timestamp 
  BEFORE UPDATE ON messages
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS update_notifications_timestamp ON notifications;
CREATE TRIGGER update_notifications_timestamp 
  BEFORE UPDATE ON notifications
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

-- =====================================================
-- STEP 7: Create RLS Policies
-- =====================================================

-- Organizations policies
DROP POLICY IF EXISTS "orgs_owner_all" ON organizations;
CREATE POLICY "orgs_owner_all" 
  ON organizations FOR ALL 
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "orgs_agent_select" ON organizations;
CREATE POLICY "orgs_agent_select" 
  ON organizations FOR SELECT 
  USING (id IN (SELECT org_id FROM public.team_members WHERE user_id = auth.uid() AND accepted_at IS NOT NULL));

-- Chatbots policies
DROP POLICY IF EXISTS "chatbots_org_all" ON chatbots;
CREATE POLICY "chatbots_org_all" 
  ON chatbots FOR ALL 
  USING (org_id IN (SELECT public.my_org_ids()));

-- Conversations policies
DROP POLICY IF EXISTS "convs_select_all" ON conversations;
CREATE POLICY "convs_select_all" 
  ON conversations FOR SELECT 
  USING (true);

DROP POLICY IF EXISTS "convs_insert_all" ON conversations;
CREATE POLICY "convs_insert_all" 
  ON conversations FOR INSERT 
  WITH CHECK (true);

DROP POLICY IF EXISTS "convs_update_org" ON conversations;
CREATE POLICY "convs_update_org" 
  ON conversations FOR UPDATE 
  USING (chatbot_id IN (SELECT id FROM chatbots WHERE org_id IN (SELECT public.my_org_ids())));

DROP POLICY IF EXISTS "convs_delete_org" ON conversations;
CREATE POLICY "convs_delete_org" 
  ON conversations FOR DELETE 
  USING (chatbot_id IN (SELECT id FROM chatbots WHERE org_id IN (SELECT public.my_org_ids())));

-- Messages policies
DROP POLICY IF EXISTS "msgs_select_all" ON messages;
CREATE POLICY "msgs_select_all" 
  ON messages FOR SELECT 
  USING (true);

DROP POLICY IF EXISTS "msgs_insert_all" ON messages;
CREATE POLICY "msgs_insert_all" 
  ON messages FOR INSERT 
  WITH CHECK (true);

DROP POLICY IF EXISTS "msgs_update_org" ON messages;
CREATE POLICY "msgs_update_org" 
  ON messages FOR UPDATE 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT public.my_org_ids())));

DROP POLICY IF EXISTS "msgs_delete_org" ON messages;
CREATE POLICY "msgs_delete_org" 
  ON messages FOR DELETE 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT public.my_org_ids())));

-- Notifications policies
DROP POLICY IF EXISTS "notifs_org_all" ON notifications;
CREATE POLICY "notifs_org_all" 
  ON notifications FOR ALL 
  USING (org_id IN (SELECT public.my_org_ids()) OR target_user_id = auth.uid());

-- Team members policies
DROP POLICY IF EXISTS "team_owner_all" ON team_members;
CREATE POLICY "team_owner_all" 
  ON team_members FOR ALL 
  USING (org_id IN (SELECT public.my_owned_org_ids()));

DROP POLICY IF EXISTS "team_self_read" ON team_members;
CREATE POLICY "team_self_read" 
  ON team_members FOR SELECT 
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "team_self_write" ON team_members;
CREATE POLICY "team_self_write" 
  ON team_members FOR UPDATE 
  USING (user_id = auth.uid());

-- Conversation notes policies
DROP POLICY IF EXISTS "notes_org" ON conversation_notes;
CREATE POLICY "notes_org" 
  ON conversation_notes FOR ALL 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT public.my_org_ids())));

-- AI sessions policies
DROP POLICY IF EXISTS "ai_sessions_org" ON ai_sessions;
CREATE POLICY "ai_sessions_org" 
  ON ai_sessions FOR ALL 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT public.my_org_ids())));

-- Chat events policies
DROP POLICY IF EXISTS "chat_events_org" ON chat_events;
CREATE POLICY "chat_events_org" 
  ON chat_events FOR ALL 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT public.my_org_ids())));

-- KB articles policies
DROP POLICY IF EXISTS "kb_org_all" ON kb_articles;
CREATE POLICY "kb_org_all" 
  ON kb_articles FOR ALL 
  USING (org_id IN (SELECT public.my_org_ids()));

DROP POLICY IF EXISTS "kb_public_read" ON kb_articles;
CREATE POLICY "kb_public_read" 
  ON kb_articles FOR SELECT 
  USING (is_published = true);

-- =====================================================
-- SUCCESS! Database schema is ready.
-- =====================================================
