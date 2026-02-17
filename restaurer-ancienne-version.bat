@echo off
title LOGESCO - Restauration Ancienne Version
echo ========================================
echo   RESTAURATION ANCIENNE VERSION
echo ========================================
echo.

echo Ce script restaure l'ancienne version
echo en cas de probleme avec la migration.
echo.
echo ⚠️ ATTENTION: Cette action annulera
echo la migration et restaurera l'etat precedent.
echo.
set /p CONFIRM="Etes-vous sur de vouloir restaurer? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo Operation annulee
    pause
    exit /b 0
)
echo.

echo [1/5] Arret des processus...
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [2/5] Recherche des sauvegardes...
set BACKUP_FOUND=0
set ANCIEN_FOUND=0

REM Chercher la sauvegarde originale
for /d %%i in (sauvegarde_client_*) do (
    if exist "%%i\logesco_original.db" (
        set BACKUP_DIR=%%i
        set BACKUP_FOUND=1
        echo ✅ Sauvegarde originale trouvee: %%i
    )
)

REM Chercher l'ancien backend
if exist "backend_ancien" (
    set ANCIEN_FOUND=1
    echo ✅ Ancien backend trouve: backend_ancien
)

if %BACKUP_FOUND%==0 if %ANCIEN_FOUND%==0 (
    echo ❌ ERREUR: Aucune sauvegarde trouvee!
    echo.
    echo Impossible de restaurer sans sauvegarde.
    echo Contactez le support technique.
    echo.
    pause
    exit /b 1
)
echo.

echo [3/5] Restauration des fichiers...
if %ANCIEN_FOUND%==1 (
    echo Restauration depuis backend_ancien...
    
    REM Supprimer le nouveau backend
    if exist "backend" (
        rmdir /s /q "backend" >nul 2>nul
        echo ✅ Nouveau backend supprime
    )
    
    REM Restaurer l'ancien
    ren "backend_ancien" "backend"
    echo ✅ Ancien backend restaure
) else (
    echo Restauration depuis la sauvegarde originale...
    
    REM Restaurer la base de données
    if exist "%BACKUP_DIR%\logesco_original.db" (
        copy "%BACKUP_DIR%\logesco_original.db" "backend\database\logesco.db" >nul
        echo ✅ Base de donnees restauree
    )
    
    REM Restaurer la configuration
    if exist "%BACKUP_DIR%\.env_original" (
        copy "%BACKUP_DIR%\.env_original" "backend\.env" >nul
        echo ✅ Configuration restauree
    )
)
echo.

echo [4/5] Restauration des donnees utilisateur...
if exist "%BACKUP_DIR%\uploads" (
    if exist "backend\uploads" rmdir /s /q "backend\uploads" >nul 2>nul
    xcopy /E /I /Y /Q "%BACKUP_DIR%\uploads" "backend\uploads" >nul 2>nul
    echo ✅ Fichiers uploads restaures
)

if exist "%BACKUP_DIR%\logs" (
    if exist "backend\logs" rmdir /s /q "backend\logs" >nul 2>nul
    xcopy /E /I /Y /Q "%BACKUP_DIR%\logs" "backend\logs" >nul 2>nul
    echo ✅ Logs restaures
)
echo.

echo [5/5] Test de l'ancienne version...
echo Demarrage de l'ancien backend...
cd backend
start /min cmd /c "npm start"
cd ..

echo Attente du demarrage...
timeout /t 8 /nobreak >nul

REM Test de connectivité (port peut être différent)
curl -s http://localhost:3002/health >nul 2>nul
if not errorlevel 1 (
    echo ✅ Ancien backend fonctionne (port 3002)
    set BACKEND_PORT=3002
) else (
    curl -s http://localhost:8080/health >nul 2>nul
    if not errorlevel 1 (
        echo ✅ Ancien backend fonctionne (port 8080)
        set BACKEND_PORT=8080
    ) else (
        echo ⚠️ Backend ne repond pas encore
        set BACKEND_PORT=inconnu
    )
)

REM Arrêter le test
taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   RESTAURATION TERMINEE
echo ========================================
echo.
echo 📁 ETAT ACTUEL:
echo    Backend: Ancienne version restauree
echo    Base de donnees: Version originale
echo    Port: %BACKEND_PORT%
echo.
echo 📊 VERIFICATION:
echo 1. Demarrez LOGESCO normalement
echo 2. Verifiez que vos donnees sont presentes
echo 3. Testez les fonctionnalites principales
echo.
echo 🔄 POUR RETENTER LA MIGRATION:
echo 1. Analysez les erreurs precedentes
echo 2. Corrigez les problemes identifies
echo 3. Executez a nouveau: migrer-client-existant.bat
echo.
echo 📞 SUPPORT:
echo Si les problemes persistent, contactez
echo le support technique avec les details
echo de l'erreur rencontree.
echo.
echo ✅ Vos donnees sont en securite!
echo.
pause