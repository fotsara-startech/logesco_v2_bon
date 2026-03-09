@echo off
title LOGESCO - Reinitialisation Base de Donnees Client
color 0C
echo ========================================
echo   LOGESCO - REINITIALISATION BASE
echo   Version Client Production
echo ========================================
echo.
echo ⚠️  ATTENTION CRITIQUE:
echo.
echo Cette operation va SUPPRIMER DEFINITIVEMENT:
echo ============================================
echo ❌ TOUS vos produits
echo ❌ TOUTES vos ventes
echo ❌ TOUS vos clients
echo ❌ TOUS vos fournisseurs
echo ❌ TOUTES vos transactions
echo ❌ TOUS vos mouvements de stock
echo ❌ TOUS vos utilisateurs personnalises
echo ❌ TOUTES vos sessions de caisse
echo ❌ TOUT votre historique
echo.
echo ✅ La base sera reinitialisee avec:
echo    - 1 utilisateur admin (admin/admin123)
echo    - 1 caisse principale (solde 0)
echo    - Parametres entreprise par defaut
echo.
echo 💾 Une sauvegarde sera creee automatiquement
echo    dans: backend\database\backups\
echo.
echo ========================================
echo.
echo Tapez exactement: REINITIALISER
echo (en majuscules, sans faute)
echo.
set /p confirm="Votre reponse: "
if not "%confirm%"=="REINITIALISER" (
    echo.
    echo ❌ Operation annulee
    echo    Aucune modification effectuee
    echo    Vos donnees sont intactes
    pause
    exit /b 0
)

echo.
echo ========================================
echo   Confirmation finale
echo ========================================
echo.
echo Etes-vous ABSOLUMENT SUR?
echo Cette action est IRREVERSIBLE!
echo.
set /p confirm2="Tapez OUI pour continuer: "
if not "%confirm2%"=="OUI" (
    echo.
    echo ❌ Operation annulee
    echo    Aucune modification effectuee
    pause
    exit /b 0
)

echo.
color 0E
echo ========================================
echo   Reinitialisation en cours...
echo ========================================
echo.

REM Vérifier si Node.js est installé
echo [1/7] Verification prerequis...
where node >nul 2>nul
if errorlevel 1 (
    color 0C
    echo ❌ ERREUR: Node.js n'est pas installe!
    echo.
    echo Installez Node.js depuis: https://nodejs.org/
    echo Version recommandee: 18 LTS ou superieure
    pause
    exit /b 1
)
echo ✅ Node.js detecte
node --version
echo.

REM Vérifier que nous sommes dans le bon dossier
echo [2/7] Verification emplacement...
if not exist "backend\database" (
    if not exist "database" (
        color 0C
        echo ❌ ERREUR: Dossier backend\database non trouve!
        echo.
        echo Assurez-vous d'executer ce script depuis:
        echo - Le dossier racine de LOGESCO, OU
        echo - Le dossier backend de LOGESCO
        pause
        exit /b 1
    )
    REM Nous sommes dans le dossier backend
    set backend_path=.
) else (
    REM Nous sommes dans le dossier racine
    set backend_path=backend
)
echo ✅ Emplacement correct
echo.

REM Arrêter tous les processus LOGESCO
echo [3/7] Arret de LOGESCO...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im logesco_v2.exe >nul 2>nul
echo ✅ Processus arretes
echo    Attente fermeture complete...
timeout /t 3 /nobreak >nul
echo.

REM Créer le dossier de sauvegarde
echo [4/7] Preparation sauvegarde...
if not exist "%backend_path%\database\backups" mkdir "%backend_path%\database\backups"

REM Sauvegarder l'ancienne base avec timestamp
if exist "%backend_path%\database\logesco.db" (
    set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set timestamp=%timestamp: =0%
    
    echo    Sauvegarde en cours...
    copy "%backend_path%\database\logesco.db" "%backend_path%\database\backups\logesco_backup_%timestamp%.db" >nul 2>nul
    
    if exist "%backend_path%\database\backups\logesco_backup_%timestamp%.db" (
        echo ✅ Sauvegarde creee avec succes
        echo    Fichier: logesco_backup_%timestamp%.db
        echo    Emplacement: %backend_path%\database\backups\
        
        REM Calculer la taille du fichier
        for %%A in ("%backend_path%\database\logesco.db") do (
            set size=%%~zA
            set /a size_kb=!size! / 1024
            echo    Taille: !size_kb! KB
        )
    ) else (
        color 0C
        echo ⚠️  ATTENTION: Sauvegarde echouee!
        echo.
        set /p continue="Continuer quand meme? (OUI/NON): "
        if not "!continue!"=="OUI" (
            echo ❌ Operation annulee
            pause
            exit /b 1
        )
    )
) else (
    echo ⚠️  Aucune base existante a sauvegarder
)
echo.

