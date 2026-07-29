# Guide Rapide - Ajout de Colonnes avec Migration Automatique

## 🎯 Objectif
Garantir que toutes les nouvelles colonnes sont automatiquement ajoutées au backend embarqué sans intervention manuelle.

## 📝 Processus en 3 étapes

### Étape 1 : Modifier le schéma Prisma

```prisma
// backend/prisma/schema.prisma

model MaTable {
  id               Int      @id @default(autoincrement())
  // ... colonnes existantes
  
  nouvelleColonne  String?  @map("nouvelle_colonne")  // ⭐ AJOUT
  dateModification DateTime @map("date_modification")  // ⭐ AJOUT
  
  @@map("ma_table")
}
```

### Étape 2 : Ajouter au validateur de schéma

```javascript
// backend/src/utils/schema-validator.js

getRequiredSchema() {
  return {
    // Tables existantes...
    
    ma_table: [  // ⭐ AJOUT ou MODIFICATION
      { name: 'nouvelle_colonne', type: 'TEXT', nullable: true },
      { name: 'date_modification', type: 'DATETIME', nullable: true }
    ]
  };
}
```

### Étape 3 : Tester

```bash
# Test local
npm start

# Vérifier les logs
cat backend/logs/backend-startup.log | grep "Schéma"

# Résultat attendu :
# ✅ Schéma de base de données valide
```

## 📋 Types de colonnes courants

| Type Prisma | Type SQLite | Nullable | Exemple |
|-------------|-------------|----------|---------|
| `String` | `TEXT` | Oui/Non | `{ name: 'nom', type: 'TEXT', nullable: false }` |
| `String?` | `TEXT` | Oui | `{ name: 'description', type: 'TEXT', nullable: true }` |
| `Int` | `INTEGER` | Non | `{ name: 'quantite', type: 'INTEGER', nullable: false }` |
| `Float` | `REAL` | Non | `{ name: 'prix', type: 'REAL', nullable: false }` |
| `Boolean` | `BOOLEAN` | Non | `{ name: 'actif', type: 'BOOLEAN', nullable: false }` |
| `DateTime` | `DATETIME` | Non | `{ name: 'created_at', type: 'DATETIME', nullable: false }` |

## ⚡ Déploiement automatique

### Backend local (développement)
1. Modifier les fichiers
2. Redémarrer : `npm start`
3. ✅ Colonnes ajoutées automatiquement

### Backend embarqué (production)
1. Copier les fichiers modifiés :
```powershell
$embedded = "$env:LOCALAPPDATA\LOGESCO\backend"
Copy-Item backend\src\server.js $embedded\src\
Copy-Item backend\src\utils\schema-validator.js $embedded\src\utils\
```

2. Tuer le processus Node :
```powershell
Get-Process node | Stop-Process -Force
```

3. Relancer l'app Flutter
4. ✅ Backend redémarre et applique les migrations automatiquement

## 🔍 Vérification

### Logs de démarrage
```bash
# Local
tail -f backend/logs/backend-startup.log

# Embarqué
tail -f "$env:LOCALAPPDATA\LOGESCO\backend\logs\backend-startup.log"
```

### Messages attendus

**Succès (pas de changement) :**
```
✅ DB existante — migration prisma ignorée (démarrage rapide)
✅ Schéma de base de données valide
🚀 Serveur LOGESCO API démarré avec succès
```

**Succès (avec corrections) :**
```
✅ DB existante — migration prisma ignorée (démarrage rapide)
🔧 Correction du schéma de base de données...
⚠️  Colonne manquante: ma_table.nouvelle_colonne
✅ Colonne nouvelle_colonne ajoutée à ma_table
📊 Résumé: 1/1 problèmes corrigés
✅ Schéma corrigé avec succès
🚀 Serveur LOGESCO API démarré avec succès
```

## 🚨 Erreurs courantes

### Erreur : "Column X does not exist"

**Cause** : Colonne manquante non détectée par le validateur

**Solution** :
1. Ajouter la colonne dans `schema-validator.js`
2. Redémarrer le backend

### Erreur : Migration ne s'applique pas

**Vérifier** :
```javascript
// Dans server.js, la méthode _validateSchema doit être appelée
async start() {
  await this._runAutoMigration();
  const prisma = await databaseManager.initialize();
  await this._validateSchema(prisma);  // ⭐ Cette ligne doit exister
  await this._runAutoSeed(prisma);
  // ...
}
```

## 📊 Exemple complet

**Scénario** : Ajouter `logo_url` à la table `parametres_entreprise`

### 1. Prisma Schema
```prisma
model ParametresEntreprise {
  id               Int      @id @default(autoincrement())
  nomEntreprise    String   @map("nom_entreprise")
  logoUrl          String?  @map("logo_url")  // ⭐ NOUVEAU
  
  @@map("parametres_entreprise")
}
```

### 2. Schema Validator
```javascript
getRequiredSchema() {
  return {
    // ...autres tables
    
    parametres_entreprise: [
      { name: 'logo_url', type: 'TEXT', nullable: true }  // ⭐ NOUVEAU
    ]
  };
}
```

### 3. Test
```bash
npm start
# Vérifier :
# ✅ Colonne logo_url ajoutée à parametres_entreprise
```

### 4. Déploiement embarqué
```powershell
# Copier les fichiers
$dst = "$env:LOCALAPPDATA\LOGESCO\backend"
Copy-Item backend\src\server.js $dst\src\
Copy-Item backend\src\utils\schema-validator.js $dst\src\utils\

# Redémarrer
Get-Process node | Stop-Process -Force
# Lancer l'app Flutter
```

✅ **Fait !** La colonne sera automatiquement ajoutée au démarrage.

## 💡 Conseils pro

1. **Toujours tester localement d'abord**
   ```bash
   node backend/test-schema-validator.js
   ```

2. **Vérifier les types de données**
   - SQLite est permissif mais préférer les bons types
   - `REAL` pour les prix (pas `INTEGER`)
   - `DATETIME` pour les dates (pas `TEXT`)

3. **Colonnes critiques**
   - Les ajouter aussi dans `quickValidate()` pour détection rapide
   
4. **Backup avant changements majeurs**
   ```bash
   cp "$env:LOCALAPPDATA\LOGESCO\backend\database\logesco.db" logesco-backup.db
   ```

5. **Documentation**
   - Mettre à jour ce fichier quand vous ajoutez des patterns récurrents

## 🎓 Ressources

- Documentation complète : `backend/MIGRATIONS.md`
- Test du validateur : `node backend/test-schema-validator.js`
- Vérification schéma : `node backend/verify-tables-schema.js`
- Logs : `backend/logs/backend-startup.log`
