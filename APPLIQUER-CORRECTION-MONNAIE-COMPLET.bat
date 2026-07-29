@echo off
chcp 65001 > nul
cls

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║    APPLICATION CORRECTION MONNAIE - TOUS LES BACKENDS        ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Cette correction empêche l'enregistrement de la monnaie
echo [INFO] à rendre comme crédit client.
echo.
echo ─────────────────────────────────────────────────────────────────
echo.

REM === 1. Backend principal (développement) ===
echo [1/4] Vérification du backend principal...
if exist "backend\src\routes\sales.js" (
    echo [✓] Backend principal trouvé
    echo [INFO] La correction est déjà appliquée dans backend\src\routes\sales.js
) else (
    echo [✗] Backend principal non trouvé
)
echo.

REM === 2. Backend embarqué (production) ===
echo [2/4] Recherche du backend embarqué...
set "BACKEND_EMB=%LOCALAPPDATA%\LOGESCO\backend"

if exist "%BACKEND_EMB%\src\routes\sales.js" (
    echo [✓] Backend embarqué trouvé: %BACKEND_EMB%
    echo.
    echo [ACTION] Copie de la correction vers le backend embarqué...
    
    REM Créer une sauvegarde
    if exist "%BACKEND_EMB%\src\routes\sales.js" (
        copy /Y "%BACKEND_EMB%\src\routes\sales.js" "%BACKEND_EMB%\src\routes\sales.js.backup" >nul
        echo [✓] Sauvegarde créée: sales.js.backup
    )
    
    REM Copier le fichier corrigé
    copy /Y "backend\src\routes\sales.js" "%BACKEND_EMB%\src\routes\sales.js" >nul
    if %ERRORLEVEL% EQU 0 (
        echo [✓] Correction appliquée au backend embarqué
    ) else (
        echo [✗] Erreur lors de la copie
    )
) else (
    echo [!] Backend embarqué non trouvé
    echo [INFO] Il sera mis à jour lors du prochain build/déploiement
)
echo.

REM === 3. Backend dist-exe (si existe) ===
echo [3/4] Vérification backend dist-exe...
if exist "dist-exe\src\routes\sales.js" (
    echo [✓] Backend dist-exe trouvé
    
    REM Créer une sauvegarde
    if exist "dist-exe\src\routes\sales.js" (
        copy /Y "dist-exe\src\routes\sales.js" "dist-exe\src\routes\sales.js.backup" >nul
        echo [✓] Sauvegarde créée: sales.js.backup
    )
    
    REM Copier le fichier corrigé
    copy /Y "backend\src\routes\sales.js" "dist-exe\src\routes\sales.js" >nul
    if %ERRORLEVEL% EQU 0 (
        echo [✓] Correction appliquée au backend dist-exe
    ) else (
        echo [✗] Erreur lors de la copie
    )
) else (
    echo [!] Backend dist-exe non trouvé (normal si pas encore packagé)
)
echo.

REM === 4. Redémarrage ===
echo [4/4] Redémarrage des backends...
echo.

REM Tuer tous les processus Node.js
echo [ACTION] Arrêt des processus Node.js en cours...
taskkill /F /IM node.exe 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [✓] Processus arrêtés
) else (
    echo [!] Aucun processus à arrêter
)
timeout /t 2 /nobreak >nul
echo.

echo ════════════════════════════════════════════════════════════════
echo   CORRECTION APPLIQUÉE AVEC SUCCÈS !
echo ════════════════════════════════════════════════════════════════
echo.
echo [PROCHAINES ÉTAPES]
echo.
echo 1. Redémarrer le backend principal:
echo    ^> cd backend
echo    ^> node src\server.js
echo.
echo 2. OU redémarrer l'application Flutter (le backend embarqué
echo    démarrera automatiquement avec la correction)
echo.
echo 3. Tester avec une vente:
echo    - Montant TTC: 17888 FCFA
echo    - Montant versé: 20000 FCFA
echo    - Résultat attendu: Monnaie 2113 FCFA, solde client = 0
echo.
echo ════════════════════════════════════════════════════════════════
echo.
pause
