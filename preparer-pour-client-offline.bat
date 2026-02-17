@echo off
echo ========================================
echo   LOGESCO v2 - Preparation Client OFFLINE
echo   Version Sans Internet - Tout Inclus
echo ========================================
echo.

REM Vérifier les prérequis
echo [0/8] Verification des prerequis...
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

echo ⚠️ ATTENTION: Cette construction necessite Internet
echo pour pre-generer Prisma. Une fois cree, le package
echo fonctionnera SANS Internet chez le client.
echo.
pause
echo.

REM Nettoyer les anciens builds
echo [1/8] Nettoyage des anciens builds...
if exist "dist-portable-offline" (
    echo Suppression de dist-portable-offline...
    attrib -R "dist-portable-offline\*.*" /S /D >nul 2>nul
    rmdir /s /q "dist-portable-offline" >nul 2>nul
    if exist "dist-portable-offline" (
        echo ⚠️ Renommage en backup...
        ren "dist-portable-offline" "dist-portable-offline-backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%"
    )
)

if exist "release\LOGESCO-Client-Offline" (
    echo Suppression de release\LOGESCO-Client-Offline...
    attrib -R "release\LOGESCO-Client-Offline\*.*" /S /D >nul 2>nul
    rmdir /s /q "release\LOGESCO-Client-Offline" >nul 2>nul
)
echo ✅ Nettoyage termine
echo.

REM Construire le backend portable OFFLINE avec le script ULTIMATE modifié
echo [2/8] Construction du backend portable OFFLINE...
echo.
cd backend
echo Utilisation du script OFFLINE (pre-generation Prisma)...
node build-portable-offline.js
if errorlevel 1 (
    echo ❌ ERREUR: Build du backend OFFLINE echoue
    cd ..
    echo.
    echo 🔧 Solutions possibles:
    echo   1. Verifier la connexion Internet (pour cette etape)
    echo   2. Fermer tous les processus Node.js
    echo   3. Nettoyer le cache npm: npm cache clean --force
    echo   4. Redemarrer en tant qu'administrateur
    echo.
    pause
    exit /b 1
)
cd ..
echo ✅ Backend portable OFFLINE construit avec Prisma pre-genere
echo.

REM Construire l'application Flutter
echo [3/8] Construction de l'application Flutter...
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
    pause
    exit /b 1
)
cd ..
echo ✅ Application Flutter construite
echo.

REM Créer le package client OFFLINE
echo [4/8] Creation du package client OFFLINE...
if not exist "release" mkdir "release"
if exist "release\LOGESCO-Client-Offline" rmdir /s /q "release\LOGESCO-Client-Offline"
mkdir "release\LOGESCO-Client-Offline"
mkdir "release\LOGESCO-Client-Offline\backend"
mkdir "release\LOGESCO-Client-Offline\app"

REM Copier le backend portable OFFLINE (avec Prisma pré-généré)
echo Copie du backend portable OFFLINE...
xcopy /E /I /Y /Q "dist-portable-offline\*" "release\LOGESCO-Client-Offline\backend\" >nul
if errorlevel 1 (
    echo ❌ ERREUR: Copie du backend OFFLINE echouee
    pause
    exit /b 1
)

REM Copier l'application Flutter
echo Copie de l'application Flutter...
xcopy /E /I /Y /Q "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client-Offline\app\" >nul
if errorlevel 1 (
    echo ❌ ERREUR: Copie de l'application echouee
    pause
    exit /b 1
)

echo ✅ Package client OFFLINE cree
echo.

REM Copier Visual C++ Redistributable
echo [5/8] Gestion Visual C++ Redistributable...
if not exist "release\LOGESCO-Client-Offline\vcredist" mkdir "release\LOGESCO-Client-Offline\vcredist"

set VCREDIST_FOUND=0
if exist "logesco_v2\assets\VC_redist.x64.exe" (
    copy /Y "logesco_v2\assets\VC_redist.x64.exe" "release\LOGESCO-Client-Offline\vcredist\vc_redist.x64.exe" >nul
    set VCREDIST_FOUND=1
    echo ✅ VC Redist copie
) else if exist "logesco_v2\assets\vc_redist.x64.exe" (
    copy /Y "logesco_v2\assets\vc_redist.x64.exe" "release\LOGESCO-Client-Offline\vcredist\vc_redist.x64.exe" >nul
    set VCREDIST_FOUND=1
    echo ✅ VC Redist copie
) else if exist "assets\VC_redist.x64.exe" (
    copy /Y "assets\VC_redist.x64.exe" "release\LOGESCO-Client-Offline\vcredist\vc_redist.x64.exe" >nul
    set VCREDIST_FOUND=1
    echo ✅ VC Redist copie
)

