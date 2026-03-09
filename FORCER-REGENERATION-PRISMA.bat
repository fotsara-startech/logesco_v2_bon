@echo off
setlocal enabledelayedexpansion
title FORCER REGENERATION PRISMA
color 0C
echo ========================================
echo   FORCER REGENERATION PRISMA
echo   Solution Definitive
echo ========================================
echo.

echo PROBLEME IDENTIFIE:
echo -------------------
echo Le client Prisma a ete pre-genere avec une base VIERGE.
echo Meme si votre base contient des donnees, Prisma utilise
echo l'ancien client qui ne "voit" rien.
echo.
echo SOLUTION:
echo ---------
echo 1. Supprimer COMPLETEMENT l'ancien client Prisma
echo 2. Introspecter VOTRE base de donnees
echo 3. Regenerer le client avec la vraie structure
echo.
pause
echo.

echo [1/6] Arret des processus
echo ===========================
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

echo [2/6] Verification base de donnees
echo ====================================
if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    echo    Chemin: backend\database\logesco.db
    echo.
    pause
    exit /b 1
)

for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
echo ✅ Base trouvee: %DB_SIZE% octets
echo.

echo [3/6] Suppression COMPLETE ancien client Prisma
echo =================================================
cd backend

echo Suppression node_modules\.prisma...
if exist "node_modules\.prisma" (
    rmdir /s /q "node_modules\.prisma" 2>nul
    echo ✅ Supprime
) else (
    echo ⚠️ Deja absent
)

echo Suppression node_modules\@prisma\client...
if exist "node_modules\@prisma\client" (
    rmdir /s /q "node_modules\@prisma\client" 2>nul
    echo ✅ Supprime
) else (
    echo ⚠️ Deja absent
)

echo Suppression node_modules\.bin\prisma...
if exist "node_modules\.bin\prisma" (
    del /f /q "node_modules\.bin\prisma" 2>nul
    echo ✅ Supprime
) else (
    echo ⚠️ Deja absent
)

echo.
echo ✅ Ancien client Prisma completement supprime
echo.

echo [4/6] Introspection de VOTRE base de donnees
echo ==============================================
echo.
echo Cette etape lit la structure REELLE de votre base
echo et met a jour le schema.prisma en consequence.
echo.

call npx prisma db pull
if errorlevel 1 (
    echo.
    echo ❌ Erreur lors de l'introspection!
    echo.
    echo VERIFICATIONS:
    echo 1. Le fichier .env existe-t-il?
    echo 2. DATABASE_URL pointe-t-il vers database/logesco.db?
    echo 3. La base de donnees est-elle accessible?
    echo.
    cd ..
    pause
    exit /b 1
)

echo.
echo ✅ Introspection reussie
echo    Le schema.prisma correspond maintenant a votre base
echo.

echo [5/6] Generation du NOUVEAU client Prisma
echo ===========================================
echo.
echo Cette etape genere un client Prisma qui "voit"
echo toutes vos donnees.
echo.

call npx prisma generate
if errorlevel 1 (
    echo.
    echo ❌ Erreur lors de la generation!
    echo.
    cd ..
    pause
    exit /b 1
)

echo.
echo ✅ Nouveau client Prisma genere
echo.

cd ..

echo [6/6] Verification
echo ===================
echo.
echo Test de demarrage du backend...
echo.

cd backend
start /min cmd /c "node src/server.js > test-output.log 2>&1"
cd ..

echo Attente 10 secondes...
timeout /t 10 /nobreak >nul

echo.
echo Verification des logs...
type backend\test-output.log | findstr "Statistiques"
echo.

REM Arreter le backend de test
taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   REGENERATION TERMINEE
echo ========================================
echo.

echo VERIFICATION:
echo -------------
echo Regardez les statistiques ci-dessus.
echo.
echo Si vous voyez:
echo   produits: 165 (ou votre nombre)
echo   clients: X
echo   ventes: Y
echo.
echo ✅ PROBLEME RESOLU!
echo.
echo Si vous voyez toujours des 0:
echo ❌ Probleme persiste
echo    → Verifier backend\test-output.log
echo    → Verifier que la base contient vraiment des donnees
echo.

echo PROCHAINES ETAPES:
echo ------------------
echo 1. Demarrez LOGESCO normalement
echo 2. Verifiez que les donnees s'affichent
echo.
echo Si ca fonctionne:
echo → Le probleme etait bien le client Prisma pre-genere
echo.
pause
