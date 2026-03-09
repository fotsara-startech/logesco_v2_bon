@echo off
echo ========================================
echo   Test Build avec Base de Donnees Propre
echo ========================================
echo.
echo Ce script teste uniquement la creation de la base propre
echo sans faire le build complet (plus rapide pour tester)
echo.

REM Nettoyer
echo [1/4] Nettoyage...
if exist "dist-portable" rmdir /s /q "dist-portable" 2>nul
echo ✅ Nettoyage termine
echo.

REM Créer le dossier de test
echo [2/4] Creation structure de test...
mkdir "dist-portable"
mkdir "dist-portable\database"
mkdir "dist-portable\prisma"

REM Copier les fichiers nécessaires
xcopy /E /I /Y /Q "backend\prisma\*" "dist-portable\prisma\" >nul
xcopy /Y /Q "backend\package.json" "dist-portable\" >nul
xcopy /Y /Q "backend\.env" "dist-portable\" >nul 2>nul
if not exist "dist-portable\.env" (
    echo DATABASE_URL="file:./database/logesco.db" > "dist-portable\.env"
)

REM Copier node_modules (pour éviter npm install)
echo    Copie node_modules (peut prendre du temps)...
xcopy /E /I /Y /Q "backend\node_modules" "dist-portable\node_modules" >nul
echo ✅ Structure creee
echo.

REM Créer la base de données propre
echo [3/4] Creation base de donnees propre...
cd dist-portable

REM Supprimer toute base existante
if exist "database\logesco.db" del /f "database\logesco.db"

REM Créer la structure
set DATABASE_URL=file:./database/logesco.db
npx prisma db push --accept-data-loss --skip-generate
if errorlevel 1 (
    echo ❌ ERREUR: Creation structure echouee
    cd ..
    pause
    exit /b 1
)

REM Initialiser avec le seed
echo    Initialisation donnees essentielles...
node prisma/seed.js
if errorlevel 1 (
    echo ❌ ERREUR: Seed echoue
    cd ..
    pause
    exit /b 1
)

cd ..
echo ✅ Base de donnees propre creee
echo.

REM Vérifier le contenu
echo [4/4] Verification du contenu...
cd dist-portable

node -e "const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient(); (async () => { const users = await prisma.utilisateur.count(); const roles = await prisma.userRole.count(); const caisses = await prisma.cashRegister.count(); const params = await prisma.parametresEntreprise.count(); const produits = await prisma.produit.count(); const ventes = await prisma.vente.count(); const clients = await prisma.client.count(); console.log(''); console.log('📊 Contenu de la base de donnees:'); console.log(''); console.log('✅ Donnees essentielles:'); console.log('   - Roles: ' + roles); console.log('   - Utilisateurs: ' + users); console.log('   - Caisses: ' + caisses); console.log('   - Parametres: ' + params); console.log(''); console.log('📭 Donnees metier:'); console.log('   - Produits: ' + produits); console.log('   - Ventes: ' + ventes); console.log('   - Clients: ' + clients); console.log(''); if (produits === 0 && ventes === 0 && clients === 0) { console.log('✅ BASE PROPRE - Prete pour le client!'); } else { console.log('⚠️  ATTENTION: Base contient des donnees de test!'); } await prisma.$disconnect(); })();"

cd ..
echo.

echo ========================================
echo   Test Termine!
echo ========================================
echo.
echo 📦 Base de donnees de test dans:
echo    dist-portable\database\logesco.db
echo.
echo 🔍 Pour inspecter:
echo    cd dist-portable
echo    npx prisma studio
echo.
echo 🔑 Identifiants:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
pause
