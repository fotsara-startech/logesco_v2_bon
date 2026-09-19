@echo off
REM ========================================
REM FIX BACKEND STARTUP - LOGESCO
REM Corrige les problemes de demarrage
REM ========================================

echo =========================================
echo CORRECTION DEMARRAGE BACKEND - LOGESCO
echo =========================================
echo.

REM Determiner le chemin AppData\Local
set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"
echo Repertoire backend: %BACKEND_DIR%
echo.

if not exist "%BACKEND_DIR%" (
    echo [ERREUR] Repertoire backend introuvable!
    echo Le logiciel doit etre installe en premier.
    pause
    exit /b 1
)

cd /d "%BACKEND_DIR%"

REM Arreter tous les processus node.exe en cours
echo [1] Arret des processus Node.js en cours...
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo    [OK] Processus arretes
echo.

REM Verifier Node.js
echo [2] Verification de Node.js...
set "NODE_EXE=%BACKEND_DIR%\node.exe"
if not exist "%NODE_EXE%" (
    echo    [WARN] Node.js portable absent, utilisation systeme...
    set "NODE_EXE=node"
)
echo    Node.js: %NODE_EXE%
"%NODE_EXE%" --version
echo.

REM Creer le dossier database
echo [3] Verification du dossier database...
if not exist "database" (
    echo    Creation du dossier database...
    mkdir "database"
)
echo    [OK] Dossier database pret
echo.

REM Generer le client Prisma
echo [4] Generation du client Prisma...
if not exist "node_modules\.prisma\client\index.js" (
    echo    Client Prisma absent, generation en cours...
    "%NODE_EXE%" node_modules\prisma\build\index.js generate
    if errorlevel 1 (
        echo    [ERREUR] Echec generation Prisma
        pause
        exit /b 1
    )
    echo    [OK] Client Prisma genere
) else (
    echo    [INFO] Client Prisma deja present, regeneration...
    "%NODE_EXE%" node_modules\prisma\build\index.js generate >nul 2>&1
    echo    [OK] Client Prisma regenere
)
echo.

REM Verifier/creer la base de donnees
echo [5] Verification de la base de donnees...
set "DB_FILE=database\logesco.db"
if not exist "%DB_FILE%" (
    echo    Base de donnees absente
    if exist "database\logesco_template.db" (
        echo    Copie du template...
        copy "database\logesco_template.db" "%DB_FILE%" >nul
        echo    [OK] Base de donnees copiee depuis template
    ) else (
        echo    [INFO] Template absent, creation au demarrage...
    )
) else (
    echo    [OK] Base de donnees existe
)
echo.

REM Creer/corriger le fichier .env
echo [6] Correction du fichier .env...
set "DB_PATH_FIXED=%CD%\database\logesco.db"
set "DB_PATH_FIXED=%DB_PATH_FIXED:\=/%"

(
    echo NODE_ENV=production
    echo PORT=8080
    echo DATABASE_URL=file:%DB_PATH_FIXED%
    echo JWT_SECRET=logesco-secret-%RANDOM%%RANDOM%
    echo JWT_EXPIRES_IN=365d
    echo CORS_ORIGIN=*
    echo LOG_LEVEL=info
) > .env

echo    [OK] Fichier .env cree/corrige
echo.

REM Nettoyer les anciens scripts
echo [7] Nettoyage des anciens scripts...
if exist "_logesco_start.cmd" del /f /q "_logesco_start.cmd" >nul 2>&1
if exist "_logesco_start.vbs" del /f /q "_logesco_start.vbs" >nul 2>&1
echo    [OK] Scripts nettoyes
echo.

REM Creer un script de demarrage ameliore
echo [8] Creation des scripts de demarrage...

REM Script CMD
(
    echo @echo off
    echo cd /d "%BACKEND_DIR%"
    echo SET "LOGESCO_DATA_DIR=%BACKEND_DIR%"
    echo SET "PORT=8080"
    echo SET "NODE_ENV=production"
    echo SET "DATABASE_URL=file:%DB_PATH_FIXED%"
    echo "%NODE_EXE%" "%BACKEND_DIR%\src\server.js"
) > _logesco_start.cmd

REM Script VBS
(
    echo Set WshShell = CreateObject("WScript.Shell"^)
    echo Dim cmd
    echo cmd = "cmd.exe /C " ^& Chr(34^) ^& "%BACKEND_DIR%\_logesco_start.cmd" ^& Chr(34^)
    echo WshShell.Run cmd, 0, False
) > _logesco_start.vbs

echo    [OK] Scripts crees
echo.

REM Tester le demarrage
echo [9] Test de demarrage du backend...
echo    Demarrage en cours (patientez 15 secondes)...
start "LOGESCO Backend" /MIN "%NODE_EXE%" src\server.js
timeout /t 15 /nobreak >nul

echo    Test de connexion...
curl -s http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    echo    [ERREUR] Backend ne repond pas!
    echo.
    echo    Lecture des logs...
    if exist "logs\backend-startup.log" (
        echo    --- DEBUT LOGS ---
        powershell -Command "Get-Content 'logs\backend-startup.log' -Tail 40"
        echo    --- FIN LOGS ---
    )
    echo.
    taskkill /F /IM node.exe >nul 2>&1
    pause
    exit /b 1
)

echo    [OK] Backend demarre avec succes!
echo.

REM Afficher les infos
echo [10] Test de l'API...
curl -s http://localhost:8080/health
echo.
echo.

REM Arreter
echo [11] Arret du backend de test...
taskkill /F /IM node.exe >nul 2>&1
echo    [OK] Backend arrete
echo.

echo =========================================
echo CORRECTION TERMINEE AVEC SUCCES!
echo =========================================
echo.
echo Le backend peut maintenant demarrer correctement.
echo.
echo Pour tester le demarrage automatique depuis Flutter:
echo 1. Fermez l'application LOGESCO si elle est ouverte
echo 2. Relancez l'application
echo 3. Le backend devrait demarrer automatiquement
echo.
echo Si le probleme persiste, executez:
echo    diagnose-backend-startup.bat
echo.
pause
