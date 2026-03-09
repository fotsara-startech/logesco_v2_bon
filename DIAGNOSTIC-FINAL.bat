@echo off
setlocal enabledelayedexpansion
title DIAGNOSTIC FINAL
color 0C
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║          DIAGNOSTIC FINAL - TROUVER LE PROBLEME        ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo Ce script va identifier EXACTEMENT pourquoi les donnees
echo disparaissent a chaque migration.
echo.
echo Vous etes dans: %CD%
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 1: ETAT AVANT MIGRATION
echo ════════════════════════════════════════════════════════
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Pas de base de donnees!
    pause
    exit /b 1
)

echo ✅ Base trouvee: backend\database\logesco.db
echo.

REM Taille de la base
for %%A in ("backend\database\logesco.db") do set DB_SIZE_AVANT=%%~zA
echo Taille: %DB_SIZE_AVANT% octets
echo.

REM Compter avec SQLite si disponible
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Comptage avec SQLite...
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set SQLITE_COUNT_AVANT=%%i
    echo   Produits (SQLite): !SQLITE_COUNT_AVANT!
    echo.
)

REM Compter avec Prisma
echo Comptage avec Prisma...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>{console.log(c);process.exit(0)}).catch(e=>{console.log('ERREUR:',e.message);process.exit(1)}).finally(()=>p.$disconnect())" > temp_count.txt 2>&1
set /p PRISMA_COUNT_AVANT=<temp_count.txt
del temp_count.txt
cd ..
echo   Produits (Prisma): %PRISMA_COUNT_AVANT%
echo.

echo ════════════════════════════════════════════════════════
echo   RESUME AVANT MIGRATION:
echo ════════════════════════════════════════════════════════
echo   Taille base: %DB_SIZE_AVANT% octets
if defined SQLITE_COUNT_AVANT echo   SQLite voit: !SQLITE_COUNT_AVANT! produits
echo   Prisma voit: %PRISMA_COUNT_AVANT% produits
echo ════════════════════════════════════════════════════════
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 2: SAUVEGARDE
echo ════════════════════════════════════════════════════════
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=diagnostic_%TIMESTAMP%

mkdir "%BACKUP_DIR%"
copy "backend\database\logesco.db" "%BACKUP_DIR%\logesco_avant.db" >nul

echo ✅ Sauvegarde: %BACKUP_DIR%\logesco_avant.db
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 3: SIMULATION MIGRATION
echo ════════════════════════════════════════════════════════
echo.

echo [A] Suppression Prisma existant...
cd backend
if exist "node_modules\.prisma" (
    rmdir /s /q "node_modules\.prisma" 2>nul
    echo     ✅ .prisma supprime
)
if exist "node_modules\@prisma\client" (
    rmdir /s /q "node_modules\@prisma\client" 2>nul
    echo     ✅ @prisma/client supprime
)
cd ..
echo.

echo [B] Suppression base actuelle...
del /f /q "backend\database\logesco.db" 2>nul
echo     ✅ Base supprimee
echo.

echo [C] Restauration base depuis sauvegarde...
copy "%BACKUP_DIR%\logesco_avant.db" "backend\database\logesco.db" >nul
echo     ✅ Base restauree
echo.

REM Verifier taille apres restauration
for %%A in ("backend\database\logesco.db") do set DB_SIZE_APRES_COPIE=%%~zA
echo     Taille apres copie: %DB_SIZE_APRES_COPIE% octets
echo.

if not "%DB_SIZE_AVANT%"=="%DB_SIZE_APRES_COPIE%" (
    echo     ⚠️  ATTENTION: Taille differente!
    echo     Avant: %DB_SIZE_AVANT%
    echo     Apres: %DB_SIZE_APRES_COPIE%
)
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 4: VERIFICATION BASE RESTAUREE
echo ════════════════════════════════════════════════════════
echo.

