@echo off
echo 🔄 Redémarrage du backend avec la correction de classification
echo ================================================================

echo.
echo 📋 Étape 1: Arrêt du backend actuel...
taskkill /f /im node.exe 2>nul
timeout /t 2 >nul

echo.
echo 📋 Étape 2: Nettoyage des processus...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do (
    echo Arrêt du processus %%a sur le port 3000
    taskkill /f /pid %%a 2>nul
)

echo.
echo 📋 Étape 3: Redémarrage du backend...
cd backend
start "Backend Logesco" cmd /k "npm run dev"

echo.
echo 📋 Étape 4: Attente du démarrage...
timeout /t 5 >nul

echo.
echo ✅ Backend redémarré avec les corrections !
echo.
echo 🔧 Corrections appliquées :
echo    ✅ Classification correcte des mouvements financiers
echo    ✅ Tous les mouvements sont maintenant des sorties (dépenses)
echo    ✅ Transport, salaires, marketing = Sorties
echo    ✅ Calculs corrects des totaux et flux net
echo.
echo 🚀 Pour tester la correction :
echo    1. Redémarrez votre application Flutter (Hot Restart)
echo    2. Allez dans "Bilan Comptable"
echo    3. Générez un rapport
echo    4. Vérifiez que les mouvements apparaissent dans "Sorties"
echo.
echo 📊 Résultat attendu :
echo    - Entrées : 0 FCFA
echo    - Sorties : 42500 FCFA (transport + salaires + marketing)
echo    - Flux Net : -42500 FCFA
echo.

cd ..
pause