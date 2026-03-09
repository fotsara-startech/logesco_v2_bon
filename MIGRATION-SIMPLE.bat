@echo off
setlocal enabledelayedexpansion
title LOGESCO - Migration Simple
color 0B
cls
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║          MIGRATION LOGESCO - APPROCHE SIMPLE           ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo PRINCIPE:
echo =========
echo 1. Mise a jour du CODE uniquement (Backend + Frontend)
echo 2. Base de donnees = JAMAIS touchee automatiquement
echo 3. Modifications BD = Scripts SQL manuels (si necessaire)
echo.
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 1/5: VERIFICATION
echo ════════════════════════════════════════════════════════
echo.
echo Dossier actuel: %CD%
echo.
set /p CONFIRM="Vous etes dans le dossier CLIENT? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo Migration annulee.
    pause
    exit /b 0
)

if not exist "backend\database\logesco.db" (
    echo.
    echo ❌ Base de donnees non trouvee!
    echo    Chemin: backend\database\logesco.db
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ Installation LOGESCO detectee
for %%A in ("backend\database\logesco.db") do echo    Base: %%~zA octets
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 2/5: RECHERCHE PACKAGE
echo ════════════════════════════════════════════════════════
echo.

set "PACKAGE_PATH="

REM Chercher le package (n'importe quel nom)
for /d %%D in (LOGESCO-Client-*) do (
    if exist "%%D\backend" (
        set "PACKAGE_PATH=%%D"
        echo ✅ Package trouve: %%D
        goto :package_found
    )
)

REM Chercher dans Package-Mise-A-Jour
for /d %%D in (Package-Mise-A-Jour\LOGESCO-Client-*) do (
    if exist "%%D\backend" (
        set "PACKAGE_PATH=%%D"
        echo ✅ Package trouve: %%D
        goto :package_found
    )
)

echo ❌ Package non trouve!
echo.
echo Placez le package ici:
echo %CD%\LOGESCO-Client-XXX\
echo.
echo Ou dans:
echo %CD%\Package-Mise-A-Jour\LOGESCO-Client-XXX\
echo.
pause
exit /b 1

:package_found
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 3/5: SAUVEGARDE
echo ════════════════════════════════════════════════════════
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_%TIMESTAMP%

echo Creation sauvegarde: %BACKUP_DIR%
mkdir "%BACKUP_DIR%"

echo.
echo [1/3] Sauvegarde base de donnees...
copy "backend\database\logesco.db" "%BACKUP_DIR%\logesco.db" >nul
echo       ✅ Base sauvegardee

echo [2/3] Sauvegarde configuration...
if exist "backend\.env" copy "backend\.env" "%BACKUP_DIR%\.env" >nul
echo       ✅ Configuration sauvegardee

echo [3/3] Sauvegarde uploads...
if exist "backend\uploads" xcopy /E /I /Y /Q "backend\uploads" "%BACKUP_DIR%\uploads" >nul 2>nul
echo       ✅ Uploads sauvegardes

echo.
echo ✅ Sauvegarde complete
echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 4/5: MISE A JOUR CODE
echo ════════════════════════════════════════════════════════
echo.

echo [1/5] Arret processus...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo       ✅ Processus arretes

echo [2/5] Sauvegarde ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien" 2>nul
ren "backend" "backend_ancien"
echo       ✅ Ancien backend sauvegarde

echo [3/5] Installation nouveau backend...
xcopy /E /I /Y /Q "%PACKAGE_PATH%\backend" "backend\" >nul
if errorlevel 1 (
    echo       ❌ Erreur!
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo       ✅ Nouveau backend installe

echo [4/5] Restauration VOTRE base de donnees...
REM Supprimer toute base vierge du package
if exist "backend\database\logesco.db" del /f /q "backend\database\logesco.db" 2>nul
if not exist "backend\database" mkdir "backend\database"

REM Restaurer la base du client
copy "%BACKUP_DIR%\logesco.db" "backend\database\logesco.db" >nul
for %%A in ("backend\database\logesco.db") do echo       ✅ Base restauree (%%~zA octets)

echo [5/5] Installation nouvelle app...
if exist "app_ancien" rmdir /s /q "app_ancien" 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo       ✅ App installee

echo.
pause
cls

echo.
echo ════════════════════════════════════════════════════════
echo   ETAPE 5/5: REGENERATION PRISMA
echo ════════════════════════════════════════════════════════
echo.
echo Prisma va etre genere avec VOTRE base de donnees.
echo Cela prend 10-20 secondes...
echo.

cd backend

REM Supprimer ancien Prisma
if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul

REM Generer Prisma
call npx prisma generate
if errorlevel 1 (
    echo.
    echo ❌ Erreur generation Prisma!
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
echo ╔════════════════════════════════════════════════════════╗
echo ║                                                        ║
echo ║              MIGRATION TERMINEE                        ║
echo ║                                                        ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo.
echo ✅ CODE mis a jour (Backend + Frontend)
echo ✅ BASE DE DONNEES preservee (non touchee)
echo.
echo 📁 SAUVEGARDES:
echo    - Donnees: %BACKUP_DIR%\
echo    - Ancien backend: backend_ancien\
echo    - Ancienne app: app_ancien\
echo.
echo 🚀 PROCHAINES ETAPES:
echo.
echo    1. Lancez: DEMARRER-LOGESCO.bat
echo.
echo    2. Testez l'application
echo.
echo    3. Si modifications de structure BD necessaires:
echo       Consultez: MIGRATIONS-BD.txt
echo.
echo 🔑 CONNEXION:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
pause
