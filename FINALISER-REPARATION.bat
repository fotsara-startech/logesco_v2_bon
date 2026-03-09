@echo off
title Finalisation Reparation
color 0B
echo ========================================
echo   FINALISATION REPARATION
echo ========================================
echo.

echo Le schema Prisma a ete mis a jour!
echo Il faut maintenant regenerer le client.
echo.
pause
echo.

cd backend

echo [1/2] Regeneration client Prisma...
echo ====================================
echo.
call npx prisma generate
echo.

echo [2/2] Test...
echo ==============
echo.

echo Demarrage backend...
start "Test Backend" node src/server.js

echo Attente 15 secondes...
timeout /t 15 /nobreak >nul
echo.

echo Test API Products...
curl -s http://localhost:8080/api/v1/products
echo.
echo.

echo Test API Users...
curl -s http://localhost:8080/api/v1/users
echo.
echo.

taskkill /f /im node.exe >nul 2>nul

cd ..

echo.
echo ========================================
echo   RESULTAT
echo ========================================
echo.

echo Si vous avez vu des donnees JSON ci-dessus:
echo   ✅ PROBLEME RESOLU!
echo.
echo   Prochaines etapes:
echo   1. Demarrer: DEMARRER-LOGESCO.bat
echo   2. Se connecter: admin / admin123
echo   3. Verifier que les donnees apparaissent
echo.

echo Si toujours vide:
echo   → Executer: verifier-tables-bd.bat
echo   → M'envoyer les resultats
echo.
pause
