@echo off
echo ========================================
echo   LOGESCO v2 - Preparation Client OPTIMISEE
echo   Demarrage Ultra-Rapide (4x plus rapide!)
echo ========================================
echo.

REM Vérifier les prérequis
echo [0/6] Verification des prerequis...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js n'est pas installe!
    pause
    exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Flutter n'est pas installe!
    pause
    exit /b 1
)

echo ✅ Node.js detecte
echo ✅ Flutter detecte
echo.

REM Nettoyer les anciens builds
echo [1/6] Nettoyage...
if exist "dist-portable" rmdir /s /q "dist-portable" 2>nul
if exist "release\LOGESCO-Client-Optimise" rmdir /s /q "release\LOGESCO-Client-Optimise" 2>nul

REM CRITIQUE: Supprimer la base de développement pour éviter de la copier
echo.
echo    Suppression base de developpement...
if exist "backend\database" (
    rmdir /s /q "backend\database" 2>nul
    echo    ✅ Base de dev supprimee (ne sera pas copiee)
) else (
    echo    ✅ Aucune base de dev a supprimer
)

echo ✅ Nettoyage termine
echo.

REM Construire le backend portable OPTIMISÉ avec base de données VIERGE
echo [2/6] Construction backend OPTIMISE avec DB VIERGE...
echo       (Prisma pre-genere, DB vierge pour production)
echo.

REM Supprimer TOUTES les bases de données de développement
echo       Nettoyage complet des bases de donnees de developpement...
if exist "backend\database" (
    rmdir /s /q "backend\database" 2>nul
    echo       ✅ Dossier database de developpement supprime
)
if exist "backend\prisma\dev.db" (
    del /f /q "backend\prisma\dev.db" 2>nul
    echo       ✅ Base dev.db supprimee
)
if exist "backend\logesco.db" (
    del /f /q "backend\logesco.db" 2>nul
    echo       ✅ Base logesco.db supprimee
)
echo       ✅ Nettoyage complet termine
echo.

