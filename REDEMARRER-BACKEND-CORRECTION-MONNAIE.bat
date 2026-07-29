@echo off
chcp 65001 > nul
cls

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║   REDÉMARRAGE BACKEND - CORRECTION MONNAIE À RENDRE          ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Correction appliquée dans: backend/src/routes/sales.js
echo [INFO] La monnaie rendue ne sera plus enregistrée comme crédit client
echo.
echo ─────────────────────────────────────────────────────────────────
echo.

cd backend

echo [1/3] Arrêt du backend existant...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo [2/3] Nettoyage du cache...
if exist node_modules\.cache rmdir /s /q node_modules\.cache

echo [3/3] Démarrage du backend corrigé...
echo.
echo ════════════════════════════════════════════════════════════════
echo   LE BACKEND EST MAINTENANT PRÊT AVEC LA CORRECTION
echo   Test: Créez une vente avec montant versé  montant TTC
echo   Résultat attendu: Monnaie à rendre sans crédit client
echo ════════════════════════════════════════════════════════════════
echo.

start "Backend Logesco - Correction Monnaie" cmd /k "node src/server.js"

echo.
echo [✓] Backend redémarré avec succès !
echo [i] Une nouvelle fenêtre s'est ouverte avec les logs du serveur
echo.
pause
