@echo off
title LOGESCO - Diagnostic Client Complet
echo ========================================
echo   DIAGNOSTIC CLIENT COMPLET
echo ========================================
echo.

echo Ce script diagnostique l'environnement client
echo pour identifier les problemes Prisma.
echo.
pause
echo.

echo [1/8] Informations systeme...
echo OS: %OS%
echo Architecture: %PROCESSOR_ARCHITECTURE%
echo Utilisateur: %USERNAME%
echo Repertoire: %CD%
echo.

echo [2/8] Verification Node.js...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ Node.js NON INSTALLE
    echo Telechargez: https://nodejs.org/
) else (
    echo ✅ Node.js INSTALLE
    node --version
    echo Emplacement: 
    where node
)
echo.

echo [3/8] Verification npm...
where npm >nul 2>nul
if errorlevel 1 (
    echo ❌ npm NON INSTALLE
) else (
    echo ✅ npm INSTALLE
    npm --version
)
echo.

echo [4/8] Verification Prisma global...
where prisma >nul 2>nul
if errorlevel 1 (
    echo ✅ Pas de Prisma global (BIEN)
) else (
    echo ⚠️ Prisma global detecte
    prisma --version
    echo Emplacement:
    where prisma
)
echo.

echo [5/8] Verification npx...
npx --version >nul 2>nul
if errorlevel 1 (
    echo ❌ npx NON DISPONIBLE
) else (
    echo ✅ npx DISPONIBLE
    npx --version
)
echo.

echo [6/8] Verification du projet LOGESCO...
if not exist "backend\package.json" (
    echo ❌ Projet LOGESCO non trouve
    echo Placez ce script dans le dossier racine du projet
    goto end_diagnostic
)

cd backend
echo ✅ Projet LOGESCO trouve

echo.
echo Contenu package.json (dependances Prisma):
findstr /i "prisma" package.json

echo.
echo [7/8] Verification des dependances locales...
if not exist "node_modules" (
    echo ❌ node_modules manquant
    echo Executez: npm install
) else (
    echo ✅ node_modules present
    
    if exist "node_modules\.bin\prisma.cmd" (
        echo ✅ Binaire Prisma Windows present
    ) else (
        echo ❌ Binaire Prisma Windows manquant
    )
    
    if exist "node_modules\.bin\prisma" (
        echo ✅ Binaire Prisma Unix present
    ) else (
        echo ❌ Binaire Prisma Unix manquant
    )
    
    if exist "node_modules\.prisma" (
        echo ✅ Client Prisma genere
    ) else (
        echo ❌ Client Prisma non genere
    )
    
    if exist "node_modules\@prisma\client" (
        echo ✅ Package @prisma/client present
        echo Version:
        type "node_modules\@prisma\client\package.json" | findstr "version"
    ) else (
        echo ❌ Package @prisma/client manquant
    )
)

echo.
echo [8/8] Verification des fichiers LOGESCO...
if exist ".env" (
    echo ✅ Fichier .env present
    echo Contenu DATABASE_URL:
    findstr "DATABASE_URL" .env
) else (
    echo ❌ Fichier .env manquant
)

if exist "prisma\schema.prisma" (
    echo ✅ Schema Prisma present
    echo Datasource:
    findstr /A "datasource\|provider\|url" prisma\schema.prisma
) else (
    echo ❌ Schema Prisma manquant
)

if exist "database" (
    echo ✅ Dossier database present
    if exist "database\logesco.db" (
        echo ✅ Base de donnees presente
        for %%A in ("database\logesco.db") do echo    Taille: %%~zA octets
    ) else (
        echo ❌ Base de donnees manquante
    )
) else (
    echo ❌ Dossier database manquant
)

echo.
echo Test des commandes Prisma...
echo.
echo Test 1: Binaire local Windows
if exist "node_modules\.bin\prisma.cmd" (
    call node_modules\.bin\prisma.cmd --version >nul 2>nul
    if errorlevel 1 (
        echo ❌ Binaire local Windows ne fonctionne pas
    ) else (
        echo ✅ Binaire local Windows fonctionne
        call node_modules\.bin\prisma.cmd --version
    )
) else (
    echo ❌ Binaire local Windows absent
)

echo.
echo Test 2: npx avec version specifique
call npx --package=prisma@6.17.1 prisma --version >nul 2>nul
if errorlevel 1 (
    echo ❌ npx version 6.17.1 ne fonctionne pas
) else (
    echo ✅ npx version 6.17.1 fonctionne
    call npx --package=prisma@6.17.1 prisma --version
)

echo.
echo Test 3: npx version globale
call npx prisma --version >nul 2>nul
if errorlevel 1 (
    echo ❌ npx version globale ne fonctionne pas
) else (
    echo ✅ npx version globale fonctionne
    call npx prisma --version
)

cd ..

:end_diagnostic
echo.
echo ========================================
echo   DIAGNOSTIC TERMINE
echo ========================================
echo.
echo Sauvegarde du diagnostic...
echo Diagnostic effectue le %date% a %time% > diagnostic_client.txt
echo. >> diagnostic_client.txt
echo Consultez diagnostic_client.txt pour les details complets.
echo.
echo Solutions recommandees:
echo 1. Si Prisma global detecte: npm uninstall -g prisma
echo 2. Si dependances manquantes: npm install
echo 3. Si client non genere: SOLUTION_CLIENT_FINALE.bat
echo.
pause