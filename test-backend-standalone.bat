@echo off
echo ========================================
echo   Test du Backend Standalone
echo ========================================
echo.

if not exist "dist\logesco-backend.exe" (
    echo ✗ Backend executable non trouve
    echo Lancez d'abord: cd backend ^&^& npm run build:standalone
    pause
    exit /b 1
)

echo ✓ Backend executable trouve
echo.
echo Demarrage du backend...
echo (Appuyez sur Ctrl+C pour arreter)
echo.

cd dist
logesco-backend.exe

pause
