const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkCategories() {
  try {
    const categories = await prisma.movementCategory.findMany({
      select: {
        id: true,
        nom: true,
        displayName: true
      }
    });

    console.log('📋 Catégories disponibles:');
    categories.forEach(cat => {
      console.log(`  - ID: ${cat.id}, Nom: ${cat.nom}, Display: ${cat.displayName}`);
    });

    // Chercher une catégorie pour paiement fournisseur
    const paiementFournisseur = categories.find(c => 
      c.nom.toLowerCase().includes('fournisseur') || 
      c.nom.toLowerCase().includes('paiement') ||
      c.displayName?.toLowerCase().includes('fournisseur')
    );

    if (paiementFournisseur) {
      console.log(`\n✅ Catégorie trouvée pour paiement fournisseur: ${paiementFournisseur.displayName} (ID: ${paiementFournisseur.id})`);
    } else {
      console.log('\n⚠️ Aucune catégorie spécifique pour paiement fournisseur trouvée');
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkCategories();
