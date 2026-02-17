@echo off
title Verification des Prerequis LOGESCO
echo ========================================
echo   Verification des Prerequis LOGESCO
echo ========================================
echo.

set ALL_OK=1

REM Vérifier Node.js
echo [1/2] Node.js...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ NON INSTALLE
    echo.
    echo Telechargez et installez Node.js 18 ou superieur:
    echo https://nodejs.org/
    echo.
    set ALL_OK=0
) else (
    echo ✓ INSTALLE
    node --version
)
echo.

REM Vérifier Visual C++ Redistributable
echo [2/2] Visual C++ Redistributable...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
if errorlevel 1 (
    echo ❌ NON INSTALLE
    echo.
    echo Telechargez et installez:
    echo Microsoft Visual C++ 2015-2022 Redistributable (x64)
    echo https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
    set ALL_OK=0
) else (
    echo ✓ INSTALLE
)
echo.

echo ========================================
if %ALL_OK%==1 (
    echo   ✓ Tous les prerequis sont installes
    echo.
    echo   Vous pouvez lancer LOGESCO avec:
    echo   DEMARRER-LOGESCO.bat
) else (
    echo   ❌ Prerequis manquants
    echo.
    echo   Installez les composants manquants
    echo   puis relancez cette verification.
)
echo ========================================
echo.
pause
