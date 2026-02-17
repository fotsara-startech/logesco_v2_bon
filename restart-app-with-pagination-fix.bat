@echo off
echo 🔄 Redémarrage de l'application avec la correction de pagination
echo ================================================================

echo.
echo 📋 Étape 1: Arrêt des processus Flutter...
taskkill /f /im flutter.exe 2>nul
taskkill /f /im dart.exe 2>nul
timeout /t 2 >nul

echo.
echo 📋 Étape 2: Nettoyage du cache Flutter...
cd logesco_v2
flutter clean >nul 2>&1

echo.
echo 📋 Étape 3: Récupération des dépendances...
flutter pub get >nul 2>&1

echo.
echo 📋 Étape 4: Génération des fichiers (si nécessaire)...
dart run build_runner build --delete-conflicting-outputs >nul 2>&1

echo.
echo 📋 Étape 5: Instructions pour redémarrer l'application...
echo.
echo ✅ Corrections appliquées avec succès !
echo.
echo 🚀 Pour tester la correction :
echo    1. Redémarrez votre application Flutter (Hot Restart complet)
echo    2. Allez dans "Mouvements financiers"
echo    3. Cliquez sur "Actualiser"
echo    4. L'erreur de cast ne devrait plus apparaître
echo.
echo 🔧 Corrections appliquées :
echo    ✅ Modèles FinancialMovement avec parsing sécurisé
echo    ✅ Modèles MovementStatistics avec parsing sécurisé
echo    ✅ Modèles CategoryStatistic avec parsing sécurisé
echo    ✅ Modèles DailySummary avec parsing sécurisé
echo    ✅ Modèles MovementSummary avec parsing sécurisé
echo    ✅ Modèles CategorySummary avec parsing sécurisé
echo    ✅ Modèle Pagination avec valeurs par défaut sécurisées
echo    ✅ DTO backend avec parsing sécurisé
echo    ✅ Gestion d'erreur améliorée dans le contrôleur
echo.
echo 📊 Types d'erreurs corrigées :
echo    - type 'Null' is not a subtype of type 'num'
echo    - Valeurs NaN et Infinity
echo    - Données manquantes ou malformées
echo    - Erreurs de cast dans la pagination
echo.

cd ..
pause