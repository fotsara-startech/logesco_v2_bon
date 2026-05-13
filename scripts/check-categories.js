/**
 * Script de diagnostic pour vérifier les catégories de mouvements financiers
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkCategories() {
  try {
    console.log('🔍 Vérification des catégories de mouvements financiers...\n');

    // Récupérer toutes les catégories (actives et inactives)
    const allCategories = await prisma.movementCategory.findMany({
      orderBy: [
        { isActive: 'desc' },
        { isDefault: 'desc' },
        { displayName: 'asc' }
      ]
    });

    console.log(`📊 Total des catégories: ${allCategories.length}\n`);

    // Séparer les catégories actives et inactives
    const activeCategories = allCategories.filter(c => c.isActive);
    const inactiveCategories = allCategories.filter(c => !c.isActive);

    console.log(`✅ Catégories actives: ${activeCategories.length}`);
    console.log(`❌ Catégories inactives: ${inactiveCategories.length}\n`);

    // Afficher les catégories actives
    if (activeCategories.length > 0) {
      console.log('📋 CATÉGORIES ACTIVES:');
      console.log('─'.repeat(80));
      activeCategories.forEach(cat => {
        console.log(`  ${cat.isDefault ? '⭐' : '📌'} ${cat.displayName} (${cat.nom})`);
        console.log(`     ID: ${cat.id} | Couleur: ${cat.color} | Icône: ${cat.icon}`);
        console.log(`     Créée: ${cat.dateCreation.toLocaleString('fr-FR')}`);
        console.log('');
      });
    }

    // Afficher les catégories inactives
    if (inactiveCategories.length > 0) {
      console.log('\n⚠️  CATÉGORIES INACTIVES:');
      console.log('─'.repeat(80));
      inactiveCategories.forEach(cat => {
        console.log(`  ${cat.isDefault ? '⭐' : '📌'} ${cat.displayName} (${cat.nom})`);
        console.log(`     ID: ${cat.id} | Couleur: ${cat.color} | Icône: ${cat.icon}`);
        console.log(`     Créée: ${cat.dateCreation.toLocaleString('fr-FR')}`);
        console.log('');
      });
    }

    // Vérifier les catégories "RATION" et "cat"
    console.log('\n🔎 Recherche des catégories "RATION" et "cat"...');
    console.log('─'.repeat(80));
    
    const rationCategory = allCategories.find(c => 
      c.nom.toLowerCase() === 'ration' || c.displayName.toLowerCase() === 'ration'
    );
    
    const catCategory = allCategories.find(c => 
      c.nom.toLowerCase() === 'cat' || c.displayName.toLowerCase() === 'cat'
    );

    if (rationCategory) {
      console.log(`\n✅ Catégorie "RATION" trouvée:`);
      console.log(`   ID: ${rationCategory.id}`);
      console.log(`   Nom: ${rationCategory.nom}`);
      console.log(`   Display Name: ${rationCategory.displayName}`);
      console.log(`   Active: ${rationCategory.isActive ? '✅ OUI' : '❌ NON'}`);
      console.log(`   Par défaut: ${rationCategory.isDefault ? 'Oui' : 'Non'}`);
      console.log(`   Couleur: ${rationCategory.color}`);
      console.log(`   Icône: ${rationCategory.icon}`);
    } else {
      console.log('\n❌ Catégorie "RATION" NON TROUVÉE');
    }

    if (catCategory) {
      console.log(`\n✅ Catégorie "cat" trouvée:`);
      console.log(`   ID: ${catCategory.id}`);
      console.log(`   Nom: ${catCategory.nom}`);
      console.log(`   Display Name: ${catCategory.displayName}`);
      console.log(`   Active: ${catCategory.isActive ? '✅ OUI' : '❌ NON'}`);
      console.log(`   Par défaut: ${catCategory.isDefault ? 'Oui' : 'Non'}`);
      console.log(`   Couleur: ${catCategory.color}`);
      console.log(`   Icône: ${catCategory.icon}`);
    } else {
      console.log('\n❌ Catégorie "cat" NON TROUVÉE');
    }

    // Proposer de réactiver les catégories inactives
    if (!rationCategory?.isActive || !catCategory?.isActive) {
      console.log('\n\n⚠️  PROBLÈME DÉTECTÉ:');
      console.log('Les catégories "RATION" et/ou "cat" sont inactives ou n\'existent pas.');
      console.log('\nPour les réactiver, exécutez:');
      console.log('  node backend/scripts/activate-categories.js');
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

checkCategories();
