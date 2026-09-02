# Guide de Migration : Colonnes NUI et RCCM

## Problème

Après une mise à jour chez un client, les colonnes **nui** et **rccm** n'ont pas été créées dans la table `clients`, empêchant la saisie de ces informations.

## Solution

Plusieurs scripts sont disponibles selon votre situation.

---

## Option 1 : Backend de développement (LOCAL)

Utilisez ce script si vous testez sur votre machine de développement :

```batch
AJOUTER-COLONNES-NUI-RCCM.bat
```

**Ce script :**
1. ✅ Vérifie la présence du backend
2. ✅ Arrête les processus Node.js
3. ✅ Exécute la migration SQL
4. ✅ Confirme l'ajout des colonnes

**Prérequis :**
- Le projet doit être dans le répertoire courant
- La base de données doit exister dans `backend/database/logesco.db`

---

## Option 2 : Chez un CLIENT (Backend embarqué)

Utilisez ce script pour corriger l'installation chez un client :

```batch
AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat
```

**Ce script :**
1. ✅ Localise le backend embarqué dans `%LOCALAPPDATA%\LOGESCO\`
2. ✅ Vérifie la base de données
3. ✅ Copie le script de migration
4. ✅ Arrête l'application et le backend
5. ✅ Exécute la migration
6. ✅ Nettoie les fichiers temporaires

**Emplacement du backend embarqué :**
```
C:\Users\[NomUtilisateur]\AppData\Local\LOGESCO\backend\
└── database\
    └── logesco.db
```

---

## Option 3 : Migration manuelle (SQL)

Si les scripts ne fonctionnent pas, vous pouvez exécuter manuellement les commandes SQL :

### Étape 1 : Ouvrir la base de données SQLite

Utilisez un outil comme **DB Browser for SQLite** ou **sqlite3.exe** :

```bash
sqlite3 "%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db"
```

### Étape 2 : Exécuter les commandes SQL

```sql
-- Ajouter la colonne nui
ALTER TABLE clients ADD COLUMN nui TEXT;

-- Ajouter la colonne rccm
ALTER TABLE clients ADD COLUMN rccm TEXT;

-- Vérifier les colonnes
PRAGMA table_info(clients);
```

### Étape 3 : Quitter et redémarrer

```sql
.quit
```

Puis redémarrez l'application.

---

## Vérification après migration

### 1. Vérifier dans la base de données

```javascript
// Script de vérification (Node.js)
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verifyColumns() {
  const tableInfo = await prisma.$queryRawUnsafe(`
    PRAGMA table_info(clients);
  `);
  
  const hasNui = tableInfo.some(col => col.name === 'nui');
  const hasRccm = tableInfo.some(col => col.name === 'rccm');
  
  console.log(`nui:  ${hasNui ? '✅' : '❌'}`);
  console.log(`rccm: ${hasRccm ? '✅' : '❌'}`);
  
  await prisma.$disconnect();
}

verifyColumns();
```

### 2. Vérifier dans l'application Flutter

1. Ouvrir le module **Clients**
2. Créer ou éditer un client
3. Les champs **NUI** et **RCCM** doivent être visibles dans le formulaire

### 3. Tester la sauvegarde

1. Remplir les champs NUI et RCCM
2. Enregistrer le client
3. Fermer et réouvrir la fiche client
4. Vérifier que les valeurs sont conservées

---

## Résolution des problèmes

### Erreur : "Script de migration non trouvé"

**Cause** : Le fichier `backend/fix-clients-nui-rccm-sqlite.js` est manquant

**Solution** :
1. Vérifiez que vous êtes dans le bon répertoire
2. Assurez-vous que le fichier existe dans `backend/`
3. Téléchargez le projet complet depuis le dépôt

### Erreur : "Base de données non trouvée"

**Cause** : Le fichier `logesco.db` n'existe pas

**Solution** :
1. Vérifiez l'emplacement : `backend/database/logesco.db`
2. Pour le backend embarqué : `%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db`
3. Si absent, lancez l'application une fois pour créer la base

### Erreur : "duplicate column name: nui"

**Cause** : Les colonnes existent déjà

**Solution** : Aucune action nécessaire, la migration a déjà été appliquée

### L'application ne démarre pas après migration

**Cause** : Le backend rencontre une erreur

**Solution** :
1. Vérifiez les logs du backend
2. Essayez de restaurer la sauvegarde :
   ```batch
   copy /Y logesco.db.backup logesco.db
   ```
3. Contactez le support technique

---

## Sauvegardes

Avant chaque migration, créez une sauvegarde :

```batch
REM Backend de développement
copy backend\database\logesco.db backend\database\logesco.db.backup

REM Backend embarqué
copy "%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db" "%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db.backup"
```

---

## Déploiement dans les futures mises à jour

Pour éviter ce problème à l'avenir, incluez la migration dans le processus de build :

### 1. Ajouter au script de démarrage du backend

Dans `backend/src/server.js`, ajouter au démarrage :

```javascript
// Exécuter les migrations automatiquement au démarrage
async function runMigrations() {
  try {
    // Vérifier et ajouter les colonnes si nécessaire
    const tableInfo = await prisma.$queryRawUnsafe(`
      PRAGMA table_info(clients);
    `);
    
    const hasNui = tableInfo.some(col => col.name === 'nui');
    const hasRccm = tableInfo.some(col => col.name === 'rccm');
    
    if (!hasNui) {
      await prisma.$executeRawUnsafe(`ALTER TABLE clients ADD COLUMN nui TEXT;`);
      console.log('✅ Colonne nui ajoutée');
    }
    
    if (!hasRccm) {
      await prisma.$executeRawUnsafe(`ALTER TABLE clients ADD COLUMN rccm TEXT;`);
      console.log('✅ Colonne rccm ajoutée');
    }
  } catch (error) {
    console.error('⚠️ Erreur lors des migrations:', error.message);
  }
}

// Appeler avant de démarrer le serveur
await runMigrations();
```

### 2. Tester la migration automatique

```batch
# Supprimer les colonnes pour tester
sqlite3 backend\database\logesco.db "ALTER TABLE clients DROP COLUMN nui;"
sqlite3 backend\database\logesco.db "ALTER TABLE clients DROP COLUMN rccm;"

# Redémarrer le backend (devrait recréer les colonnes)
cd backend
node src\server.js
```

---

## Fichiers créés

1. **backend/fix-clients-nui-rccm-sqlite.js** - Script de migration Node.js
2. **AJOUTER-COLONNES-NUI-RCCM.bat** - Migration locale (développement)
3. **AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat** - Migration chez le client (production)
4. **GUIDE_MIGRATION_NUI_RCCM.md** - Ce guide

---

## Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs du backend
2. Consultez ce guide
3. Créez une sauvegarde avant toute manipulation
4. Contactez l'équipe technique avec :
   - Le message d'erreur exact
   - La version de l'application
   - L'emplacement de la base de données
   - Les logs du backend
