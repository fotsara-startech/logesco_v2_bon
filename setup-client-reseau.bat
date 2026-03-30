@echo off
REM Script de configuration automatique du client LOGESCO pour réseau local
REM Ce script configure l'adresse du serveur AVANT le premier démarrage

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Configuration du Client LOGESCO
echo ========================================
echo.

REM Vérifier si l'application est déjà en cours d'exécution
tasklist /FI "IMAGENAME eq logesco.exe" 2>NUL | find /I /N "logesco.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo.
    echo ⚠️ L'application LOGESCO est actuellement en cours d'exécution.
    echo Veuillez la fermer avant de continuer.
    echo.
    pause
    exit /b 1
)

REM Demander l'adresse IP du serveur
echo Entrez les informations du serveur:
echo.
set /p SERVER_IP="Adresse IP du serveur (ex: 192.168.100.101): "

if "!SERVER_IP!"=="" (
    echo.
    echo ❌ Erreur: Vous devez entrer une adresse IP
    echo.
    pause
    exit /b 1
)

REM Demander le port (par défaut 8080)
set /p SERVER_PORT="Port du serveur (par défaut 8080): "
if "!SERVER_PORT!"=="" set SERVER_PORT=8080

REM Construire l'URL complète
set SERVER_URL=http://!SERVER_IP!:!SERVER_PORT!/api/v1

echo.
echo ========================================
echo Configuration:
echo.
echo Adresse IP: !SERVER_IP!
echo Port: !SERVER_PORT!
echo URL complète: !SERVER_URL!
echo.
echo ========================================
echo.

REM Tester la connexion au serveur
echo 🔍 Test de connexion au serveur...
echo.

REM Utiliser PowerShell pour tester la connexion
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://!SERVER_IP!:!SERVER_PORT!/api/v1/auth/test' -TimeoutSec 5 -ErrorAction Stop; Write-Host '✅ Serveur accessible'; exit 0 } catch { Write-Host '❌ Serveur non accessible'; exit 1 }"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ⚠️ ATTENTION: Le serveur n'est pas accessible à l'adresse !SERVER_URL!
    echo.
    echo Vérifications à faire:
    echo - L'adresse IP est-elle correcte?
    echo - Le serveur est-il en cours d'exécution?
    echo - Le port 8080 est-il accessible?
    echo - Le firewall bloque-t-il la connexion?
    echo.
    set /p CONTINUE="Continuer quand même? (O/N): "
    if /i "!CONTINUE!"=="N" (
        echo.
        echo Configuration annulée.
        echo.
        pause
        exit /b 1
    )
)

REM Créer le fichier de configuration
set CONFIG_DIR=%USERPROFILE%\Documents
set CONFIG_FILE=!CONFIG_DIR!\server_config.txt

echo.
echo 💾 Création du fichier de configuration...
echo !SERVER_URL! > "!CONFIG_FILE!"

if exist "!CONFIG_FILE!" (
    echo ✅ Fichier de configuration créé avec succès
    echo Fichier: !CONFIG_FILE!
    echo.
) else (
    echo ❌ Erreur lors de la création du fichier de configuration
    echo.
    pause
    exit /b 1
)

REM Demander si l'utilisateur veut lancer l'application
echo.
set /p LAUNCH="Lancer l'application LOGESCO maintenant? (O/N): "

if /i "!LAUNCH!"=="O" (
    echo.
    echo 🚀 Lancement de l'application...
    echo.
    
    REM Chercher l'application dans les emplacements courants
    if exist "C:\Program Files\LOGESCO\logesco.exe" (
        start "" "C:\Program Files\LOGESCO\logesco.exe"
    ) else if exist "C:\Program Files (x86)\LOGESCO\logesco.exe" (
        start "" "C:\Program Files (x86)\LOGESCO\logesco.exe"
    ) else if exist "%APPDATA%\LOGESCO\logesco.exe" (
        start "" "%APPDATA%\LOGESCO\logesco.exe"
    ) else (
        echo ⚠️ Application LOGESCO non trouvée dans les emplacements standards
        echo Veuillez lancer l'application manuellement
        echo.
    )
) else (
    echo.
    echo ℹ️ Configuration terminée
    echo Vous pouvez maintenant lancer l'application LOGESCO
    echo.
)

echo.
echo ========================================
echo Configuration terminée avec succès!
echo ========================================
echo.

pause
