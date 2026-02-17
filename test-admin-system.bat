@echo off
echo 🧪 Test du système d'administration automatique
echo.

cd backend

echo 🧹 1. Nettoyage de la base de données...
call node scripts/clean-roles.js

echo.
echo 👑 2. Création de l'utilisateur admin...
call node scripts/ensure-admin.js

echo.
echo 🔍 3. Vérification (deuxième exécution - ne devrait rien créer)...
call node scripts/ensure-admin.js

echo.
echo ✅ Test terminé ! L'utilisateur admin devrait être disponible.
echo 📋 Identifiants: admin / admin123

pause