REM Supprimer l'ancienne base et fichiers temporaires
echo [5/7] Suppression ancienne base...
if exist "%backend_path%\database\logesco.db" (
    del /f /q "%backend_path%\database\logesco.db" 2>nul
    echo    ✅ Base principale supprimee
)
if exist "%backend_path%\database\logesco.db-journal" (
    del /f /q "%backend_path%\database\logesco.db-journal" 2>nul
    echo    ✅ Journal supprime
)
if exist "%backend_path%\database\logesco.db-shm" (
    del /f /q "%backend_path%\database\logesco.db-shm" 2>nul
    echo    ✅ Shared memory supprime
)
if exist "%backend_path%\database\logesco.db-wal" (
    del /f /q "%backend_path%\database\logesco.db-wal" 2>nul
    echo    ✅ Write-ahead log supprime
)

REM Attendre un peu pour s'assurer que les fichiers sont bien supprimés
timeout /t 2 /nobreak >nul

REM Vérifier que la base est bien supprimée
if exist "%backend_path%\database\logesco.db" (
    color 0C
    echo    ❌ ERREUR: Impossible de supprimer la base
    echo    La base est peut-etre utilisee par un autre processus
    echo.
    echo    Fermez tous les programmes qui utilisent la base et reessayez
    pause
    exit /b 1
)

echo ✅ Suppression complete
echo.

REM Créer la nouvelle base vierge
echo [6/7] Creation nouvelle base VIERGE...
cd %backend_path%

REM Vérifier Prisma Client
if not exist "node_modules\.prisma\client" (
    echo    ⚠️  Prisma Client non trouve
    echo    Generation en cours...
    call npx prisma generate
    if errorlevel 1 (
        color 0C
        echo    ❌ ERREUR: Generation Prisma echouee
        cd ..
        pause
        exit /b 1
    )
    echo    ✅ Prisma Client genere
)

REM Créer la structure de la base
echo    Recreation COMPLETE structure base de donnees...
echo    (Suppression et recreation totale)

REM S'assurer que le .env pointe vers la bonne base
echo    Verification configuration .env...
if exist ".env" (
    findstr /C:"file:./database/logesco.db" .env >nul
    if errorlevel 1 (
        echo    ⚠️  DATABASE_URL incorrect dans .env
        echo    Correction en cours...
        
        REM Créer un nouveau .env avec le bon chemin
        (
            echo NODE_ENV=production
            echo PORT=8080
            echo DATABASE_URL="file:./database/logesco.db"
            echo JWT_SECRET=logesco_production_secret_key
            echo JWT_EXPIRES_IN=24h
            echo CORS_ORIGIN=*
        ) > .env
        echo    ✅ .env corrige
    ) else (
        echo    ✅ .env correct
    )
) else (
    echo    ⚠️  .env non trouve, creation...
    (
        echo NODE_ENV=production
        echo PORT=8080
        echo DATABASE_URL="file:./database/logesco.db"
        echo JWT_SECRET=logesco_production_secret_key
        echo JWT_EXPIRES_IN=24h
        echo CORS_ORIGIN=*
    ) > .env
    echo    ✅ .env cree
)

REM Utiliser --force-reset pour supprimer et recréer complètement
call npx prisma db push --force-reset --accept-data-loss --skip-generate
if errorlevel 1 (
    color 0C
    echo    ❌ ERREUR: Creation structure echouee
    cd ..
    pause
    exit /b 1
)
echo    ✅ Structure creee

REM Initialiser avec les données essentielles
echo    Initialisation donnees essentielles...
echo    (Suppression toutes donnees + creation base vierge)
echo.
node prisma\seed.js
if errorlevel 1 (
    color 0C
    echo.
    echo    ❌ ERREUR: Initialisation donnees echouee
    cd ..
    pause
    exit /b 1
)

REM Attendre que Prisma ferme toutes les connexions
echo.
echo    Attente fermeture connexions Prisma...
timeout /t 3 /nobreak >nul

REM Nous sommes toujours dans le dossier backend ici
echo.

REM Vérifier la nouvelle base
echo [7/7] Verification nouvelle base...

REM Afficher le chemin de la base pour debug
echo.
echo    Verification du chemin de la base...
echo    Chemin attendu: database\logesco.db
if exist "database\logesco.db" (
    echo    ✅ Base trouvee: database\logesco.db
    for %%A in ("database\logesco.db") do echo    Taille: %%~zA octets
) else (
    echo    ❌ Base non trouvee dans database\logesco.db
)

REM Vérifier aussi d'autres emplacements possibles
if exist "..\database\logesco.db" (
    echo    ⚠️  Base trouvee dans ..\database\logesco.db
)
if exist "logesco.db" (
    echo    ⚠️  Base trouvee dans logesco.db (racine backend)
)

REM Afficher le contenu du .env pour debug
echo.
echo    Configuration DATABASE_URL:
if exist ".env" (
    findstr /C:"DATABASE_URL" .env
) else (
    echo    ⚠️  Fichier .env non trouve
)
echo.

