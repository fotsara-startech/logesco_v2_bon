@echo off
setlocal enabledelayedexpansion
title Migration vers Package CORRIGE
color 0B
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║          MIGRATION VERS PACKAGE CORRIGE                ║
echo ║          Solution Universelle                          ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Ce script migre TOUT type de client vers le package CORRIGE:
echo   - CORRIGE    --^> CORRIGE (mise a jour)
echo   - OPTIMISE   --^> CORRIGE
echo   - ULTIMATE   --^> CORRIGE
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 1/7: VERIFICATION EMPLACEMENT
echo ════════════════════════════════════════════════════════
echo.
echo Dossier actuel: %CD%
echo.
echo IMPORTANT: Vous devez etre dans le dossier CLIENT
echo (celui qui contient vos donnees)
echo.
echo PAS dans le dossier du package!
echo.
set /p CONFIRM="Vous etes dans le dossier CLIENT? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo Migration annulee.
    pause
    exit /b 0
)
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 2/7: VERIFICATION BASE DE DONNEES
echo ════════════════════════════════════════════════════════
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    echo    Chemin: backend\database\logesco.db
    echo.
    echo Vous n'etes pas dans un dossier client valide.
    pause
    exit /b 1
)

echo ✅ Base de donnees trouvee
for %%A in ("backend\database\logesco.db") do echo    Taille: %%~zA octets
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 3/7: RECHERCHE PACKAGE CORRIGE
echo ════════════════════════════════════════════════════════
echo.

set "PACKAGE_PATH="
set "PACKAGE_FOUND=0"

echo Recherche du package CORRIGE...
echo.

REM Chercher dans le meme dossier (cas: LOGESCO-Client-CORRIGE/LOGESCO-Client-CORRIGE)
if exist "LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: .\LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Chercher dans le dossier parent
if exist "..\LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=..\LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: ..\LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Chercher dans Package-Mise-A-Jour
if exist "Package-Mise-A-Jour\LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: Package-Mise-A-Jour\LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Chercher dans release
if exist "release\LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=release\LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: release\LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Chercher dans le dossier courant (si on est deja dans un sous-dossier)
if exist "..\backend" (
    REM Verifier qu'on n'est pas deja dans le client actuel
    if exist "..\DEMARRER-LOGESCO.bat" (
        if exist "backend" (
            set "PACKAGE_PATH=."
            set "PACKAGE_FOUND=1"
            echo ✅ Package trouve: . (dossier actuel)
            goto :package_found
        )
    )
)

echo ❌ Package CORRIGE non trouve!
echo.
echo Dossier actuel: %CD%
echo.
echo Le package doit contenir un sous-dossier "backend".
echo.
echo Emplacements cherches:
echo   - .\LOGESCO-Client-CORRIGE\backend
echo   - ..\LOGESCO-Client-CORRIGE\backend
echo   - Package-Mise-A-Jour\LOGESCO-Client-CORRIGE\backend
echo   - release\LOGESCO-Client-CORRIGE\backend
echo.
echo INSTRUCTIONS:
echo.
echo 1. Vous devez etre dans le dossier CLIENT (celui avec vos donnees)
echo 2. Placez le package CORRIGE dans un de ces emplacements:
echo.
echo    Option A (RECOMMANDE):
echo    Copiez le dossier LOGESCO-Client-CORRIGE ici:
echo    %CD%\LOGESCO-Client-CORRIGE
echo.
echo    Option B:
echo    Copiez-le dans le dossier parent:
echo    %CD%\..\LOGESCO-Client-CORRIGE
echo.
echo 3. Relancez ce script
echo.
pause
exit /b 1

:package_found
echo.

REM VERIFICATION CRITIQUE: Le package ne doit PAS contenir de base vierge
echo.
echo ════════════════════════════════════════════════════════
echo   VERIFICATION CRITIQUE DU PACKAGE
echo ════════════════════════════════════════════════════════
echo.

if exist "%PACKAGE_PATH%\backend\database\logesco.db" (
    echo ⚠️  ATTENTION: Le package contient une base de donnees!
    echo.
    echo Verification de la base...
    for %%A in ("%PACKAGE_PATH%\backend\database\logesco.db") do set DB_SIZE=%%~zA
    echo Taille: !DB_SIZE! octets
    echo.
    
    if !DB_SIZE! LSS 100000 (
        echo ❌ ERREUR: Base vierge detectee dans le package!
        echo.
        echo Le package CORRIGE ne doit PAS contenir de base de donnees.
        echo Cette base vierge ecraserait vos donnees!
        echo.
        echo SOLUTION:
        echo 1. Supprimez: %PACKAGE_PATH%\backend\database\logesco.db
        echo 2. Relancez ce script
        echo.
        echo Ou regenerez le package avec: preparer-pour-client-CORRIGE.bat
        echo.
        pause
        exit /b 1
    ) else (
        echo ⚠️  Base volumineuse detectee (^>100KB^)
        echo.
        set /p CONTINUE="Continuer quand meme? (O/N): "
        if /i not "!CONTINUE!"=="O" (
            echo Migration annulee.
            pause
            exit /b 0
        )
    )
) else (
    echo ✅ Package correct: Pas de base vierge
)

echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 4/7: SAUVEGARDE COMPLETE
echo ════════════════════════════════════════════════════════
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_migration_%TIMESTAMP%

echo Creation sauvegarde: %BACKUP_DIR%
mkdir "%BACKUP_DIR%"

