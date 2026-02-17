@echo off
chcp 65001 > nul
title LOGESCO API Connection Test
color 0B

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║           LOGESCO API Connection Test                  ║
echo ║             Testing Port 3002                          ║
echo ╚════════════════════════════════════════════════════════╝
echo.

:: Test 1: Health Check
echo [1/5] Testing Health Endpoint...
curl -s -X GET "http://localhost:3002/health" ^
  -H "Content-Type: application/json" ^
  -w "\nStatus: %%{http_code}\n\n" || (
  echo ❌ FAILED - Backend not responding
  echo Please start the backend first: START_BACKEND.bat
  pause
  exit /b 1
)

:: Test 2: Get Roles
echo [2/5] Testing Roles Endpoint...
curl -s -X GET "http://localhost:3002/api/v1/roles" ^
  -H "Content-Type: application/json" ^
  -w "\nStatus: %%{http_code}\n\n"

:: Test 3: Login
echo [3/5] Testing Login Endpoint...
curl -s -X POST "http://localhost:3002/api/v1/auth/login" ^
  -H "Content-Type: application/json" ^
  -d "{\"nomUtilisateur\":\"admin\",\"motDePasse\":\"admin123\"}" ^
  -w "\nStatus: %%{http_code}\n\n"

:: Test 4: Available Cash Registers
echo [4/5] Testing Available Cash Registers Endpoint...
curl -s -X GET "http://localhost:3002/api/v1/cash-sessions/available-cash-registers" ^
  -H "Content-Type: application/json" ^
  -w "\nStatus: %%{http_code}\n\n"

:: Test 5: Active Session
echo [5/5] Testing Active Session Endpoint...
curl -s -X GET "http://localhost:3002/api/v1/cash-sessions/active" ^
  -H "Content-Type: application/json" ^
  -w "\nStatus: %%{http_code}\n\n"

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║              All Tests Completed                       ║
echo ║                                                        ║
echo ║  If all endpoints return 200 or valid responses,      ║
echo ║  the Flutter app should connect successfully!         ║
echo ╚════════════════════════════════════════════════════════╝
echo.

pause
