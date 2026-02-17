@echo off
echo ========================================
echo   LOGESCO v2 - Test du Build
echo ========================================
echo.

echo [Test 1/3] Verification du backend...
if exist "dist\logesco-backend.exe" (
    echo ✓ Backend executable trouve
) else (
    echo ✗ Backend executable manquant
    echo Lancez d'abord: cd backend ^&^& npm run build:standalone
    pause
    exit /b 1
)

echo.
echo [Test 2/3] Verification des assets Flutter...
if exist "logesco_v2\assets\backend\logesco-backend.exe" (
    echo ✓ Backend copie dans les assets
) else (
    echo ✗ Backend manquant dans les assets
    echo Copiez avec: xcopy /E /I /Y dist\* logesco_v2\assets\backend\
    pause
    exit /b 1
)

echo.
echo [Test 3/3] Verification du build Flutter...
if exist "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe" (
    echo ✓ Application Flutter construite
) else (
    echo ✗ Application Flutter non construite
    echo Lancez: cd logesco_v2 ^&^& flutter build windows --release
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Tous les tests passes!
echo ========================================
echo.
echo Vous pouvez maintenant:
echo 1. Tester l'application: cd release\LOGESCO ^&^& logesco_v2.exe
echo 2. Creer l'installeur avec InnoSetup
echo.
pause
