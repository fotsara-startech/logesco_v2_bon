@echo off
echo ========================================
echo   LOGESCO v2 - Preparation Client
echo   Version Amelioree (Gestion Erreurs)
echo ========================================
echo.

REM Vérifier les prérequis
echo [0/6] Verification des prerequis...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js n'est pas installe!
    echo.
    echo Veuillez installer Node.js 18 ou superieur:
    echo https://nodejs.org/
    echo.
    pause
    exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Flutter n'est pas installe!
    echo.
    echo Veuillez installer Flutter:
    echo https://flutter.dev/
    echo.
    pause
    exit /b 1
)

echo ✅ Node.js detecte
node --version
echo ✅ Flutter detecte
flutter --version | findstr "Flutter"
echo.

REM Nettoyer les anciens builds avec gestion d'erreurs
echo [1/6] Nettoyage des anciens builds...
if exist "dist-portable" (
    echo Suppression de dist-portable...
    attrib -R "dist-portable\*.*" /S /D >nul 2>nul
    rmdir /s /q "dist-portable" >nul 2>nul
    if exist "dist-portable" (
        echo ⚠️ Impossible de supprimer completement dist-portable
        echo Renommage en dist-portable-backup...
        ren "dist-portable" "dist-portable-backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%"
    )
)

if exist "release\LOGESCO-Client" (
    echo Suppression de release\LOGESCO-Client...
    attrib -R "release\LOGESCO-Client\*.*" /S /D >nul 2>nul
    rmdir /s /q "release\LOGESCO-Client" >nul 2>nul
)
echo ✅ Nettoyage termine
echo.

REM Construire le backend portable avec le script amélioré
echo [2/6] Construction du backend portable...
echo.
cd backend
echo Utilisation du script ameliore...
node build-portable-fixed.js
if errorlevel 1 (
    echo ❌ ERREUR: Build du backend echoue
    cd ..
    echo.
    echo 🔧 Solutions possibles:
    echo   1. Fermer tous les processus Node.js
    echo   2. Redemarrer en tant qu'administrateur
    echo   3. Verifier la connexion Internet
    echo   4. Executer: npm cache clean --force
    echo.
    pause
    exit /b 1
)
cd ..
echo ✅ Backend portable construit
echo.

REM Construire l'application Flutter
echo [3/6] Construction de l'application Flutter...
cd logesco_v2
echo Nettoyage Flutter...
call flutter clean >nul 2>nul
echo Recuperation des dependances...
call flutter pub get
if errorlevel 1 (
    echo ❌ ERREUR: flutter pub get echoue
    cd ..
    pause
    exit /b 1
)
echo Construction Windows...
call flutter build windows --release
if errorlevel 1 (
    echo ❌ ERREUR: Build Flutter echoue
    cd ..
    echo.
    echo 🔧 Solutions possibles:
    echo   1. Verifier que Visual Studio Build Tools est installe
    echo   2. Executer: flutter doctor
    echo   3. Nettoyer: flutter clean puis flutter pub get
    echo.
    pause
    exit /b 1
)
cd ..
echo ✅ Application Flutter construite
echo.

REM Créer le package client
echo [4/6] Creation du package client...
if not exist "release" mkdir "release"
if exist "release\LOGESCO-Client" rmdir /s /q "release\LOGESCO-Client"
mkdir "release\LOGESCO-Client"
mkdir "release\LOGESCO-Client\backend"
mkdir "release\LOGESCO-Client\app"

REM Copier le backend portable
echo Copie du backend portable...
xcopy /E /I /Y /Q "dist-portable\*" "release\LOGESCO-Client\backend\" >nul
if errorlevel 1 (
    echo ❌ ERREUR: Copie du backend echouee
    pause
    exit /b 1
)

REM Copier l'application Flutter
echo Copie de l'application Flutter...
xcopy /E /I /Y /Q "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client\app\" >nul
if errorlevel 1 (
    echo ❌ ERREUR: Copie de l'application echouee
    pause
    exit /b 1
)

echo ✅ Package client cree
echo.

