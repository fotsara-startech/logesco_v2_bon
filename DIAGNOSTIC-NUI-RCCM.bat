@echo off
chcp 65001 > nul
cls

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║         DIAGNOSTIC: Colonnes NUI et RCCM                     ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

if not exist "backend\check-nui-rccm-columns.js" (
    echo [❌] Script de diagnostic non trouvé
    echo.
    pause
    exit /b 1
)

cd backend
node check-nui-rccm-columns.js
cd ..

echo.
pause
