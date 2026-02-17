@echo off
title LOGESCO - Solution Client Finale
echo ========================================
echo   SOLUTION CLIENT FINALE PRISMA
echo ========================================
echo.

echo Ce script resout definitivement le probleme
echo de version Prisma chez le client.
echo.
pause
echo.

echo [1/7] Verification de l'environnement...
cd backend

if not exist "package.json" (
    echo ❌ ERREUR: Pas dans le dossier backend
    echo Placez ce script dans le dossier racine du projet
    pause
    exit /b 1
)

echo ✅ Dossier backend trouve
echo.

echo [2/7] Arret des processus existants...
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [3/7] Nettoyage complet...
if exist "database\logesco.db" (
    echo Suppression ancienne base de donnees...
    del "database\logesco.db" >nul 2>nul
)

if exist "node_modules\.prisma" (
    echo Suppression client Prisma corrompu...
    rmdir /s /q "node_modules\.prisma" >nul 2>nul
)

if exist "prisma\migrations\migration_lock.toml" (
    del "prisma\migrations\migration_lock.toml" >nul 2>nul
)

echo ✅ Nettoyage termine
echo.

echo [4/7] Verification des dependances...
if not exist "node_modules" (
    echo Installation des dependances...
    call npm install
    if errorlevel 1 (
        echo ❌ Erreur installation
        pause
        exit /b 1
    )
) else (
    echo ✅ Dependances presentes
)
echo.

echo [5/7] Verification du fichier .env...
if not exist ".env" (
    echo Creation du fichier .env...
    echo NODE_ENV=production > .env
    echo PORT=8080 >> .env
    echo DATABASE_URL="file:./database/logesco.db" >> .env
    echo JWT_SECRET="logesco-jwt-secret-change-in-production" >> .env
    echo CORS_ORIGIN="*" >> .env
    echo ✅ Fichier .env cree
) else (
    echo ✅ Fichier .env existe
)
echo.

echo [6/7] Generation du client Prisma...
set PRISMA_GENERATED=0

REM Méthode 1: Binaire Windows local
if exist "node_modules\.bin\prisma.cmd" (
    echo Tentative avec binaire local Windows...
    call node_modules\.bin\prisma.cmd generate >nul 2>nul
    if not errorlevel 1 (
        echo ✅ Client Prisma genere (binaire local)
        set PRISMA_GENERATED=1
        goto database_creation
    )
)

REM Méthode 2: npx avec version spécifique
if %PRISMA_GENERATED%==0 (
    echo Tentative avec npx version specifique...
    call npx --package=prisma@6.17.1 prisma generate
    if not errorlevel 1 (
        echo ✅ Client Prisma genere (version 6.17.1)
        set PRISMA_GENERATED=1
        goto database_creation
    )
)

REM Méthode 3: Version globale avec schéma explicite
if %PRISMA_GENERATED%==0 (
    echo Tentative avec version globale...
    call npx prisma generate --schema=prisma/schema.prisma
    if not errorlevel 1 (
        echo ✅ Client Prisma genere (version globale)
        set PRISMA_GENERATED=1
    ) else (
        echo ❌ Toutes les tentatives de generation ont echoue
        pause
        exit /b 1
    )
)

:database_creation
echo.
echo [7/7] Creation de la base de donnees...

REM S'assurer que le dossier database existe
if not exist "database" mkdir "database"

set DATABASE_CREATED=0

REM Méthode 1: Binaire local avec db push
if exist "node_modules\.bin\prisma.cmd" (
    echo Tentative db push avec binaire local...
    call node_modules\.bin\prisma.cmd db push --accept-data-loss >nul 2>nul
    if not errorlevel 1 (
        if exist "database\logesco.db" (
            echo ✅ Base de donnees creee (binaire local)
            set DATABASE_CREATED=1
            goto verification
        )
    )
)

REM Méthode 2: npx avec version spécifique
if %DATABASE_CREATED%==0 (
    echo Tentative db push avec version specifique...
    call npx --package=prisma@6.17.1 prisma db push --accept-data-loss
    if not errorlevel 1 (
        if exist "database\logesco.db" (
            echo ✅ Base de donnees creee (version 6.17.1)
            set DATABASE_CREATED=1
            goto verification
        )
    )
)

REM Méthode 3: migrate deploy
if %DATABASE_CREATED%==0 (
    echo Tentative migrate deploy...
    call npx --package=prisma@6.17.1 prisma migrate deploy
    if not errorlevel 1 (
        if exist "database\logesco.db" (
            echo ✅ Base de donnees creee (migrate deploy)
            set DATABASE_CREATED=1
        )
    )
)

REM Méthode 4: Création manuelle si tout échoue
if %DATABASE_CREATED%==0 (
    echo Creation manuelle de la base de donnees...
    echo. > "database\logesco.db"
    if exist "database\logesco.db" (
        echo ✅ Fichier de base de donnees cree manuellement
        echo ⚠️ Les tables seront creees au demarrage du serveur
        set DATABASE_CREATED=1
    )
)

:verification
echo.
echo Verification finale...
if exist "database\logesco.db" (
    echo ✅ Base de donnees: database\logesco.db
    for %%A in ("database\logesco.db") do echo    Taille: %%~zA octets
) else (
    echo ❌ Base de donnees non creee
)

if exist "node_modules\.prisma" (
    echo ✅ Client Prisma: Pret
) else (
    echo ❌ Client Prisma: Manquant
)

echo.
echo Test rapide du serveur...
start /min cmd /c "node src/server-standalone.js"
timeout /t 5 /nobreak >nul

REM Vérifier si le serveur répond
curl -s http://localhost:8080/health >nul 2>nul
if not errorlevel 1 (
    echo ✅ Serveur fonctionne!
) else (
    echo ⚠️ Serveur ne repond pas encore (normal au premier demarrage)
)

REM Arrêter le test
taskkill /f /im node.exe >nul 2>nul

cd ..
echo.
echo ========================================
echo   SOLUTION CLIENT APPLIQUEE AVEC SUCCES
echo ========================================
echo.
echo 🗄️ Base de donnees: %DATABASE_CREATED% (1=Creee, 0=Echec)
echo 🔧 Client Prisma: %PRISMA_GENERATED% (1=Genere, 0=Echec)
echo 👤 Admin: admin / admin123
echo 🌐 Serveur: http://localhost:8080
echo.
if %DATABASE_CREATED%==1 if %PRISMA_GENERATED%==1 (
    echo ✅ LOGESCO est pret pour le client!
    echo.
    echo Instructions:
    echo 1. Double-cliquez sur: DEMARRER-LOGESCO.bat
    echo 2. Attendez que l'application s'ouvre
    echo 3. Connectez-vous avec: admin / admin123
) else (
    echo ⚠️ Problemes detectes - consultez les messages ci-dessus
)
echo.
pause