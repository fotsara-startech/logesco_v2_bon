@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

title LOGESCO - Complete Startup & Test
color 0A

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║     LOGESCO Backend & API Connection Startup           ║
echo ║              Port 3002 Configuration                   ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Check if backend is already running
echo Checking if port 3002 is available...
netstat -ano | findstr :3002 > nul
if !errorlevel! equ 0 (
    echo ⚠️  Port 3002 is already in use - backend might be running
    echo.
) else (
    echo ✅ Port 3002 is available
    echo.
)

REM Start backend
echo Starting LOGESCO Backend...
cd /d "%~dp0backend"

if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    echo.
)

echo Starting server...
echo.
start "LOGESCO Backend" cmd /k "node src/server.js"

REM Wait for backend to start
echo Waiting for backend to initialize...
timeout /t 3 /nobreak

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║            Testing API Endpoints                       ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Test Health
echo [1/5] Health Check...
for /f %%a in ('curl -s -o /dev/null -w "%%{http_code}" "http://localhost:3002/health"') do set HTTP_CODE=%%a
if !HTTP_CODE! equ 200 (
    echo ✅ Health: !HTTP_CODE! - OK
) else (
    echo ❌ Health: !HTTP_CODE! - FAILED
)
echo.

REM Test Roles
echo [2/5] Roles Endpoint...
for /f %%a in ('curl -s -o /dev/null -w "%%{http_code}" "http://localhost:3002/api/v1/roles"') do set HTTP_CODE=%%a
if !HTTP_CODE! equ 200 (
    echo ✅ Roles: !HTTP_CODE! - OK
) else (
    echo ❌ Roles: !HTTP_CODE! - FAILED
)
echo.

REM Test Login
echo [3/5] Login Endpoint...
for /f %%a in ('curl -s -o /dev/null -w "%%{http_code}" -X POST "http://localhost:3002/api/v1/auth/login" -H "Content-Type: application/json" -d "{\"nomUtilisateur\":\"admin\",\"motDePasse\":\"admin123\"}"') do set HTTP_CODE=%%a
if !HTTP_CODE! equ 200 (
    echo ✅ Login: !HTTP_CODE! - OK
) else (
    echo ⚠️  Login: !HTTP_CODE! - Check credentials
)
echo.

REM Test Cash Sessions
echo [4/5] Available Cash Registers...
for /f %%a in ('curl -s -o /dev/null -w "%%{http_code}" "http://localhost:3002/api/v1/cash-sessions/available-cash-registers"') do set HTTP_CODE=%%a
if !HTTP_CODE! equ 200 (
    echo ✅ Cash Registers: !HTTP_CODE! - OK
) else (
    echo ❌ Cash Registers: !HTTP_CODE! - FAILED
)
echo.

REM Test Active Session
echo [5/5] Active Session...
for /f %%a in ('curl -s -o /dev/null -w "%%{http_code}" "http://localhost:3002/api/v1/cash-sessions/active"') do set HTTP_CODE=%%a
if !HTTP_CODE! equ 200 (
    echo ✅ Active Session: !HTTP_CODE! - OK
) else if !HTTP_CODE! equ 404 (
    echo ⚠️  Active Session: !HTTP_CODE! - No active session (expected)
) else (
    echo ❌ Active Session: !HTTP_CODE! - FAILED
)
echo.

echo ╔════════════════════════════════════════════════════════╗
echo ║            ✅ Backend is Running                       ║
echo ║                                                        ║
echo ║  API Base URL: http://localhost:3002/api/v1           ║
echo ║  Health Check: http://localhost:3002/health           ║
echo ║                                                        ║
echo ║  You can now run the Flutter app!                     ║
echo ║  The backend window will remain open.                 ║
echo ║                                                        ║
echo ║  To stop the backend, close the backend window.       ║
echo ╚════════════════════════════════════════════════════════╝
echo.

echo Press any key to return to this window at any time...
echo (Backend will continue running in the other window)
echo.
pause
