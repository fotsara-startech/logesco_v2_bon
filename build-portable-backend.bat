@echo off
echo ========================================
echo Construction du Backend Portable LOGESCO
echo ========================================
echo.

cd backend
node build-portable.js
cd ..

echo.
echo ========================================
echo Build termine!
echo ========================================
echo.
echo Le package portable est dans: dist-portable\
echo.
echo Pour tester:
echo   cd dist-portable
echo   start-backend.bat
echo.
pause
