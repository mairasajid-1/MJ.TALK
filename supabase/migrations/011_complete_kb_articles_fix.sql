-- =====================================================
-- COMPLETE KB ARTICLES FIX
-- Drop and recreate table with correct schema
-- =====================================================

-- Drop existing table (will cascade to delete data - be careful!)
DROP TABLE IF EXISTS public.kb_articles CASCADE;

-- Recreate with correct structure
CREATE TABLE public.kb_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chatbot_id UUID NOT NULL REFERENCES public.chatbots(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
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

-- Create indexes
CREATE INDEX idx_kb_articles_chatbot_id ON public.kb_articles(chatbot_id);
CREATE INDEX idx_kb_articles_org_id ON public.kb_articles(org_id);
CREATE INDEX idx_kb_articles_category ON public.kb_articles(category);
CREATE INDEX idx_kb_articles_is_published ON public.kb_articles(is_published);
CREATE INDEX idx_kb_articles_created_at ON public.kb_articles(created_at DESC);

-- Enable RLS
ALTER TABLE public.kb_articles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view published articles in their org" 
  ON public.kb_articles FOR SELECT
  USING (
    is_published = TRUE 
    AND EXISTS (
      SELECT 1 FROM public.chatbots cb
      WHERE cb.id = kb_articles.chatbot_id
    )
  );

CREATE POLICY "Users can manage articles in their org" 
  ON public.kb_articles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.chatbots cb
      JOIN public.organizations o ON cb.org_id = o.id
      WHERE cb.id = kb_articles.chatbot_id
        AND (
          o.owner_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.team_members tm
            WHERE tm.org_id = o.id 
              AND tm.user_id = auth.uid()
              AND tm.accepted_at IS NOT NULL
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.chatbots cb
      JOIN public.organizations o ON cb.org_id = o.id
      WHERE cb.id = kb_articles.chatbot_id
        AND (
          o.owner_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.team_members tm
            WHERE tm.org_id = o.id 
              AND tm.user_id = auth.uid()
              AND tm.accepted_at IS NOT NULL
          )
        )
    )
  );

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION public.update_kb_articles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_kb_articles_updated_at
  BEFORE UPDATE ON public.kb_articles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_kb_articles_updated_at();

-- Verify table structure
DO $$
DECLARE
  col_count INTEGER;
  columns TEXT;
BEGIN
  SELECT COUNT(*), STRING_AGG(column_name, ', ' ORDER BY ordinal_position)
  INTO col_count, columns
  FROM information_schema.columns
  WHERE table_schema = 'public' 
    AND table_name = 'kb_articles';
  
  RAISE NOTICE '===========================================';
  RAISE NOTICE '✅ kb_articles table recreated successfully';
  RAISE NOTICE '✅ Total columns: %', col_count;
  RAISE NOTICE '✅ Columns: %', columns;
  RAISE NOTICE '✅ RLS policies created';
  RAISE NOTICE '✅ Triggers created';
  RAISE NOTICE '✅ Indexes created';
  RAISE NOTICE '';
  RAISE NOTICE '📝 You can now create KB articles!';
  RAISE NOTICE '===========================================';
END $$;

-- Test query to verify structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'kb_articles'
ORDER BY ordinal_position;
