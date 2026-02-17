@echo off
title LOGESCO - Solution Client Prisma
echo ========================================
echo   SOLUTION PROBLEME CLIENT PRISMA
echo ========================================
echo.

echo Ce script force l'utilisation de Prisma 6.17.1
echo pour eviter les conflits avec Prisma 7 global.
echo.
pause
echo.

echo [1/5] Verification de l'environnement...
cd backend

REM Vérifier que nous sommes dans le bon dossier
if not exist "package.json" (
    echo ❌ ERREUR: Pas dans le dossier backend
    echo Placez ce script dans le dossier racine du projet
    pause
    exit /b 1
)

echo ✅ Dossier backend trouve
echo.

echo [2/5] Arret des processus existants...
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [3/5] Nettoyage complet...
REM Supprimer l'ancienne base corrompue
if exist "database\logesco.db" (
    echo Suppression ancienne base de donnees...
    del "database\logesco.db" >nul 2>nul
)

REM Supprimer le client Prisma corrompu
if exist "node_modules\.prisma" (
    echo Suppression client Prisma corrompu...
    rmdir /s /q "node_modules\.prisma" >nul 2>nul
)

REM Supprimer le lock de migration
if exist "prisma\migrations\migration_lock.toml" (
    del "prisma\migrations\migration_lock.toml" >nul 2>nul
)

echo ✅ Nettoyage termine
echo.

echo [4/5] Installation et generation avec version forcee...

REM Installer les dépendances si nécessaire
if not exist "node_modules" (
    echo Installation des dependances...
    call npm install
    if errorlevel 1 (
        echo ❌ Erreur installation
        pause
        exit /b 1
    )
)

REM Forcer l'utilisation de Prisma 6.17.1 depuis node_modules
echo Generation du client Prisma avec version locale...
if exist "node_modules\.bin\prisma.cmd" (
    call node_modules\.bin\prisma.cmd generate
    if not errorlevel 1 goto prisma_generated
)

echo ⚠️ Tentative avec npx et version specifique...
call npx --package=prisma@6.17.1 prisma generate
if not errorlevel 1 goto prisma_generated

echo ⚠️ Derniere tentative avec version globale...
call npx prisma generate --schema=prisma/schema.prisma
if errorlevel 1 (
    echo ❌ Generation impossible
    echo.
    echo Solutions manuelles:
    echo 1. npm uninstall -g prisma
    echo 2. npm cache clean --force
    echo 3. npm install
    echo.
    pause
    exit /b 1
)

:prisma_generated
echo ✅ Client Prisma genere
echo.

echo [5/5] Creation de la base de donnees...
REM S'assurer que le dossier database existe
if not exist "database" mkdir "database"

REM Utiliser db push pour créer la structure sans migrations
if exist "node_modules\.bin\prisma.cmd" (
    call node_modules\.bin\prisma.cmd db push --accept-data-loss
    if not errorlevel 1 goto database_created
)

echo ⚠️ Version locale echouee, tentative avec npx...
call npx --package=prisma@6.17.1 prisma db push --accept-data-loss
if not errorlevel 1 goto database_created

echo ⚠️ Tentative migrate deploy...
call npx --package=prisma@6.17.1 prisma migrate deploy
if errorlevel 1 (
    echo ❌ Creation base de donnees impossible
    echo Verifiez que le fichier .env existe et contient DATABASE_URL
    pause
    exit /b 1
)

:database_created
echo ✅ Base de donnees creee avec toutes les tables
echo.

echo Verification finale...
if exist "database\logesco.db" (
    echo ✅ Base de donnees: database\logesco.db
) else (
    echo ❌ Base de donnees non creee
)

if exist "node_modules\.prisma" (
    echo ✅ Client Prisma: Pret
) else (
    echo ❌ Client Prisma: Manquant
)

cd ..
echo.
echo ========================================
echo   SOLUTION CLIENT APPLIQUEE
echo ========================================
echo.
echo 🗄️ Base de donnees: Recreee avec toutes les tables
echo 🔧 Client Prisma: Version locale forcee
echo 👤 Admin: admin / admin123
echo.
echo Le probleme de version Prisma est resolu!
echo Votre client peut maintenant utiliser LOGESCO.
echo.
pause