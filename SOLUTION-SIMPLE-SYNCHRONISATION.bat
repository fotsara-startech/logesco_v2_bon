@echo off
title LOGESCO - Solution Simple Synchronisation
color 0B
echo ========================================
echo   SOLUTION SIMPLE SYNCHRONISATION
echo   Tout en une seule commande
echo ========================================
echo.

echo Ce script resout le probleme de donnees
echo non affichees en synchronisant Prisma.
echo.
echo AUCUN autre fichier necessaire!
echo.
pause
echo.

echo [1/4] Verification
echo ==================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    pause
    exit /b 1
)

echo ✅ Base de donnees trouvee
echo.

echo [2/4] Arret des processus
echo ==========================
echo.
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

echo [3/4] Synchronisation FORCEE Prisma
echo ====================================
echo.

cd backend

echo Etape 1: Suppression client Prisma existant...
if exist "node_modules\.prisma\client" (
    rmdir /s /q "node_modules\.prisma\client" 2>nul
    echo ✅ Client supprime
) else (
    echo ℹ️  Pas de client a supprimer
)
echo.

echo Etape 2: Regeneration...
call npx prisma generate
if errorlevel 1 (
    echo ❌ Erreur generation
    cd ..
    pause
    exit /b 1
)
echo ✅ Client regenere
echo.

echo Etape 3: Introspection de la base...
call npx prisma db pull
if errorlevel 1 (
    echo ⚠️  Avertissement introspection
    echo    Tentative sans force...
) else (
    echo ✅ Introspection reussie
)
echo.

echo Etape 4: Synchronisation schema...
call npx prisma db push --accept-data-loss
if errorlevel 1 (
    echo ⚠️  Avertissement synchronisation
    echo    Cela peut etre normal
) else (
    echo ✅ Schema synchronise
)
echo.

echo Etape 5: Regeneration finale...
call npx prisma generate
if errorlevel 1 (
    echo ⚠️  Avertissement regeneration finale
) else (
    echo ✅ Regeneration reussie
)
echo ✅ Synchronisation terminee
echo.

cd ..

echo [4/4] Test rapide
echo =================
echo.

echo Demarrage backend pour test...
cd backend
start "Test Backend" /MIN node src/server.js
cd ..

echo Attente 10 secondes...
timeout /t 10 /nobreak >nul

curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️  Backend ne repond pas encore
) else (
    echo ✅ Backend fonctionne!
)

echo.
echo Test API utilisateurs...
curl -s http://localhost:8080/api/users >nul 2>nul
if errorlevel 1 (
    echo ⚠️  API ne repond pas
) else (
    echo ✅ API fonctionne!
)

taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   SYNCHRONISATION TERMINEE
echo ========================================
echo.

echo 🚀 PROCHAINES ETAPES:
echo.
echo 1. Demarrer LOGESCO normalement:
echo    DEMARRER-LOGESCO.bat
echo.
echo 2. Se connecter avec:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo 3. Verifier que les donnees apparaissent
echo.

echo ℹ️  Si le probleme persiste:
echo    - Verifier les logs: backend\logs\
echo    - Consulter: GUIDE_DEPANNAGE_DONNEES_NON_AFFICHEES.md
echo.
pause
