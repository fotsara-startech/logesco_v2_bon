const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const cols = await prisma.$queryRawUnsafe(
    "PRAGMA table_info(historique_prix_achat)"
  );
  console.log('Colonnes de historique_prix_achat:');
  cols.forEach(c => console.log(`  ${c.cid} | ${c.name} | ${c.type} | notnull=${c.notnull} | dflt=${c.dflt_value}`));

  const rows = await prisma.$queryRawUnsafe(
    'SELECT * FROM historique_prix_achat LIMIT 5'
  );
  console.log('\nDonnées existantes:', rows);

  await prisma.$disconnect();
}
run().catch(e => { console.error(e.message); process.exit(1); });