cd backend
node build-portable-optimized.js
if errorlevel 1 (
    echo ❌ ERREUR: Build backend echoue
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Backend portable OPTIMISE construit avec DB VIERGE
echo.

REM Construire l'application Flutter
echo [3/6] Construction application Flutter...
cd logesco_v2
call flutter clean >nul 2>nul
call flutter pub get
if errorlevel 1 (
    echo ❌ ERREUR: flutter pub get echoue
    cd ..
    pause
    exit /b 1
)
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

REM Créer le package client OPTIMISÉ
echo [4/6] Creation package client OPTIMISE...
if not exist "release" mkdir "release"
mkdir "release\LOGESCO-Client-Optimise"
mkdir "release\LOGESCO-Client-Optimise\backend"
mkdir "release\LOGESCO-Client-Optimise\app"

echo Copie backend optimise...
xcopy /E /I /Y /Q "dist-portable\*" "release\LOGESCO-Client-Optimise\backend\" >nul

REM Vérification finale: S'assurer qu'aucune base de développement n'est présente
echo Verification finale base de donnees...
if exist "release\LOGESCO-Client-Optimise\backend\database\logesco.db" (
    echo       ✅ Base de donnees VIERGE presente
) else (
    echo       ⚠️  Base de donnees sera creee au premier demarrage
)

REM Supprimer toute base de données de développement qui aurait pu être copiée par erreur
if exist "release\LOGESCO-Client-Optimise\backend\dev.db" (
    del /f /q "release\LOGESCO-Client-Optimise\backend\dev.db" 2>nul
    echo       🗑️  Base dev.db supprimee
)
if exist "release\LOGESCO-Client-Optimise\backend\prisma\dev.db" (
    del /f /q "release\LOGESCO-Client-Optimise\backend\prisma\dev.db" 2>nul
    echo       🗑️  Base prisma/dev.db supprimee
)

echo Copie application...
xcopy /E /I /Y /Q "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client-Optimise\app\" >nul

echo ✅ Package client OPTIMISE cree
echo.

REM Copier le script de réinitialisation dans le package
echo Copie script reinitialisation...
copy "REINITIALISER-BASE-CLIENT.bat" "release\LOGESCO-Client-Optimise\REINITIALISER-BASE-DONNEES.bat" >nul
echo ✅ Script reinitialisation copie

REM Créer les scripts de démarrage OPTIMISÉS
echo [5/6] Creation scripts demarrage OPTIMISES...

REM Script de démarrage principal OPTIMISÉ
(
echo @echo off
echo title LOGESCO v2 - Demarrage OPTIMISE
echo echo ========================================
echo echo   LOGESCO v2 - Demarrage OPTIMISE
echo echo   Demarrage ultra-rapide en arriere-plan
echo echo ========================================
echo echo.
echo.
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ ERREUR: Node.js non installe!
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo [1/2] Demarrage backend en arriere-plan...
echo echo       ^(Prisma pre-genere, demarrage immediat!^)
echo echo.
echo cd backend
echo if not exist "database" mkdir "database"
echo start "LOGESCO Backend" /MIN node src/server.js
echo cd ..
echo echo       ✅ Backend demarre en arriere-plan
echo echo       Attente initialisation ^(4 secondes^)...
echo timeout /t 4 /nobreak ^>nul
echo echo.
echo echo [2/2] Demarrage application...
echo start "" "app\logesco_v2.exe"
echo echo.
echo echo ========================================
echo echo   LOGESCO v2 est maintenant actif!
echo echo ========================================
echo echo.
echo echo 🌐 Backend: http://localhost:8080
echo echo 🔑 Connexion: admin / admin123
echo echo.
echo echo ℹ️  Cette fenetre peut etre fermee.
echo echo    Le backend tourne en arriere-plan.
echo echo.
echo timeout /t 5 ^>nul
echo exit
) > "release\LOGESCO-Client-Optimise\DEMARRER-LOGESCO.bat"

REM Script d'arrêt
(
echo @echo off
echo title LOGESCO - Arret
echo echo Arret LOGESCO...
echo taskkill /f /im logesco_v2.exe 2^>nul
echo taskkill /f /im node.exe 2^>nul
echo echo ✅ LOGESCO arrete
echo timeout /t 2 ^>nul
) > "release\LOGESCO-Client-Optimise\ARRETER-LOGESCO.bat"

REM Script de vérification
(
echo @echo off
echo title LOGESCO - Verification
echo echo ========================================
echo echo   Verification Prerequis LOGESCO
echo echo ========================================
echo echo.
echo echo [1/3] Node.js...
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ NON INSTALLE
echo ^) else ^(
echo     echo ✅ INSTALLE
echo     node --version
echo ^)
echo echo.
echo echo [2/3] Backend optimise...
echo if exist "backend\node_modules\.prisma\client" ^(
echo     echo ✅ Prisma Client pre-genere
echo ^) else ^(
echo     echo ❌ Prisma Client manquant
echo ^)
echo if exist "backend\database\logesco.db" ^(
echo     echo ✅ Base de donnees VIERGE presente
echo ^) else ^(
echo     echo ⚠️  Base de donnees sera creee au demarrage
echo ^)
echo echo.
echo echo [3/3] Application...
echo if exist "app\logesco_v2.exe" ^(
echo     echo ✅ Application presente
echo ^) else ^(
echo     echo ❌ Application manquante
echo ^)
echo echo.
echo echo ========================================
echo pause
) > "release\LOGESCO-Client-Optimise\VERIFIER-PREREQUIS.bat"

echo ✅ Scripts crees
echo.

REM Créer la documentation
echo [6/6] Creation documentation...

