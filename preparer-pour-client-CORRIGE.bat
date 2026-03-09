@echo off
echo ========================================
echo   LOGESCO v2 - Package Client CORRIGE
echo   SANS Prisma Pre-genere
echo ========================================
echo.

REM Vérifier les prérequis
echo [0/6] Verification prerequis...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ Node.js non installe!
    pause
    exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
    echo ❌ Flutter non installe!
    pause
    exit /b 1
)

echo ✅ Node.js OK
echo ✅ Flutter OK
echo.

REM Nettoyer
echo [1/6] Nettoyage...
if exist "dist-portable" rmdir /s /q "dist-portable" 2>nul
if exist "release\LOGESCO-Client-CORRIGE" rmdir /s /q "release\LOGESCO-Client-CORRIGE" 2>nul
echo ✅ Nettoye
echo.

REM Construire backend
echo [2/6] Construction backend...
cd backend
node build-portable-optimized.js
if errorlevel 1 (
    echo ❌ Erreur build backend
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Backend construit
echo.

REM Construire Flutter
echo [3/6] Construction Flutter...
cd logesco_v2
call flutter clean >nul 2>nul
call flutter pub get >nul
call flutter build windows --release >nul
if errorlevel 1 (
    echo ❌ Erreur build Flutter
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Flutter construit
echo.

REM Créer package
echo [4/6] Creation package CORRIGE...
if not exist "release" mkdir "release"
mkdir "release\LOGESCO-Client-CORRIGE"
mkdir "release\LOGESCO-Client-CORRIGE\backend"
mkdir "release\LOGESCO-Client-CORRIGE\app"

echo Copie backend...
xcopy /E /I /Y /Q "dist-portable\*" "release\LOGESCO-Client-CORRIGE\backend\" >nul

echo.
echo ========================================
echo   CORRECTION CRITIQUE
echo ========================================
echo.
echo SUPPRESSION du client Prisma pre-genere...
echo (Sera regenere chez le client avec SA base)
echo.

cd "release\LOGESCO-Client-CORRIGE\backend"

if exist "node_modules\.prisma" (
    rmdir /s /q "node_modules\.prisma" 2>nul
    echo ✅ .prisma supprime
)

if exist "node_modules\@prisma\client" (
    rmdir /s /q "node_modules\@prisma\client" 2>nul
    echo ✅ @prisma/client supprime
)

echo.
echo SUPPRESSION de la base vierge...
echo (Sera creee chez le client)
echo.

if exist "database\logesco.db" (
    del /f /q "database\logesco.db" 2>nul
    if exist "database\logesco.db" (
        echo ❌ ERREUR: Impossible de supprimer la base!
        cd ..\..\..
        pause
        exit /b 1
    )
    echo ✅ Base vierge supprimee
) else (
    echo ✅ Pas de base vierge (deja supprimee)
)

REM Supprimer aussi les fichiers temporaires SQLite
if exist "database\logesco.db-shm" del /f /q "database\logesco.db-shm" 2>nul
if exist "database\logesco.db-wal" del /f /q "database\logesco.db-wal" 2>nul

REM Verification finale
if exist "database\logesco.db" (
    echo.
    echo ❌ ERREUR CRITIQUE: La base existe encore!
    echo    Le package contiendrait une base vierge qui ecraserait les donnees client!
    echo.
    cd ..\..\..
    pause
    exit /b 1
)

cd ..\..\..

echo.
echo ✅ Package CORRIGE (sans Prisma pre-genere, sans base vierge)
echo.

echo Copie application...
xcopy /E /I /Y /Q "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client-CORRIGE\app\" >nul
echo ✅ App copiee
echo.

REM Créer scripts
echo [5/6] Creation scripts...

REM Script de démarrage CORRIGÉ
(
echo @echo off
echo title LOGESCO - Demarrage
echo echo ========================================
echo echo   LOGESCO - Demarrage
echo echo ========================================
echo echo.
echo.
echo REM Verifier Node.js
echo where node ^>nul 2^>nul
echo if errorlevel 1 ^(
echo     echo ❌ Node.js non installe!
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo [1/3] Verification Prisma...
echo cd backend
echo.
echo REM Verifier si Prisma est genere
echo if not exist "node_modules\.prisma\client" ^(
echo     echo.
echo     echo ⚠️  Premiere utilisation detectee
echo     echo    Generation du client Prisma...
echo     echo    ^(Cela prend 10-15 secondes^)
echo     echo.
echo     
echo     REM Creer dossier database si necessaire
echo     if not exist "database" mkdir "database"
echo     
echo     REM Generer Prisma
echo     call npx prisma generate ^>nul 2^>nul
echo     if errorlevel 1 ^(
echo         echo ❌ Erreur generation Prisma
echo         cd ..
echo         pause
echo         exit /b 1
echo     ^)
echo     echo    ✅ Prisma genere
echo ^) else ^(
echo     echo    ✅ Prisma deja genere
echo ^)
echo.
echo echo [2/3] Demarrage backend...
echo start "LOGESCO Backend" /MIN node src/server.js
echo cd ..
echo echo       ✅ Backend demarre
echo echo       Attente initialisation ^(5 secondes^)...
echo timeout /t 5 /nobreak ^>nul
echo.
echo echo [3/3] Demarrage application...
echo start "" "app\logesco_v2.exe"
echo echo.
echo echo ========================================
echo echo   LOGESCO actif!
echo echo ========================================
echo echo.
echo echo 🌐 Backend: http://localhost:8080
echo echo 🔑 Connexion: admin / admin123
echo echo.
echo timeout /t 3 ^>nul
echo exit
) > "release\LOGESCO-Client-CORRIGE\DEMARRER-LOGESCO.bat"

REM Script d'arrêt
(
echo @echo off
echo echo Arret LOGESCO...
echo taskkill /f /im logesco_v2.exe 2^>nul
echo taskkill /f /im node.exe 2^>nul
echo echo ✅ Arrete
echo timeout /t 2 ^>nul
) > "release\LOGESCO-Client-CORRIGE\ARRETER-LOGESCO.bat"

echo ✅ Scripts crees
echo.

REM Documentation
echo [6/6] Documentation...

(
echo LOGESCO v2 - Package CORRIGE
echo =============================
echo.
echo CORRECTION APPLIQUEE:
echo ---------------------
echo ✅ Prisma Client NON pre-genere
echo    ^(Sera genere avec VOTRE base de donnees^)
echo.
echo ✅ Pas de base vierge incluse
echo    ^(Sera creee au premier demarrage^)
echo.
echo DEMARRAGE:
echo ----------
echo 1. Double-cliquez: DEMARRER-LOGESCO.bat
echo 2. Premiere fois: Attendre 15-20 secondes ^(generation Prisma^)
echo 3. Fois suivantes: 7-9 secondes
echo 4. Connexion: admin / admin123
echo.
echo MIGRATION DEPUIS ANCIEN CLIENT:
echo --------------------------------
echo 1. Copiez votre base: backend\database\logesco.db
echo 2. Lancez: DEMARRER-LOGESCO.bat
echo 3. Prisma sera genere avec VOTRE structure
echo 4. Vos donnees seront visibles!
echo.
echo PREREQUIS:
echo ----------
echo - Windows 10/11 ^(64-bit^)
echo - Node.js 18+
echo.
echo SCRIPTS:
echo --------
echo DEMARRER-LOGESCO.bat - Lance le systeme
echo ARRETER-LOGESCO.bat  - Arrete tout
echo.
) > "release\LOGESCO-Client-CORRIGE\README.txt"

echo ✅ Documentation creee
echo.

echo ========================================
echo   PACKAGE CORRIGE PRET!
echo ========================================
echo.
echo 📦 Emplacement:
echo    release\LOGESCO-Client-CORRIGE\
echo.
echo ✅ CORRECTIONS APPLIQUEES:
echo    - Prisma Client NON pre-genere
echo    - Pas de base vierge
echo    - Generation automatique au demarrage
echo    - Compatible avec migration de donnees
echo.
echo 🎯 AVANTAGES:
echo    ✅ Prisma genere avec la VRAIE base du client
echo    ✅ Pas de probleme de synchronisation
echo    ✅ Migration de donnees fonctionne
echo    ✅ Premiere utilisation: 15-20s
echo    ✅ Utilisations suivantes: 7-9s
echo.
echo 🧪 Pour tester:
echo    cd release\LOGESCO-Client-CORRIGE
echo    DEMARRER-LOGESCO.bat
echo.
pause
