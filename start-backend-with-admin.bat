@echo off
echo 🚀 Démarrage du backend LOGESCO avec vérification admin...
echo.

cd backend

echo 📦 Vérification des dépendances...
call npm install

echo.
echo 👑 Création/vérification de l'utilisateur admin...
call node scripts/ensure-admin.js

echo.
echo 🌐 Démarrage du serveur...
call npm run dev

pause