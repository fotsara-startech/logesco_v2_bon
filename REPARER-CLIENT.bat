@echo off
title Reparation Client LOGESCO
color 0A
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║          REPARATION CLIENT LOGESCO                     ║
echo ║          Solution Simple                               ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Ce script repare le probleme Prisma en 30 secondes.
echo.
echo Vous etes dans: %CD%
echo.
set /p CONFIRM="C'est le dossier d'installation LOGESCO? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo Allez dans le dossier d'installation puis relancez.
    pause
    exit /b 0
)

cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║              REPARATION EN COURS                       ║
echo ╚════════════════════════════════════════════════════════╝
echo.

echo [1/4] Arret processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo       ✅ Arretes
echo.

echo [2/4] Verification base...
if not exist "backend\database\logesco.db" (
    echo       ❌ Base non trouvee!
    pause
    exit /b 1
)
echo       ✅ Base trouvee
echo.

echo [3/4] Suppression ancien Prisma...
cd backend
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul
echo       ✅ Supprime
echo.

echo [4/4] Generation nouveau Prisma...
echo       (10-15 secondes)
call npx prisma generate >nul 2>nul
if errorlevel 1 (
    echo       ❌ Erreur!
    cd ..
    pause
    exit /b 1
)
echo       ✅ Genere
cd ..
echo.

cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║              ✅ REPARATION TERMINEE                    ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Lancez maintenant: DEMARRER-LOGESCO.bat
echo.
echo Vos donnees devraient s'afficher correctement.
echo.
pause
