/**
 * Script pour activer les catégories "RATION" et "cat"
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function activateCategories() {
  try {
    console.log('🔧 Activation des catégories "RATION" et "cat"...\n');

    // Rechercher les catégories
    const categories = await prisma.movementCategory.findMany({
      where: {
        OR: [
          { nom: { in: ['ration', 'cat'] } },
          { displayName: { in: ['RATION', 'cat'] } }
        ]
      }
    });

    if (categories.length === 0) {
      console.log('❌ Aucune catégorie "RATION" ou "cat" trouvée dans la base de données.');
      console.log('\nVérifiez que vous avez bien créé ces catégories depuis l\'interface.');
      return;
    }

    console.log(`📋 ${categories.length} catégorie(s) trouvée(s):\n`);

    // Activer chaque catégorie
    for (const category of categories) {
      console.log(`  📌 ${category.displayName} (${category.nom})`);
      console.log(`     État actuel: ${category.isActive ? '✅ Active' : '❌ Inactive'}`);

      if (!category.isActive) {
        await prisma.movementCategory.update({
          where: { id: category.id },
          data: { isActive: true }
        });
        console.log(`     ✅ Catégorie activée avec succès!`);
      } else {
        console.log(`     ℹ️  Catégorie déjà active`);
      }
      console.log('');
    }

    console.log('✅ Opération terminée!\n');
    console.log('💡 Redémarrez l\'application Flutter pour voir les changements.');

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

activateCategories();
