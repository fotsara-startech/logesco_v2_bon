@echo off
echo ========================================
echo Reconstruction du Backend LOGESCO
echo ========================================
echo.

cd backend

echo [1/5] Nettoyage...
if exist ..\dist\logesco-backend.exe del ..\dist\logesco-backend.exe
if exist ..\dist\node_modules rmdir /s /q ..\dist\node_modules

echo.
echo [2/5] Installation des dependances...
call npm install

echo.
echo [3/5] Generation du client Prisma...
call npx prisma generate

echo.
echo [4/5] Construction de l'executable...
call node build-standalone-v2.js

echo.
echo [5/5] Verification...
if exist ..\dist\logesco-backend.exe (
    if exist ..\dist\node_modules\@prisma\client (
        if exist ..\dist\node_modules\.prisma\client (
            echo.
            echo ========================================
            echo ✓ Build reussi!
            echo ========================================
            echo.
            echo Fichiers generes dans: dist\
            echo - logesco-backend.exe
            echo - node_modules\@prisma\client
            echo - node_modules\.prisma\client
            echo.
            echo Vous pouvez maintenant copier le dossier dist\ pour la distribution.
        ) else (
            echo ❌ Erreur: .prisma/client manquant
        )
    ) else (
        echo ❌ Erreur: @prisma/client manquant
    )
) else (
    echo ❌ Erreur: executable non cree
)

cd ..
pause
