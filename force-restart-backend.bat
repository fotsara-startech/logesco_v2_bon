@echo off
echo 🔄 Redémarrage forcé du backend avec nettoyage cache
echo ===================================================

echo.
echo 1️⃣ Arrêt de tous les processus Node.js...
taskkill /f /im node.exe 2>nul
taskkill /f /im nodemon.exe 2>nul
timeout /t 3 /nobreak >nul

echo.
echo 2️⃣ Navigation vers le backend...
cd backend

echo.
echo 3️⃣ Nettoyage du cache Node.js...
if exist "node_modules\.cache" rmdir /s /q "node_modules\.cache"
if exist ".next" rmdir /s /q ".next"
if exist "dist" rmdir /s /q "dist"

echo.
echo 4️⃣ Nettoyage du cache Prisma...
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma"
if exist "prisma\generated" rmdir /s /q "prisma\generated"

echo.
echo 5️⃣ Régénération complète du client Prisma...
call npx prisma generate --force
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur génération Prisma
    goto :error
)

echo.
echo 6️⃣ Test du nouveau client Prisma...
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
console.log('✅ Nouveau client Prisma chargé');
if (prisma.produit && typeof prisma.produit.findFirst === 'function') {
  console.log('✅ Méthode findFirst disponible');
} else {
  console.log('❌ Problème avec findFirst');
  process.exit(1);
}
prisma.\$disconnect();
"

if %ERRORLEVEL% neq 0 goto :error

echo.
echo 7️⃣ Redémarrage du serveur avec cache vidé...
set NODE_OPTIONS=--max-old-space-size=4096
echo Serveur redémarré - Cache Node.js vidé
echo URL: http://localhost:8080
echo.
start /b npm run dev

timeout /t 5 /nobreak >nul

echo.
echo 8️⃣ Vérification du démarrage...
curl -s http://localhost:8080/health >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ✅ Backend démarré avec succès !
) else (
    echo ⚠️  Backend en cours de démarrage...
)

echo.
echo ✅ Redémarrage forcé terminé !
echo Le backend utilise maintenant le nouveau client Prisma.
echo Testez l'import Excel dans l'application Flutter.
goto :end

:error
echo.
echo ❌ Erreur lors du redémarrage forcé
echo Vérifiez manuellement les étapes suivantes:
echo 1. npx prisma generate
echo 2. npm run dev
exit /b 1

:end
cd ..