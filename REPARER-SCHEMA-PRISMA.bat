@echo off
title Reparation Schema Prisma
color 0B
echo ========================================
echo   REPARATION SCHEMA PRISMA
echo   Solution definitive
echo ========================================
echo.

echo Ce script va:
echo 1. Laisser Prisma analyser votre BD
echo 2. Generer le schema correct
echo 3. Regenerer le client Prisma
echo 4. Tester que ca marche
echo.
pause
echo.

cd backend

echo [1/4] Sauvegarde schema actuel...
echo ==================================
echo.
copy prisma\schema.prisma prisma\schema-backup.prisma >nul
echo ✅ Sauvegarde: prisma\schema-backup.prisma
echo.

echo [2/4] Introspection BD...
echo ==========================
echo.
echo Prisma va analyser la structure de votre BD...
call npx prisma db pull
echo.

echo [3/4] Generation client Prisma...
echo ==================================
echo.
call npx prisma generate
echo.

echo [4/4] Test...
echo ==============
echo.

echo Demarrage backend pour test...
start "Test Backend" /MIN node src/server.js

echo Attente 15 secondes...
timeout /t 15 /nobreak >nul

echo.
echo Test API...
curl -s http://localhost:8080/api/v1/products
echo.
echo.

taskkill /f /im node.exe >nul 2>nul

cd ..

echo.
echo ========================================
echo   REPARATION TERMINEE
echo ========================================
echo.

echo Si vous avez vu des donnees JSON ci-dessus:
echo   ✅ PROBLEME RESOLU!
echo   → Demarrer: DEMARRER-LOGESCO.bat
echo.

echo Si toujours vide:
echo   → Executer: verifier-tables-bd.bat
echo   → Verifier que la BD contient des donnees
echo.
pause