echo.
echo [1/3] Sauvegarde base de donnees...
copy "backend\database\logesco.db" "%BACKUP_DIR%\logesco.db" >nul
if errorlevel 1 (
    echo ❌ Erreur sauvegarde base!
    pause
    exit /b 1
)
echo       ✅ Base sauvegardee

echo [2/3] Sauvegarde configuration...
if exist "backend\.env" copy "backend\.env" "%BACKUP_DIR%\.env" >nul
echo       ✅ Configuration sauvegardee

echo [3/3] Sauvegarde uploads...
if exist "backend\uploads" xcopy /E /I /Y /Q "backend\uploads" "%BACKUP_DIR%\uploads" >nul 2>nul
echo       ✅ Uploads sauvegardes
echo.
echo ✅ Sauvegarde complete: %BACKUP_DIR%
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 5/7: INSTALLATION NOUVEAU BACKEND
echo ════════════════════════════════════════════════════════
echo.

echo [1/5] Arret des processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo       ✅ Processus arretes

echo [2/5] Sauvegarde ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien" 2>nul
ren "backend" "backend_ancien"
echo       ✅ Ancien backend sauvegarde

echo [3/5] Copie nouveau backend...
xcopy /E /I /Y /Q "%PACKAGE_PATH%\backend" "backend\" >nul
if errorlevel 1 (
    echo       ❌ Erreur copie backend!
    echo.
    echo Restauration...
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo       ✅ Nouveau backend copie

echo [4/5] Suppression base vierge du package (si presente)...
if exist "backend\database\logesco.db" (
    for %%A in ("backend\database\logesco.db") do set NEW_DB_SIZE=%%~zA
    echo       ⚠️  Base detectee dans nouveau backend (!NEW_DB_SIZE! octets)
    
    REM Si la base est petite (< 100KB), c'est probablement une base vierge
    if !NEW_DB_SIZE! LSS 100000 (
        echo       ⚠️  Base vierge detectee - Suppression...
        del /f /q "backend\database\logesco.db" 2>nul
        if exist "backend\database\logesco.db" (
            echo       ❌ Impossible de supprimer la base vierge!
            echo.
            echo Restauration...
            rmdir /s /q "backend" 2>nul
            ren "backend_ancien" "backend"
            pause
            exit /b 1
        )
        echo       ✅ Base vierge supprimee
    ) else (
        echo       ⚠️  Base volumineuse - Conservation
    )
) else (
    echo       ✅ Pas de base vierge (correct)
)

REM Supprimer fichiers temporaires SQLite
if exist "backend\database\logesco.db-shm" del /f /q "backend\database\logesco.db-shm" 2>nul
if exist "backend\database\logesco.db-wal" del /f /q "backend\database\logesco.db-wal" 2>nul

if not exist "backend\database" mkdir "backend\database"

echo [5/5] Restauration de VOTRE base...
copy "%BACKUP_DIR%\logesco.db" "backend\database\logesco.db" >nul
if errorlevel 1 (
    echo       ❌ Erreur restauration base!
    echo.
    echo Restauration complete...
    rmdir /s /q "backend" 2>nul
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
for %%A in ("backend\database\logesco.db") do echo       ✅ Base restauree (%%~zA octets)

echo.
echo [6/5] Installation nouvelle app...
if exist "app_ancien" rmdir /s /q "app_ancien" 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo       ✅ App installee

echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 6/7: GENERATION PRISMA (CRITIQUE!)
echo ════════════════════════════════════════════════════════
echo.
echo Cette etape est CRITIQUE pour que vos donnees soient visibles.
echo.
echo Prisma va etre genere avec VOTRE base de donnees.
echo.
echo Generation en cours (10-20 secondes)...
echo.

cd backend

REM Supprimer tout ancien Prisma
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul

REM Generer Prisma
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ❌ Erreur generation Prisma!
    echo.
    echo Tentative avec db pull...
    call npx prisma db pull
    call npx prisma generate
    if errorlevel 1 (
        echo.
        echo ❌ Echec generation Prisma!
        echo.
        cd ..
        pause
        exit /b 1
    )
)

cd ..

echo.
echo ✅ Prisma genere avec votre base
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 7/7: VERIFICATION
echo ════════════════════════════════════════════════════════
echo.

echo Test de comptage avec Prisma...
echo.
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>console.log('Produits:',c)).catch(e=>console.log('ERREUR:',e.message)).finally(()=>p.$disconnect())"
cd ..

echo.
pause
cls

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║              MIGRATION TERMINEE                        ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo ✅ Migration vers package CORRIGE terminee!
echo.
echo 📁 SAUVEGARDES:
echo    - Donnees: %BACKUP_DIR%\
echo    - Ancien backend: backend_ancien\
echo    - Ancienne app: app_ancien\
echo.
echo 🚀 PROCHAINES ETAPES:
echo    1. Lancez: DEMARRER-LOGESCO.bat
echo    2. Connectez-vous: admin / admin123
echo    3. Verifiez que vos donnees s'affichent
echo.
echo ℹ️  PREMIERE UTILISATION:
echo    Le demarrage peut prendre 15-20 secondes
echo    (generation Prisma au premier lancement)
echo.
echo    Utilisations suivantes: 7-9 secondes
echo.
echo 📊 Si vous voyez "Produits: X" ci-dessus avec X ^> 0:
echo    ✅ Migration reussie!
echo.
echo    Si vous voyez "Produits: 0":
echo    ⚠️  Executez: REGENERER-PRISMA-SIMPLE.bat
echo.
pause
