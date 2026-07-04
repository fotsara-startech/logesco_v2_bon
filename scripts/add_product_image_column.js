const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    await prisma.$executeRawUnsafe('ALTER TABLE produits ADD COLUMN image_url TEXT');
    console.log('✅ Colonne image_url ajoutée avec succès');
  } catch (e) {
    if (e.message && e.message.includes('duplicate column')) {
      console.log('ℹ️  Colonne image_url déjà présente, rien à faire');
    } else {
      console.error('❌ Erreur:', e.message);
      process.exit(1);
    }
  } finally {
    await prisma.$disconnect();
  }
}

main();
