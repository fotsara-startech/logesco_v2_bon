@echo off
title LOGESCO - Correction Immediate Prisma
echo ========================================
echo   CORRECTION IMMEDIATE PRISMA
echo ========================================
echo.

echo Ce script va corriger le probleme de version Prisma
echo et reinitialiser la base de donnees.
echo.
echo Appuyez sur une touche pour continuer...
pause >nul
echo.

echo [1/6] Arret des processus Node.js...
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [2/6] Nettoyage des fichiers Prisma...
cd backend
if exist "database\logesco.db" (
    echo Sauvegarde de l'ancienne base...
    copy "database\logesco.db" "database\logesco_backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.db" >nul 2>nul
    del "database\logesco.db" >nul 2>nul
)
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" >nul 2>nul
echo ✅ Nettoyage termine
echo.

echo [3/6] Verification de la version Prisma locale...
call npm list @prisma/client
echo.

echo [4/6] Generation du client Prisma (version locale)...
call npx prisma@6.17.1 generate
if errorlevel 1 (
    echo ⚠️ Echec version 6.17.1, tentative version globale...
    call npx prisma generate
    if errorlevel 1 (
        echo ❌ ERREUR: Generation impossible
        echo.
        echo Solutions:
        echo 1. Verifiez votre connexion Internet
        echo 2. Executez: npm cache clean --force
        echo 3. Reinstallez: npm install
        echo.
        pause
        exit /b 1
    )
)
echo ✅ Client Prisma genere
echo.

echo [5/6] Creation de la base de donnees...
call npx prisma@6.17.1 db push
if errorlevel 1 (
    echo ⚠️ Echec db push, tentative migrate deploy...
    call npx prisma@6.17.1 migrate deploy
    if errorlevel 1 (
        echo ❌ ERREUR: Creation base de donnees impossible
        pause
        exit /b 1
    )
)
echo ✅ Base de donnees creee
echo.

echo [6/6] Initialisation des donnees de base...
if exist "scripts\ensure-admin.js" (
    node scripts\ensure-admin.js
    if errorlevel 1 (
        echo ⚠️ Erreur initialisation admin (sera fait au demarrage)
    ) else (
        echo ✅ Utilisateur admin initialise
    )
) else (
    echo ⚠️ Script ensure-admin.js non trouve
)
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
echo   CORRECTION TERMINEE
echo ========================================
echo.
echo 🗄️ Base de donnees reinitalisee
echo 🔧 Client Prisma regenere
echo 👤 Admin: admin / admin123
echo.
echo Vous pouvez maintenant:
echo 1. Tester: cd backend && npm start
echo 2. Reconstruire portable: preparer-pour-client-fixed.bat
echo.
pause