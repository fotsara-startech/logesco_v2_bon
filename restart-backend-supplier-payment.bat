@echo off
echo ========================================
echo REDEMARRAGE BACKEND - Paiement Fournisseurs
echo ========================================
echo.

echo [1/3] Arret du backend en cours...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/3] Demarrage du backend...
cd backend
start "Backend Logesco" cmd /k "npm start"

echo.
echo [3/3] Attente du demarrage...
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo Backend redemarre avec succes!
echo ========================================
echo.
echo Les nouvelles fonctionnalites sont disponibles:
echo   - Impression du releve de compte fournisseur
echo   - Paiement obligatoire avec selection de commande
echo   - Creation optionnelle de mouvement financier
echo.
echo Endpoint ajoute: GET /accounts/suppliers/:id/statement
echo Endpoint modifie: POST /accounts/suppliers/:id/transactions
echo.
pause
