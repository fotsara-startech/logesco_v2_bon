@echo off
REM Script pour compiler les versions CLIENT et SERVER de LOGESCO

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Compilation des versions CLIENT et SERVER
echo ========================================
echo.

REM Vérifier que Flutter est installé
flutter --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter n'est pas installé ou n'est pas dans le PATH
    pause
    exit /b 1
)

cd logesco_v2

REM ========================================
REM Compilation VERSION CLIENT
REM ========================================

echo.
echo 🔨 Compilation VERSION CLIENT...
echo.

REM Modifier app_config.dart pour le mode CLIENT
powershell -Command "(Get-Content lib\core\config\app_config.dart) -replace 'static const bool isClientMode = false;', 'static const bool isClientMode = true;' | Set-Content lib\core\config\app_config.dart"

REM Nettoyer les builds précédents
echo Nettoyage des builds précédents...
flutter clean

REM Compiler
echo Compilation en cours...
flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors de la compilation CLIENT
    pause
    exit /b 1
)

REM Copier l'exécutable
echo Copie de l'exécutable CLIENT...
copy build\windows\runner\Release\logesco.exe ..\logesco-client.exe

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors de la copie de l'exécutable CLIENT
    pause
    exit /b 1
)

echo ✅ VERSION CLIENT compilée avec succès

REM ========================================
REM Compilation VERSION SERVER
REM ========================================

echo.
echo 🔨 Compilation VERSION SERVER...
echo.

REM Modifier app_config.dart pour le mode SERVER
powershell -Command "(Get-Content lib\core\config\app_config.dart) -replace 'static const bool isClientMode = true;', 'static const bool isClientMode = false;' | Set-Content lib\core\config\app_config.dart"

REM Nettoyer les builds précédents
echo Nettoyage des builds précédents...
flutter clean

REM Compiler
echo Compilation en cours...
flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors de la compilation SERVER
    pause
    exit /b 1
)

REM Copier l'exécutable
echo Copie de l'exécutable SERVER...
copy build\windows\runner\Release\logesco.exe ..\logesco-server.exe

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors de la copie de l'exécutable SERVER
    pause
    exit /b 1
)

echo ✅ VERSION SERVER compilée avec succès

REM ========================================
REM Restaurer la configuration CLIENT par défaut
REM ========================================

echo.
echo 🔄 Restauration de la configuration CLIENT par défaut...
powershell -Command "(Get-Content lib\core\config\app_config.dart) -replace 'static const bool isClientMode = false;', 'static const bool isClientMode = true;' | Set-Content lib\core\config\app_config.dart"

cd ..

REM ========================================
REM Résumé
REM ========================================

echo.
echo ========================================
echo ✅ Compilation terminée avec succès!
echo ========================================
echo.
echo 📦 Fichiers générés:
echo   - logesco-client.exe (Version CLIENT)
echo   - logesco-server.exe (Version SERVER)
echo.
echo 📋 Prochaines étapes:
echo   1. Testez les deux versions
echo   2. Créez les packages de distribution
echo   3. Distribuez aux clients
echo.

pause
