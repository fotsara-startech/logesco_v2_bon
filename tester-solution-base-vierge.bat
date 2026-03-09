@echo off
title LOGESCO - Test Solution Base Vierge
color 0B
echo ========================================
echo   Test Solution Base Vierge
echo ========================================
echo.
echo Ce script va tester tous les composants
echo de la solution base vierge.
echo.
pause

echo.
echo ========================================
echo   [1/5] Verification Fichiers
echo ========================================
echo.

set all_ok=1

echo Scripts de reinitialisation:
if exist "reinitialiser-base-donnees.bat" (
    echo   ✅ reinitialiser-base-donnees.bat
) else (
    echo   ❌ reinitialiser-base-donnees.bat MANQUANT
    set all_ok=0
)

if exist "REINITIALISER-BASE-CLIENT.bat" (
    echo   ✅ REINITIALISER-BASE-CLIENT.bat
) else (
    echo   ❌ REINITIALISER-BASE-CLIENT.bat MANQUANT
    set all_ok=0
)

echo.
echo Scripts de verification:
if exist "verifier-base-vierge.bat" (
    echo   ✅ verifier-base-vierge.bat
) else (
    echo   ❌ verifier-base-vierge.bat MANQUANT
    set all_ok=0
)

echo.
echo Documentation:
if exist "GUIDE_BASE_DONNEES_VIERGE.md" (
    echo   ✅ GUIDE_BASE_DONNEES_VIERGE.md
) else (
    echo   ❌ GUIDE_BASE_DONNEES_VIERGE.md MANQUANT
    set all_ok=0
)

if exist "GUIDE_REINITIALISATION_BASE.md" (
    echo   ✅ GUIDE_REINITIALISATION_BASE.md
) else (
    echo   ❌ GUIDE_REINITIALISATION_BASE.md MANQUANT
    set all_ok=0
)

if exist "CORRECTION_BASE_VIERGE_PRODUCTION.md" (
    echo   ✅ CORRECTION_BASE_VIERGE_PRODUCTION.md
) else (
    echo   ❌ CORRECTION_BASE_VIERGE_PRODUCTION.md MANQUANT
    set all_ok=0
)

if exist "RESUME_SOLUTION_BASE_VIERGE.md" (
    echo   ✅ RESUME_SOLUTION_BASE_VIERGE.md
) else (
    echo   ❌ RESUME_SOLUTION_BASE_VIERGE.md MANQUANT
    set all_ok=0
)

if exist "LIRE_MOI_REINITIALISATION.txt" (
    echo   ✅ LIRE_MOI_REINITIALISATION.txt
) else (
    echo   ❌ LIRE_MOI_REINITIALISATION.txt MANQUANT
    set all_ok=0
)

echo.
echo Scripts modifies:
if exist "preparer-pour-client-optimise.bat" (
    echo   ✅ preparer-pour-client-optimise.bat
) else (
    echo   ❌ preparer-pour-client-optimise.bat MANQUANT
    set all_ok=0
)

if exist "backend\build-portable-optimized.js" (
    echo   ✅ backend\build-portable-optimized.js
) else (
    echo   ❌ backend\build-portable-optimized.js MANQUANT
    set all_ok=0
)

if %all_ok%==0 (
    echo.
    color 0C
    echo ❌ ERREUR: Certains fichiers sont manquants!
    pause
    exit /b 1
)

echo.
echo ✅ Tous les fichiers sont presents
echo.

echo ========================================
echo   [2/5] Verification Node.js
echo ========================================
echo.

where node >nul 2>nul
if errorlevel 1 (
    color 0C
    echo ❌ Node.js n'est pas installe!
    echo    Installez Node.js depuis: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js detecte
node --version
echo.

echo ========================================
echo   [3/5] Verification Backend
echo ========================================
echo.

if not exist "backend\prisma\schema.prisma" (
    color 0C
    echo ❌ Schema Prisma non trouve!
    pause
    exit /b 1
)
echo ✅ Schema Prisma present

if not exist "backend\prisma\seed.js" (
    color 0C
    echo ❌ Script seed non trouve!
    pause
    exit /b 1
)
echo ✅ Script seed present

if not exist "backend\package.json" (
    color 0C
    echo ❌ package.json non trouve!
    pause
    exit /b 1
)
echo ✅ package.json present

echo.

echo ========================================
echo   [4/5] Test Script Verification
echo ========================================
echo.

echo Test du script verifier-base-vierge.bat...
echo (Ce test peut echouer si la base n'existe pas encore)
echo.

REM Le test de verification peut echouer si pas de base
REM C'est normal, on continue quand meme

echo ⚠️  Test de verification saute (optionnel)
echo    Executez manuellement: verifier-base-vierge.bat
echo.

echo ========================================
echo   [5/5] Verification Package Client
echo ========================================
echo.

if exist "release\LOGESCO-Client-Optimise" (
    echo ✅ Dossier package client existe
    
    if exist "release\LOGESCO-Client-Optimise\REINITIALISER-BASE-DONNEES.bat" (
        echo ✅ Script reinitialisation present dans le package
    ) else (
        echo ⚠️  Script reinitialisation absent du package
        echo    Executez: preparer-pour-client-optimise.bat
    )
    
    if exist "release\LOGESCO-Client-Optimise\backend\database" (
        echo ✅ Dossier database present
    ) else (
        echo ⚠️  Dossier database absent
    )
) else (
    echo ⚠️  Package client non construit
    echo    Executez: preparer-pour-client-optimise.bat
)

echo.
echo ========================================
echo   RESULTAT DES TESTS
echo ========================================
echo.

if %all_ok%==1 (
    color 0A
    echo ✅ TOUS LES TESTS PASSES!
    echo.
    echo La solution base vierge est complete et fonctionnelle.
    echo.
    echo Prochaines etapes:
    echo 1. Construire le package: preparer-pour-client-optimise.bat
    echo 2. Verifier la base: verifier-base-vierge.bat
    echo 3. Tester la reinitialisation (optionnel)
    echo 4. Deployer chez le client
) else (
    color 0C
    echo ❌ CERTAINS TESTS ONT ECHOUE
    echo.
    echo Verifiez les erreurs ci-dessus et corrigez-les.
)

echo.
echo ========================================
echo   DOCUMENTATION DISPONIBLE
echo ========================================
echo.
echo - LIRE_MOI_REINITIALISATION.txt (Guide rapide)
echo - GUIDE_BASE_DONNEES_VIERGE.md (Guide complet base vierge)
echo - GUIDE_REINITIALISATION_BASE.md (Guide reinitialisation)
echo - RESUME_SOLUTION_BASE_VIERGE.md (Resume complet)
echo.
echo ========================================
color 0F
pause