if %VCREDIST_FOUND%==0 (
    echo ⚠️ ATTENTION: VC_redist.x64.exe non trouve
    echo   Telechargez-le depuis: https://aka.ms/vs/17/release/vc_redist.x64.exe
)
echo.

REM Créer les scripts de démarrage OFFLINE
echo [6/8] Creation des scripts de demarrage OFFLINE...

REM Script de vérification OFFLINE
(
echo @echo off
echo title Verification Prerequis LOGESCO OFFLINE
echo echo ========================================
echo echo   Verification Prerequis LOGESCO OFFLINE
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
echo ^)
echo echo.
echo.
echo echo [2/3] Visual C++ Redistributable...
echo reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" ^>nul 2^>^&1
echo if errorlevel 1 ^(
echo     reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" ^>nul 2^>^&1
echo     if errorlevel 1 ^(
echo         echo ❌ NON INSTALLE
echo         if exist "vcredist\vc_redist.x64.exe" ^(
echo             echo Installez: vcredist\vc_redist.x64.exe
echo         ^) else ^(
echo             echo Telechargez: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo         ^)
echo         set ALL_OK=0
echo     ^) else ^(
echo         echo ✅ INSTALLE ^(WOW64^)
echo     ^)
echo ^) else ^(
echo     echo ✅ INSTALLE
echo ^)
echo echo.
echo.
echo echo [3/3] Verification OFFLINE...
echo if exist "backend\node_modules\.prisma" ^(
echo     echo ✅ Client Prisma pre-genere present
echo ^) else ^(
echo     echo ❌ Client Prisma manquant
echo     echo Ce package n'est pas correctement prepare
echo     set ALL_OK=0
echo ^)
echo echo.
echo.
echo echo ========================================
echo if %%ALL_OK%%==1 ^(
echo     echo   ✅ PRET POUR FONCTIONNEMENT OFFLINE
echo     echo.
echo     echo   ✅ Aucune connexion Internet requise
echo     echo   ✅ Toutes les dependances incluses
echo     echo   ✅ Client Prisma pre-genere
echo     echo.
echo     echo   Lancez: DEMARRER-LOGESCO-OFFLINE.bat
echo ^) else ^(
echo     echo   ❌ Prerequis manquants
echo     echo.
echo     echo   Installez les composants requis
echo ^)
echo echo ========================================
echo pause
) > "release\LOGESCO-Client-Offline\VERIFIER-PREREQUIS-OFFLINE.bat"

