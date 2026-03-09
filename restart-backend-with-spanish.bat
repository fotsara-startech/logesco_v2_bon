@echo off
echo ========================================
echo Redemarrage du backend avec support ES
echo ========================================
echo.

echo Arret du backend en cours...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Demarrage du backend avec support espagnol...
cd backend
start "LOGESCO Backend" cmd /k "node src/server.js"

echo.
echo ========================================
echo Backend redemarre avec succes !
echo Support des langues: FR, EN, ES
echo ========================================
echo.
echo Le backend est maintenant pret a accepter 'es' comme langue de facture.
echo.
pause
