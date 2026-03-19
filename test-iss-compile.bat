@echo off
title Test compilation InnoSetup
echo.
echo Test de compilation du script InnoSetup (sans les vraies sources)...
echo.

REM Chercher ISCC
set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe"       set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"

if "%ISCC%"=="" (
    echo ERREUR: InnoSetup 6 non trouve
    pause & exit /b 1
)

REM Creer des fichiers factices pour que InnoSetup puisse compiler
echo Creation des fichiers de test...

if not exist "dist-exe" mkdir "dist-exe"
if not exist "dist-exe\prisma-engines" mkdir "dist-exe\prisma-engines"

REM Fichiers factices
echo test > "dist-exe\logesco-backend.exe"
echo test > "dist-exe\schema.prisma"
echo NODE_ENV=production > "dist-exe\.env.example"
echo test > "dist-exe\prisma-engines\query_engine.node"

REM Dossier Flutter factice
set FLUTTER_RELEASE=logesco_v2\build\windows\x64\runner\Release
if not exist "%FLUTTER_RELEASE%" mkdir "%FLUTTER_RELEASE%"
echo test > "%FLUTTER_RELEASE%\logesco_v2.exe"

if not exist "release" mkdir "release"

echo.
echo Compilation InnoSetup...
"%ISCC%" installer-setup.iss

if errorlevel 1 (
    echo.
    echo ERREUR de compilation. Voir les details ci-dessus.
) else (
    echo.
    echo OK - Script InnoSetup compile sans erreur.
    echo Le vrai installeur sera cree avec les vraies sources.
)

echo.
pause
