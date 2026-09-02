# Solution: Prisma avec pkg (Exécutable Windows)

## Problème

L'erreur `Cannot find module 'C:\snapshot\backend\node_modules\.prisma\client\index.js'` se produit car:

1. **pkg** bundle le code dans un snapshot virtuel (`C:\snapshot\`)
2. **Prisma** génère du code natif (`.node`) qui ne peut pas être bundlé
3. Prisma doit être chargé depuis le système de fichiers, pas depuis le snapshot

## Solution Implémentée

### 1. Chargeur Prisma Dynamique

Créé `backend/src/config/prisma-loader.js` qui:
- Détecte si l'app tourne en mode pkg
- Charge Prisma depuis le dossier `node_modules` à côté de l'exe
- Utilise le chargement normal en développement

### 2. Mise à Jour du Build

Le script `backend/build-standalone-v2.js` maintenant:
- Compile l'exe SANS inclure Prisma dans le snapshot
- Copie `node_modules/@prisma/client` à côté de l'exe
- Copie `node_modules/.prisma/client` (client généré)
- Copie le schéma Prisma

### 3. Structure de Distribution

```
dist/
├── logesco-backend.exe          # Exécutable
├── node_modules/
│   ├── @prisma/
│   │   └── client/              # Client Prisma (REQUIS)
│   └── .prisma/
│       └── client/              # Client généré (REQUIS)
├── prisma/
│   └── schema.prisma            # Schéma DB
├── .env.example
└── README.txt
```

### 4. Données Utilisateur

Les données sont stockées dans `%LOCALAPPDATA%\LOGESCO\backend\`:
- `database/` - Base SQLite
- `logs/` - Fichiers de logs
- `uploads/` - Fichiers uploadés
- `.env` - Configuration

## Reconstruction du Backend

### Étape 1: Nettoyer et Reconstruire

```batch
rebuild-backend-production.bat
```

Ce script:
1. Nettoie les anciens builds
2. Installe les dépendances
3. Génère le client Prisma
4. Compile l'exécutable
5. Copie les fichiers Prisma nécessaires

### Étape 2: Vérifier le Build

Vérifiez que ces fichiers existent dans `dist/`:
- ✓ `logesco-backend.exe`
- ✓ `node_modules/@prisma/client/`
- ✓ `node_modules/.prisma/client/`
- ✓ `prisma/schema.prisma`

### Étape 3: Tester Localement

```batch
cd dist
logesco-backend.exe
```

Le serveur devrait démarrer sur `http://localhost:8080`

## Distribution

### Pour Distribuer l'Application

Copiez **TOUT** le dossier `dist/` vers la machine cible:

```
dist/
├── logesco-backend.exe
├── node_modules/          ← IMPORTANT: Ne pas supprimer!
├── prisma/
├── .env.example
└── README.txt
```

### Installation sur Machine Cible

1. Copier le dossier `dist/` complet
2. Double-cliquer sur `logesco-backend.exe`
3. Le serveur crée automatiquement:
   - La base de données dans `%LOCALAPPDATA%\LOGESCO\backend\database\`
   - Les logs dans `%LOCALAPPDATA%\LOGESCO\backend\logs\`
   - Le fichier `.env` dans `%LOCALAPPDATA%\LOGESCO\backend\`

## Démarrage Automatique (Optionnel)

### Option 1: Raccourci dans le Dossier de Démarrage

1. Créer un raccourci vers `logesco-backend.exe`
2. Copier le raccourci dans:
   ```
   %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
   ```

### Option 2: Service Windows avec NSSM

```batch
# Télécharger NSSM: https://nssm.cc/download
nssm install LOGESCO-Backend "C:\chemin\vers\dist\logesco-backend.exe"
nssm set LOGESCO-Backend Start SERVICE_AUTO_START
nssm start LOGESCO-Backend
```

### Option 3: Tâche Planifiée

1. Ouvrir le Planificateur de tâches
2. Créer une tâche de base
3. Déclencheur: Au démarrage
4. Action: Démarrer `logesco-backend.exe`
5. Cocher "Exécuter même si l'utilisateur n'est pas connecté"

## Dépannage

### Erreur: "Cannot find module '@prisma/client'"

**Cause**: Le dossier `node_modules` est manquant ou incomplet

**Solution**:
1. Vérifier que `dist/node_modules/@prisma/client/` existe
2. Vérifier que `dist/node_modules/.prisma/client/` existe
3. Reconstruire avec `rebuild-backend-production.bat`

### Erreur: "Prisma Client introuvable"

**Cause**: Les fichiers Prisma n'ont pas été copiés correctement

**Solution**:
```batch
cd backend
npx prisma generate
node build-standalone-v2.js
```

### Le serveur ne démarre pas automatiquement

**Cause**: Pas de mécanisme de démarrage automatique configuré

**Solution**: Configurer une des options de démarrage automatique ci-dessus

### Erreur de permissions sur la base de données

**Cause**: Permissions insuffisantes dans `%LOCALAPPDATA%`

**Solution**:
1. Vérifier les permissions du dossier
2. Exécuter en tant qu'administrateur (première fois seulement)

## Vérification Post-Installation

### Test Manuel

```batch
# Démarrer le backend
cd dist
logesco-backend.exe

# Dans un autre terminal, tester l'API
curl http://localhost:8080/api/v1/health
```

### Vérifier les Logs

```
%LOCALAPPDATA%\LOGESCO\backend\logs\app.log
```

### Vérifier la Base de Données

```
%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db
```

## Notes Importantes

1. **Ne jamais supprimer** le dossier `node_modules` dans `dist/`
2. Les données utilisateur sont dans `%LOCALAPPDATA%\LOGESCO\backend\`
3. Chaque utilisateur Windows a sa propre base de données
4. Pour partager la DB entre utilisateurs, modifier `DATABASE_URL` dans `.env`

## Prochaines Étapes

1. Reconstruire le backend: `rebuild-backend-production.bat`
2. Tester localement
3. Configurer le démarrage automatique
4. Distribuer le dossier `dist/` complet
