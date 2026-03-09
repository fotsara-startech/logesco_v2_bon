@echo off
title REPARER LOGESCO MAINTENANT
color 0A
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║          REPARATION LOGESCO - SOLUTION EXPERT         ║
echo ║                                                        ║
echo ║  Probleme: Backend affiche 0 produits                 ║
echo ║  Cause: Client Prisma pre-genere avec base vide       ║
echo ║  Solution: Regeneration complete                      ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Vous etes dans: %CD%
echo.
echo Est-ce le dossier d'installation LOGESCO?
echo (Doit contenir: backend\, app\, etc.)
echo.
set /p CONFIRM="Confirmer (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo Allez dans le dossier d'installation LOGESCO
    echo puis relancez ce script.
    echo.
    pause
    exit /b 0
)

cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                 REPARATION EN COURS                    ║
echo ╚════════════════════════════════════════════════════════╝
echo.

echo [1/5] Arret des processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo       ✅ Fait
echo.

echo [2/5] Verification base de donnees...
if not exist "backend\database\logesco.db" (
    echo       ❌ Base non trouvee!
    echo.
    echo       Verifiez que vous etes dans le bon dossier.
    pause
    exit /b 1
)
echo       ✅ Base trouvee
echo.

echo [3/5] Suppression ancien client Prisma...
cd backend
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul
echo       ✅ Supprime
echo.

echo [4/5] Introspection de votre base...
echo       (Cela peut prendre 10-20 secondes)
call npx prisma db pull >nul 2>nul
if errorlevel 1 (
    echo       ❌ Erreur!
    cd ..
    pause
    exit /b 1
)
echo       ✅ Structure detectee
echo.

echo [5/5] Generation nouveau client Prisma...
echo       (Cela peut prendre 10-20 secondes)
call npx prisma generate >nul 2>nul
if errorlevel 1 (
    echo       ❌ Erreur!
    cd ..
    pause
    exit /b 1
)
echo       ✅ Client genere
cd ..
echo.

cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║              REPARATION TERMINEE                       ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo ✅ Le probleme est resolu!
echo.
echo PROCHAINES ETAPES:
echo ------------------
echo.
echo 1. Demarrez LOGESCO normalement
echo.
echo 2. Connectez-vous:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo 3. Verifiez que vos donnees s'affichent
echo.
echo.
echo Si vos donnees s'affichent:
echo → Le probleme etait bien le client Prisma pre-genere
echo → Tout est maintenant corrige
echo.
echo Si le probleme persiste:
echo → Lisez: SOLUTION_DEFINITIVE_EXPERT.md
echo → Ou contactez le support
echo.
echo.
pause
