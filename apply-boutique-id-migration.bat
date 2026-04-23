@echo off
echo ========================================
echo Migration: Ajout boutiqueId aux dates de peremption
echo ========================================
echo.

cd /d "%~dp0"

echo Verification de Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERREUR: Node.js n'est pas installe ou pas dans le PATH
    pause
    exit /b 1
)

echo Verification de npm...
npm --version >nul 2>&1
if errorlevel 1 (
    echo ERREUR: npm n'est pas installe ou pas dans le PATH
    pause
    exit /b 1
)

echo.
echo Installation des dependances si necessaire...
if not exist "node_modules" (
    echo Installation des packages npm...
    npm install
    if errorlevel 1 (
        echo ERREUR: Echec de l'installation des dependances
        pause
        exit /b 1
    )
)

echo.
echo Execution de la migration...
node migrate-add-boutique-id-to-dates-peremption.js

if errorlevel 1 (
    echo.
    echo ERREUR: La migration a echoue
    echo Verifiez les logs ci-dessus pour plus de details
    pause
    exit /b 1
) else (
    echo.
    echo SUCCESS: Migration terminee avec succes!
    echo.
    echo Les dates de peremption ont maintenant un champ boutiqueId
    echo Les donnees existantes ont ete assignees a la boutique principale
    echo.
)

pause