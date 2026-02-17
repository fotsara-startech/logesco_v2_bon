/**
 * Script pour vérifier le contenu de la base de données
 * Utilisation: node backend/scripts/check-database.js
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkDatabase() {
  console.log('🔍 Vérification du contenu de la base de données\n');
  console.log('=' .repeat(60) + '\n');

  try {
    // Compter les enregistrements dans chaque table
    const counts = {
      roles: await prisma.userRole.count(),
      utilisateurs: await prisma.utilisateur.count(),
      categories: await prisma.category.count(),
      produits: await prisma.produit.count(),
      stock: await prisma.stock.count(),
      fournisseurs: await prisma.fournisseur.count(),
      clients: await prisma.client.count(),
      commandes: await prisma.commandeApprovisionnement.count(),
      ventes: await prisma.vente.count(),
      caisses: await prisma.cashRegister.count(),
      mouvementsCaisse: await prisma.cashMovement.count(),
      categoriesMovements: await prisma.movementCategory.count(),
      mouvementsFinanciers: await prisma.financialMovement.count(),
      inventaires: await prisma.stockInventory.count(),
      itemsInventaire: await prisma.inventoryItem.count(),
      mouvementsStock: await prisma.mouvementStock.count(),
      recus: await prisma.historiqueRecu.count()
    };

    // Afficher les résultats
    console.log('📊 Nombre d\'enregistrements par table:\n');
    console.log(`   👥 Rôles utilisateur:           ${counts.roles}`);
    console.log(`   👤 Utilisateurs:                ${counts.utilisateurs}`);
    console.log(`   📦 Catégories de produits:      ${counts.categories}`);
    console.log(`   🛍️  Produits:                    ${counts.produits}`);
    console.log(`   📊 Stocks:                      ${counts.stock}`);
    console.log(`   🚚 Fournisseurs:                ${counts.fournisseurs}`);
    console.log(`   👨‍👩‍👧‍👦 Clients:                     ${counts.clients}`);
    console.log(`   📋 Commandes approvisionnement: ${counts.commandes}`);
    console.log(`   💰 Ventes:                      ${counts.ventes}`);
    console.log(`   💵 Caisses:                     ${counts.caisses}`);
    console.log(`   💸 Mouvements de caisse:        ${counts.mouvementsCaisse}`);
    console.log(`   📁 Catégories de mouvements:    ${counts.categoriesMovements}`);
    console.log(`   💳 Mouvements financiers:       ${counts.mouvementsFinanciers}`);
    console.log(`   📝 Inventaires:                 ${counts.inventaires}`);
    console.log(`   📋 Items d'inventaire:          ${counts.itemsInventaire}`);
    console.log(`   📦 Mouvements de stock:         ${counts.mouvementsStock}`);
    console.log(`   🧾 Reçus:                       ${counts.recus}`);

    console.log('\n' + '=' .repeat(60));

    // Vérifier si la base est vide
    const totalRecords = Object.values(counts).reduce((sum, count) => sum + count, 0);
    
    if (totalRecords === 0) {
      console.log('\n⚠️  La base de données est vide !');
      console.log('\n💡 Pour la remplir, exécutez:');
      console.log('   npm run db:seed          (ajouter des données)');
      console.log('   npm run db:reset-seed    (réinitialiser et remplir)');
    } else {
      console.log(`\n✅ La base de données contient ${totalRecords} enregistrements au total`);
    }

    // Afficher quelques exemples de données
    console.log('\n' + '=' .repeat(60));
    console.log('\n📋 Exemples de données:\n');

    // Utilisateurs
    const users = await prisma.utilisateur.findMany({
      take: 3,
      include: { role: true }
    });
    
    if (users.length > 0) {
      console.log('👥 Utilisateurs:');
      users.forEach(user => {
        console.log(`   - ${user.nomUtilisateur} (${user.email}) - Rôle: ${user.role?.displayName || 'N/A'}`);
      });
      console.log();
    }

    // Produits
    const products = await prisma.produit.findMany({
      take: 5,
      include: { 
        categorie: true,
        stock: true
      }
    });
    
    if (products.length > 0) {
      console.log('🛍️  Produits:');
      products.forEach(product => {
        const stockQty = product.stock?.quantiteDisponible || 0;
        console.log(`   - ${product.nom} (${product.reference}) - ${product.prixUnitaire}$ - Stock: ${stockQty}`);
      });
      console.log();
    }

    // Ventes récentes
    const sales = await prisma.vente.findMany({
      take: 3,
      orderBy: { dateVente: 'desc' },
      include: {
        client: true,
        vendeur: true
      }
    });
    
    if (sales.length > 0) {
      console.log('💰 Ventes récentes:');
      sales.forEach(sale => {
        const clientName = sale.client ? `${sale.client.nom} ${sale.client.prenom || ''}` : 'Client anonyme';
        const vendeurName = sale.vendeur?.nomUtilisateur || 'N/A';
        console.log(`   - ${sale.numeroVente} - ${clientName} - ${sale.montantTotal}$ - Vendeur: ${vendeurName}`);
      });
      console.log();
    }

    // Statistiques de stock
    const allProducts = await prisma.produit.findMany({
      include: { stock: true }
    });
    
    const lowStock = allProducts.filter(product => 
      product.stock && product.stock.quantiteDisponible <= product.seuilStockMinimum
    );

    if (lowStock.length > 0) {
      console.log(`⚠️  ${lowStock.length} produit(s) en stock faible:`);
      lowStock.slice(0, 5).forEach(product => {
        console.log(`   - ${product.nom}: ${product.stock?.quantiteDisponible || 0} (seuil: ${product.seuilStockMinimum})`);
      });
      console.log();
    }

    // Paramètres entreprise
    const company = await prisma.parametresEntreprise.findFirst();
    if (company) {
      console.log('🏢 Entreprise:');
      console.log(`   - ${company.nomEntreprise}`);
      console.log(`   - ${company.adresse}`);
      console.log(`   - ${company.telephone}`);
      console.log();
    }

    console.log('=' .repeat(60) + '\n');

  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error.message);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

checkDatabase();
