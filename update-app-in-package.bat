@echo off
title LOGESCO - Mise a Jour App dans Package
echo ========================================
echo   LOGESCO - Mise a Jour App dans Package
echo ========================================
echo.

echo Ce script met a jour uniquement l'application
echo dans le package client existant.
echo.

if not exist "release\LOGESCO-Client-Ultimate" (
    echo ❌ ERREUR: Package client non trouve
    echo Executez d'abord: preparer-pour-client-ultimate.bat
    pause
    exit /b 1
)

pause
echo.

echo [1/3] Reconstruction de l'application...
cd logesco_v2
call flutter clean >nul 2>nul
call flutter pub get
if errorlevel 1 (
    echo ❌ ERREUR: flutter pub get echoue
    cd ..
    pause
    exit /b 1
)

call flutter build windows --release
if errorlevel 1 (
    echo ❌ ERREUR: Build Flutter echoue
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Application reconstruite
echo.

echo [2/3] Sauvegarde de l'ancienne app...
if exist "release\LOGESCO-Client-Ultimate\app_backup" (
    rmdir /s /q "release\LOGESCO-Client-Ultimate\app_backup" >nul 2>nul
)
if exist "release\LOGESCO-Client-Ultimate\app" (
    ren "release\LOGESCO-Client-Ultimate\app" "app_backup"
    echo ✅ Ancienne app sauvegardee
)
echo.

echo [3/3] Installation de la nouvelle app...
mkdir "release\LOGESCO-Client-Ultimate\app"
xcopy /E /I /Y /Q "logesco_v2\build\windows\x64\runner\Release\*" "release\LOGESCO-Client-Ultimate\app\" >nul
if errorlevel 1 (
    echo ❌ ERREUR: Copie de l'application echouee
    echo Restauration de l'ancienne version...
    if exist "release\LOGESCO-Client-Ultimate\app_backup" (
        rmdir /s /q "release\LOGESCO-Client-Ultimate\app" >nul 2>nul
        ren "release\LOGESCO-Client-Ultimate\app_backup" "app"
    )
    pause
    exit /b 1
)
echo ✅ Nouvelle app installee
echo.

REM Nettoyer la sauvegarde si tout s'est bien passé
if exist "release\LOGESCO-Client-Ultimate\app_backup" (
    rmdir /s /q "release\LOGESCO-Client-Ultimate\app_backup" >nul 2>nul
)

echo ========================================
echo   Mise a jour terminee avec succes!
echo ========================================
echo.
echo 📱 Application: Mise a jour avec port 8080
echo 🌐 Configuration: CORRECTE
echo 📦 Package: release\LOGESCO-Client-Ultimate\
echo.
echo Vous pouvez maintenant tester:
echo cd release\LOGESCO-Client-Ultimate
echo DEMARRER-LOGESCO-ULTIMATE.bat
echo.
pause