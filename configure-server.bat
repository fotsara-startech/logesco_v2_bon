@echo off
REM Script pour configurer l'adresse du serveur LOGESCO
REM Ce script crée un fichier de configuration que l'app Flutter lira au démarrage

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Configuration du serveur LOGESCO
echo ========================================
echo.

REM Demander l'adresse IP du serveur
set /p SERVER_IP="Entrez l'adresse IP du serveur (ex: 192.168.100.101): "

REM Demander le port (par défaut 8080)
set /p SERVER_PORT="Entrez le port du serveur (par défaut 8080): "
if "!SERVER_PORT!"=="" set SERVER_PORT=8080

REM Construire l'URL complète
set SERVER_URL=http://!SERVER_IP!:!SERVER_PORT!/api/v1

echo.
echo URL du serveur: !SERVER_URL!
echo.

REM Créer le fichier de configuration dans le répertoire Documents
set CONFIG_DIR=%USERPROFILE%\Documents
set CONFIG_FILE=!CONFIG_DIR!\server_config.txt

echo Création du fichier de configuration...
echo !SERVER_URL! > "!CONFIG_FILE!"

if exist "!CONFIG_FILE!" (
    echo.
    echo ✓ Configuration sauvegardée avec succès!
    echo Fichier: !CONFIG_FILE!
    echo.
    echo Redémarrez l'application LOGESCO pour appliquer les changements.
    echo.
) else (
    echo.
    echo ✗ Erreur lors de la création du fichier de configuration
    echo.
)

pause
