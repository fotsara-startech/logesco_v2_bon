@echo off
title Migration VISIBLE
color 0B
echo ========================================
echo   MIGRATION VISIBLE
echo   Toutes les etapes affichees
echo ========================================
echo.
pause

echo.
echo [1] Verification emplacement
echo =============================
echo.
echo Dossier: %CD%
echo.
set /p CONFIRM="C'est le dossier d'installation? (O/N): "
if /i not "%CONFIRM%"=="O" exit /b 0
echo.

echo [2] Recherche base
echo ===================
echo.
if not exist "backend\database\logesco.db" (
    echo Erreur: Base non trouvee!
    pause
    exit /b 1
)
echo Base: backend\database\logesco.db
for %%A in ("backend\database\logesco.db") do echo Taille: %%~zA octets
echo.
pause

echo [3] Recherche package
echo ======================
echo.
set "PACKAGE_PATH="
if exist "LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=LOGESCO-Client-CORRIGE"
    echo Package CORRIGE trouve
) else if exist "Package-Mise-A-Jour\LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-CORRIGE"
    echo Package CORRIGE trouve
) else if exist "LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=LOGESCO-Client-Optimise"
    echo Package OPTIMISE trouve (ancien)
) else (
    echo Erreur: Aucun package trouve!
    pause
    exit /b 1
)
echo Package: %PACKAGE_PATH%
echo.
pause

echo [4] Sauvegarde
echo ===============
echo.
set BACKUP=sauvegarde_migration_visible
if exist "%BACKUP%" rmdir /s /q "%BACKUP%"
mkdir "%BACKUP%"
copy "backend\database\logesco.db" "%BACKUP%\logesco.db" >nul
echo Sauvegarde: %BACKUP%
echo.
pause

echo [5] Installation
echo =================
echo.
echo Arret processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo.

echo Sauvegarde ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien"
ren "backend" "backend_ancien"
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

echo Copie app...
if exist "app_ancien" rmdir /s /q "app_ancien"
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\"
echo.
pause

echo [6] GENERATION PRISMA (CRITIQUE)
echo ==================================
echo.
echo Cette etape est CRITIQUE!
echo Prisma doit etre genere avec VOTRE base.
echo.
echo Generation en cours (10-15 secondes)...
echo.

cd backend
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ERREUR generation Prisma!
    echo.
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo Generation terminee
echo.
pause

echo [7] Test
echo ========
echo.
echo Comptage avec Prisma...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('Produits:',c)).catch(e=>console.log('ERREUR:',e.message)).finally(()=>p.$disconnect())"
cd ..
echo.

echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
echo.
echo Si vous voyez "Produits: 165" ci-dessus:
echo   Migration reussie!
echo.
echo Si vous voyez "Produits: 0":
echo   Probleme persiste
echo.
echo Lancez: DEMARRER-LOGESCO.bat
echo.
pause
