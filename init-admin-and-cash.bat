@echo off
echo ========================================
echo   LOGESCO - Initialisation Essentielle
echo ========================================
echo.
echo Ce script va creer/verifier:
echo   - Utilisateur admin (admin/admin123)
echo   - Caisse Principale
echo.

cd backend

echo 🚀 Execution du script d'initialisation...
echo.

node scripts/ensure-admin-and-cash.js

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   ✅ INITIALISATION REUSSIE !
    echo ========================================
    echo.
    echo Vous pouvez maintenant:
    echo   1. Demarrer le backend: npm run dev
    echo   2. Demarrer l'application Flutter
    echo   3. Vous connecter avec: admin / admin123
    echo.
) else (
    echo.
    echo ========================================
    echo   ❌ ERREUR LORS DE L'INITIALISATION
    echo ========================================
    echo.
    echo Verifiez que:
    echo   - La base de donnees est accessible
    echo   - Les migrations Prisma sont appliquees
    echo   - Le fichier .env est correctement configure
    echo.
)

cd ..

pause