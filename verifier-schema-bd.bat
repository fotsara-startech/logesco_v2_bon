@echo off
title LOGESCO - Verification Schema BD
color 0E
echo ========================================
echo   VERIFICATION SCHEMA BASE DE DONNEES
echo   Comparaison BD vs Prisma
echo ========================================
echo.

echo Ce script verifie que le schema de votre
echo base de donnees correspond au schema Prisma.
echo.
pause
echo.

echo [1/3] Verification de sqlite3
echo ==============================
echo.

where sqlite3 >nul 2>nul
if errorlevel 1 (
    echo ❌ sqlite3 non installe!
    echo.
    echo Pour installer sqlite3:
    echo 1. Telecharger: https://www.sqlite.org/download.html
    echo 2. Chercher "sqlite-tools-win32" ou "sqlite-tools-win-x64"
    echo 3. Extraire sqlite3.exe dans C:\Windows\System32\
    echo 4. Relancer ce script
    echo.
    pause
    exit /b 1
)

echo ✅ sqlite3 disponible
echo.

echo [2/3] Analyse du schema de la base
echo ===================================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    pause
    exit /b 1
)

echo Extraction du schema...
echo.

REM Créer un fichier temporaire pour le schéma
set SCHEMA_FILE=schema_actuel.txt
cd backend\database

echo ========================================  > %SCHEMA_FILE%
echo   SCHEMA DE LA BASE DE DONNEES ACTUELLE >> %SCHEMA_FILE%
echo ======================================== >> %SCHEMA_FILE%
echo. >> %SCHEMA_FILE%

echo TABLES: >> %SCHEMA_FILE%
echo ------- >> %SCHEMA_FILE%
sqlite3 logesco.db ".tables" >> %SCHEMA_FILE%
echo. >> %SCHEMA_FILE%
echo. >> %SCHEMA_FILE%

echo SCHEMA COMPLET: >> %SCHEMA_FILE%
echo --------------- >> %SCHEMA_FILE%
sqlite3 logesco.db ".schema" >> %SCHEMA_FILE%

echo ✅ Schema extrait dans: backend\database\%SCHEMA_FILE%
echo.

echo Affichage des tables...
echo.
sqlite3 logesco.db ".tables"
echo.

echo Verification table utilisateurs...
echo.
sqlite3 logesco.db ".schema utilisateurs"
echo.

cd ..\..
pause
echo.

echo [3/3] Verification des donnees
echo ===============================
echo.

cd backend\database

echo Table: utilisateurs
echo -------------------
echo Nombre de lignes:
sqlite3 logesco.db "SELECT COUNT(*) FROM utilisateurs;"
echo.
echo Colonnes:
sqlite3 logesco.db "PRAGMA table_info(utilisateurs);"
echo.
echo Exemple de donnees (1ere ligne):
sqlite3 logesco.db "SELECT * FROM utilisateurs LIMIT 1;"
echo.
echo.

echo Table: produits
echo ---------------
echo Nombre de lignes:
sqlite3 logesco.db "SELECT COUNT(*) FROM produits;"
echo.
echo Colonnes:
sqlite3 logesco.db "PRAGMA table_info(produits);"
echo.
echo.

echo Table: ventes
echo -------------
echo Nombre de lignes:
sqlite3 logesco.db "SELECT COUNT(*) FROM ventes;"
echo.
echo Colonnes:
sqlite3 logesco.db "PRAGMA table_info(ventes);"
echo.
echo.

cd ..\..

echo ========================================
echo   VERIFICATION TERMINEE
echo ========================================
echo.

echo 📄 FICHIERS GENERES:
echo    backend\database\%SCHEMA_FILE%
echo.

echo 🔍 PROCHAINES ETAPES:
echo.
echo 1. Ouvrir: backend\database\%SCHEMA_FILE%
echo 2. Comparer avec: backend\prisma\schema.prisma
echo 3. Verifier que les noms de colonnes correspondent
echo.

echo ⚠️  PROBLEMES COURANTS:
echo.
echo - Noms de colonnes differents (ex: nom_utilisateur vs nomUtilisateur)
echo - Tables manquantes
echo - Types de donnees incompatibles
echo.

echo 💡 SOLUTIONS:
echo.
echo Si les schemas ne correspondent pas:
echo 1. Executer: forcer-synchronisation-prisma.bat
echo 2. Ou migrer manuellement la base
echo.

echo Si Prisma utilise des mappings (@map):
echo - Verifier que les noms mappes correspondent
echo - Exemple: nomUtilisateur String @map("nom_utilisateur")
echo.

echo Si le probleme persiste:
echo 1. Consulter: SOLUTION_PROBLEME_MIGRATION_DONNEES.md
echo 2. Verifier les logs: backend\logs\
echo 3. Tester avec: curl http://localhost:8080/api/users
echo.
pause
