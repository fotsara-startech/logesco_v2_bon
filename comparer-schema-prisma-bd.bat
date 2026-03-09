@echo off
title Comparaison Schema Prisma vs BD
color 0E
echo ========================================
echo   COMPARAISON SCHEMA PRISMA VS BD
echo ========================================
echo.

echo Ce script compare le schema Prisma
echo avec la structure reelle de la BD.
echo.
pause
echo.

cd backend

echo [1/2] Introspection de la BD...
echo =================================
echo.

echo Prisma va analyser la BD et creer un nouveau schema.
echo Le fichier sera sauvegarde dans: prisma\schema-from-db.prisma
echo.

call npx prisma db pull --schema=prisma/schema-from-db.prisma
if errorlevel 1 (
    echo ❌ Erreur introspection
    echo.
    echo Tentative sans fichier separe...
    call npx prisma db pull > schema-pull-output.txt 2>&1
    type schema-pull-output.txt
)

echo.
pause
echo.

echo [2/2] Comparaison...
echo ====================
echo.

if exist "prisma\schema-from-db.prisma" (
    echo ✅ Schema genere depuis la BD
    echo.
    echo Fichiers a comparer:
    echo - prisma\schema.prisma (actuel)
    echo - prisma\schema-from-db.prisma (depuis BD)
    echo.
    echo Ouvrez les 2 fichiers et comparez:
    echo - Les noms de tables
    echo - Les noms de colonnes
    echo - Les mappings @map()
    echo.
) else (
    echo ⚠️  Schema non genere
    echo.
    echo Le schema a ete mis a jour dans prisma\schema.prisma
    echo Verifiez les changements.
)

cd ..

echo.
echo ========================================
echo   SOLUTION
echo ========================================
echo.

echo Si les schemas sont differents:
echo.
echo OPTION A: Utiliser le schema genere
echo   1. Sauvegarder: copy backend\prisma\schema.prisma backend\prisma\schema-old.prisma
echo   2. Remplacer: copy backend\prisma\schema-from-db.prisma backend\prisma\schema.prisma
echo   3. Regenerer: cd backend ^& npx prisma generate
echo.

echo OPTION B: Corriger le schema actuel
echo   1. Comparer les 2 fichiers
echo   2. Corriger les noms de tables/colonnes
echo   3. Regenerer: cd backend ^& npx prisma generate
echo.
pause
