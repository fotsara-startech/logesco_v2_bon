@echo off
title Test Manuel Complet
color 0B
echo ========================================
echo   TEST MANUEL COMPLET
echo   Sans fichiers supplementaires
echo ========================================
echo.

echo [1/3] Test Base de Donnees
echo ============================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base non trouvee!
    pause
    exit /b 1
)

for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
echo ✅ Base trouvee: %DB_SIZE% octets
echo.

where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Comptage avec SQLite:
    cd backend\database
    
    for /f %%i in ('sqlite3 logesco.db "SELECT COUNT(*) FROM utilisateurs;"') do set USER_COUNT=%%i
    for /f %%i in ('sqlite3 logesco.db "SELECT COUNT(*) FROM produits;"') do set PROD_COUNT=%%i
    for /f %%i in ('sqlite3 logesco.db "SELECT COUNT(*) FROM ventes;"') do set SALE_COUNT=%%i
    
    echo - Utilisateurs: %USER_COUNT%
    echo - Produits: %PROD_COUNT%
    echo - Ventes: %SALE_COUNT%
    
    cd ..\..
    echo.
    
    if %USER_COUNT% GTR 0 (
        echo ✅ SQLite lit les donnees
    ) else (
        echo ❌ Base vide!
        pause
        exit /b 1
    )
) else (
    echo ⚠️  sqlite3 non disponible, on continue...
)
echo.
pause
echo.

echo [2/3] Test Backend API
echo =======================
echo.

echo Arret processus existants...
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo Demarrage backend...
cd backend
start "LOGESCO Backend" node src/server.js
cd ..

echo Attente 15 secondes...
timeout /t 15 /nobreak >nul
echo.

echo Test Health:
curl -s http://localhost:8080/health
echo.
echo.

echo Test Users API:
curl -s http://localhost:8080/api/users
echo.
echo.

echo Test Products API:
curl -s http://localhost:8080/api/products
echo.
echo.

echo Arret backend...
taskkill /f /im node.exe >nul 2>nul
echo.
pause
echo.

echo [3/3] Analyse Resultats
echo ========================
echo.

echo VERIFIEZ CI-DESSUS:
echo.
echo 1. SQLite a trouve des donnees?
echo    OUI → Base OK
echo    NON → Base vide ou corrompue
echo.
echo 2. API Users a retourne des donnees JSON?
echo    OUI → Backend fonctionne!
echo    NON → Probleme backend
echo.
echo 3. API Products a retourne des donnees?
echo    OUI → Backend fonctionne!
echo    NON → Probleme backend
echo.

echo ========================================
echo   DIAGNOSTIC
echo ========================================
echo.

echo Si SQLite trouve des donnees MAIS API retourne []:
echo   → Prisma ne lit pas correctement
echo   → SOLUTION: Verifier schema.prisma
echo.

echo Si API retourne des donnees:
echo   → Backend fonctionne correctement
echo   → Le probleme est dans l'application Flutter
echo   → Verifier URL backend dans l'app
echo.

echo Si API ne retourne rien:
echo   → Verifier: backend\logs\error.log
echo   → Verifier: backend\src\routes\
echo.
pause
