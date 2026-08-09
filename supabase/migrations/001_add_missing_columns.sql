-- =====================================================
-- Add missing columns to existing tables
-- =====================================================

-- Add missing columns to chatbots table
ALTER TABLE IF EXISTS chatbots ADD COLUMN IF NOT EXISTS allowed_domains TEXT[];
ALTER TABLE IF EXISTS chatbots ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE IF EXISTS chatbots ADD COLUMN IF NOT EXISTS system_prompt TEXT;
ALTER TABLE IF EXISTS chatbots ADD COLUMN IF NOT EXISTS welcome_message TEXT;
ALTER TABLE IF EXISTS chatbots ADD COLUMN IF NOT EXISTS initial_questions TEXT[];
ALTER TABLE IF EXISTS chatbots ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- These columns are now added to chatbots table