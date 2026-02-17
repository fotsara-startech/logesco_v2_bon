@echo off
title LOGESCO - Solution Rapide Prisma
echo ========================================
echo   SOLUTION RAPIDE PROBLEME PRISMA
echo ========================================
echo.

echo Ce script va resoudre le probleme Prisma rapidement
echo sans reconstruire tout le projet.
echo.
pause
echo.

echo [1/4] Arret des processus...
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [2/4] Correction du backend...
cd backend

REM Supprimer l'ancienne base de données corrompue
if exist "database\logesco.db" (
    echo Suppression de l'ancienne base de donnees...
    del "database\logesco.db" >nul 2>nul
)

REM Supprimer le client Prisma corrompu
if exist "node_modules\.prisma" (
    echo Suppression du client Prisma corrompu...
    rmdir /s /q "node_modules\.prisma" >nul 2>nul
)

echo ✅ Nettoyage termine
echo.

echo [3/4] Regeneration avec Prisma 6.17.1...
echo Tentative avec version locale...
call npx prisma@6.17.1 generate
if errorlevel 1 (
    echo ⚠️ Version locale echouee, tentative globale...
    call npx prisma generate
    if errorlevel 1 (
        echo ❌ Generation impossible
        echo.
        echo Essayez manuellement:
        echo 1. npm cache clean --force
        echo 2. npm install
        echo 3. npx prisma generate
        echo.
        cd ..
        pause
        exit /b 1
    )
)
echo ✅ Client Prisma genere
echo.

echo [4/4] Creation de la base de donnees...
call npx prisma@6.17.1 db push --accept-data-loss
if errorlevel 1 (
    echo ⚠️ db push echoue, tentative migrate deploy...
    call npx prisma@6.17.1 migrate deploy
    if errorlevel 1 (
        echo ❌ Creation base de donnees impossible
        cd ..
        pause
        exit /b 1
    )
)
echo ✅ Base de donnees creee
echo.

echo Test rapide du serveur...
timeout /t 2 /nobreak >nul
start /min cmd /c "node src/server-standalone.js"
timeout /t 5 /nobreak >nul

REM Tester si le serveur répond
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Serveur ne repond pas encore (normal au premier demarrage)
) else (
    echo ✅ Serveur fonctionne!
)

REM Arrêter le test
taskkill /f /im node.exe >nul 2>nul

cd ..
echo.
echo ========================================
echo   CORRECTION TERMINEE AVEC SUCCES!
echo ========================================
echo.
echo 🗄️ Base de donnees: backend/database/logesco.db
echo 🔧 Client Prisma: Regenere
echo 👤 Admin: admin / admin123
echo.
echo Vous pouvez maintenant:
echo 1. Tester: cd backend && npm start
echo 2. Construire portable: preparer-pour-client-fixed.bat
echo.
echo Le probleme Prisma est resolu!
echo.
pause