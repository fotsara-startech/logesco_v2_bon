@echo off
echo 🔄 Redémarrage de l'application avec la correction des catégories
echo ================================================================

echo.
echo 📋 CORRECTION APPLIQUÉE:
echo    ✅ Analyse des ventes par catégorie corrigée
echo    ✅ Récupération des vraies catégories via API
echo    ✅ Cache des catégories pour optimiser les performances
echo.

echo 🛑 Arrêt des processus existants...
taskkill /f /im flutter.exe 2>nul
taskkill /f /im dart.exe 2>nul
taskkill /f /im node.exe 2>nul

echo.
echo ⏳ Attente de 3 secondes...
timeout /t 3 /nobreak >nul

echo.
echo 🚀 Démarrage du backend...
cd backend
start "Backend LOGESCO" cmd /k "npm run dev"

echo.
echo ⏳ Attente du démarrage du backend (10 secondes)...
timeout /t 10 /nobreak >nul

echo.
echo 📱 Démarrage de l'application Flutter...
cd ../logesco_v2
start "Flutter LOGESCO" cmd /k "flutter run -d windows"

echo.
echo ✅ APPLICATION REDÉMARRÉE AVEC LA CORRECTION DES CATÉGORIES !
echo.
echo 🧪 POUR TESTER:
echo    1. Attendre que l'application se lance
echo    2. Aller dans RAPPORTS → Bilan Comptable
echo    3. Sélectionner une période avec des ventes
echo    4. Générer le bilan
echo    5. Vérifier la section "Ventes par Catégorie"
echo.
echo 📊 RÉSULTAT ATTENDU:
echo    ✅ Plusieurs catégories au lieu d'une seule "Produits"
echo    ✅ Montants corrects par catégorie
echo    ✅ Logs détaillés dans la console Flutter
echo.

pause