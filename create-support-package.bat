@echo off
REM ========================================
REM CREATION PACKAGE SUPPORT CLIENT
REM Cree un ZIP avec tous les fichiers necessaires
REM ========================================

echo =========================================
echo CREATION PACKAGE SUPPORT - LOGESCO
echo =========================================
echo.

set "PACKAGE_NAME=LOGESCO-Fix-Backend-Support"
set "PACKAGE_DIR=support-package"

echo [1] Nettoyage ancien package...
if exist "%PACKAGE_DIR%" rmdir /s /q "%PACKAGE_DIR%"
if exist "%PACKAGE_NAME%.zip" del /f /q "%PACKAGE_NAME%.zip"
echo    [OK] Nettoyage termine
echo.

echo [2] Creation dossier temporaire...
mkdir "%PACKAGE_DIR%"
echo    [OK] Dossier cree
echo.

echo [3] Copie des fichiers essentiels...

REM Script de correction PRINCIPAL
copy "FIX-COMPLET-AUTO.bat" "%PACKAGE_DIR%\" >nul
echo    [OK] Script principal copie

REM Fichier README
copy "LISEZ-MOI-EN-PREMIER.txt" "%PACKAGE_DIR%\" >nul
echo    [OK] README copie

REM Scripts de correction
copy "fix-backend-startup.bat" "%PACKAGE_DIR%\" >nul
copy "fix-backend-startup.ps1" "%PACKAGE_DIR%\" >nul
copy "force-recreate-scripts.bat" "%PACKAGE_DIR%\" >nul
copy "kill-all-node-and-restart.bat" "%PACKAGE_DIR%\" >nul
copy "diagnose-backend-startup.bat" "%PACKAGE_DIR%\" >nul
echo    [OK] Scripts copies

REM Documentation client
copy "PROCEDURE_CORRECTE.txt" "%PACKAGE_DIR%\" >nul
copy "SOLUTION_FINALE_COMPLETE.txt" "%PACKAGE_DIR%\" >nul
copy "INSTRUCTIONS_CLIENT_RAPIDES.txt" "%PACKAGE_DIR%\" >nul
copy "LIRE_MOI_PROBLEME_DEMARRAGE.txt" "%PACKAGE_DIR%\" >nul
copy "GUIDE_FIX_DEMARRAGE_BACKEND.md" "%PACKAGE_DIR%\" >nul
copy "SOLUTION_CARACTERES_SPECIAUX.md" "%PACKAGE_DIR%\" >nul
copy "RAPPORT_TEST_CLIENT.txt" "%PACKAGE_DIR%\" >nul
echo    [OK] Documentation copiee
echo.

