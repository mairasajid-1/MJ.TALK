const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Connecting to PostgreSQL database via Prisma...");

  // 1. Ensure kb_articles table exists with all columns
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS public.kb_articles (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      chatbot_id UUID NOT NULL,
      org_id UUID NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      category TEXT DEFAULT 'general',
      tags TEXT[] DEFAULT '{}',
      is_published BOOLEAN DEFAULT TRUE,
      created_by UUID,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );
  `);

  // 2. Ensure category column exists
  await prisma.$executeRawUnsafe(`
    ALTER TABLE public.kb_articles 
    ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general';
  `);

  // 3. Ensure tags column exists
  await prisma.$executeRawUnsafe(`
    ALTER TABLE public.kb_articles 
    ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
  `);

  // 4. Ensure is_published column exists
  await prisma.$executeRawUnsafe(`
    ALTER TABLE public.kb_articles 
    ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT TRUE;
  `);

  // 5. Ensure created_by column exists
  await prisma.$executeRawUnsafe(`
    ALTER TABLE public.kb_articles 
    ADD COLUMN IF NOT EXISTS created_by UUID;
  `);

  // 6. Update category check constraint
  try {
    await prisma.$executeRawUnsafe(`
      ALTER TABLE public.kb_articles DROP CONSTRAINT IF EXISTS kb_articles_category_check;
    `);
    await prisma.$executeRawUnsafe(`
      ALTER TABLE public.kb_articles 
      ADD CONSTRAINT kb_articles_category_check 
      CHECK (category IN ('general', 'account', 'payment', 'refund', 'technical', 'setup', 'faq'));
    `);
  } catch (err) {
    console.warn("Constraint notice:", err.message);
  }

  // 7. Reload Supabase PostgREST schema cache
  try {
    await prisma.$executeRawUnsafe(`NOTIFY pgrst, 'reload schema';`);
  } catch (err) {
    console.warn("Notify notice:", err.message);
  }

  console.log("==============================================");
  console.log("✅ SUCCESS: Database schema updated via Prisma!");
  console.log("✅ kb_articles category and created_by columns verified!");
  console.log("==============================================");
}

main()
  .catch((e) => {
    console.error("❌ Prisma DB execution error:", e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
