@echo off
echo Arret du backend...
taskkill /F /IM node.exe 2>nul
timeout /t 1 >nul
echo Demarrage du backend...
cd backend
start "Backend Logesco" cmd /k "npm start"
echo Backend redemarre!
