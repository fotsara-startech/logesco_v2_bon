@echo off
title LOGESCO - Compilation Installeur InnoSetup
echo.
echo Compilation de l'installeur InnoSetup...
echo.

REM Chercher ISCC.exe
set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe"       set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"

if "%ISCC%"=="" (
    echo ERREUR: InnoSetup 6 non trouve.
    pause & exit /b 1
)

echo InnoSetup: %ISCC%
echo.

REM Vérifier que les sources existent
if not exist "dist-exe\logesco-backend.exe" (
    echo ERREUR: dist-exe\logesco-backend.exe manquant.
    echo Lancez d'abord: cd backend ^& node build-exe.js
    pause & exit /b 1
)

set FLUTTER_RELEASE=logesco_v2\build\windows\x64\runner\Release
if not exist "%FLUTTER_RELEASE%\logesco_v2.exe" (
    echo ERREUR: %FLUTTER_RELEASE%\logesco_v2.exe manquant.
    echo Lancez d'abord: cd logesco_v2 ^& flutter build windows --release
    pause & exit /b 1
)

if not exist "release" mkdir "release"

echo Compilation...
"%ISCC%" installer-setup.iss
if errorlevel 1 (
    echo.
    echo ERREUR: InnoSetup a echoue. Voir les details ci-dessus.
    pause & exit /b 1
)

echo.
echo ================================================
echo  Installeur cree: release\LOGESCO-v2-Setup.exe
echo ================================================
echo.
pause
