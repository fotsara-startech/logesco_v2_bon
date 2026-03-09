@echo off
echo ========================================
echo Regeneration du modele Flutter
echo ========================================
echo.

cd logesco_v2

echo Etape 1: Nettoyage des fichiers generes...
flutter pub run build_runner clean

echo.
echo Etape 2: Generation des modeles...
flutter pub run build_runner build --delete-conflicting-outputs

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERREUR: La generation a echoue
    pause
    exit /b 1
)

cd ..

echo.
echo ========================================
echo Generation terminee avec succes!
echo ========================================
echo.
echo Le fichier company_profile.g.dart a ete regenere
echo avec les nouveaux champs logo et slogan.
echo.
pause
