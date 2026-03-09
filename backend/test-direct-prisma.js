// Test direct de Prisma - Version simple
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  log: ['error', 'warn'],
});

async function test() {
  console.log('========================================');
  console.log('  TEST DIRECT PRISMA');
  console.log('========================================\n');

  try {
    // Test 1: Compter les utilisateurs
    console.log('[1/4] Comptage utilisateurs...');
    const userCount = await prisma.utilisateur.count();
    console.log(`Résultat: ${userCount} utilisateurs`);
    
    if (userCount === 0) {
      console.log('❌ AUCUN utilisateur trouvé par Prisma!');
      
      // Test avec SQL brut
      console.log('\nTest avec SQL brut...');
      const rawResult = await prisma.$queryRaw`SELECT COUNT(*) as count FROM utilisateurs`;
      console.log(`SQL brut: ${rawResult[0].count} utilisateurs`);
      
      if (rawResult[0].count > 0) {
        console.log('\n❌ PROBLÈME CONFIRMÉ:');
        console.log('   - SQL brut trouve des données');
        console.log('   - Prisma ne trouve rien');
        console.log('   → Problème de mapping des colonnes');
      }
    } else {
      console.log('✅ Prisma trouve des utilisateurs');
      
      // Afficher un exemple
      const user = await prisma.utilisateur.findFirst();
      console.log('\nExemple:');
      console.log(JSON.stringify(user, null, 2));
    }
    console.log('');

    // Test 2: Compter les produits
    console.log('[2/4] Comptage produits...');
    const productCount = await prisma.produit.count();
    console.log(`Résultat: ${productCount} produits`);
    
    if (productCount > 0) {
      const product = await prisma.produit.findFirst();
      console.log('Exemple:');
      console.log(JSON.stringify(product, null, 2));
    }
    console.log('');

    // Test 3: Compter les ventes
    console.log('[3/4] Comptage ventes...');
    const salesCount = await prisma.vente.count();
    console.log(`Résultat: ${salesCount} ventes`);
    console.log('');

    // Test 4: Compter les clients
    console.log('[4/4] Comptage clients...');
    const clientCount = await prisma.client.count();
    console.log(`Résultat: ${clientCount} clients`);
    console.log('');

    // Résumé
    console.log('========================================');
    console.log('  RÉSUMÉ');
    console.log('========================================');
    console.log(`Utilisateurs: ${userCount}`);
    console.log(`Produits: ${productCount}`);
    console.log(`Ventes: ${salesCount}`);
    console.log(`Clients: ${clientCount}`);
    console.log('');

    if (userCount > 0 && productCount > 0) {
      console.log('✅ PRISMA FONCTIONNE!');
      console.log('   Le problème est probablement dans:');
      console.log('   - Les routes API du backend');
      console.log('   - L\'application Flutter');
      console.log('   - La connexion réseau');
    } else {
      console.log('❌ PRISMA NE LIT PAS LES DONNÉES');
      console.log('   Vérifier:');
      console.log('   - Le schéma Prisma');
      console.log('   - Les noms de colonnes');
      console.log('   - La base de données');
    }

  } catch (error) {
    console.error('❌ ERREUR:', error.message);
    console.error('\nDétails:', error);
  } finally {
    await prisma.$disconnect();
  }
}

test();
