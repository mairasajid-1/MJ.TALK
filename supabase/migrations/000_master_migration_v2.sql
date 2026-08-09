-- =====================================================
-- MASTER MIGRATION V2 - Complete Database Setup
-- Simplified version with better error handling
-- =====================================================

-- =====================================================
-- STEP 1: Drop existing objects safely
-- =====================================================
DROP TRIGGER IF EXISTS update_conversations_timestamp ON conversations CASCADE;
DROP TRIGGER IF EXISTS update_messages_timestamp ON messages CASCADE;
DROP TRIGGER IF EXISTS update_notifications_timestamp ON notifications CASCADE;
DROP TRIGGER IF EXISTS update_organizations_timestamp ON organizations CASCADE;
DROP FUNCTION IF EXISTS update_timestamp() CASCADE;
DROP FUNCTION IF EXISTS my_owned_org_ids() CASCADE;
DROP FUNCTION IF EXISTS my_agent_org_ids() CASCADE;
DROP FUNCTION IF EXISTS my_org_ids() CASCADE;

-- Drop tables in dependency order
DROP TABLE IF EXISTS chat_events CASCADE;
DROP TABLE IF EXISTS ai_sessions CASCADE;
DROP TABLE IF EXISTS conversation_notes CASCADE;
DROP TABLE IF EXISTS kb_articles CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS chatbots CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;

-- =====================================================
-- STEP 2: Create Core Tables
-- =====================================================

-- Organizations table
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team members table
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'agent',
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

-- Chatbots table
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

-- Conversations table
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

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('visitor', 'agent', 'ai')),
  sender_id UUID REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications table
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

-- Conversation notes table
CREATE TABLE conversation_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI sessions table
CREATE TABLE ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  model TEXT,
  tokens_used INT,
  cost NUMERIC,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat events table
CREATE TABLE chat_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KB articles table
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
-- STEP 3: Create Indexes
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
-- STEP 4: Enable Realtime
-- =====================================================

ALTER TABLE conversations REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE notifications REPLICA IDENTITY FULL;
ALTER TABLE organizations REPLICA IDENTITY FULL;
ALTER TABLE team_members REPLICA IDENTITY FULL;

-- =====================================================
-- STEP 5: Enable Row Level Security
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
-- STEP 6: Create Utility Functions (SECURITY DEFINER)
-- =====================================================

CREATE FUNCTION public.my_owned_org_ids()
RETURNS TABLE(id UUID)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT organizations.id 
  FROM public.organizations 
  WHERE owner_id = auth.uid();
$$;

CREATE FUNCTION public.my_agent_org_ids()
RETURNS TABLE(org_id UUID)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT team_members.org_id 
  FROM public.team_members
  WHERE user_id = auth.uid() AND accepted_at IS NOT NULL;
$$;

CREATE FUNCTION public.my_org_ids()
RETURNS TABLE(id UUID)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT organizations.id 
  FROM public.organizations 
  WHERE owner_id = auth.uid()
  UNION
  SELECT team_members.org_id 
  FROM public.team_members
  WHERE user_id = auth.uid() AND accepted_at IS NOT NULL;
$$;

-- =====================================================
-- STEP 7: Create Timestamp Update Function
-- =====================================================

CREATE FUNCTION public.update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Create triggers for timestamp updates
CREATE TRIGGER update_organizations_timestamp 
  BEFORE UPDATE ON organizations
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_conversations_timestamp 
  BEFORE UPDATE ON conversations
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_messages_timestamp 
  BEFORE UPDATE ON messages
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_notifications_timestamp 
  BEFORE UPDATE ON notifications
  FOR EACH ROW 
  EXECUTE FUNCTION update_timestamp();

-- =====================================================
-- STEP 8: Create RLS Policies
-- =====================================================

-- Organizations policies
CREATE POLICY "orgs_owner_all" 
  ON organizations FOR ALL 
  USING (owner_id = auth.uid());

CREATE POLICY "orgs_agent_select" 
  ON organizations FOR SELECT 
  USING (id IN (SELECT org_id FROM public.team_members WHERE user_id = auth.uid() AND accepted_at IS NOT NULL));

-- Chatbots policies
CREATE POLICY "chatbots_org_all" 
  ON chatbots FOR ALL 
  USING (org_id IN (SELECT id FROM public.my_org_ids()));

-- Conversations policies
CREATE POLICY "convs_select_all" 
  ON conversations FOR SELECT 
  USING (true);

CREATE POLICY "convs_insert_all" 
  ON conversations FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "convs_update_org" 
  ON conversations FOR UPDATE 
  USING (chatbot_id IN (SELECT id FROM chatbots WHERE org_id IN (SELECT id FROM public.my_org_ids())));

CREATE POLICY "convs_delete_org" 
  ON conversations FOR DELETE 
  USING (chatbot_id IN (SELECT id FROM chatbots WHERE org_id IN (SELECT id FROM public.my_org_ids())));

-- Messages policies
CREATE POLICY "msgs_select_all" 
  ON messages FOR SELECT 
  USING (true);

CREATE POLICY "msgs_insert_all" 
  ON messages FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "msgs_update_org" 
  ON messages FOR UPDATE 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT id FROM public.my_org_ids())));

CREATE POLICY "msgs_delete_org" 
  ON messages FOR DELETE 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT id FROM public.my_org_ids())));

-- Notifications policies
CREATE POLICY "notifs_org_all" 
  ON notifications FOR ALL 
  USING (org_id IN (SELECT id FROM public.my_org_ids()) OR target_user_id = auth.uid());

-- Team members policies
CREATE POLICY "team_owner_all" 
  ON team_members FOR ALL 
  USING (org_id IN (SELECT id FROM public.my_owned_org_ids()));

CREATE POLICY "team_self_read" 
  ON team_members FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY "team_self_write" 
  ON team_members FOR UPDATE 
  USING (user_id = auth.uid());

-- Conversation notes policies
CREATE POLICY "notes_org" 
  ON conversation_notes FOR ALL 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT id FROM public.my_org_ids())));

-- AI sessions policies
CREATE POLICY "ai_sessions_org" 
  ON ai_sessions FOR ALL 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT id FROM public.my_org_ids())));

-- Chat events policies
CREATE POLICY "chat_events_org" 
  ON chat_events FOR ALL 
  USING (conversation_id IN (SELECT c.id FROM conversations c JOIN chatbots cb ON cb.id = c.chatbot_id WHERE cb.org_id IN (SELECT id FROM public.my_org_ids())));

-- KB articles policies
CREATE POLICY "kb_org_all" 
  ON kb_articles FOR ALL 
  USING (org_id IN (SELECT id FROM public.my_org_ids()));

CREATE POLICY "kb_public_read" 
  ON kb_articles FOR SELECT 
  USING (is_published = true);

-- =====================================================
-- SUCCESS! Database schema is ready.
-- =====================================================