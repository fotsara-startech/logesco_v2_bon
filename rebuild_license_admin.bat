@echo off
echo ========================================
echo Recompilation de logesco_license_admin
echo ========================================
echo.

cd logesco_license_admin

echo [1/4] Nettoyage...
call flutter clean
if errorlevel 1 (
    echo ERREUR lors du nettoyage
    pause
    exit /b 1
)

echo.
echo [2/4] Récupération des dépendances...
call flutter pub get
if errorlevel 1 (
    echo ERREUR lors de pub get
    pause
    exit /b 1
)

echo.
echo [3/4] Compilation en mode release...
call flutter build windows --release
if errorlevel 1 (
    echo ERREUR lors de la compilation
    pause
    exit /b 1
)

echo.
echo [4/4] Terminé!
echo.
echo L'exécutable se trouve dans:
echo build\windows\x64\runner\Release\logesco_license_admin.exe
echo.
pause
