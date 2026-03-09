@echo off
title Regenerer Prisma Simple
color 0A
echo ========================================
echo   REGENERER PRISMA SIMPLE
echo ========================================
echo.
echo Ce script regenere Prisma avec votre base.
echo.
pause

echo.
echo [1] Arret processus
echo ====================
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo OK
echo.

echo [2] Suppression ancien Prisma
echo ===============================
cd backend
if exist "node_modules\.prisma" (
    rmdir /s /q "node_modules\.prisma" 2>nul
    echo .prisma supprime
)
if exist "node_modules\@prisma\client" (
    rmdir /s /q "node_modules\@prisma\client" 2>nul
    echo @prisma/client supprime
)
echo.

echo [3] Generation Prisma
echo ======================
echo Generation en cours (10-15 secondes)...
echo.
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ERREUR!
    cd ..
    pause
    exit /b 1
)
cd ..
echo.
echo OK
echo.

echo [4] Test
echo ========
echo.
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('Produits:',c)).catch(e=>console.log('ERREUR')).finally(()=>p.$disconnect())"
cd ..
echo.

echo ========================================
echo   TERMINE
echo ========================================
echo.
echo Si vous voyez "Produits: 165" ci-dessus:
echo   Prisma fonctionne!
echo.
echo Lancez: DEMARRER-LOGESCO.bat
echo.
pause
