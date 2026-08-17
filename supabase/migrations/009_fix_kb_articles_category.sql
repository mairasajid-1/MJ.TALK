-- =====================================================
-- FIX KB ARTICLES TABLE - Add missing category column
-- =====================================================

-- Check if kb_articles table exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name = 'kb_articles'
  ) THEN
    -- Create the table if it doesn't exist
    CREATE TABLE public.kb_articles (
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
    
    RAISE NOTICE 'Created kb_articles table';
  ELSE
    RAISE NOTICE 'kb_articles table already exists';
  END IF;
END $$;

-- Add category column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'kb_articles' 
      AND column_name = 'category'
  ) THEN
    ALTER TABLE public.kb_articles 
      ADD COLUMN category TEXT DEFAULT 'general';
    
    RAISE NOTICE 'Added category column to kb_articles';
  ELSE
    RAISE NOTICE 'category column already exists';
  END IF;
END $$;

-- Add constraint to category column
ALTER TABLE public.kb_articles
  DROP CONSTRAINT IF EXISTS kb_articles_category_check;

ALTER TABLE public.kb_articles
  ADD CONSTRAINT kb_articles_category_check 
  CHECK (category IN ('general', 'account', 'payment', 'refund', 'technical', 'setup', 'faq'));

-- Add other missing columns if needed
ALTER TABLE public.kb_articles
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_kb_articles_chatbot_id 
  ON public.kb_articles(chatbot_id);

CREATE INDEX IF NOT EXISTS idx_kb_articles_org_id 
  ON public.kb_articles(org_id);

CREATE INDEX IF NOT EXISTS idx_kb_articles_category 
  ON public.kb_articles(category);

CREATE INDEX IF NOT EXISTS idx_kb_articles_is_published 
  ON public.kb_articles(is_published);

CREATE INDEX IF NOT EXISTS idx_kb_articles_created_at 
  ON public.kb_articles(created_at DESC);

-- Add RLS policies for kb_articles
ALTER TABLE public.kb_articles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view published articles in their org" ON public.kb_articles;
DROP POLICY IF EXISTS "Users can manage articles in their org" ON public.kb_articles;

-- Policy: Users can view published articles in their org
CREATE POLICY "Users can view published articles in their org" 
  ON public.kb_articles FOR SELECT
  USING (
    is_published = TRUE 
    AND EXISTS (
      SELECT 1 FROM organizations o
      WHERE o.id = kb_articles.org_id
    )
  );

-- Policy: Users can manage articles in their org (insert, update, delete)
CREATE POLICY "Users can manage articles in their org" 
  ON public.kb_articles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organizations o
      WHERE o.id = kb_articles.org_id
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

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_kb_articles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_kb_articles_updated_at ON public.kb_articles;

CREATE TRIGGER update_kb_articles_updated_at
  BEFORE UPDATE ON public.kb_articles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_kb_articles_updated_at();

-- Verify the table structure
DO $$
DECLARE
  column_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO column_count
  FROM information_schema.columns
  WHERE table_schema = 'public' 
    AND table_name = 'kb_articles'
    AND column_name = 'category';
  
  IF column_count > 0 THEN
    RAISE NOTICE '✅ SUCCESS: kb_articles table has category column';
    RAISE NOTICE '✅ Knowledge Base articles can now be published';
  ELSE
    RAISE WARNING '❌ FAILED: category column still missing';
  END IF;
END $$;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '===========================================';
  RAISE NOTICE '✅ Migration 009 completed successfully';
  RAISE NOTICE '✅ kb_articles table structure fixed';
  RAISE NOTICE '✅ Category column added/verified';
  RAISE NOTICE '✅ RLS policies created';
  RAISE NOTICE '✅ You can now publish KB articles';
  RAISE NOTICE '===========================================';
END $$;
