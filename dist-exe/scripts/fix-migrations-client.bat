@echo off
:: =============================================================================
:: LOGESCO - Script de correction des migrations pour clients
:: =============================================================================
:: Ce script applique toutes les migrations manquantes de facon idempotente.
:: Safe a relancer plusieurs fois - n'applique que ce qui manque.
::
:: Usage : Double-cliquer sur ce fichier
:: =============================================================================

chcp 65001 >nul 2>&1
title LOGESCO - Correction des migrations

echo.
echo ============================================================
echo    LOGESCO - Correction des migrations
echo ============================================================
echo.

:: Trouver le dossier backend (plusieurs tentatives)
echo Recherche du dossier backend...
echo.

:: Tentative 1 : scripts est dans backend\scripts
cd /d "%~dp0.."
if exist "package.json" goto :backend_found

:: Tentative 2 : Chercher depuis AppData Local
cd /d "%LOCALAPPDATA%\LOGESCO\backend"
if exist "package.json" goto :backend_found

:: Tentative 3 : Chercher depuis Program Files
cd /d "%ProgramFiles%\LOGESCO\backend"
if exist "package.json" goto :backend_found

cd /d "%ProgramFiles(x86)%\LOGESCO\backend"
if exist "package.json" goto :backend_found

:: Tentative 4 : Chercher le dossier LOGESCO dans les lecteurs communs
for %%d in (C D E F) do (
    if exist "%%d:\LOGESCO\backend\package.json" (
        cd /d "%%d:\LOGESCO\backend"
        goto :backend_found
    )
    if exist "%%d:\Program Files\LOGESCO\backend\package.json" (
        cd /d "%%d:\Program Files\LOGESCO\backend"
        goto :backend_found
    )
)

:: Aucun dossier trouve
echo.
echo ERREUR: Impossible de trouver le dossier backend
echo.
echo Emplacements verifies:
echo   - %~dp0..
echo   - %LOCALAPPDATA%\LOGESCO\backend
echo   - %ProgramFiles%\LOGESCO\backend
echo   - Lecteurs C:, D:, E:, F:
echo.
echo Veuillez placer ce script dans le dossier:
echo   LOGESCO\backend\scripts\
echo.
pause
exit /b 1

:backend_found
echo [OK] Dossier backend trouve: %CD%
echo.

:: Trouver node.exe
set NODE_EXE=node.exe
if exist "%CD%\node.exe" (
    set NODE_EXE=%CD%\node.exe
    echo [OK] Node.js portable detecte
) else (
    where node >nul 2>&1
    if errorlevel 1 (
        echo ERREUR: Node.js introuvable
        pause
        exit /b 1
    )
    set NODE_EXE=node
    echo [OK] Node.js système detecte
)

echo.
echo ============================================================
echo    Arret du backend
echo ============================================================
echo.

:: Arrêter les processus en cours
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im logesco-backend.exe >nul 2>&1
taskkill /f /im logesco_v2.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [OK] Processus arretes
echo.

:: Application des migrations
echo ============================================================
echo    Application des migrations
echo ============================================================
echo.

:: Vérifier quel script de migration est disponible
if exist "scripts\auto-migrate.js" (
    echo Utilisation du script auto-migrate.js
    "%NODE_EXE%" scripts\auto-migrate.js
) else if exist "scripts\migrate-production.js" (
    echo Utilisation du script migrate-production.js
    "%NODE_EXE%" scripts\migrate-production.js
) else (
    echo ERREUR: Aucun script de migration trouve
    echo Fichiers recherches:
    echo   - scripts\auto-migrate.js
    echo   - scripts\migrate-production.js
    pause
    exit /b 1
)

set EXIT_CODE=%ERRORLEVEL%

echo.

if %EXIT_CODE% equ 0 (
    echo ============================================================
    echo    TERMINE AVEC SUCCES
    echo ============================================================
    echo.
    echo Les migrations ont ete appliquees.
    echo Vous pouvez maintenant relancer l'application LOGESCO.
) else (
    echo ============================================================
    echo    ERREUR
    echo ============================================================
    echo.
    echo Le script de migration a echoue.
    echo Contactez le support technique.
)

echo.
pause
