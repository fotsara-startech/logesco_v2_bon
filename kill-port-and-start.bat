@echo off
echo === Redémarrage Backend LOGESCO (port 8080) ===

echo Recherche du process sur le port 8080...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080 "') do (
    echo Tuer le process PID: %%a
    taskkill /f /pid %%a >nul 2>&1
)

echo Port libéré. Démarrage du backend...
timeout /t 1 /nobreak >nul
npm start
