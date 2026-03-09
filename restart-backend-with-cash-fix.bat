@echo off
echo ========================================
echo REDEMARRAGE DU BACKEND AVEC CORRECTION
echo ========================================
echo.
echo Correction appliquee: Synchronisation solde caisse/session
echo.

cd backend

echo [1/2] Arret du backend en cours...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Demarrage du backend...
start "Backend Logesco" cmd /k "npm start"

echo.
echo ========================================
echo Backend redemarre avec succes!
echo ========================================
echo.
echo Le solde de caisse devrait maintenant etre coherent.
echo Rafraichissez le frontend (F5) pour voir le solde correct.
echo.
pause
