@echo off
:: =============================================================================
:: LOGESCO - Script de correction des migrations (VERSION AUTONOME)
:: =============================================================================
:: Ce script peut etre place N'IMPORTE OU sur le PC du client
:: Il cherche automatiquement l'installation LOGESCO
::
:: Usage : Double-cliquer sur ce fichier depuis n'importe ou
:: =============================================================================

chcp 65001 >nul 2>&1
title LOGESCO - Correction des migrations

echo.
echo ============================================================
echo    LOGESCO - Correction des migrations
echo ============================================================
echo.
echo Recherche automatique de l'installation LOGESCO...
echo.

set BACKEND_DIR=
set FOUND=0

:: Tentative 1 : AppData Local (installation par defaut)
if exist "%LOCALAPPDATA%\LOGESCO\backend\package.json" (
    set BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend
    set FOUND=1
    echo [OK] Trouve dans: %LOCALAPPDATA%\LOGESCO\backend
    goto :backend_found
)

:: Tentative 2 : Program Files
if exist "%ProgramFiles%\LOGESCO\backend\package.json" (
    set BACKEND_DIR=%ProgramFiles%\LOGESCO\backend
    set FOUND=1
    echo [OK] Trouve dans: %ProgramFiles%\LOGESCO\backend
    goto :backend_found
)

if exist "%ProgramFiles(x86)%\LOGESCO\backend\package.json" (
    set BACKEND_DIR=%ProgramFiles(x86)%\LOGESCO\backend
    set FOUND=1
    echo [OK] Trouve dans: %ProgramFiles(x86)%\LOGESCO\backend
    goto :backend_found
)

:: Tentative 3 : Dossier du script
cd /d "%~dp0"
if exist "package.json" (
    set BACKEND_DIR=%CD%
    set FOUND=1
    echo [OK] Trouve dans: %CD%
    goto :backend_found
)

cd /d "%~dp0backend"
if exist "package.json" (
    set BACKEND_DIR=%CD%
    set FOUND=1
    echo [OK] Trouve dans: %CD%
    goto :backend_found
)

cd /d "%~dp0..\backend"
if exist "package.json" (
    set BACKEND_DIR=%CD%
    set FOUND=1
    echo [OK] Trouve dans: %CD%
    goto :backend_found
)

:: Tentative 4 : Recherche sur tous les lecteurs
echo Recherche approfondie sur les disques...
for %%d in (C D E F G) do (
    if exist "%%d:\LOGESCO\backend\package.json" (
        set BACKEND_DIR=%%d:\LOGESCO\backend
        set FOUND=1
        echo [OK] Trouve dans: %%d:\LOGESCO\backend
        goto :backend_found
    )
    if exist "%%d:\Program Files\LOGESCO\backend\package.json" (
        set BACKEND_DIR=%%d:\Program Files\LOGESCO\backend
        set FOUND=1
        echo [OK] Trouve dans: %%d:\Program Files\LOGESCO\backend
        goto :backend_found
    )
)

:: Non trouve - demander a l'utilisateur
echo.
echo Installation LOGESCO non trouvee automatiquement.
echo.
echo Emplacements verifies:
echo   - %LOCALAPPDATA%\LOGESCO\backend
echo   - %ProgramFiles%\LOGESCO\backend
echo   - Lecteurs C:, D:, E:, F:, G:
echo.
set /p BACKEND_DIR=Entrez le chemin complet du dossier backend (ou Q pour quitter): 
if /i "%BACKEND_DIR%"=="Q" exit /b 1
if not exist "%BACKEND_DIR%\package.json" (
    echo.
    echo ERREUR: Le fichier package.json n'existe pas dans: %BACKEND_DIR%
    echo Verifiez le chemin et reessayez.
    pause
    exit /b 1
)

:backend_found
echo.
cd /d "%BACKEND_DIR%"

:: Trouver node.exe
set NODE_EXE=node.exe
echo Recherche de Node.js...
if exist "%BACKEND_DIR%\node.exe" (
    set NODE_EXE=%BACKEND_DIR%\node.exe
    echo [OK] Node.js portable detecte: %BACKEND_DIR%\node.exe
) else (
    where node >nul 2>&1
    if errorlevel 1 (
        echo.
        echo ERREUR: Node.js introuvable
        echo.
        echo Node.js n'est pas installe ou n'est pas dans le PATH.
        echo Verifiez que LOGESCO est bien installe.
        pause
        exit /b 1
    )
    set NODE_EXE=node
    for /f "tokens=*" %%i in ('where node') do set NODE_PATH=%%i
    echo [OK] Node.js systeme detecte: %NODE_PATH%
)

:: Verifier le script de migration
set MIGRATE_SCRIPT=
if exist "%BACKEND_DIR%\scripts\auto-migrate.js" (
    set MIGRATE_SCRIPT=%BACKEND_DIR%\scripts\auto-migrate.js
    echo [OK] Script de migration trouve: auto-migrate.js
) else if exist "%BACKEND_DIR%\scripts\migrate-production.js" (
    set MIGRATE_SCRIPT=%BACKEND_DIR%\scripts\migrate-production.js
    echo [OK] Script de migration trouve: migrate-production.js
) else (
    echo.
    echo ERREUR: Aucun script de migration trouve
    echo Chemins verifies:
    echo   - %BACKEND_DIR%\scripts\auto-migrate.js
    echo   - %BACKEND_DIR%\scripts\migrate-production.js
    echo.
    echo Verifiez que vous avez la derniere version de LOGESCO.
    pause
    exit /b 1
)
echo.

:: Arreter le backend
echo ============================================================
echo    Arret du backend
echo ============================================================
echo.

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

"%NODE_EXE%" "%MIGRATE_SCRIPT%"
set EXIT_CODE=%ERRORLEVEL%

echo.

if %EXIT_CODE% equ 0 (
    echo ============================================================
    echo    TERMINE AVEC SUCCES
    echo ============================================================
    echo.
    echo Les migrations ont ete appliquees avec succes.
    echo Vous pouvez maintenant relancer l'application LOGESCO.
    echo.
) else (
    echo ============================================================
    echo    ERREUR
    echo ============================================================
    echo.
    echo Le script de migration a echoue avec le code: %EXIT_CODE%
    echo.
    echo Contactez le support technique avec cette information:
    echo   - Dossier backend: %BACKEND_DIR%
    echo   - Code erreur: %EXIT_CODE%
    echo   - Node.js: %NODE_EXE%
    echo.
)

pause
