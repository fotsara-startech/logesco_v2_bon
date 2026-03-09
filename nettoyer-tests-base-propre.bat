@echo off
echo ========================================
echo   Nettoyage Fichiers de Test
echo ========================================
echo.
echo Ce script supprime les fichiers de test crees
echo lors des demonstrations et tests.
echo.
echo Fichiers qui seront supprimes:
echo - backend\prisma\database\logesco-test.db
echo - dist-portable\ (dossier complet)
echo.
echo Votre base de developpement ne sera PAS affectee!
echo (backend\prisma\database\logesco.db reste intacte)
echo.
pause
echo.

echo [1/2] Suppression base de test...
if exist "backend\prisma\database\logesco-test.db" (
    del /f "backend\prisma\database\logesco-test.db"
    echo ✅ Base de test supprimee
) else (
    echo ℹ️  Aucune base de test trouvee
)
echo.

echo [2/2] Suppression dossier dist-portable...
if exist "dist-portable" (
    rmdir /s /q "dist-portable"
    echo ✅ Dossier dist-portable supprime
) else (
    echo ℹ️  Aucun dossier dist-portable trouve
)
echo.

echo ========================================
echo   Nettoyage Termine!
echo ========================================
echo.
echo ✅ Fichiers de test supprimes
echo ✅ Votre base de developpement est intacte
echo.
echo Vous pouvez maintenant:
echo - Creer un nouveau package: preparer-pour-client-optimise.bat
echo - Tester a nouveau: demo-base-propre.bat
echo.
pause
