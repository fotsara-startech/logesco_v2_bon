process.env.DATABASE_URL = process.env.DATABASE_URL || 'file:./database/logesco.db';
const { getPrismaClient } = require('./src/config/prisma-client');
const prisma = getPrismaClient();

async function main() {
  const result = await prisma.boutique.updateMany({
    where: { estPrincipale: false, nom: { in: ['TEST', 'BEDIMED SARL', 'bedimed sarl'] } },
    data: { isActive: false }
  });
  console.log('Boutiques de test désactivées:', result.count);
  await prisma.$disconnect();
}
main().catch(e => { console.error(e.message); process.exit(1); });
