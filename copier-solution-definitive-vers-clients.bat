@echo off
title Copier Solution Definitive vers Clients
color 0B
echo ========================================
echo   COPIER SOLUTION DEFINITIVE
echo ========================================
echo.

set "CLIENT1=C:\Users\DIGITAL MARKET\Videos\LOGESCO-Client-Ultimate"
set "CLIENT2=E:\Stage 2025\LOGESCO-Client-Optimise"

echo Scripts de solution definitive:
echo - REPARER-MAINTENANT.bat
echo - FORCER-REGENERATION-PRISMA.bat
echo - migration-guidee-DEFINITIVE.bat
echo - SOLUTION_DEFINITIVE_EXPERT.md
echo - LIRE_MOI_SOLUTION_DEFINITIVE.txt
echo.
pause
echo.

echo [1] Client 1 - Ultimate
echo ========================
if exist "%CLIENT1%" (
    echo Copie vers: %CLIENT1%
    copy /Y "REPARER-MAINTENANT.bat" "%CLIENT1%\" >nul 2>nul
    copy /Y "FORCER-REGENERATION-PRISMA.bat" "%CLIENT1%\" >nul 2>nul
    copy /Y "migration-guidee-DEFINITIVE.bat" "%CLIENT1%\" >nul 2>nul
    copy /Y "SOLUTION_DEFINITIVE_EXPERT.md" "%CLIENT1%\" >nul 2>nul
    copy /Y "LIRE_MOI_SOLUTION_DEFINITIVE.txt" "%CLIENT1%\" >nul 2>nul
    
    if errorlevel 1 (
        echo ❌ Erreur
    ) else (
        echo ✅ Copie reussie
    )
) else (
    echo ⚠️ Dossier non trouve
)
echo.

echo [2] Client 2 - Optimise
echo ========================
if exist "%CLIENT2%" (
    echo Copie vers: %CLIENT2%
    copy /Y "REPARER-MAINTENANT.bat" "%CLIENT2%\" >nul 2>nul
    copy /Y "FORCER-REGENERATION-PRISMA.bat" "%CLIENT2%\" >nul 2>nul
    copy /Y "migration-guidee-DEFINITIVE.bat" "%CLIENT2%\" >nul 2>nul
    copy /Y "SOLUTION_DEFINITIVE_EXPERT.md" "%CLIENT2%\" >nul 2>nul
    copy /Y "LIRE_MOI_SOLUTION_DEFINITIVE.txt" "%CLIENT2%\" >nul 2>nul
    
    if errorlevel 1 (
        echo ❌ Erreur
    ) else (
        echo ✅ Copie reussie
    )
) else (
    echo ⚠️ Dossier non trouve
)
echo.

echo ========================================
echo   COPIE TERMINEE
echo ========================================
echo.

echo PROCHAINES ETAPES:
echo.
echo Pour Client 1:
echo   cd "%CLIENT1%"
echo   REPARER-MAINTENANT.bat
echo.
echo Pour Client 2:
echo   cd "%CLIENT2%"
echo   REPARER-MAINTENANT.bat
echo.

echo DOCUMENTATION:
echo - LIRE_MOI_SOLUTION_DEFINITIVE.txt (Instructions simples)
echo - SOLUTION_DEFINITIVE_EXPERT.md (Explication complete)
echo.
pause
