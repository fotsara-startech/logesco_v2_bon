@echo off
echo ========================================
echo Migration: Ajout logo et slogan
echo ========================================
echo.

cd backend

echo Etape 1: Application de la migration SQL...
node apply-migration-logo-slogan.js

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERREUR: La migration a echoue
    cd ..
    pause
    exit /b 1
)

echo.
echo Etape 2: Generation du client Prisma...
call npx prisma generate

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERREUR: La generation du client Prisma a echoue
    cd ..
    pause
    exit /b 1
)

cd ..

echo.
echo ========================================
echo Migration terminee avec succes!
echo ========================================
echo.
echo Vous pouvez maintenant:
echo 1. Redemarrer le backend
echo 2. Regenerer le modele Flutter: regenerer-modele-flutter.bat
echo.
pause
