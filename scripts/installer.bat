@echo off
setlocal enabledelayedexpansion

echo ========================================
echo LOGESCO v2 - Installation Automatique
echo ========================================

:: Variables de configuration
set "INSTALL_DIR=C:\Program Files\LOGESCO"
set "SERVICE_NAME=LogescoAPI"
set "API_PORT=8080"

:: Vérifier les privilèges administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERREUR: Ce script doit être exécuté en tant qu'administrateur.
    echo Clic droit sur le fichier et sélectionnez "Exécuter en tant qu'administrateur"
    pause
    exit /b 1
)

echo Installation de LOGESCO v2...

:: Créer le répertoire d'installation
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    echo Répertoire d'installation créé: %INSTALL_DIR%
)

:: Copier les fichiers
echo Copie des fichiers d'application...
xcopy /E /I /Y "flutter_app\*" "%INSTALL_DIR%\app\"
xcopy /E /I /Y "api_server\*" "%INSTALL_DIR%\api\"
xcopy /E /I /Y "database\*" "%INSTALL_DIR%\database\"
xcopy /E /I /Y "config\*" "%INSTALL_DIR%\config\"

:: Configurer l'API comme service Windows
echo Configuration du service API...
sc create %SERVICE_NAME% binPath= "\"%INSTALL_DIR%\api\logesco-api.exe\"" start= auto DisplayName= "LOGESCO API Service"

if %errorLevel% equ 0 (
    echo Service %SERVICE_NAME% créé avec succès
) else (
    echo Erreur lors de la création du service
)

:: Démarrer le service
echo Démarrage du service API...
sc start %SERVICE_NAME%

:: Attendre que le service démarre
timeout /t 5 /nobreak >nul

:: Tester la connectivité API
echo Test de connectivité API...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:%API_PORT%/api/health' -TimeoutSec 10; if ($response.StatusCode -eq 200) { Write-Host 'API accessible - OK' } else { Write-Host 'API non accessible' } } catch { Write-Host 'Erreur de connexion API' }"

:: Créer les raccourcis
echo Création des raccourcis...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\LOGESCO v2.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\app\logesco_v2.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%\app'; $Shortcut.Save()"

powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\LOGESCO v2.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\app\logesco_v2.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%\app'; $Shortcut.Save()"

:: Configuration du pare-feu
echo Configuration du pare-feu Windows...
netsh advfirewall firewall add rule name="LOGESCO API" dir=in action=allow protocol=TCP localport=%API_PORT%

echo ========================================
echo Installation terminée avec succès!
echo ========================================
echo.
echo LOGESCO v2 a été installé dans: %INSTALL_DIR%
echo Service API: %SERVICE_NAME% (Port %API_PORT%)
echo.
echo Raccourcis créés:
echo - Bureau: LOGESCO v2
echo - Menu Démarrer: LOGESCO v2
echo.
echo L'application est prête à être utilisée.
echo.
pause