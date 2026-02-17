@echo off
echo ========================================
echo LOGESCO v2 - Build Complete Local Package
echo ========================================

set "DIST_DIR=%~dp0..\dist"
set "PACKAGE_DIR=%DIST_DIR%\LOGESCO-Local-Package"

:: Nettoyer le répertoire de distribution
if exist "%DIST_DIR%" (
    echo Nettoyage du répertoire de distribution...
    rmdir /s /q "%DIST_DIR%"
)

mkdir "%DIST_DIR%"
mkdir "%PACKAGE_DIR%"

echo.
echo Étape 1/5: Build de l'application Flutter Desktop...
call "%~dp0build-desktop.bat"

echo.
echo Étape 2/5: Build de l'API Node.js standalone...
call "%~dp0build-api.bat"

echo.
echo Étape 3/5: Création de la base de données SQLite...
node "%~dp0create-sqlite-db.js"

echo.
echo Étape 4/5: Assemblage du package d'installation...

:: Créer la structure du package
mkdir "%PACKAGE_DIR%\flutter_app"
mkdir "%PACKAGE_DIR%\api_server"
mkdir "%PACKAGE_DIR%\database"
mkdir "%PACKAGE_DIR%\config"
mkdir "%PACKAGE_DIR%\installer"
mkdir "%PACKAGE_DIR%\docs"

:: Copier l'application Flutter
echo Copie de l'application Flutter...
xcopy /E /I /Y "%~dp0..\logesco_v2\build\windows\x64\runner\Release\*" "%PACKAGE_DIR%\flutter_app\"

:: Copier l'API
echo Copie de l'API...
copy "%DIST_DIR%\logesco-api.exe" "%PACKAGE_DIR%\api_server\"
xcopy /E /I /Y "%DIST_DIR%\config\*" "%PACKAGE_DIR%\config\"

:: Copier la base de données
echo Copie de la base de données...
copy "%DIST_DIR%\database\logesco.db" "%PACKAGE_DIR%\database\"

:: Copier les scripts d'installation
echo Copie des scripts d'installation...
copy "%~dp0installer.bat" "%PACKAGE_DIR%\installer\"

:: Créer la documentation
echo Création de la documentation...
echo LOGESCO v2 - Guide d'Installation > "%PACKAGE_DIR%\docs\README.txt"
echo. >> "%PACKAGE_DIR%\docs\README.txt"
echo 1. Exécuter installer\installer.bat en tant qu'administrateur >> "%PACKAGE_DIR%\docs\README.txt"
echo 2. Suivre les instructions à l'écran >> "%PACKAGE_DIR%\docs\README.txt"
echo 3. Lancer LOGESCO v2 depuis le bureau ou le menu démarrer >> "%PACKAGE_DIR%\docs\README.txt"

echo.
echo Étape 5/5: Création de l'archive d'installation...

:: Créer un script PowerShell pour compresser
echo $source = '%PACKAGE_DIR%' > "%DIST_DIR%\compress.ps1"
echo $destination = '%DIST_DIR%\LOGESCO-v2-Local-Setup.zip' >> "%DIST_DIR%\compress.ps1"
echo Compress-Archive -Path $source -DestinationPath $destination -Force >> "%DIST_DIR%\compress.ps1"

powershell -ExecutionPolicy Bypass -File "%DIST_DIR%\compress.ps1"

echo.
echo ========================================
echo Package local créé avec succès!
echo ========================================
echo.
echo Fichiers générés:
echo - Package complet: %PACKAGE_DIR%
echo - Archive d'installation: %DIST_DIR%\LOGESCO-v2-Local-Setup.zip
echo.
echo Le package est prêt pour distribution aux clients.
echo.
pause