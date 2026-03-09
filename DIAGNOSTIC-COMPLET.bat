@echo off
title Diagnostic Complet
color 0E
echo ========================================
echo   DIAGNOSTIC COMPLET
echo   Identification precise du probleme
echo ========================================
echo.

echo Ce script va tester chaque couche:
echo 1. Base de donnees (SQLite)
echo 2. Prisma (ORM)
echo 3. Backend API
echo 4. Application Flutter
echo.
pause
echo.

echo ========================================
echo   ETAPE 1: BASE DE DONNEES
echo ========================================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    pause
    exit /b 1
)

for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
echo ✅ Base trouvee: %DB_SIZE% octets
echo.

where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Test avec SQLite...
    cd backend\database
    
    echo Utilisateurs:
    sqlite3 logesco.db "SELECT COUNT(*) FROM utilisateurs;"
    
    echo Produits:
    sqlite3 logesco.db "SELECT COUNT(*) FROM produits;"
    
    echo Ventes:
    sqlite3 logesco.db "SELECT COUNT(*) FROM ventes;"
    
    cd ..\..
    echo.
    echo ✅ SQLite peut lire la base
) else (
    echo ⚠️  sqlite3 non disponible
)
echo.
pause
echo.

echo ========================================
echo   ETAPE 2: PRISMA
echo ========================================
echo.

echo Test direct Prisma...
cd backend
node test-direct-prisma.js
cd ..
echo.
pause
echo.

echo ========================================
echo   ETAPE 3: BACKEND API
echo ========================================
echo.

echo Demarrage backend...
cd backend
start "Backend Test" /MIN node src/server.js
cd ..

echo Attente 15 secondes...
timeout /t 15 /nobreak >nul
echo.

echo Test API...
echo.

echo Health:
curl -s http://localhost:8080/health
echo.
echo.

echo Users:
curl -s http://localhost:8080/api/users
echo.
echo.

echo Products (5 premiers):
curl -s "http://localhost:8080/api/products?limit=5"
echo.
echo.

taskkill /f /im node.exe >nul 2>nul
echo Backend arrete.
echo.
pause
echo.

echo ========================================
echo   ETAPE 4: APPLICATION FLUTTER
echo ========================================
echo.

echo L'application Flutter doit etre testee manuellement:
echo.
echo 1. Demarrer: DEMARRER-LOGESCO.bat
echo 2. Se connecter: admin / admin123
echo 3. Verifier si les donnees apparaissent
echo.
echo Si les donnees n'apparaissent pas:
echo   → Verifier la console Flutter (F12)
echo   → Verifier les logs: backend\logs\
echo   → Verifier l'URL de connexion dans l'app
echo.
pause
echo.

echo ========================================
echo   RESUME DIAGNOSTIC
echo ========================================
echo.

echo Verifiez les resultats ci-dessus:
echo.
echo [1] SQLite lit la base?
echo     OUI → Base OK
echo     NON → Base corrompue ou vide
echo.
echo [2] Prisma lit les donnees?
echo     OUI → Prisma OK
echo     NON → Probleme schema/mapping
echo.
echo [3] API retourne des donnees?
echo     OUI → Backend OK
echo     NON → Probleme routes/controllers
echo.
echo [4] App Flutter affiche les donnees?
echo     OUI → Tout fonctionne!
echo     NON → Probleme Flutter/connexion
echo.

echo ========================================
echo   SOLUTIONS PAR PROBLEME
echo ========================================
echo.

echo Si Prisma ne lit pas:
echo   → Verifier schema.prisma
echo   → Comparer noms colonnes BD vs schema
echo   → Executer: npx prisma db pull
echo.

echo Si API ne retourne rien:
echo   → Verifier backend\src\routes\
echo   → Verifier backend\src\controllers\
echo   → Consulter: backend\logs\error.log
echo.

echo Si Flutter n'affiche rien:
echo   → Verifier URL backend dans l'app
echo   → Verifier console Flutter (F12)
echo   → Tester avec Postman/curl
echo.
pause