echo [4] Creation fichier README...
(
echo ================================================================================
echo                    PACKAGE SUPPORT BACKEND - LOGESCO
echo ================================================================================
echo.
echo Ce package contient tous les outils necessaires pour corriger le probleme
echo de demarrage automatique du backend LOGESCO.
echo.
echo SOLUTION RAPIDE ^(RECOMMANDEE^) :
echo ================================================================================
echo.
echo 1. Lisez : LISEZ-MOI-EN-PREMIER.txt
echo 2. Executez : FIX-COMPLET-AUTO.bat
echo 3. Attendez "FIX COMPLET TERMINE AVEC SUCCES"
echo 4. Relancez LOGESCO
echo.
echo FICHIERS INCLUS :
echo ================================================================================
echo.
echo PRINCIPAUX :
echo   - LISEZ-MOI-EN-PREMIER.txt         : A LIRE EN PREMIER
echo   - FIX-COMPLET-AUTO.bat             : SOLUTION TOUT-EN-UN ^(recommande^)
echo.
echo SCRIPTS :
echo   - kill-all-node-and-restart.bat    : Nettoie les processus Node.js
echo   - force-recreate-scripts.bat       : Recree les scripts de demarrage
echo   - fix-backend-startup.bat          : Correction complete
echo   - fix-backend-startup.ps1          : Version PowerShell
echo   - diagnose-backend-startup.bat     : Diagnostic detaille
echo.
echo DOCUMENTATION :
echo   - PROCEDURE_CORRECTE.txt           : Instructions detaillees
echo   - SOLUTION_FINALE_COMPLETE.txt     : Explication complete
echo   - GUIDE_FIX_DEMARRAGE_BACKEND.md   : Guide complet
echo   - SOLUTION_CARACTERES_SPECIAUX.md  : Documentation technique
echo   - RAPPORT_TEST_CLIENT.txt          : Formulaire de retour
echo.
echo UTILISATION :
echo ================================================================================
echo.
echo METHODE 1 - Automatique ^(recommandee^) :
echo   1. Double-clic sur : FIX-COMPLET-AUTO.bat
echo   2. Attendez 10 secondes
echo   3. Relancez LOGESCO
echo.
echo METHODE 2 - Manuelle :
echo   1. Executez : kill-all-node-and-restart.bat
echo   2. Executez : force-recreate-scripts.bat
echo   3. Relancez LOGESCO
echo.
echo EN CAS DE PROBLEME :
echo ================================================================================
echo.
echo 1. Executez : diagnose-backend-startup.bat
echo 2. Copiez TOUTE la sortie
echo 3. Lisez : PROCEDURE_CORRECTE.txt
echo 4. Contactez : support@logesco.com
echo.
echo SUPPORT :
echo ================================================================================
echo.
echo Email : support@logesco.com
echo Documentation : LISEZ-MOI-EN-PREMIER.txt
echo.
echo ================================================================================
) > "%PACKAGE_DIR%\README.txt"

echo    [OK] README cree
echo.

echo [5] Creation du fichier ZIP...

REM Verifier si PowerShell est disponible
where powershell >nul 2>&1
if errorlevel 1 (
    echo    [WARN] PowerShell introuvable, ZIP non cree
    echo    Compressez manuellement le dossier: %PACKAGE_DIR%
) else (
    powershell -Command "Compress-Archive -Path '%PACKAGE_DIR%\*' -DestinationPath '%PACKAGE_NAME%.zip' -Force"
    if errorlevel 1 (
        echo    [ERREUR] Echec creation ZIP
    ) else (
        echo    [OK] ZIP cree: %PACKAGE_NAME%.zip
        
        REM Afficher la taille
        for %%A in ("%PACKAGE_NAME%.zip") do (
            set size=%%~zA
            set /a size_kb=!size! / 1024
            echo    Taille: !size_kb! Ko
        )
    )
)
echo.

echo [6] Nettoyage...
REM Garder le dossier temporaire pour inspection
echo    [INFO] Dossier temporaire conserve: %PACKAGE_DIR%
echo    Vous pouvez le supprimer apres verification
echo.

echo =========================================
echo CREATION PACKAGE TERMINEE!
echo =========================================
echo.
echo Fichiers crees :
echo   - %PACKAGE_NAME%.zip
echo   - %PACKAGE_DIR%\ ^(dossier temporaire^)
echo.
echo PROCHAINES ETAPES :
echo =========================================
echo.
echo 1. Testez le contenu du ZIP :
echo    - Extrayez %PACKAGE_NAME%.zip dans un dossier test
echo    - Verifiez que tous les fichiers sont presents
echo    - Testez fix-backend-startup.bat
echo.
echo 2. Envoyez le ZIP au client :
echo    - Par email
echo    - Via WeTransfer si trop gros
echo    - Via votre systeme de ticketing
echo.
echo 3. Instructions au client :
echo    - Telechargez le fichier ZIP
echo    - Extrayez les fichiers
echo    - Lisez LISEZ-MOI-EN-PREMIER.txt
echo    - Executez fix-backend-startup.bat
echo.
echo Pour creer un nouveau package :
echo    Executez ce script de nouveau
echo.
pause