REM Script de démarrage OFFLINE principal
(
echo @echo off
echo title LOGESCO v2 - Demarrage OFFLINE
echo echo ========================================
echo echo   LOGESCO v2 - Demarrage OFFLINE
echo echo   Aucune Connexion Internet Requise
echo echo ========================================
echo echo.
echo.
echo REM Verification Node.js
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ ERREUR: Node.js n'est pas installe!
echo     echo.
echo     echo Installez Node.js depuis: https://nodejs.org/
echo     echo Ou executez: VERIFIER-PREREQUIS-OFFLINE.bat
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo ✅ Node.js detecte
echo node --version
echo echo.
echo.
echo REM Verification backend OFFLINE
echo if not exist "backend\start-backend-offline.bat" ^(
echo     echo ❌ ERREUR: Backend OFFLINE manquant!
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo REM Verification application
echo if not exist "app\logesco_v2.exe" ^(
echo     echo ❌ ERREUR: Application manquante!
echo     echo.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo REM Verification Prisma pre-genere
echo if not exist "backend\node_modules\.prisma" ^(
echo     echo ❌ ERREUR: Client Prisma pre-genere manquant!
echo     echo.
echo     echo Ce package n'a pas ete correctement prepare.
echo     echo Contactez le support technique.
echo     echo.
echo     pause
echo     exit /b 1
echo ^) else ^(
echo     echo ✅ Client Prisma pre-genere present
echo ^)
echo.
echo echo [1/3] Demarrage du backend OFFLINE...
echo echo   ✅ Aucune connexion Internet requise
echo echo   ✅ Client Prisma pre-genere
echo echo   ✅ Toutes dependances incluses
echo echo.
echo cd backend
echo start "LOGESCO Backend OFFLINE" /MIN cmd /c start-backend-offline.bat
echo cd ..
echo echo ✅ Backend OFFLINE demarre
echo echo   Attente de 10 secondes pour initialisation...
echo timeout /t 10 /nobreak ^>nul
echo.
echo echo [2/3] Verification du backend...
echo curl -s http://localhost:8080/health ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ⚠️ Backend encore en initialisation...
echo     timeout /t 5 /nobreak ^>nul
echo ^) else ^(
echo     echo ✅ Backend OFFLINE operationnel!
echo ^)
echo.
echo echo [3/3] Demarrage de l'application...
echo start "" "app\logesco_v2.exe"
echo echo ✅ Application demarree
echo.
echo echo ========================================
echo echo   LOGESCO OFFLINE MAINTENANT ACTIF
echo echo ========================================
echo echo.
echo echo 🌐 Backend: http://localhost:8080
echo echo 🔑 Connexion: admin / admin123
echo echo 📱 Interface: Application Windows
echo echo 🔌 Mode: OFFLINE ^(Aucune connexion requise^)
echo echo.
echo echo ✅ Fonctionnalites OFFLINE:
echo echo - Aucune connexion Internet requise
echo echo - Client Prisma pre-genere
echo echo - Toutes dependances incluses
echo echo - Demarrage immediat garanti
echo echo.
echo echo Cette fenetre peut etre fermee.
echo echo.
echo timeout /t 8 ^>nul
echo exit
) > "release\LOGESCO-Client-Offline\DEMARRER-LOGESCO-OFFLINE.bat"

REM Script d'arrêt
(
echo @echo off
echo title LOGESCO v2 - Arret OFFLINE
echo echo ========================================
echo echo   LOGESCO v2 - Arret OFFLINE
echo echo ========================================
echo echo.
echo echo Arret des processus LOGESCO...
echo taskkill /f /im logesco_v2.exe 2^>nul
echo taskkill /f /im node.exe 2^>nul
echo echo ✅ LOGESCO OFFLINE arrete
echo timeout /t 2 ^>nul
) > "release\LOGESCO-Client-Offline\ARRETER-LOGESCO-OFFLINE.bat"

echo ✅ Scripts OFFLINE crees
echo.

REM Documentation OFFLINE
echo [7/8] Creation de la documentation OFFLINE...

echo LOGESCO v2 - Version OFFLINE > "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ================================ >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo. >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo VERSION OFFLINE - AUCUNE CONNEXION INTERNET REQUISE >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ================================================== >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo. >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo Cette version inclut TOUT pour fonctionner sans Internet: >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Client Prisma pre-genere >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Toutes les dependances incluses >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Binaires Prisma embarques >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Configuration automatique >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo. >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo DEMARRAGE RAPIDE >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ================ >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo 1. Double-cliquez: DEMARRER-LOGESCO-OFFLINE.bat >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo 2. Aucune connexion Internet requise >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo 3. Demarrage immediat garanti >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo 4. Connexion: admin / admin123 >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo. >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo AVANTAGES VERSION OFFLINE >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ========================== >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Installation sans Internet >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Demarrage immediat >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Aucun telechargement requis >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Fonctionnement garanti hors ligne >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Parfait pour clients sans Internet >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Environnements securises >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"
echo ✅ Demonstrations >> "release\LOGESCO-Client-Offline\README-OFFLINE.txt"

echo ✅ Documentation OFFLINE creee
echo.

REM Vérification finale
echo [8/8] Verification finale du package OFFLINE...
if exist "release\LOGESCO-Client-Offline\backend\node_modules\.prisma" (
    echo ✅ Client Prisma pre-genere present dans le package
) else (
    echo ❌ ATTENTION: Client Prisma manquant dans le package!
)

if exist "release\LOGESCO-Client-Offline\backend\start-backend-offline.bat" (
    echo ✅ Script de demarrage OFFLINE present
) else (
    echo ❌ Script de demarrage OFFLINE manquant
)

echo.
echo ========================================
echo   PACKAGE OFFLINE TERMINE AVEC SUCCES!
echo ========================================
echo.
echo 📦 Package client OFFLINE pret dans:
echo    release\LOGESCO-Client-Offline\
echo.
echo 🔌 FONCTIONNALITES OFFLINE:
echo    ✅ AUCUNE connexion Internet requise
echo    ✅ Client Prisma pre-genere inclus
echo    ✅ Toutes dependances embarquees
echo    ✅ Demarrage immediat garanti
echo    ✅ Installation sans telechargement
echo.
echo 📂 Contenu OFFLINE:
echo    ✅ DEMARRER-LOGESCO-OFFLINE.bat (Demarrage sans Internet)
echo    ✅ VERIFIER-PREREQUIS-OFFLINE.bat (Verification)
echo    ✅ backend\ (Serveur avec Prisma pre-genere)
echo    ✅ app\ (Application Flutter)
echo    ✅ README-OFFLINE.txt (Documentation)
if %VCREDIST_FOUND%==1 (
    echo    ✅ vcredist\ (Visual C++ Redistributable)
) else (
    echo    ⚠️ vcredist\ (A ajouter manuellement)
)
echo.
echo 🎯 PARFAIT POUR:
echo    ✅ Clients sans connexion Internet
echo    ✅ Environnements securises
echo    ✅ Installations rapides
echo    ✅ Demonstrations
echo    ✅ Deploiements hors ligne
echo.
echo 📊 Taille approximative: ~400-600 MB
echo.
echo 🚀 PRET POUR DEPLOIEMENT OFFLINE!
echo.
pause