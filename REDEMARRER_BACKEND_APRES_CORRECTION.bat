@echo off
echo ========================================
echo Redemarrage du backend apres correction
echo ========================================
echo.
echo Correction appliquee:
echo - Mise a jour du solde de caisse lors du paiement de dette client
echo.
echo IMPORTANT: Le backend doit etre redemarre pour que les changements prennent effet
echo.
pause
echo.
echo Arret du backend en cours...
taskkill /F /IM node.exe 2>nul
timeout /t 2 >nul
echo.
echo Demarrage du backend...
cd backend
start "Backend Logesco" cmd /k "npm start"
echo.
echo ========================================
echo Backend redemarre avec succes!
echo ========================================
echo.
echo Vous pouvez maintenant tester le paiement de dette client.
echo Le solde de la caisse devrait se mettre a jour automatiquement.
echo.
pause
