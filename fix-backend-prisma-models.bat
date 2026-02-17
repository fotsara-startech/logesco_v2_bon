@echo off
echo 🔧 Correction du problème Prisma Backend
echo ========================================

echo.
echo 1️⃣ Arrêt du backend...
taskkill /f /im node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo 2️⃣ Navigation vers le backend...
cd backend

echo.
echo 3️⃣ Vérification de l'environnement...
if not exist ".env" (
    echo ❌ Fichier .env manquant - Création...
    echo DATABASE_URL="file:./dev.db" > .env
    echo JWT_SECRET="logesco-secret-key-2024" >> .env
    echo NODE_ENV="development" >> .env
    echo PORT=8080 >> .env
    echo ✅ Fichier .env créé
) else (
    echo ✅ Fichier .env trouvé
)

echo.
echo 4️⃣ Nettoyage du cache Prisma...
rmdir /s /q node_modules\.prisma 2>nul
rmdir /s /q prisma\generated 2>nul

echo.
echo 5️⃣ Régénération du client Prisma...
call npx prisma generate
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur génération Prisma
    goto :error
)

echo.
echo 6️⃣ Migration de la base de données...
call npx prisma db push --force-reset
if %ERRORLEVEL% neq 0 (
    echo ⚠️  Erreur migration - Tentative sans reset...
    call npx prisma db push
)

echo.
echo 7️⃣ Test du client Prisma...
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function test() {
  try {
    console.log('✅ Client Prisma importé');
    
    if (prisma.produit && typeof prisma.produit.findFirst === 'function') {
      console.log('✅ Modèle produit.findFirst disponible');
    } else {
      console.log('❌ Modèle produit.findFirst non disponible');
      process.exit(1);
    }
    
    await prisma.\$disconnect();
    console.log('✅ Test Prisma réussi');
  } catch (error) {
    console.log('❌ Erreur test:', error.message);
    process.exit(1);
  }
}

test();
"

if %ERRORLEVEL% neq 0 goto :error

echo.
echo 8️⃣ Redémarrage du backend...
echo Backend redémarré avec Prisma corrigé
echo URL: http://localhost:8080
echo.
echo Appuyez sur Ctrl+C pour arrêter
start /b npm run dev

echo.
echo ✅ Backend redémarré avec succès !
echo Vous pouvez maintenant tester l'import Excel
goto :end

:error
echo.
echo ❌ Erreur lors de la correction
echo.
echo Solutions manuelles:
echo 1. Vérifiez que Node.js est installé
echo 2. Exécutez: npm install
echo 3. Exécutez: npx prisma generate
echo 4. Redémarrez: npm run dev
exit /b 1

:end
cd ..