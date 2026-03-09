@echo off
echo ========================================
echo REDEMARRAGE DU BACKEND
echo ========================================
echo.
echo Nouvelle fonctionnalite: Totaux entrees/sorties dans sessions
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
echo Les details de session affichent maintenant:
echo - Total entrees (ventes + paiements)
echo - Total depenses (sorties)
echo.
echo Testez avec: cd backend ^&^& node test-session-totals.js
echo.
pause
