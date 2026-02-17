@echo off
echo ========================================
echo   LOGESCO v2 - Build Production
echo ========================================
echo.

REM Étape 1: Build du backend portable
echo [1/4] Construction du backend portable...
call build-portable-backend.bat
if errorlevel 1 (
    echo ERREUR: Build du backend echoue
    pause
    exit /b 1
)
echo ✓ Backend portable construit avec succes
echo.

REM Étape 2: Preparer le backend pour l'installeur
echo [2/4] Preparation du backend pour l'installeur...
if not exist "release\installer-files\backend" mkdir "release\installer-files\backend"
xcopy /E /I /Y "dist-portable\*" "release\installer-files\backend\"
echo ✓ Backend prepare pour l'installeur
echo.

REM Étape 3: Build de l'application Flutter
echo [3/4] Construction de l'application Flutter...
cd logesco_v2
call flutter pub get
if errorlevel 1 (
    echo ERREUR: Installation des dependances Flutter echouee
    pause
    exit /b 1
)

call flutter build windows --release
if errorlevel 1 (
    echo ERREUR: Build Flutter echoue
    pause
    exit /b 1
)
cd ..
echo ✓ Application Flutter construite avec succes
echo.

REM Étape 4: Créer le package de distribution
echo [4/4] Creation du package de distribution...
if not exist "release" mkdir "release"
if exist "release\LOGESCO" rmdir /s /q "release\LOGESCO"
mkdir "release\LOGESCO"

REM Copier l'application Flutter
xcopy /E /I /Y "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO\"

REM Créer un README
echo LOGESCO v2 - Systeme de Gestion Commerciale > "release\LOGESCO\README.txt"
echo. >> "release\LOGESCO\README.txt"
echo Installation: >> "release\LOGESCO\README.txt"
echo 1. Double-cliquez sur logesco_v2.exe >> "release\LOGESCO\README.txt"
echo 2. L'application demarre automatiquement >> "release\LOGESCO\README.txt"
echo. >> "release\LOGESCO\README.txt"
echo Le backend demarre automatiquement en arriere-plan. >> "release\LOGESCO\README.txt"
echo Aucune configuration requise. >> "release\LOGESCO\README.txt"

echo ✓ Package cree dans release\LOGESCO
echo.

echo ========================================
echo   Build termine avec succes!
echo ========================================
echo.
echo 📦 Package pret: release\LOGESCO\
echo 📝 Executable: release\LOGESCO\logesco_v2.exe
echo.
echo Vous pouvez maintenant:
echo 1. Tester l'application: cd release\LOGESCO ^&^& logesco_v2.exe
echo 2. Creer un installeur avec InnoSetup
echo 3. Distribuer le dossier LOGESCO complet
echo.
pause
