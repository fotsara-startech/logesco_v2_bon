@echo off
REM ========================================
REM DIAGNOSTIC DEMARRAGE BACKEND PRODUCTION
REM ========================================

echo =========================================
echo DIAGNOSTIC DEMARRAGE BACKEND - LOGESCO
echo =========================================
echo.

REM Determiner le chemin AppData\Local
set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"
echo [1] Verification du repertoire backend...
echo    Chemin: %BACKEND_DIR%
if not exist "%BACKEND_DIR%" (
    echo    [ERREUR] Repertoire backend introuvable!
    echo    Le logiciel doit etre installe en premier.
    pause
    exit /b 1
)
echo    [OK] Repertoire backend existe
echo.

REM Verifier node.exe
echo [2] Verification de Node.js...
set "NODE_EXE=%BACKEND_DIR%\node.exe"
if exist "%NODE_EXE%" (
    echo    [OK] Node.js portable trouve: %NODE_EXE%
    "%NODE_EXE%" --version
) else (
    echo    [WARN] Node.js portable absent, recherche Node.js systeme...
    where node >nul 2>&1
    if errorlevel 1 (
        echo    [ERREUR] Node.js introuvable!
        pause
        exit /b 1
    )
    set "NODE_EXE=node"
    node --version
    echo    [OK] Node.js systeme trouve
)
echo.

REM Verifier server.js
echo [3] Verification du fichier serveur...
if not exist "%BACKEND_DIR%\src\server.js" (
    echo    [ERREUR] server.js introuvable!
    pause
    exit /b 1
)
echo    [OK] server.js existe
echo.

REM Verifier le client Prisma
echo [4] Verification du client Prisma...
if not exist "%BACKEND_DIR%\node_modules\.prisma\client\index.js" (
    echo    [ERREUR] Client Prisma non genere!
    echo    Generation en cours...
    cd /d "%BACKEND_DIR%"
    "%NODE_EXE%" node_modules\prisma\build\index.js generate >nul 2>&1
    if errorlevel 1 (
        echo    [ERREUR] Echec generation Prisma
        pause
        exit /b 1
    )
    echo    [OK] Client Prisma genere
) else (
    echo    [OK] Client Prisma existe
)
echo.

REM Verifier database
echo [5] Verification de la base de donnees...
set "DB_DIR=%BACKEND_DIR%\database"
set "DB_FILE=%DB_DIR%\logesco.db"
if not exist "%DB_DIR%" (
    echo    [WARN] Dossier database absent, creation...
    mkdir "%DB_DIR%"
)
if not exist "%DB_FILE%" (
    echo    [WARN] Base de donnees absente
    echo    Verification du template...
    if exist "%BACKEND_DIR%\database\logesco_template.db" (
        echo    [OK] Template trouve, copie en cours...
        copy "%BACKEND_DIR%\database\logesco_template.db" "%DB_FILE%" >nul
        echo    [OK] Base de donnees initialisee depuis template
    ) else (
        echo    [INFO] Template absent, le backend creera la base au demarrage
    )
) else (
    echo    [OK] Base de donnees existe: %DB_FILE%
    echo    Taille: 
    dir "%DB_FILE%" | find "logesco.db"
)
echo.

REM Verifier le fichier .env
echo [6] Verification du fichier .env...
set "ENV_FILE=%BACKEND_DIR%\.env"
set "DB_PATH_FIXED=%DB_FILE:\=/%"
if not exist "%ENV_FILE%" (
    echo    [WARN] Fichier .env absent, creation...
    (
        echo NODE_ENV=production
        echo PORT=8080
        echo DATABASE_URL=file:%DB_PATH_FIXED%
        echo JWT_SECRET=logesco-secret-%RANDOM%%RANDOM%
        echo JWT_EXPIRES_IN=365d
        echo CORS_ORIGIN=*
        echo LOG_LEVEL=info
    ) > "%ENV_FILE%"
    echo    [OK] Fichier .env cree
) else (
    echo    [OK] Fichier .env existe
    echo    Contenu:
    type "%ENV_FILE%"
)
echo.

REM Tester le demarrage manuel
echo [7] Test de demarrage manuel du backend...
echo    Demarrage en cours (patientez 10 secondes)...
cd /d "%BACKEND_DIR%"

REM Definir les variables d'environnement
set "LOGESCO_DATA_DIR=%BACKEND_DIR%"
set "PORT=8080"
set "DATABASE_URL=file:%DB_PATH_FIXED%"

REM Demarrer en arriere-plan
start "LOGESCO Backend Test" /MIN "%NODE_EXE%" "%BACKEND_DIR%\src\server.js"

REM Attendre le demarrage
timeout /t 10 /nobreak >nul

REM Tester le endpoint health
echo    Test de connexion a http://localhost:8080/health...
curl -s http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    echo    [ERREUR] Backend ne repond pas!
    echo.
    echo    Lecture des derniers logs...
    if exist "%BACKEND_DIR%\logs\backend-startup.log" (
        echo    --- DEBUT LOGS ---
        powershell -Command "Get-Content '%BACKEND_DIR%\logs\backend-startup.log' -Tail 30"
        echo    --- FIN LOGS ---
    ) else (
        echo    [WARN] Fichier de log introuvable
    )
    echo.
    echo    Arret du processus de test...
    taskkill /F /IM node.exe >nul 2>&1
    pause
    exit /b 1
)
echo    [OK] Backend repond correctement!
echo.

REM Afficher les infos de debug
echo [8] Informations de debug du backend...
curl -s http://localhost:8080/debug
echo.
echo.

REM Arreter le backend de test
echo [9] Arret du backend de test...
taskkill /F /IM node.exe >nul 2>&1
echo    [OK] Backend arrete
echo.

echo =========================================
echo DIAGNOSTIC TERMINE - TOUT FONCTIONNE!
echo =========================================
echo.
echo Le backend peut demarrer correctement manuellement.
echo Si le probleme persiste au demarrage automatique depuis
echo l'application Flutter, cela indique un probleme avec
echo les scripts VBS ou les variables d'environnement.
echo.
echo Verifiez les fichiers generes dans:
echo    %BACKEND_DIR%\_logesco_start.cmd
echo    %BACKEND_DIR%\_logesco_start.vbs
echo.
pause
