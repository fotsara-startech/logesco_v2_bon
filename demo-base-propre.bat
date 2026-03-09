@echo off
title LOGESCO - Demo Base Propre
color 0A
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║     LOGESCO v2 - Demonstration Base de Donnees Propre     ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Ce script vous montre comment le nouveau systeme fonctionne:
echo.
echo 1. Creation d'une base de donnees propre
echo 2. Verification du contenu
echo 3. Comparaison avec votre base de developpement
echo.
pause
echo.

REM Étape 1: Compter les données dans la base de développement
echo ════════════════════════════════════════════════════════════
echo  ETAPE 1: Votre Base de Developpement
echo ════════════════════════════════════════════════════════════
echo.
echo Analyse de votre base de developpement actuelle...
echo.

cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient(); (async () => { try { const users = await prisma.utilisateur.count(); const produits = await prisma.produit.count(); const ventes = await prisma.vente.count(); const clients = await prisma.client.count(); const fournisseurs = await prisma.fournisseur.count(); console.log('📊 Votre base de developpement contient:'); console.log(''); console.log('   Utilisateurs: ' + users); console.log('   Produits: ' + produits); console.log('   Ventes: ' + ventes); console.log('   Clients: ' + clients); console.log('   Fournisseurs: ' + fournisseurs); console.log(''); console.log('⚠️  Avant: Toutes ces donnees etaient copiees chez le client!'); } catch(e) { console.log('⚠️  Base de developpement non accessible ou vide'); } await prisma.$disconnect(); })();"
cd ..

echo.
pause
echo.

REM Étape 2: Créer une base propre de test
echo ════════════════════════════════════════════════════════════
echo  ETAPE 2: Creation Base Propre (Test)
echo ════════════════════════════════════════════════════════════
echo.
echo Creation d'une base de donnees propre de test...
echo.

cd backend

REM Supprimer l'ancienne base de test
if exist "prisma\database\logesco-test.db" del /f "prisma\database\logesco-test.db" >nul 2>nul

REM Créer la structure
set DATABASE_URL=file:./prisma/database/logesco-test.db
echo [1/2] Creation structure...
npx prisma db push --accept-data-loss --skip-generate >nul 2>nul
if errorlevel 1 (
    echo ❌ Erreur creation structure
    cd ..
    pause
    exit /b 1
)
echo ✅ Structure creee

REM Initialiser avec le seed
echo [2/2] Initialisation donnees essentielles...
node prisma/seed.js
if errorlevel 1 (
    echo ❌ Erreur seed
    cd ..
    pause
    exit /b 1
)

cd ..
echo.
pause
echo.

REM Étape 3: Vérifier la base propre
echo ════════════════════════════════════════════════════════════
echo  ETAPE 3: Verification Base Propre
echo ════════════════════════════════════════════════════════════
echo.
echo Analyse de la base propre creee...
echo.

cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient({ datasources: { db: { url: 'file:./prisma/database/logesco-test.db' } } }); (async () => { const users = await prisma.utilisateur.count(); const roles = await prisma.userRole.count(); const caisses = await prisma.cashRegister.count(); const params = await prisma.parametresEntreprise.count(); const produits = await prisma.produit.count(); const ventes = await prisma.vente.count(); const clients = await prisma.client.count(); const fournisseurs = await prisma.fournisseur.count(); console.log('📊 La base propre contient:'); console.log(''); console.log('✅ Donnees essentielles:'); console.log('   Roles: ' + roles); console.log('   Utilisateurs: ' + users); console.log('   Caisses: ' + caisses); console.log('   Parametres: ' + params); console.log(''); console.log('📭 Donnees metier (vides):'); console.log('   Produits: ' + produits); console.log('   Ventes: ' + ventes); console.log('   Clients: ' + clients); console.log('   Fournisseurs: ' + fournisseurs); console.log(''); if (produits === 0 && ventes === 0 && clients === 0) { console.log('✅ BASE PROPRE - Prete pour le client!'); console.log('✅ Aucune donnee de test incluse!'); } await prisma.$disconnect(); })();"
cd ..

echo.
pause
echo.

REM Étape 4: Résumé
echo ════════════════════════════════════════════════════════════
echo  RESUME
echo ════════════════════════════════════════════════════════════
echo.
echo ✅ AVANT (Probleme):
echo    - Votre base de developpement etait copiee
echo    - Le client recevait toutes vos donnees de test
echo    - Risque de confidentialite
echo    - Base volumineuse
echo.
echo ✅ MAINTENANT (Solution):
echo    - Base propre creee a chaque build
echo    - Seulement les donnees essentielles
echo    - Pas de donnees de test
echo    - Base minimale et propre
echo.
echo 📦 Donnees incluses dans la base client:
echo    - 1 role administrateur
echo    - 1 utilisateur admin (admin/admin123)
echo    - 1 caisse principale
echo    - 1 configuration entreprise
echo.
echo 🔑 Identifiants par defaut:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo 📂 Base de test creee dans:
echo    backend\prisma\database\logesco-test.db
echo.
echo 🔍 Pour inspecter la base de test:
echo    cd backend
echo    npx prisma studio --schema prisma/schema.prisma
echo.
echo ════════════════════════════════════════════════════════════
echo.
echo Voulez-vous supprimer la base de test? (O/N)
set /p cleanup=
if /i "%cleanup%"=="O" (
    del /f "backend\prisma\database\logesco-test.db" >nul 2>nul
    echo ✅ Base de test supprimee
) else (
    echo ℹ️  Base de test conservee pour inspection
)
echo.
echo ════════════════════════════════════════════════════════════
echo  Demonstration terminee!
echo ════════════════════════════════════════════════════════════
echo.
echo Prochaines etapes:
echo.
echo 1. Creer le package client:
echo    preparer-pour-client-optimise.bat
echo.
echo 2. Verifier le package:
echo    cd release\LOGESCO-Client-Optimise\backend
echo    npx prisma studio
echo.
echo 3. Tester le demarrage:
echo    cd release\LOGESCO-Client-Optimise
echo    DEMARRER-LOGESCO.bat
echo.
pause
