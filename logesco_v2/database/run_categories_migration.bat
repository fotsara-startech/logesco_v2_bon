@echo off
echo ========================================
echo    MIGRATION TABLE CATEGORIES
echo ========================================
echo.

REM Vérifier si SQLite est disponible
sqlite3 --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: SQLite3 n'est pas installé ou pas dans le PATH
    echo Veuillez installer SQLite3 depuis: https://sqlite.org/download.html
    pause
    exit /b 1
)

REM Définir le chemin de la base de données
set DB_PATH=logesco.db

echo 📁 Base de données: %DB_PATH%
echo.

REM Vérifier si la base existe
if not exist "%DB_PATH%" (
    echo ⚠️  La base de données n'existe pas encore
    echo 🔧 Création de la base de données...
    echo.
)

echo 🚀 Exécution de la migration des catégories...
echo.

REM Exécuter la migration
sqlite3 "%DB_PATH%" < migrations/create_categories_table.sql

if %errorlevel% equ 0 (
    echo.
    echo ✅ Migration exécutée avec succès !
    echo.
    echo 📊 Vérification des données:
    echo.
    sqlite3 "%DB_PATH%" "SELECT 'Nombre de catégories:' as info, COUNT(*) as count FROM categories;"
    echo.
    sqlite3 "%DB_PATH%" "SELECT '--- Liste des catégories ---' as info; SELECT id, nom, description FROM categories ORDER BY id;"
    echo.
    echo 🎯 La table 'categories' est prête à être utilisée !
) else (
    echo.
    echo ❌ Erreur lors de l'exécution de la migration
    echo Vérifiez le fichier SQL et réessayez
)

echo.
echo ========================================
pause