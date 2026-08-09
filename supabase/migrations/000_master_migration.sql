-- =====================================================
-- MASTER MIGRATION - Complete Database Setup
-- Run this ONCE to set up the entire schema
-- =====================================================

-- Drop existing tables and functions (SAFE - only if they exist)
DROP TRIGGER IF EXISTS update_conversations_timestamp ON conversations;
DROP TRIGGER IF EXISTS update_messages_timestamp ON messages;
DROP TRIGGER IF EXISTS update_notifications_timestamp ON notifications;
DROP FUNCTION IF EXISTS update_timestamp() CASCADE;
DROP TABLE IF EXISTS chat_events CASCADE;
DROP TABLE IF EXISTS ai_sessions CASCADE;
DROP TABLE IF EXISTS conversation_notes CASCADE;
DROP TABLE IF EXISTS kb_articles CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS chatbots CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;

-- =====================================================
-- PHASE 1: Core Schema
-- =====================================================

CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'agent',
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

CREATE TABLE chatbots (
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

CREATE TABLE conversations (
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

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('visitor', 'agent', 'ai')),
  sender_id UUID REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE notifications (
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

CREATE TABLE conversation_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  model TEXT,
  tokens_used INT,
  cost NUMERIC,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE chat_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE kb_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- PHASE 2: Indexes for Performance
-- =====================================================

CREATE INDEX idx_organizations_owner ON organizations(owner_id);
CREATE INDEX idx_team_members_org ON team_members(org_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_chatbots_org ON chatbots(org_id);
CREATE INDEX idx_conversations_chatbot ON conversations(chatbot_id);
CREATE INDEX idx_conversations_agent ON conversations(assigned_agent_id);
CREATE INDEX idx_conversations_status ON conversations(status);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_notifications_org ON notifications(org_id);
CREATE INDEX idx_notifications_user ON notifications(target_user_id);
CREATE INDEX idx_ai_sessions_conversation ON ai_sessions(conversation_id);
CREATE INDEX idx_chat_events_conversation ON chat_events(conversation_id);
CREATE INDEX idx_kb_articles_org ON kb_articles(org_id);

-- =====================================================
-- PHASE 3: Update Timestamp Function
-- =====================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversations_timestamp BEFORE UPDATE ON conversations
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_messages_timestamp BEFORE UPDATE ON messages
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_notifications_timestamp BEFORE UPDATE ON notifications
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- =====================================================
-- PHASE 4: Enable Realtime
-- =====================================================

ALTER TABLE conversations REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE notifications REPLICA IDENTITY FULL;
ALTER TABLE organizations REPLICA IDENTITY FULL;
ALTER TABLE team_members REPLICA IDENTITY FULL;

-- =====================================================
-- PHASE 5: Enable RLS (Row Level Security)
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
-- PHASE 6: SECURITY DEFINER Functions (Bypass RLS)
-- =====================================================

-- Returns org_ids where the calling user is the owner
CREATE OR REPLACE FUNCTION public.my_owned_org_ids()
RETURNS SETOF UUID
LANGUAGE SQL SECURITY DEFINER STABLE
AS $$
  SELECT id FROM public.organizations WHERE owner_id = auth.uid();
$$;

-- Returns org_ids where the calling user is an accepted agent
CREATE OR REPLACE FUNCTION public.my_agent_org_ids()
RETURNS SETOF UUID
LANGUAGE SQL SECURITY DEFINER STABLE
AS $$
  SELECT org_id FROM public.team_members
  WHERE user_id = auth.uid() AND accepted_at IS NOT NULL;
$$;

-- Returns all org_ids the calling user can access (owner OR agent)
CREATE OR REPLACE FUNCTION public.my_org_ids()
RETURNS SETOF UUID
LANGUAGE SQL SECURITY DEFINER STABLE
AS $$
  SELECT id FROM public.organizations WHERE owner_id = auth.uid()
  UNION ALL
  SELECT org_id FROM public.team_members
  WHERE user_id = auth.uid() AND accepted_at IS NOT NULL;
$$;

-- =====================================================
-- PHASE 7: RLS Policies
-- =====================================================

-- Organizations: Owners have full access, agents can read
CREATE POLICY "orgs_owner_all" ON public.organizations
  FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "orgs_agent_select" ON public.organizations
  FOR SELECT USING (id IN (SELECT my_agent_org_ids()));

-- Chatbots: Access based on org membership
CREATE POLICY "chatbots_org_all" ON public.chatbots
  FOR ALL USING (org_id IN (SELECT my_org_ids()));

-- Conversations: Public for widget, org members for management
CREATE POLICY "convs_select_all" ON public.conversations FOR SELECT USING (true);
CREATE POLICY "convs_insert_all" ON public.conversations FOR INSERT WITH CHECK (true);
CREATE POLICY "convs_update_org" ON public.conversations FOR UPDATE
  USING (chatbot_id IN (SELECT id FROM public.chatbots WHERE org_id IN (SELECT my_org_ids())));
CREATE POLICY "convs_delete_org" ON public.conversations FOR DELETE
  USING (chatbot_id IN (SELECT id FROM public.chatbots WHERE org_id IN (SELECT my_org_ids())));

-- Messages: Public for widget, org members for management
CREATE POLICY "msgs_select_all" ON public.messages FOR SELECT USING (true);
CREATE POLICY "msgs_insert_all" ON public.messages FOR INSERT WITH CHECK (true);
CREATE POLICY "msgs_update_org" ON public.messages FOR UPDATE
  USING (conversation_id IN (
    SELECT c.id FROM public.conversations c
    JOIN public.chatbots cb ON cb.id = c.chatbot_id
    WHERE cb.org_id IN (SELECT my_org_ids())
  ));
CREATE POLICY "msgs_delete_org" ON public.messages FOR DELETE
  USING (conversation_id IN (
    SELECT c.id FROM public.conversations c
    JOIN public.chatbots cb ON cb.id = c.chatbot_id
    WHERE cb.org_id IN (SELECT my_org_ids())
  ));

-- Notifications: Access to org notifications or personal notifications
CREATE POLICY "notifs_org_all" ON public.notifications
  FOR ALL USING (org_id IN (SELECT my_org_ids()) OR target_user_id = auth.uid());

-- Team Members: Owners can manage, members can view/update their own
CREATE POLICY "team_owner_all" ON public.team_members
  FOR ALL USING (org_id IN (SELECT my_owned_org_ids()));

CREATE POLICY "team_self_read" ON public.team_members
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "team_self_write" ON public.team_members
  FOR UPDATE USING (user_id = auth.uid());

-- Conversation Notes: Access based on org membership
CREATE POLICY "notes_org" ON public.conversation_notes FOR ALL
  USING (conversation_id IN (
    SELECT c.id FROM public.conversations c
    JOIN public.chatbots cb ON cb.id = c.chatbot_id
    WHERE cb.org_id IN (SELECT my_org_ids())
  ));

-- AI Sessions: Access based on org membership
CREATE POLICY "ai_sessions_org" ON public.ai_sessions FOR ALL
  USING (conversation_id IN (
    SELECT c.id FROM public.conversations c
    JOIN public.chatbots cb ON cb.id = c.chatbot_id
    WHERE cb.org_id IN (SELECT my_org_ids())
  ));

-- Chat Events: Access based on org membership
CREATE POLICY "chat_events_org" ON public.chat_events FOR ALL
  USING (conversation_id IN (
    SELECT c.id FROM public.conversations c
    JOIN public.chatbots cb ON cb.id = c.chatbot_id
    WHERE cb.org_id IN (SELECT my_org_ids())
  ));

-- KB Articles: Access based on org membership or published
CREATE POLICY "kb_org_all" ON public.kb_articles FOR ALL
  USING (org_id IN (SELECT my_org_ids()));

CREATE POLICY "kb_public_read" ON public.kb_articles FOR SELECT
  USING (is_published = true);

-- =====================================================
-- Complete! All tables, indexes, and policies created.
-- =====================================================