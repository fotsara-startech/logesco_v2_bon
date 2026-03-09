@echo off
title Copier Scripts Migration vers Clients
color 0A
echo ========================================
echo   COPIER SCRIPTS VERS CLIENTS
echo ========================================
echo.

echo Ce script copie les scripts de migration corriges
echo vers les installations clients.
echo.

REM Client 1: Ultimate
set "CLIENT1=C:\Users\DIGITAL MARKET\Videos\LOGESCO-Client-Ultimate"

REM Client 2: Optimise
set "CLIENT2=E:\Stage 2025\LOGESCO-Client-Optimise"

echo [1] Client 1 - Ultimate
echo    Dossier: %CLIENT1%
echo.

if exist "%CLIENT1%" (
    echo Copie des scripts...
    copy /Y "trouver-base-donnees.bat" "%CLIENT1%\" >nul 2>nul
    copy /Y "migration-guidee-corrigee.bat" "%CLIENT1%\" >nul 2>nul
    copy /Y "verifier-config-database.bat" "%CLIENT1%\" >nul 2>nul
    copy /Y "SOLUTION_PROBLEME_BASE_DONNEES.md" "%CLIENT1%\" >nul 2>nul
    
    if errorlevel 1 (
        echo ❌ Erreur lors de la copie
    ) else (
        echo ✅ Scripts copies vers Client 1
    )
) else (
    echo ⚠️ Dossier non trouve - ignoré
)
echo.

echo [2] Client 2 - Optimise
echo    Dossier: %CLIENT2%
echo.

if exist "%CLIENT2%" (
    echo Copie des scripts...
    copy /Y "trouver-base-donnees.bat" "%CLIENT2%\" >nul 2>nul
    copy /Y "migration-guidee-corrigee.bat" "%CLIENT2%\" >nul 2>nul
    copy /Y "verifier-config-database.bat" "%CLIENT2%\" >nul 2>nul
    copy /Y "SOLUTION_PROBLEME_BASE_DONNEES.md" "%CLIENT2%\" >nul 2>nul
    
    if errorlevel 1 (
        echo ❌ Erreur lors de la copie
    ) else (
        echo ✅ Scripts copies vers Client 2
    )
) else (
    echo ⚠️ Dossier non trouve - ignoré
)
echo.

echo ========================================
echo   COPIE TERMINEE
echo ========================================
echo.

echo Scripts copies:
echo - trouver-base-donnees.bat
echo - migration-guidee-corrigee.bat
echo - verifier-config-database.bat
echo - SOLUTION_PROBLEME_BASE_DONNEES.md
echo.

echo PROCHAINES ETAPES:
echo.
echo Pour Client 1:
echo   cd "%CLIENT1%"
echo   trouver-base-donnees.bat
echo   migration-guidee-corrigee.bat
echo.
echo Pour Client 2:
echo   cd "%CLIENT2%"
echo   trouver-base-donnees.bat
echo   migration-guidee-corrigee.bat
echo.
pause
