@echo off
chcp 65001 > nul
title LOGESCO Backend Server - Port 3002
color 0A

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║         LOGESCO Backend API Server (Port 3002)         ║
echo ╚════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0backend"

if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
)

echo.
echo Starting backend server...
echo.

node src/server.js

pause
