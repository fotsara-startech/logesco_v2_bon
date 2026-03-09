@echo off
setlocal enabledelayedexpansion
title Trouver Base de Donnees
color 0E
echo ========================================
echo   TROUVER LA BASE DE DONNEES
echo ========================================
echo.

echo Recherche de logesco.db...
echo.

set "DB_FOUND=0"
set "DB_PATH="

echo [1] Dans backend\database\:
if exist "backend\database\logesco.db" (
    for %%A in ("backend\database\logesco.db") do set SIZE1=%%~zA
    echo ✅ Trouvee: !SIZE1! octets
    set "DB_FOUND=1"
    set "DB_PATH=backend\database\logesco.db"
) else (
    echo ❌ Non trouvee
)
echo.

echo [2] Dans backend\:
if exist "backend\logesco.db" (
    for %%A in ("backend\logesco.db") do set SIZE2=%%~zA
    echo ✅ Trouvee: !SIZE2! octets
    set "DB_FOUND=1"
    set "DB_PATH=backend\logesco.db"
) else (
    echo ❌ Non trouvee
)
echo.

echo [3] Dans backend\prisma\:
if exist "backend\prisma\logesco.db" (
    for %%A in ("backend\prisma\logesco.db") do set SIZE3=%%~zA
    echo ✅ Trouvee: !SIZE3! octets
    set "DB_FOUND=1"
    set "DB_PATH=backend\prisma\logesco.db"
) else (
    echo ❌ Non trouvee
)
echo.

echo [4] Dans backend\prisma\database\:
if exist "backend\prisma\database\logesco.db" (
    for %%A in ("backend\prisma\database\logesco.db") do set SIZE4=%%~zA
    echo ✅ Trouvee: !SIZE4! octets
    set "DB_FOUND=1"
    set "DB_PATH=backend\prisma\database\logesco.db"
) else (
    echo ❌ Non trouvee
)
echo.

echo [5] Recherche complete dans tous les sous-dossiers...
echo.
for /f "delims=" %%i in ('dir /s /b logesco.db 2^>nul') do (
    echo ✅ Trouvee: %%i
    for %%A in ("%%i") do echo    Taille: %%~zA octets
    set "DB_FOUND=1"
    if not defined DB_PATH set "DB_PATH=%%i"
)
echo.

echo [6] Verification .env:
echo ====================
if exist "backend\.env" (
    echo ✅ Fichier .env existe
    echo.
    echo DATABASE_URL dans .env:
    type "backend\.env" | findstr DATABASE_URL
    echo.
) else (
    echo ❌ Fichier .env non trouve
)
echo.

echo [7] Verification schema.prisma:
echo ================================
if exist "backend\prisma\schema.prisma" (
    echo ✅ schema.prisma existe
    echo.
    echo Datasource url:
    findstr /C:"url" "backend\prisma\schema.prisma" | findstr /V "///"
    echo.
) else (
    echo ❌ schema.prisma non trouve
)
echo.

echo ========================================
echo   ANALYSE ET DIAGNOSTIC
echo ========================================
echo.

if "%DB_FOUND%"=="1" (
    echo ✅ Base de donnees trouvee!
    echo.
    echo Emplacement: %DB_PATH%
    echo.
    
    REM Tester si sqlite3 est disponible
    where sqlite3 >nul 2>nul
    if not errorlevel 1 (
        echo Test du contenu:
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM produits;" 2^>nul') do (
            echo   Produits: %%i
        )
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM clients;" 2^>nul') do (
            echo   Clients: %%i
        )
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM ventes;" 2^>nul') do (
            echo   Ventes: %%i
        )
    )
) else (
    echo ❌ AUCUNE base de donnees trouvee!
    echo.
    echo MAIS le backend affiche: produits: 165
    echo.
    echo POSSIBILITES:
    echo 1. La base est dans un chemin absolu
    echo 2. La base est dans un dossier parent
    echo 3. Le backend utilise une autre configuration
)
echo.

echo ========================================
echo   SOLUTION
echo ========================================
echo.

if "%DB_FOUND%"=="1" (
    echo La base existe a: %DB_PATH%
    echo.
    echo VERIFIER:
    echo 1. Est-ce que backend\.env pointe vers ce fichier?
    echo 2. Est-ce que le chemin est relatif ou absolu?
    echo.
    echo POUR MIGRATION:
    echo Le script migration-guidee.bat doit etre modifie
    echo pour chercher la base au bon endroit.
) else (
    echo ACTIONS A FAIRE:
    echo 1. Demarrer le backend
    echo 2. Verifier les logs pour voir le chemin de la base
    echo 3. Chercher dans les dossiers parents
)
echo.
pause
