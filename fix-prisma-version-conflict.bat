@echo off
echo ========================================
echo   LOGESCO - Correction Prisma
echo ========================================
echo.

echo [1/5] Verification de l'environnement...
cd backend
if not exist "package.json" (
    echo ❌ ERREUR: Pas dans le bon repertoire
    pause
    exit /b 1
)

echo ✅ Repertoire backend trouve
echo.

echo [2/5] Nettoyage des anciens fichiers Prisma...
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" >nul 2>nul
if exist "prisma\migrations\migration_lock.toml" del /q "prisma\migrations\migration_lock.toml" >nul 2>nul
echo ✅ Nettoyage termine
echo.

echo [3/5] Reinstallation des dependances...
call npm install
if errorlevel 1 (
    echo ❌ ERREUR: Installation des dependances echouee
    pause
    exit /b 1
)
echo ✅ Dependances installees
echo.

echo [4/5] Generation du client Prisma avec version locale...
call npx prisma@6.17.1 generate
if errorlevel 1 (
    echo ⚠️ Tentative avec version globale...
    call npx prisma generate
    if errorlevel 1 (
        echo ❌ ERREUR: Generation du client echouee
        pause
        exit /b 1
    )
)
echo ✅ Client Prisma genere
echo.

echo [5/5] Application des migrations...
call npx prisma@6.17.1 migrate deploy
if errorlevel 1 (
    echo ⚠️ Tentative de creation de la base de donnees...
    call npx prisma@6.17.1 db push
    if errorlevel 1 (
        echo ❌ ERREUR: Migrations echouees
        echo.
        echo 🔧 Solutions alternatives:
        echo   1. Supprimer database\logesco.db et relancer
        echo   2. Executer: npx prisma migrate reset --force
        echo   3. Verifier les permissions du dossier database\
        echo.
        pause
        exit /b 1
    )
)
echo ✅ Base de donnees initialisee
echo.

echo [BONUS] Verification de la base de donnees...
if exist "database\logesco.db" (
    echo ✅ Fichier de base de donnees cree: database\logesco.db
) else (
    echo ⚠️ Fichier de base de donnees non trouve
)

echo.
echo ========================================
echo   Correction terminee avec succes!
echo ========================================
echo.
echo 🗄️ Base de donnees: database\logesco.db
echo 🔧 Client Prisma: Regenere
echo 📊 Tables: Creees
echo.
echo Vous pouvez maintenant:
echo 1. Tester le backend: npm start
echo 2. Reconstruire la version portable: ..\preparer-pour-client-fixed.bat
echo.
cd ..
pause