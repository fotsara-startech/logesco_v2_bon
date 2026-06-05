@echo off
REM Arrête tous les processus Node.js sur le port 8080
echo ⏹️  Arrêt du backend...
netstat -ano | findstr :8080 >nul
if %errorlevel%==0 (
  for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do taskkill /PID %%a /F >nul 2>&1
  timeout /t 2 /nobreak
)

REM Démarre le backend
echo ✅ Démarrage du backend...
cd backend
call npm start