REM Copier Visual C++ Redistributable
echo [5/6] Gestion Visual C++ Redistributable...
if not exist "release\LOGESCO-Client\vcredist" mkdir "release\LOGESCO-Client\vcredist"

REM Chercher VC Redist dans plusieurs emplacements
set VCREDIST_FOUND=0
if exist "logesco_v2\assets\VC_redist.x64.exe" (
    copy /Y "logesco_v2\assets\VC_redist.x64.exe" "release\LOGESCO-Client\vcredist\vc_redist.x64.exe" >nul
    set VCREDIST_FOUND=1
    echo ✅ VC Redist copie depuis logesco_v2\assets\VC_redist.x64.exe
) else if exist "logesco_v2\assets\vc_redist.x64.exe" (
    copy /Y "logesco_v2\assets\vc_redist.x64.exe" "release\LOGESCO-Client\vcredist\vc_redist.x64.exe" >nul
    set VCREDIST_FOUND=1
    echo ✅ VC Redist copie depuis logesco_v2\assets\vc_redist.x64.exe
) else if exist "assets\VC_redist.x64.exe" (
    copy /Y "assets\VC_redist.x64.exe" "release\LOGESCO-Client\vcredist\vc_redist.x64.exe" >nul
    set VCREDIST_FOUND=1
    echo ✅ VC Redist copie depuis assets\VC_redist.x64.exe
)

if %VCREDIST_FOUND%==0 (
    echo ⚠️ ATTENTION: VC_redist.x64.exe non trouve
    echo   Le package client n'inclura pas l'installeur VC Redistributable
    echo   Les utilisateurs devront le telecharger manuellement depuis:
    echo   https://aka.ms/vs/17/release/vc_redist.x64.exe
)
echo.

REM Créer les scripts de démarrage améliorés
echo [6/6] Creation des scripts de demarrage...

