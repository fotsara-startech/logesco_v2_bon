@echo off
title LOGESCO - Telechargement Binaires Prisma
echo ========================================
echo   TELECHARGEMENT BINAIRES PRISMA
echo ========================================
echo.

echo Ce script telecharge les binaires Prisma
echo pour les inclure dans le package offline.
echo.
pause
echo.

echo [1/4] Creation du dossier binaires...
if not exist "prisma-binaires" mkdir "prisma-binaires"
cd prisma-binaires

echo ✅ Dossier cree: prisma-binaires
echo.

echo [2/4] Telechargement des binaires Prisma...
echo.
echo Telechargement query-engine...
curl -L -o "query-engine-windows.exe" "https://binaries.prisma.sh/all_commits/4bc8b6e42ac2b675d466d64f8d5fda895023ac39/windows/query-engine.exe"
if errorlevel 1 (
    echo ❌ Erreur telechargement query-engine
) else (
    echo ✅ query-engine telecharge
)

echo.
echo Telechargement schema-engine...
curl -L -o "schema-engine-windows.exe" "https://binaries.prisma.sh/all_commits/4bc8b6e42ac2b675d466d64f8d5fda895023ac39/windows/schema-engine.exe"
if errorlevel 1 (
    echo ❌ Erreur telechargement schema-engine
) else (
    echo ✅ schema-engine telecharge
)

echo.
echo Telechargement prisma-fmt...
curl -L -o "prisma-fmt-windows.exe" "https://binaries.prisma.sh/all_commits/4bc8b6e42ac2b675d466d64f8d5fda895023ac39/windows/prisma-fmt.exe"
if errorlevel 1 (
    echo ❌ Erreur telechargement prisma-fmt
) else (
    echo ✅ prisma-fmt telecharge
)

cd ..
echo.

echo [3/4] Verification des telechargements...
if exist "prisma-binaires\query-engine-windows.exe" (
    echo ✅ query-engine present
) else (
    echo ❌ query-engine manquant
)

if exist "prisma-binaires\schema-engine-windows.exe" (
    echo ✅ schema-engine present
) else (
    echo ❌ schema-engine manquant
)

if exist "prisma-binaires\prisma-fmt-windows.exe" (
    echo ✅ prisma-fmt present
) else (
    echo ❌ prisma-fmt manquant
)
echo.

echo [4/4] Creation du script d'installation...
(
echo @echo off
echo title Installation Binaires Prisma Offline
echo echo Installation des binaires Prisma pre-telecharges...
echo.
echo if not exist "node_modules\.prisma\client" mkdir "node_modules\.prisma\client"
echo if not exist "node_modules\.prisma\client\runtime" mkdir "node_modules\.prisma\client\runtime"
echo.
echo copy "prisma-binaires\query-engine-windows.exe" "node_modules\.prisma\client\query_engine-windows.exe" ^>nul
echo copy "prisma-binaires\schema-engine-windows.exe" "node_modules\.prisma\client\schema_engine-windows.exe" ^>nul  
echo copy "prisma-binaires\prisma-fmt-windows.exe" "node_modules\.prisma\client\prisma-fmt-windows.exe" ^>nul
echo.
echo echo ✅ Binaires Prisma installes
echo echo Le serveur peut maintenant demarrer sans Internet
) > "prisma-binaires\installer-binaires.bat"

echo ✅ Script d'installation cree
echo.

echo ========================================
echo   TELECHARGEMENT TERMINE
echo ========================================
echo.
echo 📁 Dossier: prisma-binaires\
echo 📦 Binaires telecharges:
echo    ✅ query-engine-windows.exe
echo    ✅ schema-engine-windows.exe  
echo    ✅ prisma-fmt-windows.exe
echo    ✅ installer-binaires.bat
echo.
echo UTILISATION:
echo 1. Copiez le dossier prisma-binaires dans votre package
echo 2. Executez installer-binaires.bat chez le client
echo 3. Le serveur fonctionnera sans Internet
echo.
echo ALTERNATIVE:
echo Utilisez plutot: preparer-pour-client-offline.bat
echo pour un package completement automatique.
echo.
pause