# Guide de Résolution - Problème de Démarrage Automatique du Backend

## Problème Identifié

Le backend ne démarre pas automatiquement au lancement de l'application LOGESCO, mais fonctionne correctement lorsqu'il est démarré manuellement depuis `%LOCALAPPDATA%\LOGESCO\backend`.

## Causes Possibles

1. **Client Prisma non généré** - Le client ORM Prisma n'a pas été généré après l'installation
2. **Base de données absente ou corrompue** - La base SQLite n'existe pas ou est invalide
3. **Variables d'environnement incorrectes** - Les chemins dans `.env` sont mal configurés
4. **Permissions insuffisantes** - Windows bloque l'exécution des scripts VBS
5. **Node.js introuvable** - Le runtime Node.js portable ou système n'est pas accessible

## Solutions

### Solution 1: Script de Correction Automatique (RECOMMANDÉ)

Exécutez le script de correction qui diagnostique et corrige automatiquement les problèmes :

```batch
fix-backend-startup.bat
```

Ce script va :
- Vérifier l'installation de Node.js
- Générer le client Prisma s'il est manquant
- Créer/corriger la base de données
- Recréer le fichier `.env` avec les bons chemins
- Tester le démarrage du backend
- Afficher les logs en cas d'erreur

### Solution 2: Diagnostic Manuel

Si le script de correction ne résout pas le problème, utilisez le script de diagnostic :

```batch
diagnose-backend-startup.bat
```

Ce script va :
- Vérifier chaque composant individuellement
- Afficher des informations détaillées sur la configuration
- Tester le démarrage manuel
- Afficher les logs de démarrage
- Indiquer précisément quel composant pose problème

### Solution 3: Correction Manuelle Étape par Étape

Si vous préférez corriger manuellement :

#### Étape 1 : Ouvrir le répertoire backend
```batch
cd %LOCALAPPDATA%\LOGESCO\backend
```

#### Étape 2 : Arrêter tous les processus Node.js
```batch
taskkill /F /IM node.exe
```

#### Étape 3 : Générer le client Prisma
```batch
node node_modules\prisma\build\index.js generate
```

#### Étape 4 : Vérifier la base de données
```batch
dir database\logesco.db
```

Si le fichier n'existe pas et qu'un template existe :
```batch
copy database\logesco_template.db database\logesco.db
```

#### Étape 5 : Corriger le fichier .env
Éditez le fichier `.env` et assurez-vous qu'il contient :
```env
NODE_ENV=production
PORT=8080
DATABASE_URL=file:C:/Users/[VOTRE_USER]/AppData/Local/LOGESCO/backend/database/logesco.db
JWT_SECRET=logesco-secret-[RANDOM]
JWT_EXPIRES_IN=365d
CORS_ORIGIN=*
LOG_LEVEL=info
LOGESCO_DATA_DIR=C:\Users\[VOTRE_USER]\AppData\Local\LOGESCO\backend
```

**Important** : Remplacez `[VOTRE_USER]` par votre nom d'utilisateur Windows et utilisez des slashes `/` dans `DATABASE_URL`.

#### Étape 6 : Tester le démarrage manuel
```batch
node src\server.js
```

Attendez 10 secondes puis testez :
```batch
curl http://localhost:8080/health
```

Vous devriez voir : `{"status":"ok", ...}`

## Améliorations Apportées au Code

Le service backend Flutter a été amélioré avec :

1. **Logging détaillé** - Chaque étape du démarrage est maintenant loguée
2. **Vérification du client Prisma** - Le service vérifie et génère automatiquement le client Prisma si nécessaire
3. **Création automatique des dossiers** - Les dossiers `database/` et `logs/` sont créés automatiquement
4. **Lecture des logs en cas d'erreur** - Si le backend ne démarre pas, les logs sont affichés automatiquement
5. **Gestion améliorée du fichier .env** - Le fichier est recréé à chaque démarrage avec les bons chemins absolus
6. **Copie du template de base** - Le template de base de données est copié automatiquement

## Vérification Post-Correction

Après avoir appliqué une correction, vérifiez que :

1. ✅ Le fichier `node_modules\.prisma\client\index.js` existe
2. ✅ Le fichier `database\logesco.db` existe et n'est pas vide
3. ✅ Le fichier `.env` contient des chemins absolus valides
4. ✅ Le backend répond à `http://localhost:8080/health`
5. ✅ L'application Flutter démarre et se connecte au backend

## Fichiers de Log

En cas de problème, consultez les logs :
- **Backend** : `%LOCALAPPDATA%\LOGESCO\backend\logs\backend-startup.log`
- **Flutter** : Visible dans la console de développement

## Support Supplémentaire

Si le problème persiste après avoir appliqué toutes les solutions :

1. Exécutez `diagnose-backend-startup.bat` et partagez la sortie complète
2. Partagez le contenu de `backend\logs\backend-startup.log`
3. Vérifiez les permissions Windows sur le dossier `%LOCALAPPDATA%\LOGESCO`
4. Vérifiez que l'antivirus ne bloque pas l'exécution de scripts VBS
5. Essayez d'exécuter l'application en tant qu'administrateur (temporairement pour tester)

## Notes Techniques

### Pourquoi le démarrage automatique peut échouer ?

Le backend est démarré via un script VBS pour éviter l'apparition d'une fenêtre console noire. Le processus est :

```
Flutter App
  └─> wscript.exe _logesco_start.vbs
       └─> cmd.exe _logesco_start.cmd
            └─> node.exe src\server.js
```

Si l'un de ces éléments échoue (VBS bloqué, variables d'env manquantes, Prisma non généré), le backend ne démarre pas mais aucune erreur n'est visible.

### Pourquoi ça marche manuellement ?

Quand vous démarrez manuellement depuis `AppData`, vous exécutez probablement :
```batch
node src\server.js
```

Dans ce cas, le terminal hérite des variables d'environnement de votre session Windows, et Node.js trouve automatiquement les modules. Mais quand c'est lancé via VBS en mode détaché, ces variables ne sont pas héritées - d'où l'importance du fichier `.env` et des scripts CMD/VBS corrects.

## Checklist de Vérification Rapide

- [ ] Node.js est installé (portable ou système)
- [ ] Le dossier `%LOCALAPPDATA%\LOGESCO\backend` existe
- [ ] Le fichier `src\server.js` existe
- [ ] Le dossier `node_modules\.prisma\client` existe
- [ ] Le fichier `database\logesco.db` existe
- [ ] Le fichier `.env` contient des chemins absolus
- [ ] Le port 8080 n'est pas utilisé par une autre application
- [ ] Aucun processus `node.exe` zombie n'est en cours d'exécution

## Prévention Future

Pour éviter ce problème sur de nouvelles installations :

1. Le script d'installation devrait générer le client Prisma
2. Le script d'installation devrait créer la base de données initiale
3. Le script d'installation devrait tester le démarrage du backend
4. Le fichier `.env` devrait être créé avec des chemins absolus dès l'installation
