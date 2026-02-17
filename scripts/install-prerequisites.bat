@echo off
echo ========================================
echo Installation des Prerequis LOGESCO
echo ========================================
echo.

REM Vérifier les droits administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ⚠ Ce script necessite les droits administrateur
    echo Clic droit ^> Executer en tant qu'administrateur
    echo.
    pause
    exit /b 1
)

echo ✓ Droits administrateur confirmes
echo.

REM Vérifier Node.js
echo [1/2] Verification de Node.js...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ Node.js n'est pas installe
    echo.
    echo Telechargement de Node.js...
    
    REM Télécharger Node.js
    set NODE_INSTALLER=%TEMP%\node-installer.msi
    powershell -Command "& {Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%NODE_INSTALLER%'}"
    
    if exist "%NODE_INSTALLER%" (
        echo Installation de Node.js...
        msiexec /i "%NODE_INSTALLER%" /qn /norestart
        echo ✓ Node.js installe
        del "%NODE_INSTALLER%"
    ) else (
        echo ❌ Echec du telechargement
        echo Installez manuellement: https://nodejs.org/
        pause
        exit /b 1
    )
) else (
    echo ✓ Node.js deja installe
    node --version
)
echo.

REM Vérifier Visual C++ Redistributable
echo [2/2] Verification de Visual C++ Redistributable...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
if errorlevel 1 (
    echo ❌ Visual C++ Redistributable non installe
    echo.
    
    REM Chercher le fichier dans le dossier vcredist
    if exist "%~dp0..\release\LOGESCO-Client\vcredist\vc_redist.x64.exe" (
        echo Installation de Visual C++ Redistributable...
        "%~dp0..\release\LOGESCO-Client\vcredist\vc_redist.x64.exe" /install /quiet /norestart
        echo ✓ Visual C++ Redistributable installe
    ) else (
        echo Telechargement de Visual C++ Redistributable...
        set VC_INSTALLER=%TEMP%\vc_redist.x64.exe
        powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '%VC_INSTALLER%'}"
        
        if exist "%VC_INSTALLER%" (
            echo Installation...
            "%VC_INSTALLER%" /install /quiet /norestart
            echo ✓ Visual C++ Redistributable installe
            del "%VC_INSTALLER%"
        ) else (
            echo ❌ Echec du telechargement
            echo Installez manuellement: https://aka.ms/vs/17/release/vc_redist.x64.exe
            pause
            exit /b 1
        )
    )
) else (
    echo ✓ Visual C++ Redistributable deja installe
)
echo.

echo ========================================
echo   Installation terminee avec succes!
echo ========================================
echo.
echo Vous pouvez maintenant lancer LOGESCO.
echo.
pause
