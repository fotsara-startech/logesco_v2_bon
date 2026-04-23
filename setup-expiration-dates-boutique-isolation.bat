@echo off
echo ========================================
echo Configuration complete: Isolation par boutique pour dates de peremption
echo ========================================
echo.

cd /d "%~dp0"

echo Etape 1: Application de la migration...
echo ----------------------------------------
call apply-boutique-id-migration.bat
if errorlevel 1 (
    echo ERREUR: La migration a echoue
    pause
    exit /b 1
)

echo.
echo Etape 2: Test de l'isolation par boutique...
echo ----------------------------------------
echo Execution du test de verification...
node test-expiration-dates-boutique-isolation.js

if errorlevel 1 (
    echo.
    echo ERREUR: Les tests ont echoue
    echo Verifiez les logs ci-dessus pour plus de details
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo SUCCESS: Configuration terminee avec succes!
    echo ========================================
    echo.
    echo L'isolation par boutique est maintenant active pour les dates de peremption:
    echo.
    echo ✅ Schema Prisma mis a jour avec boutiqueId
    echo ✅ Migration de base de donnees appliquee
    echo ✅ Donnees existantes migrees vers boutique principale
    echo ✅ API backend mise a jour avec filtrage par boutique
    echo ✅ DTO mis a jour pour inclure boutiqueId
    echo ✅ Tests de verification passes
    echo.
    echo Prochaines etapes:
    echo 1. Redemarrer le serveur backend
    echo 2. Tester l'application Flutter
    echo 3. Verifier que les dates de peremption sont bien isolees par boutique
    echo.
)

pause