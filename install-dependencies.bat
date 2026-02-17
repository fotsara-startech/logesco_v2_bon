@echo off
echo ========================================
echo   Installation des Dependances
echo   LOGESCO v2
echo ========================================
echo.

REM Vérifier Node.js
echo [1/4] Verification de Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ✗ Node.js n'est pas installe
    echo.
    echo Telechargez et installez Node.js depuis:
    echo https://nodejs.org/
    echo.
    echo Choisissez la version LTS (Long Term Support)
    pause
    exit /b 1
) else (
    node --version
    echo ✓ Node.js installe
)

echo.
echo [2/4] Verification de Flutter...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ✗ Flutter n'est pas installe
    echo.
    echo Telechargez et installez Flutter depuis:
    echo https://flutter.dev/
    echo.
    echo Suivez le guide d'installation pour Windows
    pause
    exit /b 1
) else (
    flutter --version | findstr "Flutter"
    echo ✓ Flutter installe
)

echo.
echo [3/4] Installation des dependances Backend...
cd backend
call npm install
if errorlevel 1 (
    echo ✗ Erreur lors de l'installation des dependances backend
    pause
    exit /b 1
)
echo ✓ Dependances backend installees
cd ..

echo.
echo [4/4] Installation des dependances Flutter...
cd logesco_v2
call flutter pub get
if errorlevel 1 (
    echo ✗ Erreur lors de l'installation des dependances Flutter
    pause
    exit /b 1
)
echo ✓ Dependances Flutter installees
cd ..

echo.
echo ========================================
echo   Installation terminee avec succes!
echo ========================================
echo.
echo Vous pouvez maintenant:
echo 1. Lancer le build: build-production.bat
echo 2. Tester en dev: cd backend ^&^& npm run dev
echo.
pause
