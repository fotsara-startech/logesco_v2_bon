@echo off
title LOGESCO - Sauvegarde Donnees Client
echo ========================================
echo   SAUVEGARDE DONNEES CLIENT EXISTANT
echo ========================================
echo.

echo Ce script sauvegarde toutes les donnees
echo du client avant la mise a jour.
echo.
echo IMPORTANT: Cette etape est OBLIGATOIRE
echo avant toute mise a jour!
echo.
pause
echo.

REM Créer le dossier de sauvegarde avec timestamp
set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_client_%TIMESTAMP%

echo [1/6] Creation du dossier de sauvegarde...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
echo ✅ Dossier cree: %BACKUP_DIR%
echo.

echo [2/6] Sauvegarde de la base de donnees...
if exist "backend\database\logesco.db" (
    copy "backend\database\logesco.db" "%BACKUP_DIR%\logesco_original.db" >nul
    echo ✅ Base de donnees sauvegardee
    
    REM Obtenir la taille du fichier
    for %%A in ("backend\database\logesco.db") do echo    Taille: %%~zA octets
) else (
    echo ❌ Base de donnees non trouvee: backend\database\logesco.db
    echo Verifiez le chemin d'installation
    pause
    exit /b 1
)
echo.

echo [3/6] Export des donnees en SQL...
if exist "backend\database\logesco.db" (
    REM Utiliser sqlite3 si disponible
    where sqlite3 >nul 2>nul
    if not errorlevel 1 (
        echo Export du schema...
        sqlite3 "backend\database\logesco.db" ".schema" > "%BACKUP_DIR%\schema_original.sql"
        echo Export des donnees...
        sqlite3 "backend\database\logesco.db" ".dump" > "%BACKUP_DIR%\donnees_completes.sql"
        echo ✅ Export SQL termine
    ) else (
        echo ⚠️ sqlite3 non disponible, sauvegarde fichier uniquement
    )
) else (
    echo ❌ Impossible d'exporter les donnees
)
echo.

echo [4/6] Sauvegarde des fichiers de configuration...
if exist "backend\.env" (
    copy "backend\.env" "%BACKUP_DIR%\.env_original" >nul
    echo ✅ Configuration .env sauvegardee
)

if exist "backend\package.json" (
    copy "backend\package.json" "%BACKUP_DIR%\package_original.json" >nul
    echo ✅ Package.json sauvegarde
)
echo.

echo [5/6] Sauvegarde des uploads et logs...
if exist "backend\uploads" (
    xcopy /E /I /Y /Q "backend\uploads" "%BACKUP_DIR%\uploads" >nul 2>nul
    echo ✅ Dossier uploads sauvegarde
)

if exist "backend\logs" (
    xcopy /E /I /Y /Q "backend\logs" "%BACKUP_DIR%\logs" >nul 2>nul
    echo ✅ Dossier logs sauvegarde
)
echo.

echo [6/6] Creation du rapport de sauvegarde...
(
echo RAPPORT DE SAUVEGARDE LOGESCO
echo ==============================
echo Date: %date% %time%
echo Dossier: %BACKUP_DIR%
echo.
echo FICHIERS SAUVEGARDES:
echo - logesco_original.db ^(Base de donnees principale^)
echo - schema_original.sql ^(Structure de la BD^)
echo - donnees_completes.sql ^(Export complet^)
echo - .env_original ^(Configuration backend^)
echo - package_original.json ^(Dependances^)
echo - uploads\ ^(Fichiers utilisateur^)
echo - logs\ ^(Journaux systeme^)
echo.
echo INSTRUCTIONS RESTAURATION:
echo 1. Copier logesco_original.db vers backend\database\logesco.db
echo 2. Copier .env_original vers backend\.env
echo 3. Restaurer les dossiers uploads et logs
echo.
echo IMPORTANT: Conservez ce dossier jusqu'a validation
echo complete de la mise a jour!
) > "%BACKUP_DIR%\RAPPORT_SAUVEGARDE.txt"

echo ✅ Rapport cree
echo.

REM Calculer la taille totale de la sauvegarde
echo Calcul de la taille de sauvegarde...
for /f %%i in ('dir "%BACKUP_DIR%" /s /-c ^| find "bytes"') do set BACKUP_SIZE=%%i

echo ========================================
echo   SAUVEGARDE TERMINEE AVEC SUCCES
echo ========================================
echo.
echo 📁 Dossier: %BACKUP_DIR%
echo 📊 Taille: %BACKUP_SIZE% octets
echo 📋 Rapport: %BACKUP_DIR%\RAPPORT_SAUVEGARDE.txt
echo.
echo FICHIERS SAUVEGARDES:
echo ✅ Base de donnees principale
echo ✅ Export SQL complet
echo ✅ Configuration backend
echo ✅ Fichiers utilisateur
echo ✅ Journaux systeme
echo.
echo PROCHAINES ETAPES:
echo 1. Conservez ce dossier de sauvegarde
echo 2. Executez: migrer-client-existant.bat
echo 3. En cas de probleme: restaurer-ancienne-version.bat
echo.
echo ⚠️ NE SUPPRIMEZ PAS ce dossier avant validation
echo complete de la mise a jour!
echo.
pause