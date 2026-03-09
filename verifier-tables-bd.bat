@echo off
title Verification Tables BD
color 0E
echo ========================================
echo   VERIFICATION TABLES BASE DE DONNEES
echo ========================================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base non trouvee!
    pause
    exit /b 1
)

where sqlite3 >nul 2>nul
if errorlevel 1 (
    echo ❌ sqlite3 non installe!
    echo.
    echo Telechargez sqlite3 depuis:
    echo https://www.sqlite.org/download.html
    pause
    exit /b 1
)

cd backend\database

echo Liste des tables:
echo ==================
sqlite3 logesco.db ".tables"
echo.
echo.

echo Schema table utilisateurs:
echo ==========================
sqlite3 logesco.db ".schema utilisateurs"
echo.
echo.

echo Comptage donnees:
echo =================
echo.

echo Utilisateurs:
sqlite3 logesco.db "SELECT COUNT(*) FROM utilisateurs;"

echo Produits:
sqlite3 logesco.db "SELECT COUNT(*) FROM produits;"

echo Ventes:
sqlite3 logesco.db "SELECT COUNT(*) FROM ventes;"

echo Clients:
sqlite3 logesco.db "SELECT COUNT(*) FROM clients;"

echo Fournisseurs:
sqlite3 logesco.db "SELECT COUNT(*) FROM fournisseurs;"

echo.
echo.

echo Exemple utilisateur:
echo ====================
sqlite3 logesco.db "SELECT * FROM utilisateurs LIMIT 1;"

echo.
echo.

echo Exemple produit:
echo ================
sqlite3 logesco.db "SELECT * FROM produits LIMIT 1;"

cd ..\..

echo.
echo ========================================
echo   ANALYSE
echo ========================================
echo.

echo Si vous voyez des donnees ci-dessus:
echo   → La base contient des donnees
echo   → Prisma ne les lit pas
echo   → Probleme de mapping schema.prisma
echo.

echo Copiez les resultats et envoyez-les moi.
echo.
pause
