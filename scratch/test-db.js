const { Client } = require('pg');

async function testConn(url) {
  console.log("Testing URL:", url.replace(/:[^:@]+@/, ':****@'));
  const client = new Client({ connectionString: url });
  try {
    await client.connect();
    const res = await client.query('SELECT current_database(), now()');
    console.log("SUCCESS!", res.rows[0]);
    await client.end();
    return true;
  } catch (err) {
    console.error("FAIL:", err.message);
    return false;
  }
}

async function run() {
  const password = "hgjdawskljgkadildy8";
  const ref = "lzubrcmdawuujszeoxea";
  
  const urls = [
    `postgresql://postgres:${password}@db.${ref}.supabase.co:5432/postgres`,
    `postgresql://postgres.${ref}:${password}@aws-0-eu-central-1.pooler.supabase.com:6543/postgres`,
    `postgresql://postgres.${ref}:${password}@aws-0-us-east-1.pooler.supabase.com:6543/postgres`,
    `postgresql://postgres.${ref}:${password}@aws-0-us-west-1.pooler.supabase.com:6543/postgres`,
    `postgresql://postgres.${ref}:${password}@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres`,
    `postgresql://postgres.${ref}:${password}@aws-0-sa-east-1.pooler.supabase.com:6543/postgres`,
    `postgresql://postgres.${ref}:${password}@aws-0-me-central-1.pooler.supabase.com:6543/postgres`,
  ];

  for (const u of urls) {
    const ok = await testConn(u);
    if (ok) {
      console.log("WORKING URL FOUND:", u);
      break;
    }
  }
}

run();
