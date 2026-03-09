@echo off
title LOGESCO - Reinitialisation Base de Donnees
color 0C
echo ========================================
echo   LOGESCO - REINITIALISATION BASE
echo ========================================
echo.
echo ⚠️  ATTENTION: Cette operation va:
echo    - SUPPRIMER toutes les donnees actuelles
echo    - REINITIALISER la base de donnees
echo    - CREER une base VIERGE avec uniquement:
echo      * 1 utilisateur admin
echo      * 1 caisse principale
echo      * Parametres entreprise par defaut
echo.
echo ❌ TOUTES VOS DONNEES SERONT PERDUES:
echo    - Produits
echo    - Ventes
echo    - Clients
echo    - Fournisseurs
echo    - Transactions
echo    - Mouvements de stock
echo    - Utilisateurs personnalises
echo.
echo ========================================
echo.

REM Demander confirmation
set /p confirm="Tapez OUI (en majuscules) pour confirmer: "
if not "%confirm%"=="OUI" (
    echo.
    echo ❌ Operation annulee
    echo    Aucune modification effectuee
    pause
    exit /b 0
)

echo.
echo ========================================
echo   Reinitialisation en cours...
echo ========================================
echo.

REM Vérifier si Node.js est installé
echo [1/6] Verification prerequis...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js n'est pas installe!
    echo    Installez Node.js depuis: https://nodejs.org/
    pause
    exit /b 1
)
echo ✅ Node.js detecte
echo.

REM Arrêter le backend s'il tourne
echo [2/6] Arret du backend...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Backend arrete
echo.

REM Sauvegarder l'ancienne base (au cas où)
echo [3/6] Sauvegarde ancienne base...
if exist "backend\database\logesco.db" (
    if not exist "backend\database\backups" mkdir "backend\database\backups"
    set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set timestamp=%timestamp: =0%
    copy "backend\database\logesco.db" "backend\database\backups\logesco_backup_%timestamp%.db" >nul 2>nul
    echo ✅ Sauvegarde creee: backups\logesco_backup_%timestamp%.db
) else (
    echo ⚠️  Aucune base existante a sauvegarder
)
echo.

REM Supprimer l'ancienne base
echo [4/6] Suppression ancienne base...
if exist "backend\database\logesco.db" (
    del /f /q "backend\database\logesco.db" 2>nul
    echo ✅ Ancienne base supprimee
) else (
    echo ⚠️  Aucune base a supprimer
)

REM Supprimer aussi les fichiers temporaires SQLite
if exist "backend\database\logesco.db-journal" (
    del /f /q "backend\database\logesco.db-journal" 2>nul
)
if exist "backend\database\logesco.db-shm" (
    del /f /q "backend\database\logesco.db-shm" 2>nul
)
if exist "backend\database\logesco.db-wal" (
    del /f /q "backend\database\logesco.db-wal" 2>nul
)
echo.

REM Créer la nouvelle base vierge
echo [5/6] Creation nouvelle base VIERGE...
cd backend

REM Vérifier que Prisma est disponible
if not exist "node_modules\.prisma\client" (
    echo ⚠️  Prisma Client non trouve, generation...
    call npx prisma generate >nul 2>nul
)

REM Créer la structure de la base
echo    Creation structure...
call npx prisma db push --accept-data-loss --skip-generate >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Impossible de creer la structure
    cd ..
    pause
    exit /b 1
)
echo    ✅ Structure creee

REM Initialiser avec les données essentielles
echo    Initialisation donnees essentielles...
node prisma\seed.js
if errorlevel 1 (
    echo ❌ ERREUR: Impossible d'initialiser les donnees
    cd ..
    pause
    exit /b 1
)

cd ..
echo ✅ Nouvelle base VIERGE creee
echo.

REM Vérifier la nouvelle base
echo [6/6] Verification nouvelle base...

REM Créer un script de vérification temporaire dans le dossier backend
echo const { PrismaClient } = require('@prisma/client'); > backend\temp_verify.js
echo const prisma = new PrismaClient(); >> backend\temp_verify.js
echo. >> backend\temp_verify.js
echo async function verify() { >> backend\temp_verify.js
echo   try { >> backend\temp_verify.js
echo     const users = await prisma.utilisateur.count(); >> backend\temp_verify.js
echo     const products = await prisma.produit.count(); >> backend\temp_verify.js
echo     const sales = await prisma.vente.count(); >> backend\temp_verify.js
echo     const customers = await prisma.client.count(); >> backend\temp_verify.js
echo     const suppliers = await prisma.fournisseur.count(); >> backend\temp_verify.js
echo     const cashRegisters = await prisma.cashRegister.count(); >> backend\temp_verify.js
echo. >> backend\temp_verify.js
echo     console.log('   Utilisateurs:', users); >> backend\temp_verify.js
echo     console.log('   Produits:', products); >> backend\temp_verify.js
echo     console.log('   Ventes:', sales); >> backend\temp_verify.js
echo     console.log('   Clients:', customers); >> backend\temp_verify.js
echo     console.log('   Fournisseurs:', suppliers); >> backend\temp_verify.js
echo     console.log('   Caisses:', cashRegisters); >> backend\temp_verify.js
echo. >> backend\temp_verify.js
echo     if (users === 1 ^&^& products === 0 ^&^& sales === 0 ^&^& customers === 0 ^&^& suppliers === 0 ^&^& cashRegisters === 1) { >> backend\temp_verify.js
echo       console.log('\n   ✅ BASE VIERGE CONFIRMEE'); >> backend\temp_verify.js
echo       process.exit(0); >> backend\temp_verify.js
echo     } else { >> backend\temp_verify.js
echo       console.log('\n   ⚠️  ATTENTION: Donnees inattendues'); >> backend\temp_verify.js
echo       process.exit(1); >> backend\temp_verify.js
echo     } >> backend\temp_verify.js
echo   } catch (error) { >> backend\temp_verify.js
echo     console.error('   ❌ Erreur:', error.message); >> backend\temp_verify.js
echo     process.exit(1); >> backend\temp_verify.js
echo   } finally { >> backend\temp_verify.js
echo     await prisma.$disconnect(); >> backend\temp_verify.js
echo   } >> backend\temp_verify.js
echo } >> backend\temp_verify.js
echo. >> backend\temp_verify.js
echo verify(); >> backend\temp_verify.js

cd backend
node temp_verify.js
set verify_result=%errorlevel%
cd ..

REM Nettoyer le fichier temporaire
del backend\temp_verify.js 2>nul

if %verify_result% neq 0 (
    echo.
    echo ⚠️  La verification a detecte un probleme
    echo    Verifiez manuellement la base de donnees
    pause
    exit /b 1
)

echo.
echo ========================================
echo   ✅ REINITIALISATION REUSSIE!
echo ========================================
echo.
echo 🎯 Base de donnees VIERGE creee avec:
echo    - 1 utilisateur admin
echo    - 1 caisse principale
echo    - Parametres entreprise par defaut
echo.
echo 🔑 Identifiants de connexion:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo 💾 Sauvegarde ancienne base:
echo    backend\database\backups\
echo.
echo 🚀 Prochaines etapes:
echo    1. Demarrez LOGESCO
echo    2. Connectez-vous avec admin/admin123
echo    3. Personnalisez les parametres entreprise
echo    4. Changez le mot de passe admin
echo    5. Creez vos utilisateurs, produits, etc.
echo.
echo ⚠️  IMPORTANT:
echo    - Changez le mot de passe admin
echo    - Personnalisez les informations entreprise
echo    - L'ancienne base est sauvegardee dans backups\
echo.
echo ========================================
pause
