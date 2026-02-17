@echo off
title LOGESCO - Verification Package Offline
echo ========================================
echo   VERIFICATION PACKAGE OFFLINE
echo ========================================
echo.

echo Ce script verifie que le package offline
echo est correctement prepare avec Prisma pre-genere.
echo.
pause
echo.

echo [1/5] Verification de l'existence du package...
if not exist "release\LOGESCO-Client-Offline" (
    echo ❌ Package offline non trouve
    echo Executez d'abord: preparer-offline-simple.bat
    pause
    exit /b 1
)
echo ✅ Package offline trouve
echo.

echo [2/5] Verification du backend...
if not exist "release\LOGESCO-Client-Offline\backend" (
    echo ❌ Dossier backend manquant
    pause
    exit /b 1
)
echo ✅ Dossier backend present
echo.

echo [3/5] Verification du client Prisma pre-genere...
if exist "release\LOGESCO-Client-Offline\backend\node_modules\.prisma" (
    echo ✅ Client Prisma pre-genere present
    
    REM Vérifier les fichiers critiques
    if exist "release\LOGESCO-Client-Offline\backend\node_modules\.prisma\client" (
        echo ✅ Dossier client Prisma present
    ) else (
        echo ❌ Dossier client Prisma manquant
    )
    
    REM Compter les fichiers générés
    for /f %%i in ('dir "release\LOGESCO-Client-Offline\backend\node_modules\.prisma" /s /b ^| find /c /v ""') do set PRISMA_FILES=%%i
    echo    Fichiers Prisma generes: %PRISMA_FILES%
    
    if %PRISMA_FILES% GTR 10 (
        echo ✅ Client Prisma completement genere
    ) else (
        echo ⚠️ Client Prisma partiellement genere
    )
) else (
    echo ❌ Client Prisma pre-genere MANQUANT
    echo.
    echo SOLUTION:
    echo 1. Allez dans release\LOGESCO-Client-Offline\backend
    echo 2. Executez: npm install
    echo 3. Executez: npx prisma generate
    echo 4. Relancez cette verification
    echo.
    pause
    exit /b 1
)
echo.

echo [4/5] Verification des scripts offline...
if exist "release\LOGESCO-Client-Offline\DEMARRER-LOGESCO-OFFLINE.bat" (
    echo ✅ Script de demarrage offline present
) else (
    echo ❌ Script de demarrage offline manquant
)

if exist "release\LOGESCO-Client-Offline\backend\start-backend-offline.bat" (
    echo ✅ Script backend offline present
) else (
    echo ❌ Script backend offline manquant
)
echo.

echo [5/5] Verification de l'application...
if exist "release\LOGESCO-Client-Offline\app\logesco_v2.exe" (
    echo ✅ Application Flutter presente
) else (
    echo ❌ Application Flutter manquante
)
echo.

REM Calculer la taille du package
echo Calcul de la taille du package...
for /f %%i in ('dir "release\LOGESCO-Client-Offline" /s /-c ^| find "bytes"') do set PACKAGE_SIZE=%%i

echo ========================================
echo   VERIFICATION TERMINEE
echo ========================================
echo.
echo 📦 Package: release\LOGESCO-Client-Offline\
echo 📊 Taille: %PACKAGE_SIZE% octets
echo 📁 Fichiers Prisma: %PRISMA_FILES%
echo.
echo STATUT:
if exist "release\LOGESCO-Client-Offline\backend\node_modules\.prisma" (
    if %PRISMA_FILES% GTR 10 (
        echo ✅ PACKAGE OFFLINE PRET
        echo.
        echo Ce package peut etre deploye chez un client
        echo SANS connexion Internet.
        echo.
        echo UTILISATION:
        echo 1. Copiez LOGESCO-Client-Offline chez le client
        echo 2. Executez: DEMARRER-LOGESCO-OFFLINE.bat
        echo 3. Aucune connexion Internet requise!
    ) else (
        echo ⚠️ PACKAGE PARTIELLEMENT PRET
        echo Client Prisma incomplet - Regenerez-le
    )
) else (
    echo ❌ PACKAGE NON PRET
    echo Client Prisma manquant - Executez preparer-offline-simple.bat
)
echo.
pause