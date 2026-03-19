@echo off
setlocal enabledelayedexpansion
title LOGESCO v2 - Build Installeur Complet

REM Garder la fenetre ouverte si lance par double-clic
if not defined LOGESCO_BUILD_STARTED (
    set LOGESCO_BUILD_STARTED=1
    cmd /k "%~f0" STARTED
    exit /b
)

echo.
echo ============================================================
echo   LOGESCO v2 - Build Installeur Complet
echo   Produit: release\LOGESCO-v2-Setup.exe
echo ============================================================
echo.

REM ── Verification des prerequis ────────────────────────────────────────────

echo [Prerequis] Verification...
echo.

where node >nul 2>nul
if errorlevel 1 (
    echo ERREUR: Node.js non trouve. Installez Node.js 18+: https://nodejs.org/
    pause & exit /b 1
)
echo OK Node.js:
node --version

where flutter >nul 2>nul
if errorlevel 1 (
    echo ERREUR: Flutter non trouve. Installez Flutter: https://flutter.dev/
    pause & exit /b 1
)
echo OK Flutter:
flutter --version 2>nul | findstr "Flutter"

set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe"       set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"
if "%ISCC%"=="" (
    echo ERREUR: InnoSetup 6 non trouve. Telechargez: https://jrsoftware.org/isdl.php
    pause & exit /b 1
)
echo OK InnoSetup: %ISCC%
echo.

REM ── Etape 1 : Build backend EXE ───────────────────────────────────────────

echo ------------------------------------------------------------
echo  ETAPE 1/4 : Compilation du backend (logesco-backend.exe)
echo ------------------------------------------------------------
echo.

cd backend

echo Arret des processus Node.js (evite EPERM sur prisma generate)...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco-backend.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo Installation des dependances backend...
call npm install
if errorlevel 1 ( echo ERREUR: npm install echoue & cd .. & pause & exit /b 1 )

echo.
echo Generation du client Prisma...
call npx prisma generate
if errorlevel 1 ( echo ERREUR: prisma generate echoue & cd .. & pause & exit /b 1 )

echo.
echo Preparation du backend portable (node.exe + node_modules)...
call node build-exe.js
if errorlevel 1 ( echo ERREUR: build-exe.js echoue & cd .. & pause & exit /b 1 )

cd ..

if not exist "dist-exe\node.exe" (
    echo ERREUR: dist-exe\node.exe introuvable apres build
    echo Verifiez que build-exe.js s'est execute correctement
    pause & exit /b 1
)
if not exist "dist-exe\src\server.js" (
    echo ERREUR: dist-exe\src\server.js introuvable apres build
    pause & exit /b 1
)
echo.
echo OK Backend pret: dist-exe\node.exe + dist-exe\src\server.js
echo.

REM ── Etape 2 : Build Flutter Windows ───────────────────────────────────────

echo ------------------------------------------------------------
echo  ETAPE 2/4 : Build Flutter Windows
echo ------------------------------------------------------------
echo.

cd logesco_v2

echo Nettoyage Flutter...
call flutter clean >nul 2>nul

echo Recuperation des dependances...
call flutter pub get
if errorlevel 1 ( echo ERREUR: flutter pub get echoue & cd .. & pause & exit /b 1 )

echo Build Windows release...
call flutter build windows --release
if errorlevel 1 ( echo ERREUR: flutter build windows echoue & cd .. & pause & exit /b 1 )

cd ..

set FLUTTER_RELEASE=logesco_v2\build\windows\x64\runner\Release
if not exist "%FLUTTER_RELEASE%\logesco_v2.exe" (
    echo ERREUR: logesco_v2.exe introuvable apres build Flutter
    echo Verifiez le nom de l'exe dans: %FLUTTER_RELEASE%\
    dir "%FLUTTER_RELEASE%\*.exe" 2>nul
    pause & exit /b 1
)
echo.
echo OK Flutter build: %FLUTTER_RELEASE%\logesco_v2.exe
echo.

REM ── Etape 3 : Dossier release ─────────────────────────────────────────────

if not exist "release" mkdir "release"

REM ── Etape 4 : Compiler l'installeur InnoSetup ─────────────────────────────

echo ------------------------------------------------------------
echo  ETAPE 4/4 : Compilation de l'installeur (InnoSetup)
echo ------------------------------------------------------------
echo.

"%ISCC%" installer-setup.iss
if errorlevel 1 (
    echo ERREUR: InnoSetup a echoue. Verifiez installer-setup.iss
    pause & exit /b 1
)

if not exist "release\LOGESCO-v2-Setup.exe" (
    echo ERREUR: LOGESCO-v2-Setup.exe introuvable apres InnoSetup
    pause & exit /b 1
)

REM ── Resultat ───────────────────────────────────────────────────────────────

echo.
echo ============================================================
echo   BUILD TERMINE AVEC SUCCES
echo ============================================================
echo.
echo Installeur: release\LOGESCO-v2-Setup.exe
echo.
echo Ce que fait l'installeur chez le client:
echo   - Installe logesco_v2.exe dans Program Files\LOGESCO
echo   - Installe logesco-backend.exe dans AppData\Local\LOGESCO\backend
echo   - Cree les dossiers database/, uploads/, logs/
echo   - Cree un raccourci bureau + menu Demarrer
echo.
echo Mise a jour d'un client existant:
echo   - Relancer LOGESCO-v2-Setup.exe sur la machine client
echo   - Les donnees (logesco.db, uploads) sont conservees
echo   - Les migrations Prisma s'appliquent automatiquement
echo.
echo Identifiants par defaut: admin / admin123
echo.
pause
