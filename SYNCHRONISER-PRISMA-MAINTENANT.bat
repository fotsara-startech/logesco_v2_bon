@echo off
title LOGESCO - Synchronisation Prisma
color 0B
echo ========================================
echo   SYNCHRONISATION PRISMA
echo   Version compatible toutes versions
echo ========================================
echo.

echo Arret des processus...
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

cd backend

echo Suppression ancien client Prisma...
if exist "node_modules\.prisma\client" (
    rmdir /s /q "node_modules\.prisma\client" 2>nul
    echo ✅ Supprime
)
echo.

echo [1/3] Generation client Prisma...
call npx prisma generate
echo.

echo [2/3] Synchronisation avec la base...
call npx prisma db push --accept-data-loss
echo.

echo [3/3] Regeneration finale...
call npx prisma generate
echo.

cd ..

echo ========================================
echo   SYNCHRONISATION TERMINEE
echo ========================================
echo.

echo 🚀 Demarrer LOGESCO:
echo    DEMARRER-LOGESCO.bat
echo.

echo 🔑 Connexion:
echo    admin / admin123
echo.
pause
