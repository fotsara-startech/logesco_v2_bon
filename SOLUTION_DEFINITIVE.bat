@echo off
title SOLUTION DEFINITIVE - Reinitialisation Complete
color 0E
echo ========================================
echo   SOLUTION DEFINITIVE
echo   Reinitialisation Complete Base
echo ========================================
echo.
echo Cette solution va:
echo 1. SUPPRIMER completement la base
echo 2. RECREER la structure
echo 3. INITIALISER avec donnees vierges
echo.
pause

REM Aller dans le dossier backend
cd backend

echo.
echo [1/4] Suppression COMPLETE de la base...
if exist "database\logesco.db" del /f /q "database\logesco.db"
if exist "database\logesco.db-journal" del /f /q "database\logesco.db-journal"
if exist "database\logesco.db-shm" del /f /q "database\logesco.db-shm"
if exist "database\logesco.db-wal" del /f /q "database\logesco.db-wal"
echo ✅ Base supprimee
echo.

echo [2/4] Recreation structure...
call npx prisma db push --force-reset --accept-data-loss --skip-generate
if errorlevel 1 (
    echo ❌ ERREUR
    pause
    exit /b 1
)
echo ✅ Structure creee
echo.

echo [3/4] Initialisation donnees...
node prisma\seed.js
if errorlevel 1 (
    echo ❌ ERREUR
    pause
    exit /b 1
)
echo.

echo [4/4] Verification...
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.utilisateur.count().then(c=>{console.log('Utilisateurs:',c);process.exit(c===1?0:1)}).catch(e=>{console.error(e);process.exit(1)})"
if errorlevel 1 (
    echo ❌ Verification echouee
) else (
    echo ✅ Base VIERGE confirmee
)

cd ..
echo.
echo ========================================
echo   TERMINE
echo ========================================
pause
