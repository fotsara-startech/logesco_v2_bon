@echo off
echo 🔧 Correction du problème d'import Prisma
echo ==========================================

echo.
echo 1️⃣ Nettoyage du cache Prisma...
cd backend
rmdir /s /q node_modules\.prisma 2>nul
rmdir /s /q prisma\generated 2>nul

echo.
echo 2️⃣ Régénération du client Prisma...
call npx prisma generate

echo.
echo 3️⃣ Vérification de la génération...
if exist "node_modules\.prisma\client\index.js" (
    echo ✅ Client Prisma généré avec succès
) else (
    echo ❌ Échec de la génération du client Prisma
    goto :error
)

echo.
echo 4️⃣ Test de l'import du client...
node -e "
try {
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient();
  console.log('✅ Import PrismaClient réussi');
  
  // Vérifier que le modèle produit existe
  if (prisma.produit) {
    console.log('✅ Modèle produit accessible via prisma.produit');
  } else {
    console.log('❌ Modèle produit non accessible');
  }
  
  prisma.$disconnect();
} catch (error) {
  console.log('❌ Erreur import:', error.message);
  process.exit(1);
}
"

if %ERRORLEVEL% neq 0 goto :error

echo.
echo 5️⃣ Redémarrage du backend recommandé...
echo Pour appliquer les corrections, redémarrez le backend avec:
echo   npm run dev
echo.
echo ✅ Correction terminée avec succès !
goto :end

:error
echo.
echo ❌ Erreur lors de la correction
echo Vérifiez manuellement:
echo   1. Le fichier schema.prisma
echo   2. Les dépendances npm
echo   3. Les permissions de fichiers
exit /b 1

:end
cd ..