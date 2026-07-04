const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const result = await prisma.$queryRawUnsafe("PRAGMA table_info(produits)");
  const col = result.find(r => r.name === 'image_url');
  if (col) {
    console.log('✅ Colonne image_url présente:', col);
  } else {
    console.log('❌ Colonne image_url ABSENTE. Colonnes disponibles:', result.map(r => r.name));
  }
  await prisma.$disconnect();
}

main().catch(console.error);
