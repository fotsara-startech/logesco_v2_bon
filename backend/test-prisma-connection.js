/**
 * Script de test de connexion Prisma
 * Teste si Prisma peut lire les données de la base
 */

const { PrismaClient } = require('@prisma/client');
const path = require('path');

// Configuration
const dbPath = path.join(__dirname, 'database', 'logesco.db');
process.env.DATABASE_URL = `file:${dbPath}`;

console.log('========================================');
console.log('  TEST CONNEXION PRISMA');
console.log('========================================\n');

console.log(`Base de données: ${dbPath}\n`);

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});

async function testConnection() {
  try {
    console.log('[1/6] Test de connexion...');
    await prisma.$connect();
    console.log('✅ Connexion Prisma établie\n');

    console.log('[2/6] Test lecture utilisateurs...');
    const users = await prisma.utilisateur.findMany({
      take: 5,
      select: {
        id: true,
        nomUtilisateur: true,
        email: true,
        isActive: true,
      },
    });
    console.log(`✅ ${users.length} utilisateurs trouvés`);
    if (users.length > 0) {
      console.log('Exemple:');
      console.log(JSON.stringify(users[0], null, 2));
    } else {
      console.log('⚠️  AUCUN utilisateur trouvé!');
      console.log('   Cela indique un problème de lecture Prisma');
    }
    console.log('');

    console.log('[3/6] Test lecture produits...');
    const products = await prisma.produit.findMany({
      take: 5,
      select: {
        id: true,
        reference: true,
        nom: true,
        prixUnitaire: true,
        estActif: true,
      },
    });
    console.log(`✅ ${products.length} produits trouvés`);
    if (products.length > 0) {
      console.log('Exemple:');
      console.log(JSON.stringify(products[0], null, 2));
    } else {
      console.log('⚠️  AUCUN produit trouvé!');
    }
    console.log('');

    console.log('[4/6] Test lecture ventes...');
    const sales = await prisma.vente.findMany({
      take: 5,
      select: {
        id: true,
        numeroVente: true,
        dateVente: true,
        montantTotal: true,
        statut: true,
      },
    });
    console.log(`✅ ${sales.length} ventes trouvées`);
    if (sales.length > 0) {
      console.log('Exemple:');
      console.log(JSON.stringify(sales[0], null, 2));
    } else {
      console.log('⚠️  AUCUNE vente trouvée!');
    }
    console.log('');

    console.log('[5/6] Comptage total...');
    const counts = await Promise.all([
      prisma.utilisateur.count(),
      prisma.produit.count(),
      prisma.vente.count(),
      prisma.client.count(),
      prisma.fournisseur.count(),
    ]);

    console.log('Résultats:');
    console.log(`- Utilisateurs: ${counts[0]}`);
    console.log(`- Produits: ${counts[1]}`);
    console.log(`- Ventes: ${counts[2]}`);
    console.log(`- Clients: ${counts[3]}`);
    console.log(`- Fournisseurs: ${counts[4]}`);
    console.log('');

    console.log('[6/6] Test requête brute SQL...');
    const rawUsers = await prisma.$queryRaw`SELECT COUNT(*) as count FROM utilisateurs`;
    console.log(`✅ Requête SQL brute: ${rawUsers[0].count} utilisateurs`);
    console.log('');

    // Comparaison
    if (counts[0] === 0 && rawUsers[0].count > 0) {
      console.log('❌ PROBLÈME IDENTIFIÉ:');
      console.log('   - SQL brut trouve des données');
      console.log('   - Prisma ne trouve rien');
      console.log('   → Problème de mapping/schéma Prisma');
      console.log('');
      console.log('SOLUTION:');
      console.log('   1. Exécuter: npx prisma db pull');
      console.log('   2. Exécuter: npx prisma generate');
      console.log('   3. Relancer ce test');
    } else if (counts[0] > 0) {
      console.log('✅ PRISMA FONCTIONNE CORRECTEMENT!');
      console.log('   Les données sont accessibles via Prisma');
    } else {
      console.log('⚠️  AUCUNE DONNÉE TROUVÉE');
      console.log('   La base de données semble vide');
    }

  } catch (error) {
    console.error('❌ ERREUR:', error.message);
    console.error('');
    console.error('Détails:', error);
    console.error('');
    console.error('CAUSES POSSIBLES:');
    console.error('1. Base de données corrompue');
    console.error('2. Schéma Prisma incompatible');
    console.error('3. Chemin de base incorrect');
    console.error('4. Permissions fichier');
    console.error('');
    console.error('SOLUTIONS:');
    console.error('1. Vérifier que la base existe: backend/database/logesco.db');
    console.error('2. Exécuter: npx prisma generate');
    console.error('3. Exécuter: npx prisma db push');
  } finally {
    await prisma.$disconnect();
    console.log('');
    console.log('========================================');
    console.log('  FIN DU TEST');
    console.log('========================================');
  }
}

// Exécuter le test
testConnection()
  .catch((error) => {
    console.error('Erreur fatale:', error);
    process.exit(1);
  });
