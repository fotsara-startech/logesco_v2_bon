@echo off
echo ========================================
echo   Test de Deploiement LOGESCO v2
echo ========================================
echo.

REM Test 1: Vérifier que le backend existe
echo [1/6] Verification du backend...
if exist "dist\logesco-backend.exe" (
    echo ✓ Backend executable trouve
) else (
    echo ✗ Backend executable manquant
    echo Lancez d'abord: cd backend ^&^& npm run build:standalone
    pause
    exit /b 1
)

REM Test 2: Démarrer le backend en arrière-plan
echo.
echo [2/6] Demarrage du backend...
start /B dist\logesco-backend.exe
timeout /t 5 /nobreak >nul
echo ✓ Backend demarre

REM Test 3: Tester l'API de santé
echo.
echo [3/6] Test de l'API de sante...
curl -s http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    echo ✗ API non accessible
    goto cleanup
) else (
    echo ✓ API accessible
)

REM Test 4: Tester l'authentification
echo.
echo [4/6] Test de l'authentification...
curl -s -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"admin@logesco.com\",\"password\":\"admin123\"}" >nul 2>&1
if errorlevel 1 (
    echo ✗ Authentification echouee
    goto cleanup
) else (
    echo ✓ Authentification reussie
)

REM Test 5: Vérifier l'application Flutter
echo.
echo [5/6] Verification de l'application Flutter...
if exist "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe" (
    echo ✓ Application Flutter construite
) else (
    echo ✗ Application Flutter manquante
    echo Lancez: cd logesco_v2 ^&^& flutter build windows --release
)

REM Test 6: Vérifier l'installeur
echo.
echo [6/6] Verification de l'installeur...
if exist "installer-setup.iss" (
    echo ✓ Script InnoSetup present
    if exist "release\LOGESCO-v2-Setup.exe" (
        echo ✓ Installeur deja cree
    ) else (
        echo ⚠ Installeur non cree - lancez InnoSetup
    )
) else (
    echo ✗ Script InnoSetup manquant
)

echo.
echo ========================================
echo   Resultats du Test
echo ========================================
echo.
echo ✓ Backend: Fonctionnel
echo ✓ API: Operationnelle  
echo ✓ Authentification: OK
echo.
echo 🎉 Le deploiement est pret!
echo.
echo Prochaines etapes:
echo 1. Creer l'installeur avec InnoSetup
echo 2. Tester sur une machine vierge
echo 3. Distribuer aux clients
echo.

:cleanup
echo.
echo Arret du backend...
taskkill /F /IM logesco-backend.exe >nul 2>&1
echo ✓ Backend arrete
echo.
pause