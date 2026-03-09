@echo off
title Verification Package CORRIGE
color 0A
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║        VERIFICATION PACKAGE CORRIGE                    ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Ce script verifie que le package CORRIGE est correct
echo et ne contient PAS de base de donnees vierge.
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   RECHERCHE DU PACKAGE
echo ════════════════════════════════════════════════════════
echo.

set "PACKAGE_FOUND=0"
set "PACKAGE_PATH="

REM Chercher dans release
if exist "release\LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=release\LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: release\LOGESCO-Client-CORRIGE
    goto :verify
)

REM Chercher dans le dossier courant
if exist "LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: LOGESCO-Client-CORRIGE
    goto :verify
)

REM Chercher dans le dossier parent
if exist "..\LOGESCO-Client-CORRIGE\backend" (
    set "PACKAGE_PATH=..\LOGESCO-Client-CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package trouve: ..\LOGESCO-Client-CORRIGE
    goto :verify
)

echo ❌ Package CORRIGE non trouve!
echo.
echo Emplacements cherches:
echo   - release\LOGESCO-Client-CORRIGE
echo   - LOGESCO-Client-CORRIGE
echo   - ..\LOGESCO-Client-CORRIGE
echo.
echo Creez d'abord le package avec:
echo   preparer-pour-client-CORRIGE.bat
echo.
pause
exit /b 1

:verify
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   VERIFICATION DU PACKAGE
echo ════════════════════════════════════════════════════════
echo.

set "ERRORS=0"

echo [1/6] Structure du package...
if not exist "%PACKAGE_PATH%\backend" (
    echo       ❌ Dossier backend manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ Dossier backend present
)

if not exist "%PACKAGE_PATH%\app" (
    echo       ❌ Dossier app manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ Dossier app present
)

if not exist "%PACKAGE_PATH%\DEMARRER-LOGESCO.bat" (
    echo       ❌ Script de demarrage manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ Script de demarrage present
)

echo.
echo [2/6] Backend...
if not exist "%PACKAGE_PATH%\backend\src\server.js" (
    echo       ❌ server.js manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ server.js present
)

if not exist "%PACKAGE_PATH%\backend\prisma\schema.prisma" (
    echo       ❌ schema.prisma manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ schema.prisma present
)

if not exist "%PACKAGE_PATH%\backend\package.json" (
    echo       ❌ package.json manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ package.json present
)

echo.
echo [3/6] Verification CRITIQUE: Base de donnees...
if exist "%PACKAGE_PATH%\backend\database\logesco.db" (
    echo       ❌ BASE DE DONNEES VIERGE DETECTEE!
    echo.
    echo       ERREUR CRITIQUE:
    echo       Le package contient une base de donnees vierge.
    echo       Cette base ecraserait les donnees du client!
    echo.
    for %%A in ("%PACKAGE_PATH%\backend\database\logesco.db") do echo       Taille: %%~zA octets
    echo.
    set /a ERRORS+=1
) else (
    echo       ✅ Pas de base vierge (CORRECT)
)

if exist "%PACKAGE_PATH%\backend\database\logesco.db-shm" (
    echo       ⚠️  Fichier temporaire SQLite detecte (.db-shm)
)

if exist "%PACKAGE_PATH%\backend\database\logesco.db-wal" (
    echo       ⚠️  Fichier temporaire SQLite detecte (.db-wal)
)

echo.
echo [4/6] Verification Prisma pre-genere...
if exist "%PACKAGE_PATH%\backend\node_modules\.prisma" (
    echo       ❌ Prisma pre-genere detecte!
    echo.
    echo       ERREUR:
    echo       Le package contient un client Prisma pre-genere.
    echo       Il doit etre genere chez le client avec SA base.
    echo.
    set /a ERRORS+=1
) else (
    echo       ✅ Pas de Prisma pre-genere (CORRECT)
)

if exist "%PACKAGE_PATH%\backend\node_modules\@prisma\client" (
    if exist "%PACKAGE_PATH%\backend\node_modules\@prisma\client\index.js" (
        echo       ⚠️  @prisma/client contient des fichiers generes
        set /a ERRORS+=1
    ) else (
        echo       ✅ @prisma/client present (package uniquement)
    )
)

echo.
echo [5/6] Application Flutter...
if not exist "%PACKAGE_PATH%\app\logesco_v2.exe" (
    echo       ❌ logesco_v2.exe manquant!
    set /a ERRORS+=1
) else (
    echo       ✅ logesco_v2.exe present
)

echo.
echo [6/6] Taille du package...
echo       Calcul en cours...

REM Compter les fichiers
set FILE_COUNT=0
for /r "%PACKAGE_PATH%" %%F in (*) do set /a FILE_COUNT+=1
echo       Fichiers: %FILE_COUNT%

echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   RESULTAT DE LA VERIFICATION
echo ════════════════════════════════════════════════════════
echo.

if %ERRORS% EQU 0 (
    echo ✅✅✅ PACKAGE CORRECT ✅✅✅
    echo.
    echo Le package CORRIGE est pret pour la distribution!
    echo.
    echo ✅ Structure complete
    echo ✅ Pas de base de donnees vierge
    echo ✅ Pas de Prisma pre-genere
    echo ✅ Application presente
    echo.
    echo Vous pouvez distribuer ce package aux clients.
    echo.
    echo Pour migrer un client:
    echo 1. Copiez le package chez le client
    echo 2. Executez: MIGRER-VERS-CORRIGE.bat
    echo.
) else (
    echo ❌❌❌ PACKAGE DEFECTUEUX ❌❌❌
    echo.
    echo Le package contient %ERRORS% erreur^(s^)!
    echo.
    echo ⚠️  NE PAS DISTRIBUER CE PACKAGE!
    echo.
    echo SOLUTION:
    echo 1. Corrigez les erreurs ci-dessus
    echo 2. Regenerez le package:
    echo    preparer-pour-client-CORRIGE.bat
    echo 3. Reverifiez avec ce script
    echo.
)

echo Package: %PACKAGE_PATH%
echo.
pause