where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Comptage avec SQLite...
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set SQLITE_COUNT_APRES_COPIE=%%i
    echo   Produits (SQLite): !SQLITE_COUNT_APRES_COPIE!
    echo.
    
    if not "!SQLITE_COUNT_AVANT!"=="!SQLITE_COUNT_APRES_COPIE!" (
        echo   ❌ PROBLEME: Nombre different!
        echo   Avant: !SQLITE_COUNT_AVANT!
        echo   Apres: !SQLITE_COUNT_APRES_COPIE!
        echo.
        echo   La base n'a pas ete correctement restauree!
        pause
    )
)
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 5: GENERATION PRISMA
echo ════════════════════════════════════════════════════════
echo.

echo Generation Prisma avec la base restauree...
echo (10-15 secondes)
echo.

cd backend
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ❌ ERREUR lors de la generation Prisma!
    echo.
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo ✅ Prisma genere
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 6: VERIFICATION FINALE
echo ════════════════════════════════════════════════════════
echo.

echo Comptage avec Prisma apres generation...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>{console.log(c);process.exit(0)}).catch(e=>{console.log('ERREUR:',e.message);process.exit(1)}).finally(()=>p.$disconnect())" > temp_count2.txt 2>&1
set /p PRISMA_COUNT_APRES=<temp_count2.txt
del temp_count2.txt
cd ..
echo   Produits (Prisma): %PRISMA_COUNT_APRES%
echo.

cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║                  RESULTAT DIAGNOSTIC                   ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo AVANT MIGRATION:
echo ────────────────
echo   Taille base: %DB_SIZE_AVANT% octets
if defined SQLITE_COUNT_AVANT echo   SQLite: !SQLITE_COUNT_AVANT! produits
echo   Prisma: %PRISMA_COUNT_AVANT% produits
echo.
echo.
echo APRES COPIE BASE:
echo ─────────────────
echo   Taille base: %DB_SIZE_APRES_COPIE% octets
if defined SQLITE_COUNT_APRES_COPIE echo   SQLite: !SQLITE_COUNT_APRES_COPIE! produits
echo.
echo.
echo APRES GENERATION PRISMA:
echo ────────────────────────
echo   Prisma: %PRISMA_COUNT_APRES% produits
echo.
echo.
echo ════════════════════════════════════════════════════════
echo   ANALYSE
echo ════════════════════════════════════════════════════════
echo.

if "%PRISMA_COUNT_AVANT%"=="%PRISMA_COUNT_APRES%" (
    echo ✅ SUCCES! Les donnees sont preservees
    echo.
    echo    Le processus de migration fonctionne correctement.
    echo.
) else (
    echo ❌ ECHEC! Les donnees sont perdues
    echo.
    echo    Prisma avant: %PRISMA_COUNT_AVANT%
    echo    Prisma apres: %PRISMA_COUNT_APRES%
    echo.
    
    if defined SQLITE_COUNT_APRES_COPIE (
        if "!SQLITE_COUNT_APRES_COPIE!"=="%PRISMA_COUNT_AVANT%" (
            echo    ℹ️  SQLite voit les donnees: !SQLITE_COUNT_APRES_COPIE!
            echo    ℹ️  Mais Prisma ne les voit pas: %PRISMA_COUNT_APRES%
            echo.
            echo    PROBLEME: Generation Prisma incorrecte
            echo.
            echo    SOLUTIONS POSSIBLES:
            echo    1. Verifier schema.prisma
            echo    2. Executer: npx prisma db pull
            echo    3. Puis: npx prisma generate
        ) else (
            echo    ❌ SQLite aussi ne voit pas les donnees!
            echo    ❌ La base n'a pas ete correctement restauree
            echo.
            echo    PROBLEME: Copie de la base de donnees
        )
    )
)
echo.
echo ════════════════════════════════════════════════════════
echo.
echo Sauvegarde diagnostic: %BACKUP_DIR%
echo.
pause
