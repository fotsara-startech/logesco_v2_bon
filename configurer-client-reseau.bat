@echo off
REM ============================================================
REM Configuration Automatique du Client LOGESCO pour Serveur Distant
REM ============================================================
REM
REM Usage: configurer-client-reseau.bat <IP_SERVEUR>
REM Exemple: configurer-client-reseau.bat 192.168.1.100
REM
REM Ce script modifie automatiquement la configuration du client
REM pour pointer vers un serveur Linux distant au lieu de localhost
REM ============================================================

setlocal enabledelayedexpansion

if "%1"=="" (
    echo.
    echo ============================================================
    echo Configuration Client LOGESCO - Mode Serveur Distant
    echo ============================================================
    echo.
    echo Usage: configurer-client-reseau.bat ^<IP_SERVEUR^>
    echo.
    echo Exemple:
    echo   configurer-client-reseau.bat 192.168.1.100
    echo.
    echo Parametres:
    echo   IP_SERVEUR = Adresse IP du serveur Linux (ex: 192.168.1.100^)
    echo.
    echo Pour trouver l'IP du serveur Linux:
    echo   1. Se connecter au serveur: ssh user@serveur
    echo   2. Executer: hostname -I
    echo   3. Copier l'IP affichee
    echo.
    echo ============================================================
    echo.
    pause
    exit /b 1
)

set SERVER_IP=%1
set PROJECT_DIR=%~dp0

REM Valider le format IP (simple)
echo %SERVER_IP% | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo.
    echo ERREUR: "%SERVER_IP%" n'est pas une adresse IP valide
    echo Format attendu: XXX.XXX.XXX.XXX
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo Configuration Client LOGESCO
echo ============================================================
echo.
echo Serveur cible: %SERVER_IP%:8080
echo Repertoire: %PROJECT_DIR%
echo.

REM Verifier que le repertoire Flutter existe
if not exist "%PROJECT_DIR%logesco_v2" (
    echo ERREUR: Le repertoire logesco_v2 n'existe pas!
    echo Attendu: %PROJECT_DIR%logesco_v2
    echo.
    pause
    exit /b 1
)

echo [1/4] Modification de api_config.dart...
if exist "%PROJECT_DIR%logesco_v2\lib\core\config\api_config.dart" (
    powershell -NoProfile -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\core\config\api_config.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\core\config\api_config.dart'"
    if errorlevel 0 (
        echo   ✓ api_config.dart modifie
    ) else (
        echo   ✗ Erreur lors de la modification
    )
) else (
    echo   ⚠ Fichier non trouve
)

echo [2/4] Modification de environment_config.dart...
if exist "%PROJECT_DIR%logesco_v2\lib\core\config\environment_config.dart" (
    powershell -NoProfile -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\core\config\environment_config.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\core\config\environment_config.dart'"
    if errorlevel 0 (
        echo   ✓ environment_config.dart modifie
    ) else (
        echo   ✗ Erreur lors de la modification
    )
) else (
    echo   ⚠ Fichier non trouve
)

echo [3/4] Modification de initial_bindings.dart...
if exist "%PROJECT_DIR%logesco_v2\lib\core\bindings\initial_bindings.dart" (
    powershell -NoProfile -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\core\bindings\initial_bindings.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\core\bindings\initial_bindings.dart'"
    if errorlevel 0 (
        echo   ✓ initial_bindings.dart modifie
    ) else (
        echo   ✗ Erreur lors de la modification
    )
) else (
    echo   ⚠ Fichier non trouve
)

echo [4/4] Modification de local_config.dart...
if exist "%PROJECT_DIR%logesco_v2\lib\config\local_config.dart" (
    powershell -NoProfile -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\config\local_config.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\config\local_config.dart'"
    if errorlevel 0 (
        echo   ✓ local_config.dart modifie
    ) else (
        echo   ✗ Erreur lors de la modification
    )
) else (
    echo   ⚠ Fichier non trouve
)

echo.
echo ============================================================
echo Configuration Terminee!
echo ============================================================
echo.
echo Serveur configure: %SERVER_IP%:8080
echo.
echo Prochaines etapes:
echo.
echo  1. Verifier la connectivite:
echo     ping %SERVER_IP%
echo.
echo  2. Tester la connexion API:
echo     curl http://%SERVER_IP%:8080/api/v1/health
echo.
echo  3. Nettoyer et recompiler:
echo     cd logesco_v2
echo     flutter clean
echo     flutter pub get
echo.
echo  4. Build production (pour installer sur d'autres postes):
echo     flutter build windows --release
echo.
echo  5. Ou lancer en mode dev:
echo     flutter run -d windows
echo.
echo ============================================================
echo.
pause