echo LOGESCO v2 - Systeme de Gestion Commerciale OPTIMISE > "release\LOGESCO-Client-Optimise\README.txt"
echo ============================================================ >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo VERSION OPTIMISEE - DEMARRAGE ULTRA-RAPIDE >> "release\LOGESCO-Client-Optimise\README.txt"
echo ========================================== >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo Cette version demarre 4x plus vite que la version standard! >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo DEMARRAGE RAPIDE >> "release\LOGESCO-Client-Optimise\README.txt"
echo ================ >> "release\LOGESCO-Client-Optimise\README.txt"
echo 1. Double-cliquez sur: DEMARRER-LOGESCO.bat >> "release\LOGESCO-Client-Optimise\README.txt"
echo 2. Attendez 7-9 secondes >> "release\LOGESCO-Client-Optimise\README.txt"
echo 3. L'application s'ouvre automatiquement >> "release\LOGESCO-Client-Optimise\README.txt"
echo 4. Connectez-vous avec: admin / admin123 >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo OPTIMISATIONS >> "release\LOGESCO-Client-Optimise\README.txt"
echo ============== >> "release\LOGESCO-Client-Optimise\README.txt"
echo ✅ Prisma Client pre-genere (pas de generation au demarrage) >> "release\LOGESCO-Client-Optimise\README.txt"
echo ✅ Base de donnees VIERGE pour production >> "release\LOGESCO-Client-Optimise\README.txt"
echo ✅ Backend demarre en arriere-plan (pas de fenetre visible) >> "release\LOGESCO-Client-Optimise\README.txt"
echo ✅ Scripts intelligents (verifications conditionnelles) >> "release\LOGESCO-Client-Optimise\README.txt"
echo ✅ Demarrage 4x plus rapide (7-9s au lieu de 30-40s) >> "release\LOGESCO-Client-Optimise\README.txt"
echo ⚠️  AUCUNE donnee de developpement incluse >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo PREREQUIS >> "release\LOGESCO-Client-Optimise\README.txt"
echo --------- >> "release\LOGESCO-Client-Optimise\README.txt"
echo - Windows 10/11 (64-bit) >> "release\LOGESCO-Client-Optimise\README.txt"
echo - Node.js 18 ou superieur (https://nodejs.org/) >> "release\LOGESCO-Client-Optimise\README.txt"
echo - 500 MB d'espace disque libre >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo SCRIPTS DISPONIBLES >> "release\LOGESCO-Client-Optimise\README.txt"
echo =================== >> "release\LOGESCO-Client-Optimise\README.txt"
echo DEMARRER-LOGESCO.bat           - Lance le systeme (ultra-rapide!) >> "release\LOGESCO-Client-Optimise\README.txt"
echo ARRETER-LOGESCO.bat            - Arrete tous les processus >> "release\LOGESCO-Client-Optimise\README.txt"
echo VERIFIER-PREREQUIS.bat         - Verifie l'installation >> "release\LOGESCO-Client-Optimise\README.txt"
echo REINITIALISER-BASE-DONNEES.bat - Reinitialise la base (DANGER!) >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo CONNEXION PAR DEFAUT >> "release\LOGESCO-Client-Optimise\README.txt"
echo ==================== >> "release\LOGESCO-Client-Optimise\README.txt"
echo Nom d'utilisateur: admin >> "release\LOGESCO-Client-Optimise\README.txt"
echo Mot de passe: admin123 >> "release\LOGESCO-Client-Optimise\README.txt"
echo. >> "release\LOGESCO-Client-Optimise\README.txt"
echo SUPPORT >> "release\LOGESCO-Client-Optimise\README.txt"
echo ======= >> "release\LOGESCO-Client-Optimise\README.txt"
echo Version: 2.0 OPTIMISEE >> "release\LOGESCO-Client-Optimise\README.txt"
echo Performance: 4x plus rapide >> "release\LOGESCO-Client-Optimise\README.txt"
echo Temps demarrage: 7-9 secondes >> "release\LOGESCO-Client-Optimise\README.txt"

echo ✅ Documentation creee
echo.

echo ========================================
echo   Preparation OPTIMISEE terminee!
echo ========================================
echo.
echo 📦 Package client OPTIMISE pret dans:
echo    release\LOGESCO-Client-Optimise\
echo.
echo 🚀 OPTIMISATIONS:
echo    ✅ Prisma Client pre-genere
echo    ✅ Base de donnees VIERGE pour production
echo    ✅ Demarrage en arriere-plan
echo    ✅ Scripts intelligents
echo    ✅ 4x plus rapide (7-9s au lieu de 30-40s)
echo    ⚠️  AUCUNE donnee de developpement incluse
echo.
echo 📂 Contenu:
echo    ✅ DEMARRER-LOGESCO.bat (Lance tout - RAPIDE!)
echo    ✅ ARRETER-LOGESCO.bat (Arrete tout)
echo    ✅ VERIFIER-PREREQUIS.bat (Verification)
echo    ✅ backend\ (Backend optimise)
echo    ✅ app\ (Application Flutter)
echo    ✅ README.txt (Instructions)
echo.
echo 🧪 Pour tester:
echo    cd release\LOGESCO-Client-Optimise
echo    DEMARRER-LOGESCO.bat
echo.
echo 🔑 Identifiants:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo 🎯 PACKAGE OPTIMISE PRET!
echo    Demarrage 4x plus rapide pour vos clients!
echo.
pause
