@echo off
echo ========================================
echo   Verification Base de Donnees Propre
echo ========================================
echo.

cd backend

echo Verification du contenu de la base de donnees...
echo.

node -e "const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient({ datasources: { db: { url: 'file:./prisma/database/logesco-test.db' } } }); (async () => { const users = await prisma.utilisateur.count(); const roles = await prisma.userRole.count(); const caisses = await prisma.cashRegister.count(); const params = await prisma.parametresEntreprise.count(); const produits = await prisma.produit.count(); const ventes = await prisma.vente.count(); const clients = await prisma.client.count(); console.log('📊 Statistiques de la base de donnees:'); console.log(''); console.log('✅ Donnees essentielles:'); console.log('   - Roles:', roles); console.log('   - Utilisateurs:', users); console.log('   - Caisses:', caisses); console.log('   - Parametres entreprise:', params); console.log(''); console.log('📭 Donnees metier (doivent etre vides):'); console.log('   - Produits:', produits); console.log('   - Ventes:', ventes); console.log('   - Clients:', clients); console.log(''); if (produits === 0 && ventes === 0 && clients === 0) { console.log('✅ Base de donnees PROPRE - Prete pour le client!'); } else { console.log('⚠️  ATTENTION: La base contient des donnees de test!'); } await prisma.$disconnect(); })();"

echo.
echo ========================================
cd ..
pause
