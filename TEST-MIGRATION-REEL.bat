@echo off
title Test Migration Reel
color 0E
echo ========================================
echo   TEST MIGRATION REEL
echo ========================================
echo.
echo Ce script teste une VRAIE migration:
echo - Depuis un client avec donnees
echo - Vers le package CORRIGE
echo.
pause

echo.
echo [1] Ou etes-vous?
echo ==================
echo.
echo Dossier actuel: %CD%
echo.
echo Vous devez etre dans le dossier CLIENT
echo (celui qui a des donnees, pas le package)
echo.
echo Exemple:
echo   BON: E:\Stage 2025\LOGESCO-Client-Optimise
echo   MAUVAIS: E:\Stage 2025\LOGESCO-Client-CORRIGE
echo.
set /p CONFIRM="Vous etes dans le dossier CLIENT? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo Allez dans le dossier CLIENT puis relancez.
    pause
    exit /b 0
)
echo.

echo [2] Verification base
echo ======================
echo.
if not exist "backend\database\logesco.db" (
    echo Erreur: Pas de base!
    echo Vous n'etes pas dans un dossier client valide.
    pause
    exit /b 1
)
echo Base: backend\database\logesco.db
for %%A in ("backend\database\logesco.db") do echo Taille: %%~zA octets
echo.

echo Comptage AVANT migration...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('AVANT:',c)).catch(e=>console.log('ERREUR:',e.message)).finally(()=>p.$disconnect())"
cd ..
echo.
pause

echo [3] Ou est le package CORRIGE?
echo ================================
echo.
echo Le package doit etre:
echo - Dans le meme dossier parent
echo - Ou dans un sous-dossier ici
echo.

set "PACKAGE_PATH="

REM Chercher dans le dossier parent
if exist "..\LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=..\LOGESCO-Client-CORRIGE"
    echo Trouve: ..\LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Chercher ici
if exist "LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=LOGESCO-Client-CORRIGE"
    echo Trouve: LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Chercher dans Package-Mise-A-Jour
if exist "Package-Mise-A-Jour\LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-CORRIGE"
    echo Trouve: Package-Mise-A-Jour\LOGESCO-Client-CORRIGE
    goto :package_found
)

echo Erreur: Package CORRIGE non trouve!
echo.
echo Copiez le package ici ou dans le dossier parent.
echo.
pause
exit /b 1

:package_found
echo.
echo Package: %PACKAGE_PATH%
echo.
pause

echo [4] Sauvegarde
echo ===============
echo.
set BACKUP=test_migration_backup
if exist "%BACKUP%" rmdir /s /q "%BACKUP%"
mkdir "%BACKUP%"
copy "backend\database\logesco.db" "%BACKUP%\logesco.db" >nul
echo Sauvegarde: %BACKUP%
echo.
pause

echo [5] Migration
echo ==============
echo.
echo Arret processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo.

echo Sauvegarde ancien backend...
if exist "backend_test_ancien" rmdir /s /q "backend_test_ancien"
ren "backend" "backend_test_ancien"
echo.

echo Copie nouveau backend...
xcopy /E /I /Y /Q "%PACKAGE_PATH%\backend" "backend\"
echo.

echo Suppression base vierge...
if exist "backend\database\logesco.db" del /f /q "backend\database\logesco.db"
if not exist "backend\database" mkdir "backend\database"
echo.

echo Restauration VOTRE base...
copy "%BACKUP%\logesco.db" "backend\database\logesco.db" >nul
for %%A in ("backend\database\logesco.db") do echo Taille: %%~zA octets
echo.
pause

echo [6] GENERATION PRISMA
echo ======================
echo.
echo Generation (10-15 secondes)...
echo.

cd backend
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
echo Generation OK
echo.
pause

echo [7] Verification
echo =================
echo.
echo Comptage APRES migration...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('APRES:',c)).catch(e=>console.log('ERREUR:',e.message)).finally(()=>p.$disconnect())"
cd ..
echo.

echo ========================================
echo   RESULTAT
echo ========================================
echo.
echo Regardez les lignes AVANT et APRES.
echo.
echo Si identiques: Migration reussie!
echo Si differentes: Migration echouee!
echo.
echo Pour restaurer:
echo   rmdir /s /q backend
echo   ren backend_test_ancien backend
echo.
pause
