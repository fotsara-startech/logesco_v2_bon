require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function check() {
  // État de la queue
  const stats = await prisma.$queryRawUnsafe(`
    SELECT synced, COUNT(*) as count FROM sync_queue GROUP BY synced
  `);
  console.log('Queue stats:', stats);

  // Entrées en attente
  const pending = await prisma.$queryRawUnsafe(`
    SELECT id, table_name, operation, record_id, created_at, error
    FROM sync_queue WHERE synced = 0 ORDER BY id DESC LIMIT 10
  `);
  console.log('\nEn attente:', pending);

  // Métadonnées
  const meta = await prisma.$queryRawUnsafe('SELECT * FROM sync_meta');
  console.log('\nMeta:', meta);

  await prisma.$disconnect();
}
check().catch(e => { console.error(e.message); process.exit(1); });
