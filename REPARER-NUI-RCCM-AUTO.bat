@echo off
chcp 65001 > nul
cls

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║    RÉPARATION AUTOMATIQUE: Colonnes NUI et RCCM             ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Ce script va :
echo   1. Diagnostiquer la base de données
echo   2. Appliquer la migration si nécessaire
echo   3. Vérifier le résultat
echo.
echo ─────────────────────────────────────────────────────────────────
echo.
pause
cls

REM ═══════════════════════════════════════════════════════════════
REM ÉTAPE 1 : DIAGNOSTIC INITIAL
REM ═══════════════════════════════════════════════════════════════
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║   ÉTAPE 1/3 : DIAGNOSTIC INITIAL                             ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

cd backend 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [❌] Dossier backend non trouvé
    pause
    exit /b 1
)

node check-nui-rccm-columns.js > ..\diagnostic_initial.txt 2>&1
type ..\diagnostic_initial.txt
cd ..

REM Vérifier si les colonnes manquent
findstr /C:"MANQUANTE" diagnostic_initial.txt >nul
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [!] Colonnes manquantes détectées
    set NEED_MIGRATION=1
) else (
    echo.
    echo [✓] Les colonnes sont déjà présentes
    set NEED_MIGRATION=0
    goto :DONE
)

echo.
pause
cls

REM ═══════════════════════════════════════════════════════════════
REM ÉTAPE 2 : MIGRATION
REM ═══════════════════════════════════════════════════════════════
if %NEED_MIGRATION%==1 (
    echo.
    echo ╔═══════════════════════════════════════════════════════════════╗
    echo ║   ÉTAPE 2/3 : APPLICATION DE LA MIGRATION                    ║
    echo ╚═══════════════════════════════════════════════════════════════╝
    echo.
    
    REM Arrêter les processus
    echo [1] Arrêt des processus en cours...
    taskkill /F /IM node.exe 2>nul
    taskkill /F /IM logesco_v2.exe 2>nul
    timeout /t 2 /nobreak >nul
    echo.
    
    REM Créer une sauvegarde
    echo [2] Création d'une sauvegarde...
    if exist "backend\database\logesco.db" (
        copy /Y "backend\database\logesco.db" "backend\database\logesco.db.backup" >nul
        echo [✓] Sauvegarde créée: backend\database\logesco.db.backup
    )
    
    REM Vérifier aussi le backend embarqué
    set "BACKEND_EMB=%LOCALAPPDATA%\LOGESCO\backend"
    if exist "%BACKEND_EMB%\database\logesco.db" (
        copy /Y "%BACKEND_EMB%\database\logesco.db" "%BACKEND_EMB%\database\logesco.db.backup" >nul
        echo [✓] Sauvegarde créée: %BACKEND_EMB%\database\logesco.db.backup
    )
    echo.
    
    REM Exécuter la migration
    echo [3] Exécution de la migration...
    echo.
    cd backend
    node fix-clients-nui-rccm-sqlite.js
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [❌] Échec de la migration
        cd ..
        pause
        exit /b 1
    )
    cd ..
    echo.
    
    REM Migration du backend embarqué si existe
    if exist "%BACKEND_EMB%\database\logesco.db" (
        echo [4] Migration du backend embarqué...
        copy /Y "backend\fix-clients-nui-rccm-sqlite.js" "%BACKEND_EMB%\" >nul
        cd /d "%BACKEND_EMB%"
        
        set "NODE_EXE=%BACKEND_EMB%\node.exe"
        if not exist "%NODE_EXE%" set "NODE_EXE=node"
        
        "%NODE_EXE%" fix-clients-nui-rccm-sqlite.js
        del /Q fix-clients-nui-rccm-sqlite.js 2>nul
        
        cd /d "%~dp0"
        echo.
    )
    
    pause
    cls
)

REM ═══════════════════════════════════════════════════════════════
REM ÉTAPE 3 : VÉRIFICATION FINALE
REM ═══════════════════════════════════════════════════════════════
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║   ÉTAPE 3/3 : VÉRIFICATION FINALE                            ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

cd backend
node check-nui-rccm-columns.js > ..\diagnostic_final.txt 2>&1
type ..\diagnostic_final.txt
cd ..

REM Vérifier le succès
findstr /C:"✅ Présente" diagnostic_final.txt | findstr /C:"nui" >nul
if %ERRORLEVEL% EQU 0 (
    findstr /C:"✅ Présente" diagnostic_final.txt | findstr /C:"rccm" >nul
    if %ERRORLEVEL% EQU 0 (
        set MIGRATION_SUCCESS=1
    ) else (
        set MIGRATION_SUCCESS=0
    )
) else (
    set MIGRATION_SUCCESS=0
)

echo.
echo ════════════════════════════════════════════════════════════════

if %MIGRATION_SUCCESS%==1 (
    echo.
    echo   ✅ RÉPARATION RÉUSSIE !
    echo.
    echo   Les colonnes NUI et RCCM ont été ajoutées avec succès
    echo   Vous pouvez maintenant redémarrer l'application
    echo.
) else (
    echo.
    echo   ⚠️ VÉRIFICATION RECOMMANDÉE
    echo.
    echo   La migration a été exécutée mais la vérification
    echo   n'a pas pu confirmer le succès complet.
    echo   Consultez les logs ci-dessus pour plus de détails.
    echo.
)

echo ════════════════════════════════════════════════════════════════
echo.
echo [FICHIERS CRÉÉS]
echo   - diagnostic_initial.txt  (avant migration)
echo   - diagnostic_final.txt    (après migration)
echo   - logesco.db.backup       (sauvegarde)
echo.

:DONE
echo.
pause

REM Nettoyer les fichiers temporaires
del /Q diagnostic_initial.txt 2>nul
del /Q diagnostic_final.txt 2>nul
