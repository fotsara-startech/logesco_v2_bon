process.env.DATABASE_URL = 'file:./database/logesco.db';
const { getPrismaClient } = require('./src/config/prisma-client');
const prisma = getPrismaClient();

async function main() {
  const boutiques = await prisma.boutique.findMany({
    orderBy: [{ estPrincipale: 'desc' }, { nom: 'asc' }],
    include: {
      _count: { select: { utilisateurs: true, ventes: true } }
    }
  });
  console.log(JSON.stringify(boutiques, null, 2));
  await prisma.$disconnect();
}
main().catch(e => { console.error(e.message); process.exit(1); });
