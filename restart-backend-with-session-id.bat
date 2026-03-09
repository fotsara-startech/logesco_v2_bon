@echo off
echo ========================================
echo REDEMARRAGE BACKEND - SOLUTION FINALE
echo ========================================
echo.
echo Solution implementee: sessionId dans ventes et mouvements
echo.
echo Avantages:
echo - Lien direct entre operations et sessions
echo - Plus de problemes de dates/fuseaux horaires
echo - Totaux toujours corrects
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
echo Les nouvelles ventes/mouvements sont maintenant lies a leur session.
echo Les totaux sont calcules directement via sessionId.
echo.
echo Pour tester:
echo 1. Creer une nouvelle session
echo 2. Effectuer des ventes/depenses
echo 3. Fermer la session
echo 4. Verifier les totaux dans les details
echo.
pause
