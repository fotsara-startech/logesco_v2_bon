@echo off
echo ========================================
echo   TEST ULTRA SIMPLE
echo ========================================
echo.
echo Test en cours...
echo.

REM Creer fichier de log
echo TEST MIGRATION > test-resultat.txt
echo ==================== >> test-resultat.txt
echo. >> test-resultat.txt

REM Compter AVANT
echo [1] Comptage AVANT...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>{console.log(c);process.exit(0)}).catch(e=>{console.log('0');process.exit(1)}).finally(()=>p.$disconnect())" > count-avant.txt 2>&1
set /p COUNT_AVANT=<count-avant.txt
cd ..
echo AVANT: %COUNT_AVANT% produits
echo AVANT: %COUNT_AVANT% produits >> test-resultat.txt
echo.

REM Sauvegarder
echo [2] Sauvegarde...
if exist test_backup rmdir /s /q test_backup
mkdir test_backup
copy "backend\database\logesco.db" "test_backup\logesco.db" >nul
echo OK
echo.

REM Supprimer Prisma
echo [3] Suppression Prisma...
cd backend
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul
cd ..
echo OK
echo.

REM Restaurer base
echo [4] Restauration base...
del /f /q "backend\database\logesco.db" 2>nul
copy "test_backup\logesco.db" "backend\database\logesco.db" >nul
echo OK
echo.

REM Generer Prisma
echo [5] Generation Prisma...
echo (Cela prend 10-15 secondes)
cd backend
call npx prisma generate >nul 2>&1
cd ..
echo OK
echo.

REM Compter APRES
echo [6] Comptage APRES...
cd backend
node -e "const {PrismaClient}=require('@prisma/client');const p=new PrismaClient();p.produit.count().then(c=>{console.log(c);process.exit(0)}).catch(e=>{console.log('0');process.exit(1)}).finally(()=>p.$disconnect())" > count-apres.txt 2>&1
set /p COUNT_APRES=<count-apres.txt
cd ..
echo APRES: %COUNT_APRES% produits
echo APRES: %COUNT_APRES% produits >> test-resultat.txt
echo.

echo ========================================
echo   RESULTAT
echo ========================================
echo.
echo AVANT:  %COUNT_AVANT% produits
echo APRES:  %COUNT_APRES% produits
echo.
echo. >> test-resultat.txt
echo RESULTAT: >> test-resultat.txt

if "%COUNT_AVANT%"=="%COUNT_APRES%" (
    echo SUCCES! Les donnees sont preservees
    echo SUCCES! >> test-resultat.txt
) else (
    echo ECHEC! Les donnees sont perdues
    echo ECHEC! >> test-resultat.txt
)

echo.
echo Resultat sauvegarde dans: test-resultat.txt
echo.
pause
