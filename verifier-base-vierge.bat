@echo off
echo ========================================
echo   Verification Base de Donnees VIERGE
echo ========================================
echo.

REM Vérifier si Node.js est installé
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js n'est pas installe!
    pause
    exit /b 1
)

REM Créer un script de vérification temporaire dans le dossier backend
echo const { PrismaClient } = require('@prisma/client'); > backend\temp_check.js
echo const prisma = new PrismaClient(); >> backend\temp_check.js
echo. >> backend\temp_check.js
echo async function checkDatabase() { >> backend\temp_check.js
echo   try { >> backend\temp_check.js
echo     console.log('Verification de la base de donnees...\n'); >> backend\temp_check.js
echo. >> backend\temp_check.js
echo     const users = await prisma.utilisateur.count(); >> backend\temp_check.js
echo     const products = await prisma.produit.count(); >> backend\temp_check.js
echo     const sales = await prisma.vente.count(); >> backend\temp_check.js
echo     const customers = await prisma.client.count(); >> backend\temp_check.js
echo     const suppliers = await prisma.fournisseur.count(); >> backend\temp_check.js
echo     const cashRegisters = await prisma.cashRegister.count(); >> backend\temp_check.js
echo. >> backend\temp_check.js
echo     console.log('Resultats:'); >> backend\temp_check.js
echo     console.log('----------'); >> backend\temp_check.js
echo     console.log(`Utilisateurs: ${users}`); >> backend\temp_check.js
echo     console.log(`Produits: ${products}`); >> backend\temp_check.js
echo     console.log(`Ventes: ${sales}`); >> backend\temp_check.js
echo     console.log(`Clients: ${customers}`); >> backend\temp_check.js
echo     console.log(`Fournisseurs: ${suppliers}`); >> backend\temp_check.js
echo     console.log(`Caisses: ${cashRegisters}\n`); >> backend\temp_check.js
echo. >> backend\temp_check.js
echo     if (users === 1 ^&^& products === 0 ^&^& sales === 0 ^&^& customers === 0 ^&^& suppliers === 0 ^&^& cashRegisters === 1) { >> backend\temp_check.js
echo       console.log('✅ BASE DE DONNEES VIERGE'); >> backend\temp_check.js
echo       console.log('   Contient uniquement:'); >> backend\temp_check.js
echo       console.log('   - 1 utilisateur admin'); >> backend\temp_check.js
echo       console.log('   - 1 caisse principale'); >> backend\temp_check.js
echo       console.log('   - Parametres entreprise\n'); >> backend\temp_check.js
echo       console.log('🎯 Prete pour production!'); >> backend\temp_check.js
echo     } else { >> backend\temp_check.js
echo       console.log('⚠️  BASE DE DONNEES CONTIENT DES DONNEES'); >> backend\temp_check.js
echo       console.log('   Cette base contient des donnees de test/developpement'); >> backend\temp_check.js
echo     } >> backend\temp_check.js
echo   } catch (error) { >> backend\temp_check.js
echo     console.error('❌ Erreur:', error.message); >> backend\temp_check.js
echo   } finally { >> backend\temp_check.js
echo     await prisma.$disconnect(); >> backend\temp_check.js
echo   } >> backend\temp_check.js
echo } >> backend\temp_check.js
echo. >> backend\temp_check.js
echo checkDatabase(); >> backend\temp_check.js

cd backend
node temp_check.js
cd ..

REM Nettoyer le fichier temporaire
del backend\temp_check.js 2>nul

echo.
echo ========================================
pause
