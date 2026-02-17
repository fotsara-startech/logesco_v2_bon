@echo off
echo ========================================
echo Copie des DLL Visual C++ Runtime
echo ========================================
echo.

REM Définir le dossier cible
set TARGET=%1
if "%TARGET%"=="" (
    echo ERREUR: Dossier cible non specifie
    echo Usage: copy-vcredist-dlls.bat [dossier_cible]
    exit /b 1
)

if not exist "%TARGET%" (
    echo ERREUR: Le dossier cible n'existe pas: %TARGET%
    exit /b 1
)

echo Dossier cible: %TARGET%
echo.

REM Chercher les DLL dans les emplacements standards de Visual C++ Redistributable
set FOUND=0

REM Essayer System32 (64-bit)
if exist "C:\Windows\System32\msvcp140.dll" (
    echo Copie depuis System32...
    copy /Y "C:\Windows\System32\msvcp140.dll" "%TARGET%\" >nul 2>&1
    copy /Y "C:\Windows\System32\vcruntime140.dll" "%TARGET%\" >nul 2>&1
    copy /Y "C:\Windows\System32\vcruntime140_1.dll" "%TARGET%\" >nul 2>&1
    set FOUND=1
)

if %FOUND%==1 (
    echo ✓ DLL copiees avec succes
    echo.
    echo DLL ajoutees:
    echo   - msvcp140.dll
    echo   - vcruntime140.dll
    echo   - vcruntime140_1.dll
    echo.
) else (
    echo ⚠ ATTENTION: DLL Visual C++ Runtime non trouvees
    echo.
    echo Les utilisateurs devront installer:
    echo   Microsoft Visual C++ 2015-2022 Redistributable (x64)
    echo.
    echo Telechargement:
    echo   https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
)

exit /b 0
