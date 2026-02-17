@echo off
echo ========================================
echo LOGESCO v2 - Tests Flutter
echo ========================================
echo.

set "info=echo [INFO]"
set "success=echo [SUCCESS]"
set "error=echo [ERROR]"
set "warning=echo [WARNING]"

%info% Verification de Flutter...
flutter --version >nul 2>&1
if errorlevel 1 (
    %error% Flutter n'est pas installe ou non accessible
    pause
    exit /b 1
)

%success% Flutter detecte

echo.
%info% Etape 1: Installation des dependances...
call flutter pub get
if errorlevel 1 (
    %error% Echec de l'installation des dependances
    pause
    exit /b 1
)

%success% Dependances installees

echo.
%info% Etape 2: Verification de la configuration...
call flutter doctor
if errorlevel 1 (
    %warning% Problemes detectes par Flutter Doctor
    %info% Continuez-vous quand meme? (O/N)
    set /p choice="Votre choix: "
    if /i not "%choice%"=="O" (
        exit /b 1
    )
)

echo.
%info% Etape 3: Tests unitaires...
call flutter test
if errorlevel 1 (
    %error% Echec des tests unitaires
    pause
    exit /b 1
)

%success% Tests unitaires reussis

echo.
%info% Etape 4: Tests d'integration...
%warning% Les tests d'integration necessitent un emulateur ou un appareil connecte
%info% Voulez-vous lancer les tests d'integration? (O/N)
set /p choice2="Votre choix: "
if /i "%choice2%"=="O" (
    %info% Verification des appareils connectes...
    call flutter devices
    
    %info% Lancement des tests d'integration...
    call flutter test integration_test/app_test.dart
    if errorlevel 1 (
        %warning% Certains tests d'integration ont echoue
    ) else (
        %success% Tests d'integration reussis
    )
)

echo.
%info% Etape 5: Application de demonstration...
%info% Voulez-vous lancer l'application pour tests manuels? (O/N)
set /p choice3="Votre choix: "
if /i "%choice3%"=="O" (
    %info% Lancement de l'application Flutter...
    %info% Utilisez Ctrl+C pour arreter l'application
    call flutter run
)

echo.
echo ========================================
%success% TESTS FLUTTER TERMINES
echo ========================================
echo.
%info% Resultats:
echo   - Tests unitaires: Executes
echo   - Tests d'integration: Selon choix utilisateur
echo   - Application: Selon choix utilisateur
echo.
%info% Pour relancer les tests:
echo   flutter test                    (tests unitaires)
echo   flutter test integration_test/  (tests d'integration)
echo   flutter run                     (application)
echo.
pause