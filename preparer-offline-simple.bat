@echo off
echo ========================================
echo   LOGESCO - Preparation OFFLINE Simple
echo ========================================
echo.

echo Ce script cree une version offline en modifiant
echo le package standard pour inclure Prisma pre-genere.
echo.
pause
echo.

echo [1/4] Construction du package standard...
call preparer-pour-client-ultimate.bat
if errorlevel 1 (
    echo ❌ ERREUR: Construction du package standard echouee
    pause
    exit /b 1
)
echo ✅ Package standard cree
echo.

echo [2/4] Copie vers version offline...
if exist "release\LOGESCO-Client-Offline" (
    rmdir /s /q "release\LOGESCO-Client-Offline" >nul 2>nul
)

xcopy /E /I /Y /Q "release\LOGESCO-Client-Ultimate" "release\LOGESCO-Client-Offline" >nul
if errorlevel 1 (
    echo ❌ ERREUR: Copie vers version offline echouee
    pause
    exit /b 1
)
echo ✅ Version offline copiee
echo.

echo [3/4] Pre-generation du client Prisma...
cd "release\LOGESCO-Client-Offline\backend"

REM S'assurer que les dépendances sont installées
if not exist "node_modules" (
    echo Installation des dependances...
    call npm install
    if errorlevel 1 (
        echo ❌ ERREUR: Installation dependances echouee
        cd ..\..\..
        pause
        exit /b 1
    )
)

REM Pré-générer le client Prisma
echo Pre-generation du client Prisma...
call npx prisma@6.17.1 generate
if errorlevel 1 (
    echo ⚠️ Tentative avec version globale...
    call npx prisma generate
    if errorlevel 1 (
        echo ❌ ERREUR: Pre-generation Prisma echouee
        cd ..\..\..
        pause
        exit /b 1
    )
)

cd ..\..\..
echo ✅ Client Prisma pre-genere
echo.

echo [4/4] Creation des scripts offline...

REM Script de démarrage offline
(
echo @echo off
echo title LOGESCO Backend Server OFFLINE
echo echo ========================================
echo echo LOGESCO Backend Server OFFLINE
echo echo Aucune Connexion Internet Requise
echo echo ========================================
echo echo.
echo.
echo REM Verifier Node.js
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ ERREUR: Node.js n'est pas installe!
echo     echo Installez Node.js depuis: https://nodejs.org/
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo ✅ Node.js detecte
echo node --version
echo echo.
echo.
echo REM Verifier client Prisma pre-genere
echo if not exist "node_modules\\.prisma" ^(
echo     echo ❌ ERREUR: Client Prisma pre-genere manquant!
echo     echo Ce package n'a pas ete correctement prepare.
echo     pause
echo     exit /b 1
echo ^) else ^(
echo     echo ✅ Client Prisma pre-genere present
echo ^)
echo.
echo REM Creer dossier database si necessaire
echo if not exist "database" mkdir "database"
echo.
echo REM Creer la base de donnees si elle n'existe pas
echo if not exist "database\\logesco.db" ^(
echo     echo Creation de la base de donnees...
echo     npx prisma db push --accept-data-loss ^>nul 2^>nul
echo     if errorlevel 1 ^(
echo         echo ⚠️ Erreur creation BD, sera creee au demarrage
echo     ^) else ^(
echo         echo ✅ Base de donnees creee
echo     ^)
echo ^)
echo.
echo echo 🚀 Demarrage du serveur OFFLINE...
echo echo Backend: http://localhost:8080
echo echo Connexion: admin / admin123
echo echo Mode: OFFLINE ^(Aucune connexion requise^)
echo echo.
echo.
echo node "%%~dp0src\\server-standalone.js"
echo.
echo if errorlevel 1 ^(
echo     echo ❌ Erreur serveur - Consultez les logs
echo     pause
echo ^)
) > "release\LOGESCO-Client-Offline\backend\start-backend-offline.bat"

REM Script de démarrage principal offline
(
echo @echo off
echo title LOGESCO - Demarrage OFFLINE
echo echo ========================================
echo echo   LOGESCO - Demarrage OFFLINE
echo echo   Aucune Connexion Internet Requise
echo echo ========================================
echo echo.
echo.
echo echo [1/3] Verification des prerequis...
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ Node.js manquant - Installez depuis https://nodejs.org/
echo     pause
echo     exit /b 1
echo ^)
echo echo ✅ Node.js present
echo.
echo echo [2/3] Demarrage backend OFFLINE...
echo cd backend
echo start "LOGESCO Backend OFFLINE" /MIN cmd /c start-backend-offline.bat
echo cd ..
echo timeout /t 8 /nobreak ^>nul
echo echo ✅ Backend OFFLINE demarre
echo.
echo echo [3/3] Demarrage application...
echo start "" "app\\logesco_v2.exe"
echo echo ✅ Application demarree
echo.
echo echo ========================================
echo echo   LOGESCO OFFLINE ACTIF
echo echo ========================================
echo echo 🌐 Backend: http://localhost:8080
echo echo 🔑 Connexion: admin / admin123
echo echo 🔌 Mode: OFFLINE
echo echo.
echo timeout /t 5 ^>nul
) > "release\LOGESCO-Client-Offline\DEMARRER-LOGESCO-OFFLINE.bat"

REM Documentation offline
(
echo LOGESCO Version OFFLINE
echo =======================
echo.
echo Cette version fonctionne SANS connexion Internet.
echo.
echo DEMARRAGE:
echo 1. Double-cliquez: DEMARRER-LOGESCO-OFFLINE.bat
echo 2. Aucune connexion Internet requise
echo 3. Connexion: admin / admin123
echo.
echo AVANTAGES:
echo ✅ Aucune connexion Internet requise
echo ✅ Client Prisma pre-genere
echo ✅ Demarrage immediat
echo ✅ Installation sans telechargement
echo.
echo PARFAIT POUR:
echo - Clients sans Internet fiable
echo - Environnements securises
echo - Demonstrations
echo - Installations rapides
) > "release\LOGESCO-Client-Offline\README-OFFLINE.txt"

echo ✅ Scripts offline crees
echo.

echo ========================================
echo   VERSION OFFLINE CREEE AVEC SUCCES!
echo ========================================
echo.
echo 📦 Package: release\LOGESCO-Client-Offline\
echo 🔌 Mode: OFFLINE (Aucune connexion requise)
echo ✅ Client Prisma: Pre-genere
echo.
echo CONTENU:
echo ✅ DEMARRER-LOGESCO-OFFLINE.bat (Demarrage principal)
echo ✅ backend\start-backend-offline.bat (Backend offline)
echo ✅ app\ (Application Flutter)
echo ✅ README-OFFLINE.txt (Documentation)
echo.
echo 🎯 PRET POUR DEPLOIEMENT SANS INTERNET!
echo.
echo UTILISATION CHEZ LE CLIENT:
echo 1. Copiez le dossier LOGESCO-Client-Offline
echo 2. Double-cliquez: DEMARRER-LOGESCO-OFFLINE.bat
echo 3. Aucune connexion Internet requise!
echo.
pause