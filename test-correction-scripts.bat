@echo off
title Test Correction Scripts
echo ========================================
echo   Test Correction Scripts Verification
echo ========================================
echo.

echo [1/3] Verification fichiers corriges...
echo.

set all_ok=1

if exist "verifier-base-vierge.bat" (
    echo ✅ verifier-base-vierge.bat
) else (
    echo ❌ verifier-base-vierge.bat MANQUANT
    set all_ok=0
)

if exist "reinitialiser-base-donnees.bat" (
    echo ✅ reinitialiser-base-donnees.bat
) else (
    echo ❌ reinitialiser-base-donnees.bat MANQUANT
    set all_ok=0
)

if exist "REINITIALISER-BASE-CLIENT.bat" (
    echo ✅ REINITIALISER-BASE-CLIENT.bat
) else (
    echo ❌ REINITIALISER-BASE-CLIENT.bat MANQUANT
    set all_ok=0
)

echo.
echo [2/3] Verification structure backend...
echo.

if exist "backend\node_modules\@prisma\client" (
    echo ✅ @prisma/client installe
) else (
    echo ⚠️  @prisma/client non installe
    echo    Executez: cd backend ^&^& npm install
    set all_ok=0
)

if exist "backend\prisma\schema.prisma" (
    echo ✅ Schema Prisma present
) else (
    echo ❌ Schema Prisma MANQUANT
    set all_ok=0
)

if exist "backend\prisma\seed.js" (
    echo ✅ Script seed present
) else (
    echo ❌ Script seed MANQUANT
    set all_ok=0
)

echo.
echo [3/3] Test creation fichier temporaire...
echo.

REM Tester la création du fichier temporaire au bon endroit
echo console.log('Test OK'); > backend\test_temp.js
if exist "backend\test_temp.js" (
    echo ✅ Creation fichier dans backend\ fonctionne
    del backend\test_temp.js 2>nul
) else (
    echo ❌ Impossible de creer fichier dans backend\
    set all_ok=0
)

echo.
echo ========================================
echo   RESULTAT
echo ========================================
echo.

if %all_ok%==1 (
    color 0A
    echo ✅ TOUS LES TESTS PASSES!
    echo.
    echo Les scripts corriges sont prets a etre utilises.
    echo.
    echo Prochaines etapes:
    echo 1. Si la base existe: verifier-base-vierge.bat
    echo 2. Pour reinitialiser: reinitialiser-base-donnees.bat
    echo 3. Pour le package client: preparer-pour-client-optimise.bat
) else (
    color 0C
    echo ❌ CERTAINS TESTS ONT ECHOUE
    echo.
    echo Verifiez les erreurs ci-dessus.
    echo.
    echo Si @prisma/client n'est pas installe:
    echo   cd backend
    echo   npm install
    echo   cd ..
)

echo.
echo ========================================
color 0F
pause
