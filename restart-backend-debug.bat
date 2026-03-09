@echo off
echo ========================================
echo REDEMARRAGE BACKEND - MODE DEBUG
echo ========================================
echo.

echo [1/3] Arret du backend en cours...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/3] Demarrage du backend avec logs...
cd backend

echo.
echo ========================================
echo Backend demarre - Surveillez les logs
echo ========================================
echo.
echo Testez maintenant:
echo 1. Impression du releve (GET /accounts/suppliers/:id/statement)
echo 2. Liste des commandes impayees (GET /accounts/suppliers/:id/unpaid-procurements)
echo.
echo Les logs apparaitront ci-dessous:
echo ========================================
echo.

npm start
