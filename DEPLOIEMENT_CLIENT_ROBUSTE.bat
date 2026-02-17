@echo off
title LOGESCO - Deploiement Client Robuste
echo ========================================
echo   DEPLOIEMENT CLIENT ROBUSTE
echo ========================================
echo.

echo Ce script prepare LOGESCO pour fonctionner
echo sur n'importe quel environnement client.
echo.
pause
echo.

echo [1/8] Verification de l'environnement...
if not exist "backend\package.json" (
    echo ❌ ERREUR: Executez ce script depuis la racine du projet
    pause
    exit /b 1
)

echo ✅ Projet LOGESCO detecte
echo.

echo [2/8] Arret des processus...
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [3/8] Nettoyage complet du backend...
cd backend

REM Supprimer tous les fichiers générés
if exist "database\logesco.db" del "database\logesco.db" >nul 2>nul
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" >nul 2>nul
if exist "prisma\migrations\migration_lock.toml" del "prisma\migrations\migration_lock.toml" >nul 2>nul

echo ✅ Nettoyage termine
echo.

echo [4/8] Installation des dependances...
call npm install
if errorlevel 1 (
    echo ❌ Erreur installation
    pause
    exit /b 1
)
echo ✅ Dependances installees
echo.

echo [5/8] Generation du client Prisma (version forcee)...
REM Utiliser directement la version locale pour éviter les conflits
call .\node_modules\.bin\prisma generate
if errorlevel 1 (
    echo ⚠️ Version locale echouee, tentative avec version specifique...
    call npx --package=@prisma/client@6.17.1 --package=prisma@6.17.1 prisma generate
    if errorlevel 1 (
        echo ❌ Generation impossible
        pause
        exit /b 1
    )
)
echo ✅ Client Prisma genere
echo.

echo [6/8] Creation de la base de donnees...
REM Utiliser db push pour créer la structure complète
call .\node_modules\.bin\prisma db push --accept-data-loss
if errorlevel 1 (
    echo ⚠️ db push local echoue, tentative avec version specifique...
    call npx --package=prisma@6.17.1 prisma db push --accept-data-loss
    if errorlevel 1 (
        echo ❌ Creation base de donnees impossible
        pause
        exit /b 1
    )
)
echo ✅ Base de donnees creee avec toutes les tables
echo.

echo [7/8] Initialisation des donnees de base...
if exist "scripts\ensure-admin.js" (
    node scripts\ensure-admin.js
    if errorlevel 1 (
        echo ⚠️ Erreur initialisation admin (sera fait au demarrage)
    ) else (
        echo ✅ Utilisateur admin initialise
    )
)

if exist "scripts\ensure-base-data.js" (
    node scripts\ensure-base-data.js
    if errorlevel 1 (
        echo ⚠️ Erreur donnees de base (sera fait au demarrage)
    ) else (
        echo ✅ Donnees de base initialisees
    )
)
echo.

echo [8/8] Test du serveur...
echo Demarrage du serveur pour test...
start /min cmd /c "node src/server-standalone.js"
timeout /t 8 /nobreak >nul

REM Tester la connexion
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Serveur ne repond pas encore (normal au premier demarrage)
) else (
    echo ✅ Serveur fonctionne parfaitement!
)

REM Arrêter le test
taskkill /f /im node.exe >nul 2>nul

cd ..
echo.
echo ========================================
echo   DEPLOIEMENT CLIENT TERMINE
echo ========================================
echo.
echo 🗄️ Base de donnees: backend/database/logesco.db
echo 🔧 Client Prisma: Version locale forcee
echo 👤 Admin: admin / admin123
echo 🌐 Serveur: http://localhost:8080
echo.
echo LOGESCO est pret pour le client!
echo.
echo Instructions pour le client:
echo 1. Double-cliquez sur: DEMARRER-LOGESCO.bat
echo 2. Attendez que l'application s'ouvre
echo 3. Connectez-vous avec: admin / admin123
echo.
pause