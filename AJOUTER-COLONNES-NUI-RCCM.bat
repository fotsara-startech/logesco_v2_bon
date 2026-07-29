@echo off
chcp 65001 > nul
cls

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║    MIGRATION: Ajout colonnes NUI et RCCM aux clients        ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Ce script va ajouter les colonnes "nui" et "rccm" 
echo [INFO] à la table clients dans la base de données SQLite
echo.
echo ─────────────────────────────────────────────────────────────────
echo.

REM Vérifier si on est dans le bon répertoire
if not exist "backend" (
    echo [❌] Erreur: Dossier backend non trouvé
    echo [INFO] Assurez-vous d'exécuter ce script depuis la racine du projet
    echo.
    pause
    exit /b 1
)

cd backend

REM Vérifier si le script de migration existe
if not exist "fix-clients-nui-rccm-sqlite.js" (
    echo [❌] Erreur: Script de migration non trouvé
    echo [INFO] Fichier manquant: backend\fix-clients-nui-rccm-sqlite.js
    echo.
    pause
    exit /b 1
)

REM Vérifier si la base de données existe
if not exist "database\logesco.db" (
    echo [❌] Erreur: Base de données non trouvée
    echo [INFO] Fichier manquant: backend\database\logesco.db
    echo.
    pause
    exit /b 1
)

echo [1/3] Arrêt du backend en cours...
taskkill /F /IM node.exe 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [✓] Backend arrêté
    timeout /t 2 /nobreak >nul
) else (
    echo [!] Aucun backend à arrêter
)
echo.

echo [2/3] Exécution de la migration...
echo.
node fix-clients-nui-rccm-sqlite.js

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [❌] La migration a échoué
    echo [INFO] Vérifiez les messages d'erreur ci-dessus
    echo.
    cd ..
    pause
    exit /b 1
)

echo.
echo [3/3] Migration terminée avec succès !
echo.

cd ..

echo ════════════════════════════════════════════════════════════════
echo   ✅ COLONNES NUI ET RCCM AJOUTÉES AVEC SUCCÈS
echo ════════════════════════════════════════════════════════════════
echo.
echo [PROCHAINES ÉTAPES]
echo.
echo 1. Redémarrez le backend:
echo    ^> cd backend
echo    ^> node src\server.js
echo.
echo 2. OU redémarrez l'application Flutter
echo.
echo 3. Vérifiez dans l'interface client que les champs
echo    NUI et RCCM sont maintenant disponibles
echo.
echo ════════════════════════════════════════════════════════════════
echo.
pause
