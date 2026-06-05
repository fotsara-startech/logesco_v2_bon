@echo off
echo ========================================
echo  SWITCH -> BASE CLIENT
echo ========================================
echo.
echo [!] Assure-toi que le backend est ARRETE avant de continuer
echo     (Ctrl+C dans le terminal npm start)
echo.

:: Verifier que le fichier client existe
if not exist ".env.client-%1" (
    echo ERREUR: Fichier .env.client-%1 introuvable
    echo.
    echo Usage: switch-to-client.bat [nom-client]
    echo Exemple: switch-to-client.bat alategot
    echo.
    echo Fichiers clients disponibles:
    dir /B ".env.client-*" 2>nul
    exit /b 1
)

:: Sauvegarder la BD SQLite dev si elle existe
if exist "prisma\database\logesco.db" (
    echo Sauvegarde BD dev...
    copy /Y "prisma\database\logesco.db" "prisma\database\logesco.db.dev-backup" >nul
)

:: Supprimer la BD SQLite locale (le pull depuis Neon client va la repeupler)
if exist "prisma\database\logesco.db" del /F "prisma\database\logesco.db"
if exist "database\logesco.db" del /F "database\logesco.db"

:: Activer le .env client
copy /Y ".env.client-%1" ".env" >nul

:: Reinitialiser le last_pull pour forcer un pull complet depuis Neon client
echo Reinitialisation du cache de synchronisation...

echo.
echo [OK] .env pointe vers la BD client: %1
echo [OK] BD SQLite locale supprimee (sera peuplee depuis Neon client au demarrage)
echo.
echo Demarre le backend avec: npm start
echo ========================================
