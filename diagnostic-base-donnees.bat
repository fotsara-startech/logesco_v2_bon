@echo off
title LOGESCO - Diagnostic Base de Donnees
echo ========================================
echo   Diagnostic Base de Donnees
echo ========================================
echo.

echo [1/3] Recherche fichiers base de donnees...
echo.

REM Chercher tous les fichiers .db
echo Fichiers .db trouves:
dir /s /b *.db 2>nul
echo.

echo [2/3] Verification dossier backend...
echo.

if exist "backend\database" (
    echo ✅ Dossier backend\database existe
    dir /b backend\database\*.db 2>nul
    if errorlevel 1 (
        echo    ⚠️  Aucun fichier .db dans backend\database
    )
) else (
    echo ❌ Dossier backend\database n'existe pas
)

if exist "database" (
    echo ✅ Dossier database existe (racine)
    dir /b database\*.db 2>nul
    if errorlevel 1 (
        echo    ⚠️  Aucun fichier .db dans database
    )
) else (
    echo ⚠️  Dossier database n'existe pas (racine)
)

echo.
echo [3/3] Verification fichier .env...
echo.

if exist "backend\.env" (
    echo ✅ Fichier backend\.env existe
    echo    Contenu DATABASE_URL:
    findstr /C:"DATABASE_URL" backend\.env
) else (
    echo ❌ Fichier backend\.env n'existe pas
)

if exist ".env" (
    echo ✅ Fichier .env existe (racine)
    echo    Contenu DATABASE_URL:
    findstr /C:"DATABASE_URL" .env
) else (
    echo ⚠️  Fichier .env n'existe pas (racine)
)

echo.
echo ========================================
echo   Diagnostic termine
echo ========================================
echo.
pause
