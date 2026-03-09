@echo off
title Copie Scripts vers Package Client
echo ========================================
echo   COPIE SCRIPTS VERS PACKAGE CLIENT
echo ========================================
echo.

echo Ce script copie tous les scripts de migration
echo et synchronisation vers le package client.
echo.

set "PACKAGE_PATH=C:\Users\DIGITAL MARKET\Videos\LOGESCO-Client-Ultimate"

echo Dossier cible: %PACKAGE_PATH%
echo.

if not exist "%PACKAGE_PATH%" (
    echo ❌ Dossier package non trouve!
    echo.
    echo Veuillez modifier PACKAGE_PATH dans ce script
    echo pour pointer vers votre dossier d'installation client.
    echo.
    pause
    exit /b 1
)

echo Copie des scripts...
echo.

REM Scripts de migration
copy "migration-guidee-FIXE.bat" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ migration-guidee-FIXE.bat

copy "forcer-synchronisation-prisma.bat" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ forcer-synchronisation-prisma.bat

copy "tester-lecture-prisma.bat" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ tester-lecture-prisma.bat

copy "verifier-schema-bd.bat" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ verifier-schema-bd.bat

copy "diagnostic-migration-donnees.bat" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ diagnostic-migration-donnees.bat

copy "restaurer-donnees-urgence.bat" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ restaurer-donnees-urgence.bat

REM Script Node.js de test
copy "backend\test-prisma-connection.js" "%PACKAGE_PATH%\backend\" >nul 2>nul
if not errorlevel 1 echo ✅ backend\test-prisma-connection.js

REM Documentation
copy "LIRE_EN_PREMIER_SYNCHRONISATION.txt" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ LIRE_EN_PREMIER_SYNCHRONISATION.txt

copy "GUIDE_DEPANNAGE_DONNEES_NON_AFFICHEES.md" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ GUIDE_DEPANNAGE_DONNEES_NON_AFFICHEES.md

copy "SOLUTION_FINALE_SYNCHRONISATION.txt" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ SOLUTION_FINALE_SYNCHRONISATION.txt

copy "LIRE_MOI_MIGRATION_DONNEES.txt" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ LIRE_MOI_MIGRATION_DONNEES.txt

copy "GUIDE_MIGRATION_CLIENT_RAPIDE.md" "%PACKAGE_PATH%\" >nul 2>nul
if not errorlevel 1 echo ✅ GUIDE_MIGRATION_CLIENT_RAPIDE.md

echo.
echo ========================================
echo   COPIE TERMINEE
echo ========================================
echo.

echo 📦 Fichiers copies vers:
echo    %PACKAGE_PATH%
echo.

echo 🚀 PROCHAINES ETAPES:
echo.
echo 1. Aller dans le dossier client:
echo    cd "%PACKAGE_PATH%"
echo.
echo 2. Executer:
echo    forcer-synchronisation-prisma.bat
echo.
pause
