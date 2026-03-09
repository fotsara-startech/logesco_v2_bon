@echo off
title Apres Migration - Regenerer Prisma
color 0A
echo ========================================
echo   APRES MIGRATION
echo   Regeneration Prisma
echo ========================================
echo.
echo Executez ce script APRES chaque migration
echo pour garantir que Prisma voit vos donnees.
echo.
pause

echo.
echo [1] Arret processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo OK
echo.

echo [2] Suppression Prisma existant...
cd backend
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul
echo OK
cd ..
echo.

echo [3] Generation Prisma avec votre base...
echo (10-15 secondes)
cd backend
call npx prisma generate
cd ..
echo.
echo OK
echo.

echo ========================================
echo   TERMINE
echo ========================================
echo.
echo Prisma a ete regenere avec votre base.
echo.
echo Maintenant lancez: DEMARRER-LOGESCO.bat
echo.
pause
