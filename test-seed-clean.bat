@echo off
echo ========================================
echo   Test du Seed de Base de Donnees Propre
echo ========================================
echo.

cd backend

echo [1/3] Suppression ancienne base de donnees de test...
if exist "prisma\database\logesco-test.db" del /f "prisma\database\logesco-test.db"
echo ✅ Nettoyage termine
echo.

echo [2/3] Creation structure base de donnees...
set DATABASE_URL=file:./prisma/database/logesco-test.db
npx prisma db push --accept-data-loss --skip-generate
if errorlevel 1 (
    echo ❌ ERREUR: Creation structure echouee
    cd ..
    pause
    exit /b 1
)
echo ✅ Structure creee
echo.

echo [3/3] Initialisation donnees essentielles...
node prisma/seed.js
if errorlevel 1 (
    echo ❌ ERREUR: Seed echoue
    cd ..
    pause
    exit /b 1
)
echo.

echo ========================================
echo   Test Reussi!
echo ========================================
echo.
echo 📊 Base de donnees de test creee:
echo    backend\prisma\database\logesco-test.db
echo.
echo 🔍 Verifiez avec:
echo    cd backend
echo    npx prisma studio --schema prisma/schema.prisma
echo.
echo 🔑 Identifiants:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
cd ..
pause
