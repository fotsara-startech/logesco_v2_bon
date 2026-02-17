@echo off
REM ========================================
REM LOGESCO Backend - Demarrage SILENCIEUX
REM Demarre en arriere-plan sans fenetre
REM ========================================

REM Creer le dossier database si necessaire
if not exist "database" mkdir "database"

REM Verification rapide: Client Prisma deja genere?
if not exist "node_modules\.prisma\client" (
    call npx prisma generate >nul 2>nul
)

REM Verification rapide: Base de donnees existe?
if not exist "database\logesco.db" (
    call npx prisma db push --accept-data-loss >nul 2>nul
)

REM Demarrage en arriere-plan avec fenetre minimisee
start "LOGESCO Backend" /MIN node src/server.js

REM Attendre 3 secondes pour l'initialisation
timeout /t 3 /nobreak >nul

exit
