@echo off
echo 🔧 Redémarrage du backend avec correction Prisma
echo ================================================

echo.
echo 1️⃣ Arrêt du backend existant...
taskkill /f /im node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo 2️⃣ Vérification de l'environnement...
cd backend

if not exist ".env" (
    echo ❌ Fichier .env manquant
    echo Création d'un fichier .env minimal...
    echo DATABASE_URL="file:./dev.db" > .env
    echo JWT_SECRET="your-secret-key-here" >> .env
    echo NODE_ENV="development" >> .env
    echo PORT=8080 >> .env
)

echo ✅ Fichier .env vérifié

echo.
echo 3️⃣ Régénération du client Prisma...
call npx prisma generate
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur génération Prisma
    goto :error
)

echo.
echo 4️⃣ Migration de la base de données...
call npx prisma db push
if %ERRORLEVEL% neq 0 (
    echo ⚠️  Erreur migration (peut être normale si la DB existe)
)

echo.
echo 5️⃣ Démarrage du backend...
echo Backend démarré sur http://localhost:8080
echo Appuyez sur Ctrl+C pour arrêter
call npm run dev

goto :end

:error
echo.
echo ❌ Erreur lors du redémarrage
echo Vérifiez manuellement la configuration
exit /b 1

:end
cd ..