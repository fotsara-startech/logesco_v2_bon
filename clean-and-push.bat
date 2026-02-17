@echo off
echo Nettoyage du repo Git pour push vers GitHub...

REM Supprimer les fichiers volumineux du cache Git
echo Suppression des fichiers volumineux de l'historique Git...
git rm -r --cached Package-Mise-A-Jour-Client 2>nul
git rm -r --cached dist-portable 2>nul
git rm -r --cached backend/node_modules 2>nul
git rm -r --cached logesco_v2/node_modules 2>nul
git rm --cached backend/prisma/database/logesco.db 2>nul
git rm --cached dist-portable/prisma/database/logesco.db 2>nul
git rm --cached logesco_v2/assets/VC_redist.x64.exe 2>nul
git rm --cached Package-Mise-A-Jour-Client.zip 2>nul

echo.
echo Ajout des modifications...
git add .gitignore

echo.
echo Commit des changements...
git commit -m "Nettoyage: suppression des fichiers volumineux et mise à jour .gitignore"

echo.
echo Push vers GitHub (peut prendre du temps)...
git push -u origin main --force

echo.
echo Terminé!
pause
