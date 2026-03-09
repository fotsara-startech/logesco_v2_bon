@echo off
echo ========================================
echo Installation SecureTimeService
echo ========================================
echo.

cd logesco_v2

echo [1/3] Installation des dependances...
call flutter pub get

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Echec de l'installation des dependances
    pause
    exit /b 1
)

echo.
echo [2/3] Verification de l'installation...
call flutter pub deps | findstr "ntp"

echo.
echo [3/3] Test du service...
echo.
cd ..
dart test-secure-time-service.dart

echo.
echo ========================================
echo Installation terminee avec succes!
echo ========================================
echo.
echo Prochaines etapes:
echo 1. Lire GUIDE_SECURE_TIME_SERVICE.md
echo 2. Tester la manipulation: TEST_MANIPULATION_HORLOGE.md
echo 3. Le LicenseService utilise deja le SecureTimeService
echo.
pause
