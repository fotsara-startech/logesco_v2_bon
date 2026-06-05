@echo off
echo ========================================
echo  SWITCH -> BASE DE DEV
echo ========================================
echo.
echo [!] Assure-toi que le backend est ARRETE avant de continuer
echo     (Ctrl+C dans le terminal npm start)
echo.
:: Sauvegarder la BD SQLite client si elle existe
if exist "prisma\database\logesco.db" (
    echo Sauvegarde BD client...
    copy /Y "prisma\database\logesco.db" "prisma\database\logesco.db.client-backup" >nul
)

:: Supprimer la BD SQLite locale (sera recree proprement au demarrage)
if exist "prisma\database\logesco.db" del /F "prisma\database\logesco.db"
if exist "database\logesco.db" del /F "database\logesco.db"

:: Activer le .env de dev
copy /Y ".env.dev" ".env" >nul

echo.
echo [OK] .env pointe vers la BD de DEV
echo [OK] BD SQLite locale supprimee (sera recreee avec les donnees dev depuis Neon)
echo.
echo Demarre le backend avec: npm start
echo ========================================
