@echo off
title Test Migration Simple
color 0E
echo ========================================
echo   TEST MIGRATION SIMPLE
echo ========================================
echo.

echo Ce script teste la migration etape par etape
echo pour identifier exactement ou ca echoue.
echo.
pause
echo.

echo [1] Verification base actuelle
echo ================================
if not exist "backend\database\logesco.db" (
    echo ❌ Pas de base!
    pause
    exit /b 1
)

echo ✅ Base trouvee
echo.

echo Comptage donnees AVANT migration...
cd backend
for /f %%i in ('node -e "const {PrismaClient} = require('@prisma/client'); const p = new PrismaClient(); p.produit.count().then(c => console.log(c)).finally(() => p.$disconnect())"') do set COUNT_AVANT=%%i
cd ..
echo   Produits AVANT: %COUNT_AVANT%
echo.
pause
echo.

echo [2] Sauvegarde base
echo ====================
set TIMESTAMP=%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP=test_backup_%TIMESTAMP%

mkdir %BACKUP%
copy "backend\database\logesco.db" "%BACKUP%\logesco.db" >nul
echo ✅ Sauvegarde: %BACKUP%
echo.
pause
echo.

echo [3] Simulation copie nouveau backend
echo ======================================
echo (On simule en gardant le meme backend)
echo.

echo Suppression Prisma existant...
cd backend
if exist "node_modules\.prisma" (
    rmdir /s /q "node_modules\.prisma" 2>nul
    echo ✅ .prisma supprime
)
if exist "node_modules\@prisma\client" (
    rmdir /s /q "node_modules\@prisma\client" 2>nul
    echo ✅ @prisma/client supprime
)
cd ..
echo.
pause
echo.

echo [4] Restauration base (simulation)
echo ====================================
echo On recopie la meme base...
copy "%BACKUP%\logesco.db" "backend\database\logesco.db" >nul
echo ✅ Base recopiee
echo.
pause
echo.

echo [5] CRITIQUE: Generation Prisma
echo =================================
echo Generation Prisma avec la base restauree...
echo (10-15 secondes)
echo.

cd backend
call npx prisma generate
if errorlevel 1 (
    echo ❌ ERREUR generation!
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo ✅ Prisma genere
echo.
pause
echo.

echo [6] Verification APRES
echo =======================
echo Comptage donnees APRES migration...
cd backend
for /f %%i in ('node -e "const {PrismaClient} = require('@prisma/client'); const p = new PrismaClient(); p.produit.count().then(c => console.log(c)).finally(() => p.$disconnect())"') do set COUNT_APRES=%%i
cd ..
echo   Produits APRES: %COUNT_APRES%
echo.

echo ========================================
echo   RESULTAT
echo ========================================
echo.
echo Produits AVANT:  %COUNT_AVANT%
echo Produits APRES:  %COUNT_APRES%
echo.

if "%COUNT_AVANT%"=="%COUNT_APRES%" (
    echo ✅ SUCCES! Les donnees sont preservees
) else (
    echo ❌ ECHEC! Les donnees sont perdues
    echo.
    echo DIAGNOSTIC:
    echo - Base contient les donnees (verifie avec SQLite)
    echo - Mais Prisma ne les voit pas
    echo - Probleme de generation Prisma
)
echo.
pause
