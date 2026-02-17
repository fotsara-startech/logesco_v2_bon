@echo off
echo ========================================
echo   LOGESCO v2 - Preparation Client
echo ========================================
echo.

REM Nettoyer les anciens builds
echo [1/5] Nettoyage des anciens builds...
if exist "dist-portable" rmdir /s /q "dist-portable"
if exist "release\LOGESCO-Client" rmdir /s /q "release\LOGESCO-Client"
echo ✓ Nettoyage termine
echo.

REM Construire le backend portable
echo [2/5] Construction du backend portable...
call build-portable-backend.bat
if errorlevel 1 (
    echo ERREUR: Build du backend echoue
    pause
    exit /b 1
)
echo ✓ Backend portable construit
echo.

REM Construire l'application Flutter
echo [3/5] Construction de l'application Flutter...
cd logesco_v2
call flutter pub get
call flutter build windows --release
if errorlevel 1 (
    echo ERREUR: Build Flutter echoue
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✓ Application Flutter construite
echo.

REM Créer le package client
echo [4/5] Creation du package client...
if not exist "release" mkdir "release"
if exist "release\LOGESCO-Client" rmdir /s /q "release\LOGESCO-Client"
mkdir "release\LOGESCO-Client"
mkdir "release\LOGESCO-Client\backend"
mkdir "release\LOGESCO-Client\app"

REM Copier le backend portable
echo Copie du backend portable...
xcopy /E /I /Y "dist-portable\*" "release\LOGESCO-Client\backend\"

REM Copier l'application Flutter
echo Copie de l'application Flutter...
xcopy /E /I /Y "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client\app\"

REM Copier les DLL Visual C++ Runtime
echo Copie des DLL Visual C++ Runtime...
call scripts\copy-vcredist-dlls.bat "release\LOGESCO-Client\app"

echo ✓ Package client cree
echo.

REM Copier Visual C++ Redistributable depuis assets
echo Copie de Visual C++ Redistributable...
if not exist "release\LOGESCO-Client\vcredist" mkdir "release\LOGESCO-Client\vcredist"
if exist "logesco_v2\assets\VC_redist.x64.exe" (
    copy /Y "logesco_v2\assets\VC_redist.x64.exe" "release\LOGESCO-Client\vcredist\vc_redist.x64.exe" >nul
    echo ✓ VC Redist copie depuis logesco_v2\assets
) else if exist "logesco_v2\assets\vc_redist.x64.exe" (
    copy /Y "logesco_v2\assets\vc_redist.x64.exe" "release\LOGESCO-Client\vcredist\vc_redist.x64.exe" >nul
    echo ✓ VC Redist copie depuis logesco_v2\assets
) else (
    echo ⚠ ATTENTION: VC_redist.x64.exe non trouve dans logesco_v2\assets
    echo   Le package client n'inclura pas l'installeur VC Redistributable
    echo   Les utilisateurs devront le telecharger manuellement
)
echo.

REM Créer les scripts de démarrage
echo [5/5] Creation des scripts de demarrage...

REM Script de vérification des prérequis
(
echo @echo off
echo title Verification des Prerequis LOGESCO
echo echo ========================================
echo echo   Verification des Prerequis LOGESCO
echo echo ========================================
echo echo.
echo.
echo set ALL_OK=1
echo.
echo echo [1/2] Node.js...
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ NON INSTALLE
echo     echo.
echo     echo Telechargez et installez Node.js 18 ou superieur:
echo     echo https://nodejs.org/
echo     echo.
echo     set ALL_OK=0
echo ^) else ^(
echo     echo ✓ INSTALLE
echo     node --version
echo ^)
echo echo.
echo.
echo echo [2/2] Visual C++ Redistributable...
echo reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" ^>nul 2^>^&1
echo if errorlevel 1 ^(
echo     echo ❌ NON INSTALLE
echo     echo.
echo     echo Installez: vcredist\vc_redist.x64.exe
echo     echo ou telechargez:
echo     echo https://aka.ms/vs/17/release/vc_redist.x64.exe
echo     echo.
echo     set ALL_OK=0
echo ^) else ^(
echo     echo ✓ INSTALLE
echo ^)
echo echo.
echo.
echo echo ========================================
echo if %%ALL_OK%%==1 ^(
echo     echo   ✓ Tous les prerequis sont installes
echo     echo.
echo     echo   Vous pouvez lancer LOGESCO avec:
echo     echo   DEMARRER-LOGESCO.bat
echo ^) else ^(
echo     echo   ❌ Prerequis manquants
echo     echo.
echo     echo   Installez les composants manquants
echo     echo   puis relancez cette verification.
echo ^)
echo echo ========================================
echo echo.
echo pause
) > "release\LOGESCO-Client\VERIFIER-PREREQUIS.bat"