REM Créer un script de vérification temporaire (nous sommes déjà dans backend)
(
echo const { PrismaClient } = require('@prisma/client'^);
echo const fs = require('fs'^);
echo const path = require('path'^);
echo.
echo // Afficher le chemin de la base utilisé
echo console.log('   Chemin base utilise par Prisma:'^);
echo const dbPath = process.env.DATABASE_URL ^|^| 'file:./database/logesco.db';
echo console.log('   ', dbPath^);
echo.
echo // Vérifier si le fichier existe
echo const dbFile = dbPath.replace('file:', ''^);
echo if (fs.existsSync(dbFile^)^) {
echo   const stats = fs.statSync(dbFile^);
echo   console.log('   Taille fichier:', stats.size, 'octets\n'^);
echo } else {
echo   console.log('   ⚠️  Fichier non trouve!\n'^);
echo }
echo.
echo // Forcer la reconnexion avec le bon chemin
echo const prisma = new PrismaClient({
echo   datasources: {
echo     db: {
echo       url: 'file:./database/logesco.db'
echo     }
echo   }
echo }^);
echo.
echo async function verify(^) {
echo   try {
echo     // Attendre un peu pour s'assurer que la base est bien fermée
echo     await new Promise(resolve =^> setTimeout(resolve, 1000^)^);
echo.
echo     const users = await prisma.utilisateur.count(^);
echo     const products = await prisma.produit.count(^);
echo     const sales = await prisma.vente.count(^);
echo     const customers = await prisma.client.count(^);
echo     const suppliers = await prisma.fournisseur.count(^);
echo     const cashRegisters = await prisma.cashRegister.count(^);
echo     const company = await prisma.parametresEntreprise.findFirst(^);
echo.
echo     console.log('   Utilisateurs:', users^);
echo     console.log('   Produits:', products^);
echo     console.log('   Ventes:', sales^);
echo     console.log('   Clients:', customers^);
echo     console.log('   Fournisseurs:', suppliers^);
echo     console.log('   Caisses:', cashRegisters^);
echo     console.log('   Entreprise:', company ? company.nomEntreprise : 'Non trouvee'^);
echo.
echo     if (users === 1 ^&^& products === 0 ^&^& sales === 0 ^&^& customers === 0 ^&^& suppliers === 0 ^&^& cashRegisters === 1 ^&^& company^) {
echo       console.log('\n   ✅ BASE VIERGE CONFIRMEE - TOUT EST OK'^);
echo       process.exit(0^);
echo     } else {
echo       console.log('\n   ⚠️  ATTENTION: Donnees inattendues detectees'^);
echo       console.log('   La base lue ne correspond pas a la base creee!'^);
echo       console.log('   Verifiez le fichier .env et DATABASE_URL'^);
echo       process.exit(1^);
echo     }
echo   } catch (error^) {
echo     console.error('   ❌ Erreur verification:', error.message^);
echo     process.exit(1^);
echo   } finally {
echo     await prisma.$disconnect(^);
echo   }
echo }
echo.
echo verify(^);
) > temp_verify_client.js

REM Exécuter la vérification (nous sommes déjà dans backend)
node temp_verify_client.js
set verify_result=%errorlevel%

REM Nettoyer le fichier temporaire
del temp_verify_client.js 2>nul

REM Retourner au dossier racine si nécessaire
if "%backend_path%"=="backend" cd ..

echo.

if %verify_result% neq 0 (
    color 0C
    echo ⚠️  La verification a detecte un probleme
    echo    La base a ete creee mais contient des donnees inattendues
    echo.
    echo Vous pouvez:
    echo 1. Reexecuter ce script
    echo 2. Restaurer la sauvegarde depuis backups\
    echo 3. Contacter le support
    pause
    exit /b 1
)

color 0A
echo ========================================
echo   ✅ REINITIALISATION REUSSIE!
echo ========================================
echo.
echo 🎯 Base de donnees VIERGE creee avec:
echo    ✅ 1 utilisateur admin
echo    ✅ 1 caisse principale (solde: 0)
echo    ✅ Parametres entreprise par defaut
echo.
echo 🔑 Identifiants de connexion:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo 💾 Sauvegarde ancienne base:
echo    Emplacement: %backend_path%\database\backups\
echo    Fichier: logesco_backup_%timestamp%.db
echo.
echo 🚀 PROCHAINES ETAPES IMPORTANTES:
echo ========================================
echo 1. Demarrez LOGESCO (DEMARRER-LOGESCO.bat)
echo 2. Connectez-vous avec: admin / admin123
echo 3. Allez dans Parametres ^> Entreprise
echo 4. Personnalisez les informations entreprise
echo 5. Allez dans Parametres ^> Utilisateurs
echo 6. Changez le mot de passe admin
echo 7. Creez vos utilisateurs
echo 8. Ajoutez vos produits
echo 9. Configurez vos caisses si necessaire
echo.
echo ⚠️  SECURITE - A FAIRE IMMEDIATEMENT:
echo ========================================
echo 🔒 Changez le mot de passe admin!
echo 🏢 Personnalisez les infos entreprise!
echo 👥 Creez vos utilisateurs avec roles appropries!
echo.
echo 💡 CONSEIL:
echo    Si vous avez besoin de restaurer l'ancienne base,
echo    copiez le fichier depuis backups\ vers database\
echo    et renommez-le en logesco.db
echo.
echo ========================================
color 0F
pause
