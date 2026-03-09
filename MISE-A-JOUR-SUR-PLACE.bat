@echo off
title Mise a Jour Sur Place
color 0A
echo ========================================
echo   MISE A JOUR SUR PLACE
echo   (Meme package, version plus recente)
echo ========================================
echo.
echo Ce script met a jour un client CORRIGE
echo vers une version plus recente du package CORRIGE.
echo.
pause

echo.
echo [1] Verification
echo =================
echo.
echo Dossier: %CD%
echo.

if not exist "backend\database\logesco.db" (
    echo Erreur: Pas de base!
    pause
    exit /b 1
)

echo Base: backend\database\logesco.db
for %%A in ("backend\database\logesco.db") do echo Taille: %%~zA octets
echo.

echo Comptage AVANT...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('AVANT:',c)).catch(e=>console.log('ERREUR')).finally(()=>p.$disconnect())"
cd ..
echo.
pause

echo.
echo [2] Sauvegarde complete
echo ========================
echo.

set BACKUP=backup_mise_a_jour
if exist "%BACKUP%" rmdir /s /q "%BACKUP%"
mkdir "%BACKUP%"

echo Sauvegarde base...
copy "backend\database\logesco.db" "%BACKUP%\logesco.db" >nul

echo Sauvegarde .env...
if exist "backend\.env" copy "backend\.env" "%BACKUP%\.env" >nul

echo Sauvegarde uploads...
if exist "backend\uploads" xcopy /E /I /Y /Q "backend\uploads" "%BACKUP%\uploads" >nul 2>nul

echo Sauvegarde: %BACKUP%
echo.
pause

echo.
echo [3] Arret processus
echo ====================
echo.
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo OK
echo.

echo.
echo [4] Regeneration Prisma
echo ========================
echo.
echo Suppression ancien Prisma...
cd backend
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul
echo.

echo Generation avec votre base...
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ERREUR generation!
    cd ..
    pause
    exit /b 1
)
cd ..
echo.
echo OK
echo.
pause

echo.
echo [5] Verification
echo =================
echo.
echo Comptage APRES...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('APRES:',c)).catch(e=>console.log('ERREUR')).finally(()=>p.$disconnect())"
cd ..
echo.

echo ========================================
echo   TERMINE
echo ========================================
echo.
echo Regardez AVANT et APRES.
echo.
echo Si identiques: Mise a jour reussie!
echo.
pause
