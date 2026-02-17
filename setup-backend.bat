@echo off
echo 🚀 Configuration automatique du backend LOGESCO...

cd backend

echo 📦 Installation des dépendances...
call npm install

echo 🔧 Génération du client Prisma...
call npx prisma generate

echo 🗄️ Configuration de la base de données...
call node scripts/setup-database.js

echo ✅ Configuration terminée!
echo.
echo 🌐 Démarrage du serveur...
call node start-with-setup.js

pause