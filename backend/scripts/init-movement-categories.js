/**
 * Script d'initialisation des catégories de mouvements financiers
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const defaultCategories = [
  {
    nom: 'achats',
    displayName: 'Achats de marchandises',
    color: '#EF4444',
    icon: 'shopping_cart',
    isDefault: true
  },
  {
    nom: 'charges',
    displayName: 'Charges et frais',
    color: '#F59E0B',
    icon: 'receipt_long',
    isDefault: true
  },
  {
    nom: 'salaires',
    displayName: 'Salaires du personnel',
    color: '#10B981',
    icon: 'people',
    isDefault: true
  },
  {
    nom: 'maintenance',
    displayName: 'Maintenance et réparations',
    color: '#8B5CF6',
    icon: 'build',
    isDefault: true
  },
  {
    nom: 'transport',
    displayName: 'Transport et livraison',
    color: '#06B6D4',
    icon: 'local_shipping',
    isDefault: true
  },
  {
    nom: 'autres',
    displayName: 'Autres dépenses',
    color: '#6B7280',
    icon: 'more_horiz',
    isDefault: true
  }
];

async function initCategories() {
  try {
    console.log('🏗️ Initialisation des catégories de mouvements financiers...');

    // Vérifier si des catégories existent déjà
    const existingCount = await prisma.movementCategory.count();
    
    if (existingCount > 0) {
      console.log(`⚠️ ${existingCount} catégories existent déjà. Ajout des catégories manquantes seulement.`);
    }

    let createdCount = 0;
    let skippedCount = 0;

    for (const category of defaultCategories) {
      try {
        // Vérifier si la catégorie existe déjà
        const existing = await prisma.movementCategory.findUnique({
          where: { nom: category.nom }
        });

        if (existing) {
          console.log(`⏭️ Catégorie "${category.displayName}" existe déjà`);
          skippedCount++;
          continue;
        }

        // Créer la catégorie
        const created = await prisma.movementCategory.create({
          data: category
        });

        console.log(`✅ Catégorie créée: ${created.displayName} (${created.nom})`);
        createdCount++;

      } catch (error) {
        console.error(`❌ Erreur lors de la création de la catégorie "${category.nom}":`, error.message);
      }
    }

    console.log('\n📊 Résumé:');
    console.log(`✅ Catégories créées: ${createdCount}`);
    console.log(`⏭️ Catégories existantes: ${skippedCount}`);
    console.log(`📋 Total des catégories: ${await prisma.movementCategory.count()}`);

    // Afficher toutes les catégories
    const allCategories = await prisma.movementCategory.findMany({
      orderBy: { nom: 'asc' }
    });

    console.log('\n📋 Catégories disponibles:');
    allCategories.forEach(cat => {
      console.log(`  - ${cat.displayName} (${cat.nom}) - ${cat.color} ${cat.icon}`);
    });

  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation des catégories:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script si appelé directement
if (require.main === module) {
  initCategories();
}

module.exports = { initCategories, defaultCategories };