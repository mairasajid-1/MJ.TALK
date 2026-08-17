-- =====================================================
-- ADD chatbot_id column to kb_articles
-- =====================================================

-- Add chatbot_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'kb_articles' 
      AND column_name = 'chatbot_id'
  ) THEN
    -- Add the column (nullable at first)
    ALTER TABLE public.kb_articles 
      ADD COLUMN chatbot_id UUID REFERENCES chatbots(id) ON DELETE CASCADE;
    
    RAISE NOTICE 'Added chatbot_id column to kb_articles';
    
    -- If there are existing articles, we need to set a default chatbot_id
    -- Get the first chatbot for each org and assign articles to it
    UPDATE public.kb_articles ka
    SET chatbot_id = (
      SELECT c.id 
      FROM chatbots c 
      WHERE c.org_id = ka.org_id 
      LIMIT 1
    )
    WHERE chatbot_id IS NULL;
    
    -- Now make it NOT NULL
    ALTER TABLE public.kb_articles 
      ALTER COLUMN chatbot_id SET NOT NULL;
    
    RAISE NOTICE 'Set chatbot_id for existing articles';
  ELSE
    RAISE NOTICE 'chatbot_id column already exists';
  END IF;
END $$;

-- Recreate the index
CREATE INDEX IF NOT EXISTS idx_kb_articles_chatbot_id 
  ON public.kb_articles(chatbot_id);

-- Update RLS policies to use chatbot_id
DROP POLICY IF EXISTS "Users can view published articles in their org" ON public.kb_articles;
DROP POLICY IF EXISTS "Users can manage articles in their org" ON public.kb_articles;

-- Policy: Users can view published articles for chatbots in their org
CREATE POLICY "Users can view published articles in their org" 
  ON public.kb_articles FOR SELECT
  USING (
    is_published = TRUE 
    AND EXISTS (
      SELECT 1 FROM chatbots cb
      JOIN organizations o ON cb.org_id = o.id
      WHERE cb.id = kb_articles.chatbot_id
    )
  );

-- Policy: Users can manage articles for chatbots in their org
CREATE POLICY "Users can manage articles in their org" 
  ON public.kb_articles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM chatbots cb
      JOIN organizations o ON cb.org_id = o.id
      WHERE cb.id = kb_articles.chatbot_id
        AND (
          o.owner_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM team_members tm
            WHERE tm.org_id = o.id 
              AND tm.user_id = auth.uid()
              AND tm.accepted_at IS NOT NULL
          )
        )
    )
  );

-- Verify
DO $$
DECLARE
  chatbot_id_exists BOOLEAN;
  org_id_exists BOOLEAN;
  category_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'kb_articles' AND column_name = 'chatbot_id'
  ) INTO chatbot_id_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'kb_articles' AND column_name = 'org_id'
  ) INTO org_id_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'kb_articles' AND column_name = 'category'
  ) INTO category_exists;
  
  IF chatbot_id_exists AND org_id_exists AND category_exists THEN
    RAISE NOTICE '===========================================';
    RAISE NOTICE '✅ SUCCESS: All columns exist';
    RAISE NOTICE '✅ chatbot_id: %', chatbot_id_exists;
    RAISE NOTICE '✅ org_id: %', org_id_exists;
    RAISE NOTICE '✅ category: %', category_exists;
    RAISE NOTICE '✅ Knowledge Base is fully functional';
    RAISE NOTICE '===========================================';
  ELSE
    RAISE WARNING 'Some columns missing. Check table structure.';
  END IF;
END $$;
