@echo off
echo ========================================
echo LOGESCO v2 - Test complet des fonctionnalites
echo Avec donnees reelles - Pas de mock data
echo ========================================
echo.

:: Configuration des couleurs pour Windows
for /f %%A in ('"prompt $H &echo on &for %%B in (1) do rem"') do set BS=%%A

:: Fonction pour afficher en couleur
set "info=echo [INFO]"
set "success=echo [SUCCESS]"
set "error=echo [ERROR]"
set "warning=echo [WARNING]"

%info% Verification des prerequis...

:: Verifier Node.js
node --version >nul 2>&1
if errorlevel 1 (
    %error% Node.js n'est pas installe ou non accessible
    pause
    exit /b 1
)

:: Verifier Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    %error% Flutter n'est pas installe ou non accessible
    pause
    exit /b 1
)

%success% Prerequis valides

echo.
%info% Etape 1: Configuration de l'environnement de test...
cd backend
call node scripts/setup-test-environment.js
if errorlevel 1 (
    %error% Echec de la configuration de l'environnement
    pause
    exit /b 1
)

echo.
%info% Etape 1.5: Desactivation du rate limiting pour les tests...
call npm run rate-limit:disable
if errorlevel 1 (
    %warning% Probleme avec la desactivation du rate limiting
)

echo.
%info% Etape 2: Installation des dependances backend...
call npm install
if errorlevel 1 (
    %error% Echec de l'installation des dependances backend
    pause
    exit /b 1
)

echo.
%info% Etape 3: Configuration de la base de donnees...
call npm run db:setup
if errorlevel 1 (
    %warning% Probleme avec la base de donnees, tentative de reset...
    call npm run db:reset
)

echo.
%info% Etape 4: Demarrage du serveur backend...
%info% Le serveur va demarrer en arriere-plan...
start "LOGESCO Backend Server" cmd /k "npm run dev"

:: Attendre que le serveur soit pret
%info% Attente du demarrage du serveur (10 secondes)...
timeout /t 10 /nobreak >nul

echo.
%info% Etape 5: Test de connectivite du serveur...
curl -s http://localhost:8080 >nul 2>&1
if errorlevel 1 (
    %error% Le serveur ne repond pas sur le port 8080
    %info% Verifiez que le serveur a demarre correctement
    pause
    exit /b 1
)

%success% Serveur backend operationnel

echo.
%info% Etape 6: Execution des tests backend avec donnees reelles...
call node scripts/comprehensive-real-data-test.js
if errorlevel 1 (
    %error% Echec des tests backend
    pause
    exit /b 1
)

%success% Tests backend termines avec succes

echo.
%info% Etape 7: Configuration Flutter...
cd ..\logesco_v2
call flutter pub get
if errorlevel 1 (
    %error% Echec de l'installation des dependances Flutter
    pause
    exit /b 1
)

echo.
%info% Etape 8: Configuration Flutter...
cd ..\logesco_v2
call flutter pub get
if errorlevel 1 (
    %error% Echec de l'installation des dependances Flutter
    pause
    exit /b 1
)

echo.
%info% Etape 9: Tests unitaires Flutter...
call flutter test
if errorlevel 1 (
    %warning% Certains tests unitaires Flutter ont echoue
) else (
    %success% Tests unitaires Flutter reussis
)

echo.
%info% Etape 10: Tests d'integration Flutter...
%warning% Les tests Flutter necessitent un emulateur ou un appareil connecte
%info% Voulez-vous lancer les tests d'integration Flutter? (O/N)
set /p choice="Votre choix: "
if /i "%choice%"=="O" (
    %info% Verification des appareils connectes...
    call flutter devices
    
    %info% Lancement des tests d'integration Flutter...
    call flutter test integration_test/app_test.dart
    if errorlevel 1 (
        %warning% Certains tests d'integration Flutter ont echoue
    ) else (
        %success% Tests d'integration Flutter termines avec succes
    )
)

echo.
%info% Etape 11: Lancement de l'application Flutter pour tests manuels...
%info% Voulez-vous lancer l'application Flutter pour tests manuels? (O/N)
set /p choice2="Votre choix: "
if /i "%choice2%"=="O" (
    %info% Lancement de l'application Flutter...
    %info% Utilisez Ctrl+C pour arreter l'application
    call flutter run
)

echo.
echo ========================================
%success% TESTS COMPLETS TERMINES
echo ========================================
echo.
%info% Resultats disponibles dans:
echo   - backend/scripts/test-results/test-results.json
echo   - Logs du serveur dans la fenetre separee
echo.
%info% Pour arreter le serveur backend:
echo   - Fermez la fenetre "LOGESCO Backend Server"
echo   - Ou utilisez Ctrl+C dans cette fenetre
echo.
%info% Donnees de test creees:
echo   - Utilisateurs de test
echo   - Fournisseurs realistes
echo   - Clients varies (particuliers/entreprises)
echo   - Produits avec prix reels
echo   - Comptes bancaires
echo   - Mouvements de stock
echo.
%warning% Pour nettoyer les donnees de test:
echo   cd backend
echo   npm run db:reset
echo.
pause