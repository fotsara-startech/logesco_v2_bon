@echo off
title Test Direct Prisma
color 0B
echo ========================================
echo   TEST DIRECT PRISMA
echo ========================================
echo.

echo Ce test verifie si Prisma peut lire
echo les donnees directement.
echo.
pause
echo.

cd backend
node test-direct-prisma.js
cd ..

echo.
echo ========================================
echo   INTERPRETATION
echo ========================================
echo.

echo Si "Prisma fonctionne":
echo   → Le probleme est dans l'API ou l'app Flutter
echo   → Executer: tester-api-backend.bat
echo.

echo Si "Prisma ne lit pas les donnees":
echo   → Probleme de schema/mapping
echo   → Verifier: backend\prisma\schema.prisma
echo.
pause
