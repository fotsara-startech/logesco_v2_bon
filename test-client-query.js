const path = require('path');
const { PrismaClient } = require('@prisma/client');
const dbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'backend', 'database', 'logesco.db');
const prisma = new PrismaClient({ datasources: { db: { url: 'file:' + dbPath } } });

async function main() {
  try {
    const r = await prisma.client.findMany({ take: 2, include: { compte: true } });
    console.log('✅ clients OK, count:', r.length);
  } catch(e) {
    console.log('❌ clients ERREUR:', e.message);
  }
  await prisma.$disconnect();
}
main();
