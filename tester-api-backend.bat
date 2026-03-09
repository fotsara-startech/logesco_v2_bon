@echo off
title Test API Backend
color 0E
echo ========================================
echo   TEST API BACKEND
echo ========================================
echo.

echo Arret processus existants...
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo.

echo Demarrage backend...
cd backend
start "LOGESCO Backend" node src/server.js
cd ..

echo Attente demarrage (15 secondes)...
timeout /t 15 /nobreak >nul
echo.

echo ========================================
echo   TESTS API
echo ========================================
echo.

echo [1/5] Test sante backend...
curl -s http://localhost:8080/health
echo.
echo.

echo [2/5] Test utilisateurs...
curl -s http://localhost:8080/api/users
echo.
echo.

echo [3/5] Test produits...
curl -s http://localhost:8080/api/products
echo.
echo.

echo [4/5] Test categories...
curl -s http://localhost:8080/api/categories
echo.
echo.

echo [5/5] Test ventes...
curl -s http://localhost:8080/api/sales
echo.
echo.

echo ========================================
echo   FIN DES TESTS
echo ========================================
echo.

echo Si vous voyez des donnees JSON ci-dessus:
echo   → Le backend fonctionne correctement
echo   → Le probleme est dans l'application Flutter
echo.

echo Si vous voyez des erreurs ou []:
echo   → Le backend ne lit pas les donnees
echo   → Verifier les logs: backend\logs\
echo.

echo Appuyez sur une touche pour arreter le backend...
pause >nul

taskkill /f /im node.exe >nul 2>nul
echo Backend arrete.
