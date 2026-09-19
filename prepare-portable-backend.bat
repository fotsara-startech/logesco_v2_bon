@echo off
REM ========================================
REM PREPARATION BACKEND PORTABLE - LOGESCO
REM Prepare un backend pret a l'emploi
REM ========================================

echo =========================================
echo PREPARATION BACKEND PORTABLE - LOGESCO
echo =========================================
echo.

cd /d "%~dp0backend"

if not exist "src\server.js" (
    echo [ERREUR] Repertoire backend invalide!
    pause
    exit /b 1
)

echo [1] Verification de Node.js...
where node >nul 2>&1
if errorlevel 1 (
    echo    [ERREUR] Node.js introuvable! Installez Node.js d'abord.
    pause
    exit /b 1
)
node --version
echo    [OK] Node.js trouve
echo.

echo [2] Installation des dependances...
if not exist "node_modules" (
    echo    Installation en cours (peut prendre quelques minutes)...
    call npm install --production
    if errorlevel 1 (
        echo    [ERREUR] Echec installation
        pause
        exit /b 1
    )
)
echo    [OK] Dependances installees
echo.

echo [3] Generation du client Prisma...
call npx prisma generate
if errorlevel 1 (
    echo    [ERREUR] Echec generation Prisma
    pause
    exit /b 1
)
echo    [OK] Client Prisma genere
echo.

echo [4] Creation du dossier database...
if not exist "database" mkdir database
echo    [OK] Dossier database pret
echo.

echo [5] Creation de la base de donnees template...
if not exist "database\logesco_template.db" (
    echo    Creation du schema initial...
    call npx prisma db push --accept-data-loss --skip-generate
    if errorlevel 1 (
        echo    [ERREUR] Echec creation schema
        pause
        exit /b 1
    )
    
    REM Copier la base fraiche comme template
    if exist "database\logesco.db" (
        copy "database\logesco.db" "database\logesco_template.db" >nul
        echo    [OK] Template de base cree
    )
) else (
    echo    [INFO] Template deja existant
)
echo.

echo [6] Creation du fichier .env...
set "BACKEND_DIR=%CD%"
set "DB_PATH=%BACKEND_DIR%\database\logesco.db"
set "DB_PATH=%DB_PATH:\=/%"

(
    echo NODE_ENV=production
    echo PORT=8080
    echo DATABASE_URL=file:%DB_PATH%
    echo JWT_SECRET=logesco-secret-%RANDOM%%RANDOM%%RANDOM%
    echo JWT_EXPIRES_IN=365d
    echo CORS_ORIGIN=*
    echo LOG_LEVEL=info
) > .env.template

echo    [OK] Fichier .env.template cree
echo.

echo [7] Test de demarrage...
echo    Demarrage du backend (patientez 10 secondes)...
start "LOGESCO Backend Test" /MIN node src\server.js
timeout /t 10 /nobreak >nul

echo    Test de connexion...
curl -s http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    echo    [ERREUR] Backend ne repond pas!
    echo    Lecture des logs...
    if exist "logs\backend-startup.log" (
        type logs\backend-startup.log
    )
    taskkill /F /IM node.exe >nul 2>&1
    pause
    exit /b 1
)

echo    [OK] Backend fonctionne!
echo.

echo [8] Test de l'API...
curl -s http://localhost:8080/health
echo.
echo.

echo [9] Arret du backend...
taskkill /F /IM node.exe >nul 2>&1
echo    [OK] Backend arrete
echo.

echo [10] Creation des scripts de demarrage...

REM Script de demarrage simple
(
    echo @echo off
    echo cd /d "%%~dp0"
    echo node src\server.js
    echo pause
) > start-backend-console.bat

REM Script de demarrage silencieux
(
    echo @echo off
    echo cd /d "%%~dp0"
    echo start "LOGESCO Backend" /MIN node src\server.js
) > start-backend-silent-simple.bat

echo    [OK] Scripts de demarrage crees
echo.

echo =========================================
echo PREPARATION TERMINEE AVEC SUCCES!
echo =========================================
echo.
echo Le backend est maintenant pret a etre deploye.
echo.
echo Fichiers crees :
echo   - node_modules\.prisma\client\        (Client Prisma genere)
echo   - database\logesco_template.db        (Base de donnees template)
echo   - .env.template                       (Configuration template)
echo   - start-backend-console.bat           (Demarrage avec console)
echo   - start-backend-silent-simple.bat     (Demarrage silencieux)
echo.
echo IMPORTANT pour le deploiement :
echo 1. Copiez tout le dossier backend vers %LOCALAPPDATA%\LOGESCO\backend
echo 2. Copiez .env.template vers .env (et ajustez les chemins si necessaire)
echo 3. L'application Flutter pourra demarrer le backend automatiquement
echo.
echo Pour tester manuellement : start-backend-console.bat
echo.
pause
