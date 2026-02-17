const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function debugDatabase() {
  try {
    console.log('🔍 Diagnostic de la base de données...');
    
    // Vérifier les produits
    const products = await prisma.produit.findMany();
    console.log(`📦 Produits: ${products.length}`);
    
    // Vérifier les inventaires
    const inventories = await prisma.stockInventory.findMany();
    console.log(`📋 Inventaires: ${inventories.length}`);
    
    // Vérifier les items d'inventaire
    const items = await prisma.inventoryItem.findMany();
    console.log(`📝 Items d'inventaire: ${items.length}`);
    
    // Afficher les détails des inventaires
    for (const inventory of inventories) {
      console.log(`\n📋 Inventaire ${inventory.id}: ${inventory.nom} (${inventory.status})`);
      
      const inventoryItems = await prisma.inventoryItem.findMany({
        where: { inventaireId: inventory.id },
        include: {
          produit: {
            select: {
              nom: true,
              prixUnitaire: true,
              prixAchat: true
            }
          }
        }
      });
      
      console.log(`   Items: ${inventoryItems.length}`);
      
      inventoryItems.forEach((item, index) => {
        console.log(`   ${index + 1}. ${item.produit?.nom || 'Produit inconnu'}`);
        console.log(`      - Prix unitaire: ${item.prixUnitaire || 'N/A'} FCFA`);
        console.log(`      - Prix achat: ${item.prixAchat || 'N/A'} FCFA`);
        console.log(`      - Quantité système: ${item.quantiteSysteme}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

debugDatabase();