@echo off
REM ========================================
REM LOGESCO Backend - PRODUCTION OPTIMISE
REM Demarrage ultra-rapide pour production
REM ========================================

cd /d "%~dp0"

REM Creer le dossier database si necessaire
if not exist "database" mkdir "database"

REM OPTIMISATION: Ne generer Prisma que si vraiment necessaire
set NEED_GENERATE=0
if not exist "node_modules\.prisma\client\index.js" set NEED_GENERATE=1

if %NEED_GENERATE%==1 (
    echo [INIT] Generation Prisma...
    call npx prisma generate >nul 2>nul
)

REM OPTIMISATION: Ne creer la DB que si elle n'existe pas
if not exist "database\logesco.db" (
    echo [INIT] Creation base de donnees...
    call npx prisma db push --accept-data-loss --skip-generate >nul 2>nul
)

REM Demarrage direct sans logs verbeux
node src/server.js

exit /b %ERRORLEVEL%
