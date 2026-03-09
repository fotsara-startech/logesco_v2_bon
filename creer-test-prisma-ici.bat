@echo off
title Creation test-prisma-connection.js
echo ========================================
echo   CREATION FICHIER TEST PRISMA
echo ========================================
echo.

echo Ce script cree le fichier test-prisma-connection.js
echo dans le dossier backend actuel.
echo.

if not exist "backend" (
    echo ❌ Dossier backend non trouve!
    echo    Vous devez executer ce script depuis le dossier d'installation LOGESCO.
    pause
    exit /b 1
)

echo Creation du fichier...
echo.

(
echo /**
echo  * Script de test de connexion Prisma
echo  * Teste si Prisma peut lire les donnees de la base
echo  */
echo.
echo const { PrismaClient } = require^('@prisma/client'^);
echo const path = require^('path'^);
echo.
echo // Configuration
echo const dbPath = path.join^(__dirname, 'database', 'logesco.db'^);
echo process.env.DATABASE_URL = `file:${dbPath}`;
echo.
echo console.log^('========================================'^);
echo console.log^('  TEST CONNEXION PRISMA'^);
echo console.log^('========================================\n'^);
echo.
echo console.log^(`Base de donnees: ${dbPath}\n`^);
echo.
echo const prisma = new PrismaClient^({
echo   log: ['query', 'info', 'warn', 'error'],
echo }^);
echo.
echo async function testConnection^(^) {
echo   try {
echo     console.log^('[1/6] Test de connexion...'^);
echo     await prisma.$connect^(^);
echo     console.log^('✅ Connexion Prisma etablie\n'^);
echo.
echo     console.log^('[2/6] Test lecture utilisateurs...'^);
echo     const users = await prisma.utilisateur.findMany^({
echo       take: 5,
echo       select: {
echo         id: true,
echo         nomUtilisateur: true,
echo         email: true,
echo         isActive: true,
echo       },
echo     }^);
echo     console.log^(`✅ ${users.length} utilisateurs trouves`^);
echo     if ^(users.length ^> 0^) {
echo       console.log^('Exemple:'^);
echo       console.log^(JSON.stringify^(users[0], null, 2^)^);
echo     } else {
echo       console.log^('⚠️  AUCUN utilisateur trouve!'^);
echo       console.log^('   Cela indique un probleme de lecture Prisma'^);
echo     }
echo     console.log^(''^);
echo.
echo     console.log^('[3/6] Test lecture produits...'^);
echo     const products = await prisma.produit.findMany^({
echo       take: 5,
echo       select: {
echo         id: true,
echo         reference: true,
echo         nom: true,
echo         prixUnitaire: true,
echo         estActif: true,
echo       },
echo     }^);
echo     console.log^(`✅ ${products.length} produits trouves`^);
echo     if ^(products.length ^> 0^) {
echo       console.log^('Exemple:'^);
echo       console.log^(JSON.stringify^(products[0], null, 2^)^);
echo     } else {
echo       console.log^('⚠️  AUCUN produit trouve!'^);
echo     }
echo     console.log^(''^);
echo.
echo     console.log^('[4/6] Test lecture ventes...'^);
echo     const sales = await prisma.vente.findMany^({
echo       take: 5,
echo       select: {
echo         id: true,
echo         numeroVente: true,
echo         dateVente: true,
echo         montantTotal: true,
echo         statut: true,
echo       },
echo     }^);
echo     console.log^(`✅ ${sales.length} ventes trouvees`^);
echo     if ^(sales.length ^> 0^) {
echo       console.log^('Exemple:'^);
echo       console.log^(JSON.stringify^(sales[0], null, 2^)^);
echo     } else {
echo       console.log^('⚠️  AUCUNE vente trouvee!'^);
echo     }
echo     console.log^(''^);
echo.
echo     console.log^('[5/6] Comptage total...'^);
echo     const counts = await Promise.all^([
echo       prisma.utilisateur.count^(^),
echo       prisma.produit.count^(^),
echo       prisma.vente.count^(^),
echo       prisma.client.count^(^),
echo       prisma.fournisseur.count^(^),
echo     ]^);
echo.
echo     console.log^('Resultats:'^);
echo     console.log^(`- Utilisateurs: ${counts[0]}`^);
echo     console.log^(`- Produits: ${counts[1]}`^);
echo     console.log^(`- Ventes: ${counts[2]}`^);
echo     console.log^(`- Clients: ${counts[3]}`^);
echo     console.log^(`- Fournisseurs: ${counts[4]}`^);
echo     console.log^(''^);
echo.
echo     console.log^('[6/6] Test requete brute SQL...'^);
echo     const rawUsers = await prisma.$queryRaw`SELECT COUNT^(^*^) as count FROM utilisateurs`;
echo     console.log^(`✅ Requete SQL brute: ${rawUsers[0].count} utilisateurs`^);
echo     console.log^(''^);
echo.
echo     // Comparaison
echo     if ^(counts[0] === 0 ^&^& rawUsers[0].count ^> 0^) {
echo       console.log^('❌ PROBLEME IDENTIFIE:'^);
echo       console.log^('   - SQL brut trouve des donnees'^);
echo       console.log^('   - Prisma ne trouve rien'^);
echo       console.log^('   → Probleme de mapping/schema Prisma'^);
echo       console.log^(''^);
echo       console.log^('SOLUTION:'^);
echo       console.log^('   1. Executer: npx prisma db pull'^);
echo       console.log^('   2. Executer: npx prisma generate'^);
echo       console.log^('   3. Relancer ce test'^);
echo     } else if ^(counts[0] ^> 0^) {
echo       console.log^('✅ PRISMA FONCTIONNE CORRECTEMENT!'^);
echo       console.log^('   Les donnees sont accessibles via Prisma'^);
echo     } else {
echo       console.log^('⚠️  AUCUNE DONNEE TROUVEE'^);
echo       console.log^('   La base de donnees semble vide'^);
echo     }
echo.
echo   } catch ^(error^) {
echo     console.error^('❌ ERREUR:', error.message^);
echo     console.error^(''^);
echo     console.error^('Details:', error^);
echo     console.error^(''^);
echo     console.error^('CAUSES POSSIBLES:'^);
echo     console.error^('1. Base de donnees corrompue'^);
echo     console.error^('2. Schema Prisma incompatible'^);
echo     console.error^('3. Chemin de base incorrect'^);
echo     console.error^('4. Permissions fichier'^);
echo     console.error^(''^);
echo     console.error^('SOLUTIONS:'^);
echo     console.error^('1. Verifier que la base existe: backend/database/logesco.db'^);
echo     console.error^('2. Executer: npx prisma generate'^);
echo     console.error^('3. Executer: npx prisma db push'^);
echo   } finally {
echo     await prisma.$disconnect^(^);
echo     console.log^(''^);
echo     console.log^('========================================'^);
echo     console.log^('  FIN DU TEST'^);
echo     console.log^('========================================'^);
echo   }
echo }
echo.
echo // Executer le test
echo testConnection^(^)
echo   .catch^(^(error^) =^> {
echo     console.error^('Erreur fatale:', error^);
echo     process.exit^(1^);
echo   }^);
) > backend\test-prisma-connection.js

echo ✅ Fichier cree: backend\test-prisma-connection.js
echo.

echo ========================================
echo   CREATION TERMINEE
echo ========================================
echo.

echo 🚀 PROCHAINES ETAPES:
echo.
echo 1. Tester la lecture Prisma:
echo    tester-lecture-prisma.bat
echo.
echo 2. Si probleme, forcer la synchronisation:
echo    forcer-synchronisation-prisma.bat
echo.
pause
