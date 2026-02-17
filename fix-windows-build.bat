@echo off
echo 🔧 Correction des problèmes de build Windows Flutter
echo ==================================================

echo.
echo 1️⃣ Nettoyage complet...
cd logesco_v2
call flutter clean
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur flutter clean
    goto :error
)

echo.
echo 2️⃣ Suppression du cache de build Windows...
if exist "build\windows" rmdir /s /q "build\windows"
if exist ".dart_tool" rmdir /s /q ".dart_tool"

echo.
echo 3️⃣ Récupération des dépendances...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur flutter pub get
    goto :error
)

echo.
echo 4️⃣ Vérification de la configuration Flutter...
call flutter doctor
if %ERRORLEVEL% neq 0 (
    echo ⚠️  Problèmes détectés par flutter doctor
)

echo.
echo 5️⃣ Tentative de build en mode release (plus stable)...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Erreur build release
    goto :debug_mode
)

echo.
echo ✅ Build release réussi !
echo Lancement de l'application...
start "" "build\windows\x64\runner\Release\logesco_v2.exe"
goto :end

:debug_mode
echo.
echo 6️⃣ Tentative en mode debug avec verbose...
call flutter run -d windows --verbose
goto :end

:error
echo.
echo ❌ Erreur lors de la correction
echo.
echo 💡 Solutions alternatives:
echo 1. Redémarrer Visual Studio
echo 2. Redémarrer l'ordinateur
echo 3. Vérifier les mises à jour Windows
echo 4. Utiliser un émulateur Android à la place
exit /b 1

:end
cd ..