REM Script de vérification des prérequis amélioré
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
echo echo [1/3] Node.js...
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ NON INSTALLE
echo     echo.
echo     echo Telechargez et installez Node.js 18 ou superieur:
echo     echo https://nodejs.org/
echo     echo.
echo     set ALL_OK=0
echo ^) else ^(
echo     echo ✅ INSTALLE
echo     node --version
echo     echo.
echo     REM Verifier la version
echo     for /f "tokens=1" %%%%v in ^('node --version'^) do set NODE_VERSION=%%%%v
echo     echo Version detectee: %%NODE_VERSION%%
echo ^)
echo echo.
echo.
echo echo [2/3] Visual C++ Redistributable...
echo reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" ^>nul 2^>^&1
echo if errorlevel 1 ^(
echo     reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" ^>nul 2^>^&1
echo     if errorlevel 1 ^(
echo         echo ❌ NON INSTALLE
echo         echo.
echo         if exist "vcredist\vc_redist.x64.exe" ^(
echo             echo Installez: vcredist\vc_redist.x64.exe
echo         ^) else ^(
echo             echo Telechargez et installez:
echo             echo https://aka.ms/vs/17/release/vc_redist.x64.exe
echo         ^)
echo         echo.
echo         set ALL_OK=0
echo     ^) else ^(
echo         echo ✅ INSTALLE ^(WOW64^)
echo     ^)
echo ^) else ^(
echo     echo ✅ INSTALLE
echo ^)
echo echo.
echo.
echo echo [3/3] Port 8080...
echo netstat -an ^| find ":8080" ^>nul
echo if errorlevel 1 ^(
echo     echo ✅ LIBRE
echo ^) else ^(
echo     echo ⚠️ OCCUPE
echo     echo   Un autre programme utilise le port 8080
echo     echo   Fermez les autres applications ou changez le port
echo ^)
echo echo.
echo.
echo echo ========================================
echo if %%ALL_OK%%==1 ^(
echo     echo   ✅ Tous les prerequis sont installes
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

REM Script de démarrage robuste
(
echo @echo off
echo title LOGESCO v2 - Demarrage
echo echo ========================================
echo echo   LOGESCO v2 - Systeme de Gestion
echo echo ========================================
echo echo.
echo.
echo REM Verification Node.js
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ ERREUR: Node.js n'est pas installe!
echo     echo.
echo     echo Veuillez installer Node.js 18 ou superieur:
echo     echo https://nodejs.org/
echo     echo.
echo     echo Ou executez: VERIFIER-PREREQUIS.bat
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo ✅ Node.js detecte
echo node --version
echo echo.
echo.
echo REM Verification du backend
echo if not exist "backend\start-backend.bat" ^(
echo     echo ❌ ERREUR: Fichiers backend manquants!
echo     echo.
echo     echo Verifiez que le dossier backend\ est present
echo     echo et contient tous les fichiers necessaires.
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo REM Verification de l'application
echo if not exist "app\logesco_v2.exe" ^(
echo     echo ❌ ERREUR: Application manquante!
echo     echo.
echo     echo Verifiez que le fichier app\logesco_v2.exe existe.
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo [1/2] Demarrage du backend...
echo echo.
echo cd backend
echo start "LOGESCO Backend" /MIN cmd /c start-backend.bat
echo cd ..
echo echo ✅ Backend demarre en arriere-plan
echo echo   Attente de 10 secondes pour l'initialisation...
echo echo.
echo timeout /t 10 /nobreak ^>nul
echo.
echo echo [2/2] Demarrage de l'application...
echo echo.
echo start "" "app\logesco_v2.exe"
echo echo ✅ Application demarree
echo echo.
echo echo ========================================
echo echo   LOGESCO est maintenant actif
echo echo ========================================
echo echo.
echo echo 🌐 Backend: http://localhost:8080
echo echo 🔑 Connexion: admin / admin123
echo echo 📱 Interface: Application Windows
echo echo.
echo echo ℹ️ Cette fenetre peut etre fermee.
echo echo   Pour arreter LOGESCO, fermez l'application.
echo echo.
echo timeout /t 5 ^>nul
echo exit
) > "release\LOGESCO-Client\DEMARRER-LOGESCO.bat"

REM Script d'arrêt
(
echo @echo off
echo title LOGESCO v2 - Arret
echo echo ========================================
echo echo   LOGESCO v2 - Arret du Systeme
echo echo ========================================
echo echo.
echo.
echo echo Arret des processus LOGESCO...
echo echo.
echo taskkill /f /im logesco_v2.exe 2^>nul
echo taskkill /f /im node.exe 2^>nul
echo echo.
echo echo ✅ LOGESCO arrete
echo echo.
echo timeout /t 2 ^>nul
) > "release\LOGESCO-Client\ARRETER-LOGESCO.bat"

REM README détaillé pour le client
echo LOGESCO v2 - Systeme de Gestion Commerciale > "release\LOGESCO-Client\README.txt"
echo ============================================== >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo DEMARRAGE RAPIDE >> "release\LOGESCO-Client\README.txt"
echo ================ >> "release\LOGESCO-Client\README.txt"
echo 1. Double-cliquez sur: DEMARRER-LOGESCO.bat >> "release\LOGESCO-Client\README.txt"
echo 2. Attendez que l'application s'ouvre >> "release\LOGESCO-Client\README.txt"
echo 3. Connectez-vous avec: admin / admin123 >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo PREREQUIS >> "release\LOGESCO-Client\README.txt"
echo --------- >> "release\LOGESCO-Client\README.txt"
echo - Windows 10/11 (64-bit) >> "release\LOGESCO-Client\README.txt"
echo - Node.js 18 ou superieur (https://nodejs.org/) >> "release\LOGESCO-Client\README.txt"
echo - Visual C++ Redistributable (inclus ou telechargeable) >> "release\LOGESCO-Client\README.txt"
echo - 500 MB d'espace disque libre >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo VERIFICATION >> "release\LOGESCO-Client\README.txt"
echo ============= >> "release\LOGESCO-Client\README.txt"
echo Avant le premier demarrage, executez: >> "release\LOGESCO-Client\README.txt"
echo VERIFIER-PREREQUIS.bat >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo SCRIPTS DISPONIBLES >> "release\LOGESCO-Client\README.txt"
echo =================== >> "release\LOGESCO-Client\README.txt"
echo DEMARRER-LOGESCO.bat     - Lance le systeme complet >> "release\LOGESCO-Client\README.txt"
echo ARRETER-LOGESCO.bat      - Arrete tous les processus >> "release\LOGESCO-Client\README.txt"
echo VERIFIER-PREREQUIS.bat   - Verifie l'installation >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo CONNEXION PAR DEFAUT >> "release\LOGESCO-Client\README.txt"
echo ==================== >> "release\LOGESCO-Client\README.txt"
echo Nom d'utilisateur: admin >> "release\LOGESCO-Client\README.txt"
echo Mot de passe: admin123 >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo STRUCTURE >> "release\LOGESCO-Client\README.txt"
echo ========= >> "release\LOGESCO-Client\README.txt"
echo backend\                 - Serveur backend (Node.js) >> "release\LOGESCO-Client\README.txt"
echo app\                     - Application LOGESCO >> "release\LOGESCO-Client\README.txt"
echo vcredist\                - Visual C++ Redistributable >> "release\LOGESCO-Client\README.txt"
echo *.bat                    - Scripts de gestion >> "release\LOGESCO-Client\README.txt"
echo README.txt               - Ce fichier >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo DEPANNAGE >> "release\LOGESCO-Client\README.txt"
echo ========= >> "release\LOGESCO-Client\README.txt"
echo 1. Executez: VERIFIER-PREREQUIS.bat >> "release\LOGESCO-Client\README.txt"
echo 2. Verifiez que Node.js est installe: node --version >> "release\LOGESCO-Client\README.txt"
echo 3. Consultez les logs: backend\logs\error.log >> "release\LOGESCO-Client\README.txt"
echo 4. Verifiez le port 8080 n'est pas utilise >> "release\LOGESCO-Client\README.txt"
echo 5. Redemarrez en tant qu'administrateur >> "release\LOGESCO-Client\README.txt"
echo. >> "release\LOGESCO-Client\README.txt"
echo SUPPORT >> "release\LOGESCO-Client\README.txt"
echo ======= >> "release\LOGESCO-Client\README.txt"
echo Version: 2.0 >> "release\LOGESCO-Client\README.txt"
echo Date: %date% >> "release\LOGESCO-Client\README.txt"
echo Systeme: Windows >> "release\LOGESCO-Client\README.txt"

echo ✅ Scripts de demarrage crees
echo.

REM Calculer la taille approximative
echo Calcul de la taille du package...
for /f %%i in ('dir "release\LOGESCO-Client" /s /-c ^| find "bytes"') do set SIZE=%%i
echo.

echo ========================================
echo   Preparation terminee avec succes!
echo ========================================
echo.
echo 📦 Package client pret dans:
echo    release\LOGESCO-Client\
echo.
echo 📂 Contenu:
echo    ✅ DEMARRER-LOGESCO.bat (Lance tout)
echo    ✅ ARRETER-LOGESCO.bat (Arrete tout)
echo    ✅ VERIFIER-PREREQUIS.bat (Diagnostic)
echo    ✅ backend\ (Serveur Node.js)
echo    ✅ app\ (Application Flutter)
echo    ✅ README.txt (Instructions detaillees)
if %VCREDIST_FOUND%==1 (
    echo    ✅ vcredist\ (Visual C++ Redistributable)
) else (
    echo    ⚠️ vcredist\ (VC Redist manquant)
)
echo.
echo 📊 Taille approximative: ~300-500 MB
echo.
echo 🧪 Pour tester:
echo    cd release\LOGESCO-Client
echo    VERIFIER-PREREQUIS.bat
echo    DEMARRER-LOGESCO.bat
echo.
echo 📦 Pour distribuer:
echo    1. Compresser LOGESCO-Client en ZIP
echo    2. Ou creer un installeur avec InnoSetup
echo    3. Inclure les instructions du README.txt
echo.
echo 🔑 Identifiants par defaut:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
pause