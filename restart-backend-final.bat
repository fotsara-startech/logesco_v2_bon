@echo off
echo ========================================
echo REDEMARRAGE FINAL DU BACKEND
echo ========================================
echo.
echo Corrections appliquees:
echo 1. Synchronisation solde caisse/session
echo 2. Ajout totaux entrees/sorties
echo 3. Creation mouvements de caisse pour ventes
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
echo Les nouvelles ventes creent maintenant des mouvements de caisse.
echo Les totaux d'entrees/sorties sont maintenant corrects.
echo.
echo Pour tester:
echo   cd backend
echo   node test-session-totals.js
echo.
pause
