@echo off
chcp 65001 >nul
echo ========================================
echo Vérification de l'intégration espagnol
echo ========================================
echo.

set "ERRORS=0"

echo [1/9] Vérification du fichier es_translations.dart...
if exist "logesco_v2\lib\core\translations\es_translations.dart" (
    echo ✓ Fichier de traduction espagnol trouvé
) else (
    echo ✗ ERREUR: Fichier es_translations.dart manquant
    set /a ERRORS+=1
)

echo.
echo [2/9] Vérification de app_translations.dart...
findstr /C:"es_translations.dart" "logesco_v2\lib\core\translations\app_translations.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Import es_translations.dart présent
) else (
    echo ✗ ERREUR: Import es_translations.dart manquant
    set /a ERRORS+=1
)

echo.
echo [3/9] Vérification de la locale es_ES...
findstr /C:"'es_ES': esTranslations" "logesco_v2\lib\core\translations\app_translations.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Locale es_ES configurée
) else (
    echo ✗ ERREUR: Locale es_ES manquante
    set /a ERRORS+=1
)

echo.
echo [4/9] Vérification du language_controller.dart...
findstr /C:"case 'es':" "logesco_v2\lib\core\controllers\language_controller.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Support de 'es' dans le contrôleur
) else (
    echo ✗ ERREUR: Support 'es' manquant dans le contrôleur
    set /a ERRORS+=1
)

echo.
echo [5/9] Vérification du language_selector.dart...
findstr /C:"Español" "logesco_v2\lib\core\widgets\language_selector.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Option Español dans le sélecteur
) else (
    echo ✗ ERREUR: Option Español manquante
    set /a ERRORS+=1
)

echo.
echo [6/9] Vérification de main.dart...
findstr /C:"case 'es':" "logesco_v2\lib\main.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Support 'es' dans main.dart
) else (
    echo ✗ ERREUR: Support 'es' manquant dans main.dart
    set /a ERRORS+=1
)

echo.
echo [7/9] Vérification de la validation backend...
findstr /C:"valid('fr', 'en', 'es')" "backend\src\validation\schemas.js" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Validation backend accepte 'es'
) else (
    echo ✗ ERREUR: Validation backend ne supporte pas 'es'
    set /a ERRORS+=1
)

echo.
echo [8/9] Vérification des traductions de reçus...
findstr /C:"'es': {" "logesco_v2\lib\features\printing\utils\receipt_translations.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Traductions espagnoles pour les reçus
) else (
    echo ✗ ERREUR: Traductions reçus espagnols manquantes
    set /a ERRORS+=1
)

echo.
echo [9/9] Vérification du dropdown paramètres entreprise...
findstr /C:"Español" "logesco_v2\lib\features\company_settings\views\company_settings_page.dart" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Option Español dans paramètres entreprise
) else (
    echo ✗ ERREUR: Option Español manquante dans paramètres
    set /a ERRORS+=1
)

echo.
echo ========================================
echo Résumé de la vérification
echo ========================================

if %ERRORS% EQU 0 (
    echo.
    echo ✓✓✓ SUCCÈS ✓✓✓
    echo Tous les fichiers sont correctement configurés !
    echo.
    echo PROCHAINE ÉTAPE:
    echo Redémarrez le backend avec: restart-backend-with-spanish.bat
    echo.
) else (
    echo.
    echo ✗✗✗ ERREURS DÉTECTÉES ✗✗✗
    echo %ERRORS% erreur(s) trouvée(s)
    echo Veuillez corriger les erreurs ci-dessus.
    echo.
)

echo ========================================
pause
