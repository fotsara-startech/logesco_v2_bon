@echo off
echo ========================================
echo   LOGESCO v2 - Preparation Client
echo   Avec Prisma Pre-genere (Solution Offline)
echo ========================================
echo.

REM Vérifier les prérequis
echo [0/7] Verification des prerequis...
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
echo [1/7] Nettoyage...
if exist "dist-portable" rmdir /s /q "dist-portable" 2>nul
if exist "release\LOGESCO-Client-Optimise" rmdir /s /q "release\LOGESCO-Client-Optimise" 2>nul
echo ✅ Nettoyage termine
echo.

REM Générer Prisma dans le backend source AVANT de copier
echo [2/7] Generation Prisma dans backend source...
cd backend
if not exist "node_modules" (
    echo    Installation dependances backend...
    call npm install
)
echo    Generation Prisma Client...
call npx prisma generate
if errorlevel 1 (
    echo ❌ ERREUR: Generation Prisma echouee
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Prisma Client genere dans backend source
echo.

REM Créer le dossier dist-portable
echo [3/7] Creation structure dist-portable...
if not exist "dist-portable" mkdir "dist-portable"
echo ✅ Structure creee
echo.

REM Copier les fichiers source
echo [4/7] Copie des fichiers source...
xcopy /E /I /Y /Q "backend\src" "dist-portable\src\" >nul
xcopy /E /I /Y /Q "backend\prisma" "dist-portable\prisma\" >nul
copy /Y "backend\package.json" "dist-portable\" >nul
copy /Y "backend\package-lock.json" "dist-portable\" >nul
copy /Y "backend\.env.example" "dist-portable\" >nul
echo ✅ Fichiers source copies
echo.

REM Créer le fichier .env pour production
echo [5/7] Configuration production...
(
echo NODE_ENV=production
echo PORT=8080
echo DATABASE_URL="file:./database/logesco.db"
echo JWT_SECRET=logesco_production_secret_key_change_in_production
echo JWT_EXPIRES_IN=24h
echo CORS_ORIGIN=*
) > "dist-portable\.env"
echo ✅ Fichier .env cree
echo.

REM Installer les dépendances de production
echo [6/7] Installation dependances production...
cd dist-portable
call npm ci --omit=dev --ignore-scripts
if errorlevel 1 (
    echo ⚠️  npm ci echoue, tentative avec npm install...
    call npm install --production --ignore-scripts
)
cd ..
echo ✅ Dependances installees
echo.

REM Copier le Prisma Client généré depuis le backend source
echo [7/7] Copie Prisma Client pre-genere...
if exist "backend\node_modules\.prisma" (
    xcopy /E /I /Y /Q "backend\node_modules\.prisma" "dist-portable\node_modules\.prisma\" >nul
    echo ✅ Prisma Client copie
) else (
    echo ❌ ERREUR: Prisma Client non trouve dans backend
    pause
    exit /b 1
)

REM Créer la base de données vierge
echo.
echo Creation base de donnees VIERGE...
cd dist-portable
if not exist "database" mkdir "database"
call npx prisma db push --accept-data-loss --skip-generate
if errorlevel 1 (
    echo ⚠️  Erreur creation base (sera creee au demarrage)
) else (
    echo    Initialisation donnees essentielles...
    node prisma\seed.js
)
cd ..
echo ✅ Base de donnees VIERGE creee
echo.

REM Construire l'application Flutter
echo Construction application Flutter...
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

REM Créer le package client
echo Creation package client...
if not exist "release" mkdir "release"
mkdir "release\LOGESCO-Client-Optimise"
mkdir "release\LOGESCO-Client-Optimise\backend"
mkdir "release\LOGESCO-Client-Optimise\app"

xcopy /E /I /Y /Q "dist-portable\*" "release\LOGESCO-Client-Optimise\backend\" >nul
xcopy /E /I /Y /Q "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client-Optimise\app\" >nul

REM Copier le script de réinitialisation
copy "REINITIALISER-BASE-CLIENT.bat" "release\LOGESCO-Client-Optimise\REINITIALISER-BASE-DONNEES.bat" >nul

echo ✅ Package client cree
echo.

REM Créer les scripts de démarrage
echo Creation scripts demarrage...
(
echo @echo off
echo title LOGESCO v2 - Demarrage
echo cd backend
echo if not exist "database" mkdir "database"
echo start "LOGESCO Backend" /MIN node src/server.js
echo cd ..
echo timeout /t 4 /nobreak ^>nul
echo start "" "app\logesco_v2.exe"
echo timeout /t 5 ^>nul
echo exit
) > "release\LOGESCO-Client-Optimise\DEMARRER-LOGESCO.bat"

(
echo @echo off
echo taskkill /f /im logesco_v2.exe 2^>nul
echo taskkill /f /im node.exe 2^>nul
echo timeout /t 2 ^>nul
) > "release\LOGESCO-Client-Optimise\ARRETER-LOGESCO.bat"

echo ✅ Scripts crees
echo.

echo ========================================
echo   ✅ Preparation terminee!
echo ========================================
echo.
echo 📦 Package pret dans:
echo    release\LOGESCO-Client-Optimise\
echo.
echo 🚀 Avantages:
echo    ✅ Prisma Client pre-genere (pas de telechargement)
echo    ✅ Base de donnees VIERGE
echo    ✅ Fonctionne OFFLINE
echo    ✅ Demarrage ultra-rapide
echo.
echo 🔑 Identifiants:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
pause
