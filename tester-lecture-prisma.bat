@echo off
title LOGESCO - Test Lecture Prisma
color 0B
echo ========================================
echo   TEST LECTURE PRISMA
echo   Verification que Prisma lit les donnees
echo ========================================
echo.

echo Ce script teste si Prisma peut lire
echo les donnees de votre base de donnees.
echo.
pause
echo.

echo [1/2] Arret des processus
echo ==========================
echo.
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

echo [2/2] Execution du test Prisma
echo ===============================
echo.

cd backend
node test-prisma-connection.js
cd ..

echo.
echo ========================================
echo   TEST TERMINE
echo ========================================
echo.

echo 📊 INTERPRETATION DES RESULTATS:
echo.
echo Si "Prisma ne trouve rien" mais "SQL brut trouve des donnees":
echo   → Probleme de mapping/schema Prisma
echo   → Solution: forcer-synchronisation-prisma.bat
echo.
echo Si "Prisma fonctionne correctement":
echo   → Le probleme est ailleurs (backend, API, frontend)
echo   → Verifier les logs backend
echo.
echo Si "Aucune donnee trouvee":
echo   → La base est vide
echo   → Restaurer depuis une sauvegarde
echo.

echo 🔧 PROCHAINES ETAPES:
echo.
echo Si Prisma ne lit pas les donnees:
echo   1. Executer: forcer-synchronisation-prisma.bat
echo   2. Relancer ce test
echo.
echo Si Prisma lit les donnees mais l'app non:
echo   1. Verifier les logs: backend\logs\
echo   2. Tester l'API: curl http://localhost:8080/api/users
echo   3. Verifier le frontend
echo.
pause
