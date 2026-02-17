@echo off
echo ========================================
echo Redemarrage du backend avec migration
echo ========================================

echo.
echo [1/3] Arret du backend...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/3] Regeneration du client Prisma...
call npx prisma generate

echo.
echo [3/3] Demarrage du backend...
start "Backend Logesco" cmd /k "npm run dev"

echo.
echo ========================================
echo Backend redemarre avec succes!
echo ========================================
pause
