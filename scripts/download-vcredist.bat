@echo off
echo ========================================
echo Telechargement Visual C++ Redistributable
echo ========================================
echo.

set DOWNLOAD_DIR=%~dp0..\release\LOGESCO-Client\vcredist
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

echo Telechargement de vc_redist.x64.exe...
echo.

REM Utiliser PowerShell pour télécharger
powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '%DOWNLOAD_DIR%\vc_redist.x64.exe'}"

if exist "%DOWNLOAD_DIR%\vc_redist.x64.exe" (
    echo ✓ Telechargement reussi
    echo.
    echo Fichier: %DOWNLOAD_DIR%\vc_redist.x64.exe
    echo.
    echo Ce fichier peut etre distribue avec votre application.
    echo Les utilisateurs devront l'executer avant la premiere utilisation.
) else (
    echo ❌ Echec du telechargement
    echo.
    echo Telechargez manuellement depuis:
    echo https://aka.ms/vs/17/release/vc_redist.x64.exe
)

echo.
pause
