@echo off
title LOGESCO v2
echo ========================================
echo   LOGESCO v2 - Demarrage
echo ========================================
echo.

REM Vérifier que Node.js est installé
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js n'est pas installe!
    echo.
    echo Veuillez installer Node.js 18 ou superieur:
    echo https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo ✓ Node.js detecte
node --version
echo.

REM Vérifier que le dossier backend existe
if not exist "release\LOGESCO-Client\backend" (
    echo ❌ ERREUR: Dossier backend introuvable!
    echo.
    echo Assurez-vous d'executer ce script depuis le dossier racine du projet.
    echo.
    pause
    exit /b 1
)

echo [1/2] Demarrage du backend...
echo.

REM Démarrer le backend en arrière-plan
start "LOGESCO Backend" /MIN cmd /c "cd release\LOGESCO-Client\backend && start-backend.bat"

echo ✓ Backend demarre en arriere-plan
echo   Attente de 8 secondes pour l'initialisation...
echo.

REM Attendre que le backend soit prêt
timeout /t 8 /nobreak >nul

echo [2/2] Demarrage de l'application...
echo.

REM Vérifier que l'application existe
if not exist "release\LOGESCO-Client\app\logesco_v2.exe" (
    echo ❌ ERREUR: Application introuvable!
    echo.
    pause
    exit /b 1
)

REM Démarrer l'application
start "" "release\LOGESCO-Client\app\logesco_v2.exe"

echo ✓ Application demarree
echo.
echo ========================================
echo   LOGESCO est maintenant en cours
echo ========================================
echo.
echo Backend: http://localhost:8080
echo Connexion: admin / admin123
echo.
echo Cette fenetre peut etre fermee.
echo.
timeout /t 3 >nul
exit
