const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Script pour insérer les catégories par défaut
 */
async function seedCategories() {
  console.log('🌱 Insertion des catégories par défaut...');

  const defaultCategories = [
    {
      nom: 'Smartphones',
      description: 'Téléphones intelligents et accessoires mobiles'
    },
    {
      nom: 'Ordinateurs',
      description: 'PC, laptops et composants informatiques'
    },
    {
      nom: 'Accessoires',
      description: 'Câbles, chargeurs et autres accessoires électroniques'
    },
    {
      nom: 'Écrans',
      description: 'Moniteurs et écrans pour ordinateurs'
    },
    {
      nom: 'Audio',
      description: 'Casques, écouteurs et équipements audio'
    }
  ];

  let created = 0;
  let existing = 0;

  for (const categoryData of defaultCategories) {
    try {
      const category = await prisma.category.create({
        data: categoryData
      });
      console.log(`✅ Catégorie créée: ${category.nom}`);
      created++;
    } catch (error) {
      if (error.code === 'P2002') {
        console.log(`ℹ️  Catégorie existe déjà: ${categoryData.nom}`);
        existing++;
      } else {
        console.error(`❌ Erreur création ${categoryData.nom}:`, error.message);
      }
    }
  }

  console.log('\n📊 Résumé:');
  console.log(`   - Catégories créées: ${created}`);
  console.log(`   - Catégories existantes: ${existing}`);
  console.log(`   - Total: ${created + existing}`);

  // Afficher toutes les catégories
  const allCategories = await prisma.category.findMany({
    orderBy: { nom: 'asc' }
  });

  console.log('\n📋 Catégories dans la base:');
  allCategories.forEach(cat => {
    console.log(`   - ${cat.id}: ${cat.nom} (${cat.description || 'Pas de description'})`);
  });

  console.log('\n🎯 Insertion terminée!');
}

// Exécuter le script
seedCategories()
  .catch((error) => {
    console.error('❌ Erreur:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });