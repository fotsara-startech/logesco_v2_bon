@echo off
REM ========================================
REM LOGESCO Backend - Demarrage OPTIMISE
REM Demarrage rapide sans commandes Prisma
REM ========================================

REM Verification Node.js rapide
where node >nul 2>nul
if errorlevel 1 (
    echo ERREUR: Node.js non installe
    exit /b 1
)

REM Creer le dossier database si necessaire
if not exist "database" mkdir "database"

REM Verification rapide: Client Prisma deja genere?
if not exist "node_modules\.prisma\client" (
    echo Generation Prisma requise (premiere fois uniquement)...
    call npx prisma generate >nul 2>nul
)

REM Verification rapide: Base de donnees existe?
if not exist "database\logesco.db" (
    echo Creation base de donnees (premiere fois uniquement)...
    call npx prisma db push --accept-data-loss >nul 2>nul
)

REM Demarrage direct du serveur
node src/server.js
