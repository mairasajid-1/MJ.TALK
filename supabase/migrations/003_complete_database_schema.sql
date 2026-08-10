-- =====================================================
-- COMPREHENSIVE SCHEMA FIX - Complete Database Setup
-- This migration adds ALL missing columns and tables
-- to support the full application feature set
-- =====================================================

-- =====================================================
-- STEP 1: Extend Chatbots Table (CRITICAL FIX)
-- Add all missing columns expected by application
-- =====================================================

ALTER TABLE IF EXISTS chatbots
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS system_prompt TEXT DEFAULT 'You are a helpful customer support assistant.',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' 
    CHECK (status IN ('active', 'inactive')),
  ADD COLUMN IF NOT EXISTS widget_color TEXT DEFAULT '#6366f1',
  ADD COLUMN IF NOT EXISTS pre_chat_form_enabled BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS escalation_keyword TEXT DEFAULT 'ESCALATE',
  ADD COLUMN IF NOT EXISTS allowed_domains TEXT[] DEFAULT '{}';

-- =====================================================
-- STEP 2: Extend Conversations Table
-- Add all enhanced columns for conversation management
-- =====================================================

ALTER TABLE IF EXISTS conversations
  ADD COLUMN IF NOT EXISTS session_id TEXT,
  ADD COLUMN IF NOT EXISTS page_url TEXT,
  ADD COLUMN IF NOT EXISTS browser_info TEXT,
  ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'medium'
    CHECK (priority IN ('low', 'medium', 'high')),
  ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'widget'
    CHECK (source IN ('widget', 'manual', 'ai_handoff', 'human_request')),
  ADD COLUMN IF NOT EXISTS subject TEXT,
  ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS escalation_requested_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;

-- =====================================================
-- STEP 3: Extend Messages Table
-- Add message metadata and delivery tracking
-- =====================================================

-- First, rename sender_type to role if it hasn't been done already
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' AND column_name = 'sender_type'
  ) THEN
    ALTER TABLE messages RENAME COLUMN sender_type TO role;
  END IF;
END $$;

-- Update the role constraint to match application expectations
ALTER TABLE messages
  DROP CONSTRAINT IF EXISTS messages_role_check;
ALTER TABLE messages
  ADD CONSTRAINT messages_role_check CHECK (role IN ('user', 'assistant', 'admin'));

ALTER TABLE IF EXISTS messages
  ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text'
    CHECK (message_type IN ('text', 'image', 'file', 'system')),
  ADD COLUMN IF NOT EXISTS is_seen BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT 'sent'
    CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed')),
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- =====================================================
-- STEP 4: Extend Notifications Table
-- Add comprehensive notification fields
-- =====================================================

ALTER TABLE IF EXISTS notifications
  ADD COLUMN IF NOT EXISTS target_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS action_url TEXT,
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- Fix read column naming (might be 'read' or 'is_read')
ALTER TABLE IF EXISTS notifications
  ADD COLUMN IF NOT EXISTS read BOOLEAN DEFAULT FALSE;

-- Drop and recreate type constraint to include all valid types
ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications
  ADD CONSTRAINT notifications_type_check CHECK (
    type IN ('new_chat', 'new_message', 'escalated', 'flagged', 'idle', 'assigned', 'mention')
  );

-- =====================================================
-- STEP 5B: Create KB Articles Table (after chatbots extended)
-- =====================================================

CREATE TABLE IF NOT EXISTS kb_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chatbot_id UUID NOT NULL REFERENCES chatbots(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT DEFAULT 'general'
    CHECK (category IN ('general', 'account', 'payment', 'refund', 'technical', 'setup', 'faq')),
  tags TEXT[] DEFAULT '{}',
  is_published BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 5C: Create Remaining Tables
-- =====================================================

-- Profiles table (user roles and status)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'customer'
    CHECK (role IN ('customer', 'agent', 'admin', 'super_admin')),
  status TEXT DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'suspended')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent status (workload + availability)
CREATE TABLE IF NOT EXISTS agent_status (
  agent_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  online_status TEXT DEFAULT 'offline'
    CHECK (online_status IN ('online', 'away', 'busy', 'offline')),
  last_active TIMESTAMPTZ DEFAULT NOW(),
  active_chat_count INT DEFAULT 0,
  max_concurrent_chats INT DEFAULT 5,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Typing indicators (real-time status)
CREATE TABLE IF NOT EXISTS typing_indicators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '3 seconds'
);

