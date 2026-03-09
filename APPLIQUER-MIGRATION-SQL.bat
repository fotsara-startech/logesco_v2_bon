@echo off
setlocal enabledelayedexpansion
title Application Migration SQL
color 0E
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║        APPLICATION MIGRATION SQL MANUELLE              ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Ce script vous aide a appliquer une migration SQL
echo sur votre base de donnees.
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 1/4: VERIFICATION
echo ════════════════════════════════════════════════════════
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    echo    Chemin: backend\database\logesco.db
    echo.
    echo Vous devez etre dans le dossier d'installation LOGESCO.
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
echo   ETAPE 2/4: CHOIX DE LA MIGRATION
echo ════════════════════════════════════════════════════════
echo.

if not exist "backend\prisma\migrations" (
    echo ❌ Dossier migrations non trouve!
    pause
    exit /b 1
)

echo Migrations SQL disponibles:
echo.

set COUNT=0
for %%F in (backend\prisma\migrations\*.sql) do (
    set /a COUNT+=1
    echo [!COUNT!] %%~nxF
    set "MIGRATION_!COUNT!=%%F"
)

if %COUNT% EQU 0 (
    echo Aucune migration SQL trouvee.
    echo.
    pause
    exit /b 0
)

echo.
echo [0] Annuler
echo.
set /p CHOICE="Choisissez une migration (0-%COUNT%): "

if "%CHOICE%"=="0" (
    echo Migration annulee.
    pause
    exit /b 0
)

if %CHOICE% LSS 1 (
    echo Choix invalide.
    pause
    exit /b 1
)

if %CHOICE% GTR %COUNT% (
    echo Choix invalide.
    pause
    exit /b 1
)

set "SELECTED_MIGRATION=!MIGRATION_%CHOICE%!"
echo.
echo Migration selectionnee: %SELECTED_MIGRATION%
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 3/4: SAUVEGARDE
echo ════════════════════════════════════════════════════════
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=backend\database\logesco_backup_%TIMESTAMP%.db

echo Creation sauvegarde...
copy "backend\database\logesco.db" "%BACKUP_FILE%" >nul
if errorlevel 1 (
    echo ❌ Erreur sauvegarde!
    pause
    exit /b 1
)

echo ✅ Sauvegarde creee: %BACKUP_FILE%
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 4/4: APPLICATION MIGRATION
echo ════════════════════════════════════════════════════════
echo.

echo Contenu de la migration:
echo ────────────────────────────────────────────────────────
type "%SELECTED_MIGRATION%"
echo ────────────────────────────────────────────────────────
echo.
echo.
set /p CONFIRM="Appliquer cette migration? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo Migration annulee.
    pause
    exit /b 0
)

echo.
echo Application de la migration...
echo.

REM Vérifier si sqlite3 est disponible
where sqlite3 >nul 2>nul
if errorlevel 1 (
    echo.
    echo ⚠️  sqlite3 non trouve!
    echo.
    echo METHODE ALTERNATIVE:
    echo.
    echo 1. Telechargez DB Browser for SQLite:
    echo    https://sqlitebrowser.org/
    echo.
    echo 2. Ouvrez: backend\database\logesco.db
    echo.
    echo 3. Allez dans: Execute SQL
    echo.
    echo 4. Copiez le contenu de:
    echo    %SELECTED_MIGRATION%
    echo.
    echo 5. Collez et executez
    echo.
    echo 6. Sauvegardez
    echo.
    echo Ou utilisez un outil en ligne:
    echo https://sqliteonline.com/
    echo.
    pause
    exit /b 1
)

REM Appliquer la migration
sqlite3 "backend\database\logesco.db" < "%SELECTED_MIGRATION%" 2>nul
if errorlevel 1 (
    echo.
    echo ❌ Erreur lors de l'application!
    echo.
    echo Restauration de la sauvegarde...
    copy "%BACKUP_FILE%" "backend\database\logesco.db" >nul
    echo ✅ Sauvegarde restauree
    echo.
    echo Consultez le fichier SQL pour voir le probleme.
    pause
    exit /b 1
)

echo.
echo ✅ Migration appliquee avec succes!
echo.
pause
cls

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║           MIGRATION SQL APPLIQUEE                      ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo ✅ Migration: %SELECTED_MIGRATION%
echo ✅ Sauvegarde: %BACKUP_FILE%
echo.
echo 🚀 PROCHAINES ETAPES:
echo.
echo    1. Regenerez Prisma:
echo       cd backend
echo       npx prisma generate
echo       cd ..
echo.
echo    2. Demarrez l'application:
echo       DEMARRER-LOGESCO.bat
echo.
echo    3. Testez les nouvelles fonctionnalites
echo.
echo 📁 SAUVEGARDE:
echo    Si probleme, restaurez avec:
echo    copy "%BACKUP_FILE%" "backend\database\logesco.db"
echo.
pause