REM Script de démarrage complet
(
echo @echo off
echo title LOGESCO v2
echo echo ========================================
echo echo   LOGESCO v2 - Demarrage
echo echo ========================================
echo echo.
echo.
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ ERREUR: Node.js n'est pas installe!
echo     echo.
echo     echo Veuillez installer Node.js 18 ou superieur:
echo     echo https://nodejs.org/
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo ✓ Node.js detecte
echo node --version
echo echo.
echo.
echo echo [1/2] Demarrage du backend...
echo echo.
echo cd backend
echo start "LOGESCO Backend" /MIN cmd /c start-backend.bat
echo cd ..
echo echo ✓ Backend demarre en arriere-plan
echo echo   Attente de 8 secondes pour l'initialisation...
echo echo.
echo timeout /t 8 /nobreak ^>nul
echo.
echo echo [2/2] Demarrage de l'application...
echo echo.
echo start "" "app\logesco_v2.exe"
echo echo ✓ Application demarree
echo echo.
echo echo ========================================
echo echo   LOGESCO est maintenant en cours
echo echo ========================================
echo echo.
echo echo Backend: http://localhost:8080
echo echo Connexion: admin / admin123
echo echo.
echo echo Cette fenetre peut etre fermee.
echo echo.
echo timeout /t 3 ^>nul
echo exit
) > "release\LOGESCO-Client\DEMARRER-LOGESCO.bat"

REM README pour le client
echo LOGESCO v2 - Systeme de Gestion Commerciale > "release\LOGESCO-Client\README.txt"
echo ============================================== >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo PREREQUIS >> "release\LOGESCO-Client\README.txt"
echo --------- >> "release\LOGESCO-Client\README.txt"
echo - Windows 10/11 (64-bit) >> "release\LOGESCO-Client\README.txt"
echo - Node.js 18 ou superieur >> "release\LOGESCO-Client\README.txt"
echo   Telecharger: https://nodejs.org/ >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo INSTALLATION >> "release\LOGESCO-Client\README.txt"
echo ------------ >> "release\LOGESCO-Client\README.txt"
echo 1. Installer Node.js si pas deja installe >> "release\LOGESCO-Client\README.txt"
echo 2. Extraire ce dossier ou vous voulez >> "release\LOGESCO-Client\README.txt"
echo 3. Double-cliquer sur: DEMARRER-LOGESCO.bat >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo DEMARRAGE >> "release\LOGESCO-Client\README.txt"
echo --------- >> "release\LOGESCO-Client\README.txt"
echo Double-cliquez sur: DEMARRER-LOGESCO.bat >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo Le backend demarre automatiquement en arriere-plan, >> "release\LOGESCO-Client\README.txt"
echo puis l'application s'ouvre. >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo CONNEXION PAR DEFAUT >> "release\LOGESCO-Client\README.txt"
echo -------------------- >> "release\LOGESCO-Client\README.txt"
echo Nom d'utilisateur: admin >> "release\LOGESCO-Client\README.txt"
echo Mot de passe: admin123 >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo DEMARRAGE AUTOMATIQUE (Optionnel) >> "release\LOGESCO-Client\README.txt"
echo ---------------------------------- >> "release\LOGESCO-Client\README.txt"
echo Pour que le backend demarre automatiquement au boot: >> "release\LOGESCO-Client\README.txt"
echo 1. Ouvrir: backend\ >> "release\LOGESCO-Client\README.txt"
echo 2. Executer en admin: install-service.bat >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo STRUCTURE >> "release\LOGESCO-Client\README.txt"
echo --------- >> "release\LOGESCO-Client\README.txt"
echo DEMARRER-LOGESCO.bat  - Lance backend + application >> "release\LOGESCO-Client\README.txt"
echo backend\              - Serveur backend (Node.js) >> "release\LOGESCO-Client\README.txt"
echo app\                  - Application LOGESCO >> "release\LOGESCO-Client\README.txt"
echo README.txt            - Ce fichier >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo SUPPORT >> "release\LOGESCO-Client\README.txt"
echo ------- >> "release\LOGESCO-Client\README.txt"
echo En cas de probleme: >> "release\LOGESCO-Client\README.txt"
echo 1. Verifier que Node.js est installe: node --version >> "release\LOGESCO-Client\README.txt"
echo 2. Consulter les logs: backend\logs\error.log >> "release\LOGESCO-Client\README.txt"
echo 3. Verifier le port 8080 n'est pas utilise >> "release\LOGESCO-Client\README.txt"

echo ✓ Scripts de demarrage crees
echo.

echo ========================================
echo   Preparation terminee avec succes!
echo ========================================
echo.
echo 📦 Package client pret dans:
echo    release\LOGESCO-Client\
echo.
echo 📂 Contenu:
echo    - DEMARRER-LOGESCO.bat (Lance tout)
echo    - backend\ (Serveur Node.js)
echo    - app\ (Application Flutter)
echo    - README.txt (Instructions)
echo.
echo 📊 Taille approximative: ~200 MB
echo.
echo 🚀 Pour tester:
echo    cd release\LOGESCO-Client
echo    DEMARRER-LOGESCO.bat
echo.
echo 📦 Pour distribuer:
echo    Compresser le dossier LOGESCO-Client en ZIP
echo    ou creer un installeur avec InnoSetup
echo.
pause
