@echo off
REM ============================================================
REM LOGESCO v2 - Build Client Réseau (Frontend uniquement)
REM Script pour compiler l'installeur client réseau
REM ============================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo LOGESCO v2 - Build Client Réseau (Frontend uniquement)
echo ============================================================
echo.

REM Vérifier que nous sommes dans le bon répertoire
if not exist "logesco_v2" (
    echo ERREUR: Le dossier 'logesco_v2' n'existe pas
    echo Assurez-vous d'exécuter ce script depuis la racine du projet
    pause
    exit /b 1
)

REM Vérifier que Inno Setup est installé
if not exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo ERREUR: Inno Setup 6 n'est pas installé
    echo Téléchargez-le depuis: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

echo [1/4] Nettoyage des anciens builds...
if exist "logesco_v2\build\windows" (
    rmdir /s /q "logesco_v2\build\windows"
    echo ✓ Ancien build supprimé
)

echo.
echo [2/4] Compilation Flutter (Frontend uniquement)...
cd logesco_v2
call flutter clean
if errorlevel 1 (
    echo ERREUR: Échec du flutter clean
    cd ..
    pause
    exit /b 1
)

call flutter pub get
if errorlevel 1 (
    echo ERREUR: Échec du flutter pub get
    cd ..
    pause
    exit /b 1
)

call flutter build windows --release
if errorlevel 1 (
    echo ERREUR: Échec de la compilation Flutter
    cd ..
    pause
    exit /b 1
)

echo ✓ Compilation Flutter réussie
cd ..

echo.
echo [3/4] Vérification des fichiers compilés...
if not exist "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe" (
    echo ERREUR: logesco_v2.exe n'a pas été généré
    pause
    exit /b 1
)
echo ✓ Fichiers compilés trouvés

echo.
echo [4/4] Création de l'installeur Inno Setup...
if not exist "release" mkdir release

REM Compiler le script Inno Setup
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /O"release" "installer-setup-client-network.iss"

if errorlevel 1 (
    echo ERREUR: Échec de la compilation Inno Setup
    pause
    exit /b 1
)

echo ✓ Installeur créé avec succès

echo.
echo ============================================================
echo BUILD RÉUSSI!
echo ============================================================
echo.
echo Fichier d'installation:
echo   release\LOGESCO-v2-Client-Network-Setup.exe
echo.
echo Cet installeur contient:
echo   - Application Flutter (frontend uniquement)
echo   - Aucun backend
echo   - Aucune base de données locale
echo   - Configuration serveur à fournir au premier démarrage
echo.
echo Pour distribuer aux clients:
echo   1. Copiez le fichier .exe
echo   2. Fournissez l'adresse du serveur LOGESCO
echo   3. Fournissez les identifiants de connexion
echo.
pause
