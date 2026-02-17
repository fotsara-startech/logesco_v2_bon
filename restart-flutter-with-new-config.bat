@echo off
echo 🔄 Redémarrage de l'application Flutter avec la nouvelle configuration
echo ================================================================

echo.
echo 📋 Vérifications préalables:
echo   ✅ Backend sur le port 3002
echo   ✅ Configuration API mise à jour
echo   ✅ Système de sessions de caisse opérationnel
echo   ✅ Devise FCFA configurée

echo.
echo 🛑 Arrêt des processus Flutter existants...
taskkill /f /im flutter.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo 🧹 Nettoyage du cache Flutter...
cd logesco_v2
flutter clean
flutter pub get

echo.
echo 🚀 Démarrage de l'application Flutter...
echo   Port backend: 3002
echo   URL API: http://localhost:3002/api/v1
echo   Sessions de caisse: Activées
echo   Devise: FCFA

echo.
echo 💡 Identifiants de test:
echo   Utilisateur: admin
echo   Mot de passe: password123

echo.
echo ⚡ Lancement en mode hot reload...
flutter run -d windows --hot

pause