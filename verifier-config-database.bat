@echo off
title Verification Config Database
color 0B
echo ========================================
echo   VERIFICATION CONFIG DATABASE
echo ========================================
echo.

echo [1] Fichier .env:
echo =================
if exist "backend\.env" (
    echo ✅ Fichier .env existe
    echo.
    echo Contenu:
    type "backend\.env"
    echo.
) else (
    echo ❌ Fichier .env non trouve
)
echo.

echo [2] Recherche logesco.db:
echo =========================
echo.

echo Dans backend\database\:
dir "backend\database\logesco.db" 2>nul
echo.

echo Dans backend\:
dir "backend\logesco.db" 2>nul
echo.

echo Dans backend\prisma\:
dir "backend\prisma\logesco.db" 2>nul
echo.

echo Recherche complete:
dir /s /b logesco.db 2>nul
echo.

echo [3] Schema Prisma:
echo ==================
if exist "backend\prisma\schema.prisma" (
    echo Datasource dans schema.prisma:
    findstr /C:"url" "backend\prisma\schema.prisma"
) else (
    echo ❌ schema.prisma non trouve
)
echo.

echo ========================================
echo   DIAGNOSTIC
echo ========================================
echo.

echo Le backend affiche: produits: 165
echo Donc la base existe et contient des donnees.
echo.

echo Si backend\database\ est vide:
echo   → La base est ailleurs
echo   → Verifier DATABASE_URL dans .env
echo   → Verifier url dans schema.prisma
echo.
pause
