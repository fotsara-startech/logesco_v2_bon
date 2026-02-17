@echo off
echo 🔄 Redémarrage du backend avec les corrections des mouvements financiers
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
echo 📋 Étape 5: Test de connectivité...
curl -s http://localhost:3000/api/v1/health >nul
if %errorlevel% equ 0 (
    echo ✅ Backend redémarré avec succès !
    echo 🌐 Disponible sur: http://localhost:3000
) else (
    echo ⚠️ Backend en cours de démarrage...
    echo 💡 Vérifiez manuellement dans quelques secondes
)

echo.
echo 📋 Étape 6: Instructions pour tester la correction...
echo.
echo 1. Ouvrez l'application Flutter
echo 2. Allez dans la section "Mouvements financiers"
echo 3. Essayez d'actualiser la page
echo 4. L'erreur de cast ne devrait plus apparaître
echo.
echo 🔧 Si le problème persiste:
echo    - Vérifiez les logs du backend dans la fenêtre qui s'est ouverte
echo    - Vérifiez les logs Flutter dans votre IDE
echo    - Redémarrez l'application Flutter
echo.

pause