@echo off
echo ========================================
echo   LOGESCO v2 - Build avec Prisma
echo ========================================
echo.
echo Ce script genere Prisma d'abord pour eviter
echo les problemes de telechargement.
echo.

REM Étape 1: Générer Prisma dans le backend source
echo [1/3] Generation de Prisma dans le backend source...
cd backend

echo Installation des dependances...
call npm install
if errorlevel 1 (
    echo ERREUR: Installation echouee
    cd ..
    pause
    exit /b 1
)

echo Generation du client Prisma...
call npx prisma generate
if errorlevel 1 (
    echo ERREUR: Generation Prisma echouee
    cd ..
    pause
    exit /b 1
)

echo ✓ Prisma genere avec succes
cd ..
echo.

REM Étape 2: Vérifier que Prisma est bien généré
echo [2/3] Verification de Prisma...
if exist "backend\node_modules\.prisma\client" (
    echo ✓ Client Prisma trouve
) else (
    echo ❌ Client Prisma introuvable!
    pause
    exit /b 1
)
echo.

REM Étape 3: Builder le package client
echo [3/3] Construction du package client...
call preparer-pour-client.bat

echo.
echo ========================================
echo   Build termine avec succes!
echo ========================================
echo.
echo Le package est pret dans: release\LOGESCO-Client\
echo.
pause
