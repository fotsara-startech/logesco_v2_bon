@echo off
title Diagnostic Simple
color 0E
echo.
echo ========================================
echo   DIAGNOSTIC SIMPLE
echo ========================================
echo.
echo Ce script va identifier le probleme.
echo.
pause

echo.
echo [1] Verification base actuelle
echo ================================
echo.

if not exist "backend\database\logesco.db" (
    echo Erreur: Pas de base de donnees!
    pause
    exit /b 1
)

echo Base trouvee: backend\database\logesco.db
echo.

REM Taille
for %%A in ("backend\database\logesco.db") do echo Taille: %%~zA octets
echo.

REM Compter avec Prisma AVANT
echo Comptage Prisma AVANT...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('AVANT:',c)).catch(e=>console.log('ERREUR:',e.message)).finally(()=>p.$disconnect())"
cd ..
echo.
pause

echo.
echo [2] Sauvegarde
echo ==============
echo.

set BACKUP=diagnostic_backup
if exist "%BACKUP%" rmdir /s /q "%BACKUP%"
mkdir "%BACKUP%"
copy "backend\database\logesco.db" "%BACKUP%\logesco.db" >nul
echo Sauvegarde: %BACKUP%\logesco.db
echo.
pause

echo.
echo [3] Suppression Prisma
echo ======================
echo.

cd backend
if exist "node_modules\.prisma" (
    rmdir /s /q "node_modules\.prisma"
    echo .prisma supprime
)
if exist "node_modules\@prisma\client" (
    rmdir /s /q "node_modules\@prisma\client"
    echo @prisma/client supprime
)
cd ..
echo.
pause

echo.
echo [4] Suppression et restauration base
echo =====================================
echo.

del /f /q "backend\database\logesco.db"
echo Base supprimee
echo.

copy "%BACKUP%\logesco.db" "backend\database\logesco.db" >nul
echo Base restauree
echo.

for %%A in ("backend\database\logesco.db") do echo Taille apres copie: %%~zA octets
echo.
pause

echo.
echo [5] Generation Prisma
echo =====================
echo.
echo Generation en cours (10-15 secondes)...
echo.

cd backend
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ERREUR generation Prisma!
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo Generation terminee
echo.
pause

echo.
echo [6] Verification APRES
echo ======================
echo.

echo Comptage Prisma APRES...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('APRES:',c)).catch(e=>console.log('ERREUR:',e.message)).finally(()=>p.$disconnect())"
cd ..
echo.

echo.
echo ========================================
echo   RESULTAT
echo ========================================
echo.
echo Regardez les lignes AVANT et APRES ci-dessus.
echo.
echo Si AVANT = APRES : Migration fonctionne
echo Si AVANT != APRES : Migration echoue
echo.
echo Copiez-moi ces 2 lignes!
echo.
pause
