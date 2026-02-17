@echo off
echo ========================================
echo Creation d'un nouveau repo Git propre
echo ========================================

REM Sauvegarder le dossier .git actuel
echo Sauvegarde de l'ancien .git...
if exist .git_backup rmdir /s /q .git_backup
move .git .git_backup

REM Initialiser un nouveau repo
echo Initialisation d'un nouveau repo Git...
git init

REM Ajouter tous les fichiers (le .gitignore filtrera automatiquement)
echo Ajout des fichiers (filtres par .gitignore)...
git add .

REM Premier commit
echo Creation du commit initial...
git commit -m "Initial commit - Logesco V2 (repo propre sans historique)"

REM Configurer la branche main
echo Configuration de la branche main...
git branch -M main

REM Ajouter le remote
echo Ajout du remote GitHub...
git remote add origin https://github.com/fotsara-startech/logesco_v2_bon.git

REM Pousser vers GitHub
echo Push vers GitHub (force push car nouveau repo)...
git push -u origin main --force

echo.
echo ========================================
echo Termine! Verifiez sur GitHub.
echo ========================================
pause
