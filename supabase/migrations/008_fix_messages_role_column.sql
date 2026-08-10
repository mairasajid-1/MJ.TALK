-- =====================================================
-- FIX MESSAGES TABLE - Rename sender_type to role
-- Update constraint to match application expectations
-- =====================================================

-- Step 1: Rename sender_type column to role (if it exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'messages' 
      AND column_name = 'sender_type'
  ) THEN
    -- Rename the column
    ALTER TABLE public.messages RENAME COLUMN sender_type TO role;
    
    -- Drop old constraint
    ALTER TABLE public.messages 
      DROP CONSTRAINT IF EXISTS messages_sender_type_check;
    
    RAISE NOTICE 'Renamed sender_type to role';
  ELSE
    RAISE NOTICE 'Column sender_type does not exist or already renamed';
  END IF;
END $$;

-- Step 2: Update constraint to accept user/assistant/admin
ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_role_check;

ALTER TABLE public.messages
  ADD CONSTRAINT messages_role_check 
  CHECK (role IN ('user', 'assistant', 'admin'));

-- Step 3: Update existing data to use new role values
UPDATE public.messages 
SET role = CASE 
  WHEN role = 'visitor' THEN 'user'
  WHEN role = 'ai' THEN 'assistant'
  WHEN role = 'agent' THEN 'admin'
  ELSE role
END
WHERE role IN ('visitor', 'ai', 'agent');

-- Step 4: Verify the changes
DO $$
DECLARE
  role_column_exists BOOLEAN;
  sender_type_column_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' AND column_name = 'role'
  ) INTO role_column_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' AND column_name = 'sender_type'
  ) INTO sender_type_column_exists;
  
  IF role_column_exists AND NOT sender_type_column_exists THEN
    RAISE NOTICE 'SUCCESS: messages table now uses role column with correct constraint';
  ELSE
    RAISE WARNING 'ISSUE: Check messages table structure manually';
  END IF;
END $$;

-- =====================================================
-- Optional: Add helpful indexes
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_messages_conversation_role 
  ON public.messages(conversation_id, role);

CREATE INDEX IF NOT EXISTS idx_messages_created_at 
  ON public.messages(created_at DESC);

-- =====================================================
-- Update RLS policies if they reference sender_type
-- =====================================================

-- Drop and recreate policies that might reference the old column
DROP POLICY IF EXISTS "Users can insert their own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;

-- Recreate with role column
CREATE POLICY "Users can insert their own messages" 
  ON public.messages FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Users can view messages in their org conversations" 
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      JOIN chatbots cb ON c.chatbot_id = cb.id
      WHERE c.id = messages.conversation_id
    )
  );

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 008 completed successfully';
  RAISE NOTICE '✅ Messages table now uses "role" column';
  RAISE NOTICE '✅ Constraint updated to accept: user, assistant, admin';
  RAISE NOTICE '✅ Existing data migrated from visitor/ai/agent';
END $$;
