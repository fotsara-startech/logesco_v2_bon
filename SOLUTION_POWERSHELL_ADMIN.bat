@echo off
echo ========================================
echo SOLUTION - Erreur PowerShell Security
echo ========================================
echo.
echo IMPORTANT: Executer ce script EN TANT QU'ADMINISTRATEUR
echo.
echo Etape 1: Autoriser l'execution des scripts...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
echo.
echo Etape 2: Regeneration du client Prisma...
cd backend
npx prisma generate
echo.
echo ✓ Probleme resolu!
echo.
echo Demarrage du backend...
node src/server-standalone.js
pause