-- Purchase requests (for enterprise/upgrade tracking)
CREATE TABLE IF NOT EXISTS purchase_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL,
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  request_details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Sessions (detection, confidence, escalation tracking)
ALTER TABLE IF EXISTS ai_sessions
  ADD COLUMN IF NOT EXISTS detected_intent TEXT,
  ADD COLUMN IF NOT EXISTS intent_label TEXT
    CHECK (intent_label IS NULL OR intent_label IN ('refund', 'technical', 'account', 'billing', 'complaint', 'setup', 'general', 'other')),
  ADD COLUMN IF NOT EXISTS intent_confidence NUMERIC(3, 2),
  ADD COLUMN IF NOT EXISTS ai_confidence_score NUMERIC(3, 2),
  ADD COLUMN IF NOT EXISTS escalated_to_human BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS escalation_reason TEXT,
  ADD COLUMN IF NOT EXISTS ai_summary TEXT,
  ADD COLUMN IF NOT EXISTS handoff_summary TEXT,
  ADD COLUMN IF NOT EXISTS kb_articles_used UUID[] DEFAULT '{}';

-- =====================================================
-- STEP 6: Create Indexes for Performance
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_conversations_assigned_agent ON conversations(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_conversations_chatbot ON conversations(chatbot_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_last_msg ON conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_is_seen ON messages(is_seen) WHERE is_seen = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_unread_org ON notifications(org_id) WHERE read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_unread_user ON notifications(target_user_id) WHERE read = FALSE;
CREATE INDEX IF NOT EXISTS idx_agent_status_online ON agent_status(online_status) WHERE online_status != 'offline';
CREATE INDEX IF NOT EXISTS idx_typing_indicators_conversation ON typing_indicators(conversation_id);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_expires ON typing_indicators(expires_at);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_org ON purchase_requests(org_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_status ON purchase_requests(status);

-- KB articles indexes (only if columns exist - kb_articles table should have been created above)
-- Skip if table doesn't exist to avoid errors
DO $$
BEGIN
  -- Check if kb_articles table exists AND has the chatbot_id column
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'kb_articles' 
    AND column_name = 'chatbot_id'
  ) THEN
    -- Use EXECUTE to run DDL inside the block
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_kb_chatbot ON kb_articles(chatbot_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_kb_org ON kb_articles(org_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_kb_category ON kb_articles(category)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_kb_published ON kb_articles(is_published) WHERE is_published = TRUE';
  END IF;
END $$;

-- =====================================================
-- STEP 7: Create Utility Functions
-- =====================================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update conversation last_message_at when new message arrives
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at,
      updated_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-notify org when customer sends message
CREATE OR REPLACE FUNCTION public.notify_on_new_message()
RETURNS TRIGGER AS $$
DECLARE
  v_org_id UUID;
BEGIN
  IF NEW.role != 'user' THEN
    RETURN NEW;
  END IF;

  SELECT c.org_id
  INTO v_org_id
  FROM conversations conv
  JOIN chatbots c ON c.id = conv.chatbot_id
  WHERE conv.id = NEW.conversation_id
  LIMIT 1;

  IF v_org_id IS NOT NULL THEN
    INSERT INTO notifications (org_id, conversation_id, type, message, priority)
    VALUES (v_org_id, NEW.conversation_id, 'new_message', 'New message from customer', 'normal');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Notify and log when conversation escalated
CREATE OR REPLACE FUNCTION public.notify_on_escalation()
RETURNS TRIGGER AS $$
DECLARE
  v_org_id UUID;
BEGIN
  IF NEW.status = 'escalated' AND (OLD.status IS NULL OR OLD.status <> 'escalated') THEN
    SELECT org_id
    INTO v_org_id
    FROM chatbots
    WHERE id = NEW.chatbot_id
    LIMIT 1;

    IF v_org_id IS NOT NULL THEN
      INSERT INTO notifications (org_id, conversation_id, type, message, priority)
      VALUES (v_org_id, NEW.id, 'escalated', 'Conversation escalated — requires human attention', 'high');

      NEW.escalation_requested_at = NOW();
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-create profile on new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'customer')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 8: Create Triggers
-- =====================================================

-- Update timestamps
DROP TRIGGER IF EXISTS update_chatbots_timestamp ON chatbots;
CREATE TRIGGER update_chatbots_timestamp
  BEFORE UPDATE ON chatbots
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_conversations_timestamp ON conversations;
CREATE TRIGGER update_conversations_timestamp
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_timestamp ON messages;
CREATE TRIGGER update_messages_timestamp
  BEFORE UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_notifications_timestamp ON notifications;
CREATE TRIGGER update_notifications_timestamp
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_kb_articles_timestamp ON kb_articles;
CREATE TRIGGER update_kb_articles_timestamp
  BEFORE UPDATE ON kb_articles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_purchase_requests_timestamp ON purchase_requests;
CREATE TRIGGER update_purchase_requests_timestamp
  BEFORE UPDATE ON purchase_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_ai_sessions_timestamp ON ai_sessions;
CREATE TRIGGER update_ai_sessions_timestamp
  BEFORE UPDATE ON ai_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Message hooks
DROP TRIGGER IF EXISTS on_message_last_update ON messages;
CREATE TRIGGER on_message_last_update
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION public.update_conversation_last_message();

DROP TRIGGER IF EXISTS on_new_message_notify ON messages;
CREATE TRIGGER on_new_message_notify
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_new_message();

-- Escalation hooks
DROP TRIGGER IF EXISTS on_conversation_escalated ON conversations;
CREATE TRIGGER on_conversation_escalated
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_escalation();

-- User signup hook
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- STEP 9: Enable RLS on All Tables
-- =====================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chatbots ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE kb_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_sessions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 10: Create RLS Policies
-- =====================================================

-- Organizations
DROP POLICY IF EXISTS "org_access" ON organizations;
CREATE POLICY "org_access" ON organizations FOR ALL
  USING (
    owner_id = auth.uid() OR
    id IN (SELECT public.my_org_ids())
  );

-- Chatbots
DROP POLICY IF EXISTS "chatbot_access" ON chatbots;
CREATE POLICY "chatbot_access" ON chatbots FOR ALL
  USING (org_id IN (SELECT public.my_org_ids()));

-- Conversations - org members + public widget
DROP POLICY IF EXISTS "conversation_org_access" ON conversations;
CREATE POLICY "conversation_org_access" ON conversations FOR ALL
  USING (
    chatbot_id IN (
      SELECT id FROM chatbots WHERE org_id IN (SELECT public.my_org_ids())
    )
  );

DROP POLICY IF EXISTS "conversation_public_insert" ON conversations;
CREATE POLICY "conversation_public_insert" ON conversations FOR INSERT
  WITH CHECK (TRUE);

DROP POLICY IF EXISTS "conversation_public_select" ON conversations;
CREATE POLICY "conversation_public_select" ON conversations FOR SELECT
  USING (TRUE);

-- Messages - org members + public widget
DROP POLICY IF EXISTS "message_org_access" ON messages;
CREATE POLICY "message_org_access" ON messages FOR ALL
  USING (
    conversation_id IN (
      SELECT id FROM conversations WHERE chatbot_id IN (
        SELECT id FROM chatbots WHERE org_id IN (SELECT public.my_org_ids())
      )
    )
  );

DROP POLICY IF EXISTS "message_public_insert" ON messages;
CREATE POLICY "message_public_insert" ON messages FOR INSERT
  WITH CHECK (TRUE);

DROP POLICY IF EXISTS "message_public_select" ON messages;
CREATE POLICY "message_public_select" ON messages FOR SELECT
  USING (TRUE);

-- Notifications
DROP POLICY IF EXISTS "notification_access" ON notifications;
CREATE POLICY "notification_access" ON notifications FOR ALL
  USING (
    org_id IN (SELECT public.my_org_ids())
    OR target_user_id = auth.uid()
  );

-- Team members (avoid recursion by using direct checks)
DROP POLICY IF EXISTS "team_access" ON team_members;
CREATE POLICY "team_access" ON team_members FOR ALL
  USING (
    org_id IN (SELECT public.my_owned_org_ids())
    OR user_id = auth.uid()
  );

-- Profiles
DROP POLICY IF EXISTS "profile_self" ON profiles;
CREATE POLICY "profile_self" ON profiles FOR SELECT
  USING (id = auth.uid());

DROP POLICY IF EXISTS "profile_self_update" ON profiles;
CREATE POLICY "profile_self_update" ON profiles FOR UPDATE
  USING (id = auth.uid());

-- Agent status
DROP POLICY IF EXISTS "agent_status_own" ON agent_status;
CREATE POLICY "agent_status_own" ON agent_status FOR ALL
  USING (agent_id = auth.uid());

-- Typing indicators
DROP POLICY IF EXISTS "typing_indicator_org" ON typing_indicators;
CREATE POLICY "typing_indicator_org" ON typing_indicators FOR ALL
  USING (
    conversation_id IN (
      SELECT id FROM conversations WHERE chatbot_id IN (
        SELECT id FROM chatbots WHERE org_id IN (SELECT public.my_org_ids())
      )
    )
  );

-- KB Articles
DROP POLICY IF EXISTS "kb_org_access" ON kb_articles;
CREATE POLICY "kb_org_access" ON kb_articles FOR ALL
  USING (org_id IN (SELECT public.my_org_ids()));

DROP POLICY IF EXISTS "kb_public_read" ON kb_articles;
CREATE POLICY "kb_public_read" ON kb_articles FOR SELECT
  USING (is_published = TRUE);

-- Purchase requests
DROP POLICY IF EXISTS "purchase_request_org" ON purchase_requests;
CREATE POLICY "purchase_request_org" ON purchase_requests FOR ALL
  USING (org_id IN (SELECT public.my_org_ids()));

-- =====================================================
-- STEP 11: Enable Realtime for Key Tables
-- =====================================================

ALTER TABLE conversations REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE notifications REPLICA IDENTITY FULL;
ALTER TABLE typing_indicators REPLICA IDENTITY FULL;
ALTER TABLE agent_status REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'conversations') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'notifications') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'typing_indicators') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'agent_status') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE agent_status;
  END IF;
END$$;

-- =====================================================
-- SUCCESS! Complete database schema is ready.
-- =====================================================
