@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

title LOGESCO - Complete Application Startup
color 0A

REM Stop any running node processes
taskkill /F /IM node.exe >nul 2>&1

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     LOGESCO v2 - Backend ^& Flutter Application              ║
echo ║                                                            ║
echo ║              Configuration: Port 3002                      ║
echo ║              Database: SQLite                              ║
echo ║              Admin: admin / admin123                       ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Start Backend
echo [1/3] Starting Backend API Server...
start "LOGESCO Backend" cmd /c "cd /d "%~dp0backend" && node src/server.js && pause"

REM Wait for backend to initialize
timeout /t 4 /nobreak >nul

echo [2/3] Verifying Backend Connection...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3002/health' -TimeoutSec 5 -ErrorAction Stop; Write-Host 'OK - Backend Ready' } catch { Write-Host 'FAILED'; exit 1 }"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Backend failed to start
    pause
    exit /b 1
)

echo [3/3] Launching Flutter Application...
echo.
cd /d "%~dp0logesco_v2"

echo ╔════════════════════════════════════════════════════════════╗
echo ║         Starting Flutter Development Server               ║
echo ║                                                            ║
echo ║  If you see connection errors:                            ║
echo ║  1. Check that the Backend window is still open           ║
echo ║  2. Verify it shows "Serveur en écoute sur le port 3002" ║
echo ║                                                            ║
echo ║  You can safely ignore this window while testing          ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

flutter run -d windows

pause
