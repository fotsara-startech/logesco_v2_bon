@echo off
echo ========================================
echo Test de Copie VC Redistributable
echo ========================================
echo.

echo Verification du fichier source...
if exist "logesco_v2\assets\VC_redist.x64.exe" (
    echo ✓ Fichier trouve: logesco_v2\assets\VC_redist.x64.exe
    for %%A in ("logesco_v2\assets\VC_redist.x64.exe") do echo   Taille: %%~zA octets
) else if exist "logesco_v2\assets\vc_redist.x64.exe" (
    echo ✓ Fichier trouve: logesco_v2\assets\vc_redist.x64.exe
    for %%A in ("logesco_v2\assets\vc_redist.x64.exe") do echo   Taille: %%~zA octets
) else (
    echo ❌ Fichier non trouve dans logesco_v2\assets\
    echo.
    echo Placez VC_redist.x64.exe dans logesco_v2\assets\
    pause
    exit /b 1
)

echo.
echo Creation du dossier de test...
if not exist "test-vcredist" mkdir "test-vcredist"

echo Copie du fichier...
if exist "logesco_v2\assets\VC_redist.x64.exe" (
    copy /Y "logesco_v2\assets\VC_redist.x64.exe" "test-vcredist\vc_redist.x64.exe" >nul
) else (
    copy /Y "logesco_v2\assets\vc_redist.x64.exe" "test-vcredist\vc_redist.x64.exe" >nul
)

if exist "test-vcredist\vc_redist.x64.exe" (
    echo ✓ Copie reussie
    for %%A in ("test-vcredist\vc_redist.x64.exe") do echo   Taille: %%~zA octets
) else (
    echo ❌ Echec de la copie
    pause
    exit /b 1
)

echo.
echo Nettoyage...
rmdir /s /q "test-vcredist"

echo.
echo ========================================
echo ✓ Test reussi!
echo ========================================
echo.
echo Le script preparer-pour-client.bat copiera correctement
echo le fichier VC_redist.x64.exe dans le package client.
echo.
pause
