# Système de Migrations Automatiques - LOGESCO Backend

## Vue d'ensemble

Le backend LOGESCO dispose d'un système de validation et correction automatique du schéma de base de données qui s'exécute à chaque démarrage.

## Comment ça fonctionne

### 1. **Démarrage du serveur** (`server.js`)

Au démarrage, le serveur effectue ces étapes dans l'ordre :

```
1. _runAutoMigration()  → Applique prisma db push (première installation uniquement)
2. initialize()         → Initialise la connexion Prisma
3. _validateSchema()    → Vérifie et corrige le schéma ⭐ NOUVEAU
4. _runAutoSeed()       → Crée les données initiales si DB vide
5. start()              → Démarre le serveur HTTP
```

### 2. **Validation du schéma** (`schema-validator.js`)

Le validateur effectue :

#### **A. Validation rapide (Quick Validate)**
- Vérifie les colonnes critiques des tables principales
- Exécution ultra-rapide (~10ms)
- Si tout est OK, termine immédiatement

#### **B. Validation complète (Full Validate)**
- N'est exécutée QUE si la validation rapide échoue
- Scanne toutes les tables et colonnes définies
- Ajoute automatiquement les colonnes manquantes
- Génère un rapport détaillé

## Ajouter une nouvelle colonne au système

Pour garantir qu'une nouvelle colonne soit toujours présente, modifiez `schema-validator.js` :

```javascript
getRequiredSchema() {
  return {
    // ... tables existantes
    
    ma_nouvelle_table: [
      { name: 'id', type: 'INTEGER', nullable: false },
      { name: 'ma_colonne', type: 'TEXT', nullable: true },
      { name: 'created_at', type: 'DATETIME', nullable: false }
    ]
  };
}
```

### Types de données supportés

- `INTEGER` - Entiers
- `REAL` / `FLOAT` - Nombres décimaux
- `TEXT` - Texte
- `BOOLEAN` - Booléen (0/1)
- `DATETIME` - Date et heure

### Valeurs par défaut

Le système ajoute automatiquement des valeurs par défaut selon le type :

| Type | Nullable | Valeur par défaut |
|------|----------|-------------------|
| INTEGER | Non | `DEFAULT 0` |
| REAL | Non | `DEFAULT 0.0` |
| TEXT | Non | `DEFAULT ''` |
| BOOLEAN | Non | `DEFAULT 0` |
| DATETIME | Non | `DEFAULT CURRENT_TIMESTAMP` |
| Tous | Oui | Aucune (NULL autorisé) |

## Logs et débogage

### Activation des logs

Les logs sont automatiquement écrits dans :
- **Local** : `backend/logs/backend-startup.log`
- **Embarqué** : `%LOCALAPPDATA%/LOGESCO/backend/logs/backend-startup.log`

### Messages de log

```
✅ DB existante — migration prisma ignorée (démarrage rapide)
🔍 Vérification du schéma de base de données...
✅ Schéma de base de données valide
```

Ou si correction nécessaire :

```
🔧 Correction du schéma de base de données...
⚠️  Colonne manquante: stock.date_modification
✅ Colonne date_modification ajoutée à stock
📊 Résumé: 3/3 problèmes corrigés
✅ Schéma corrigé avec succès
```

## Tests manuels

### Tester le validateur

```bash
# Test sur la base locale
node backend/test-schema-validator.js

# Test sur la base embarquée
$env:LOGESCO_DATA_DIR = "$env:LOCALAPPDATA\LOGESCO"
node backend/test-schema-validator.js
```

### Simuler une colonne manquante

```sql
-- Supprimer une colonne (SQLite ne supporte pas DROP COLUMN)
-- Il faut recréer la table sans la colonne

-- 1. Renommer la table
ALTER TABLE stock RENAME TO stock_old;

-- 2. Recréer sans la colonne
CREATE TABLE stock (
  id INTEGER PRIMARY KEY,
  produit_id INTEGER NOT NULL,
  quantite_disponible INTEGER NOT NULL,
  quantite_reservee INTEGER NOT NULL,
  derniere_maj DATETIME NOT NULL
  -- date_modification manquante volontairement
);

-- 3. Copier les données
INSERT INTO stock SELECT id, produit_id, quantite_disponible, quantite_reservee, derniere_maj FROM stock_old;

-- 4. Supprimer l'ancienne
DROP TABLE stock_old;
```

Ensuite, démarrer le backend :
```bash
npm start
```

Le système détectera et ajoutera automatiquement `date_modification`.

## Maintenance

### Ajouter une vérification pour une nouvelle table

1. Ouvrir `backend/src/utils/schema-validator.js`
2. Modifier `getRequiredSchema()` :

```javascript
getRequiredSchema() {
  return {
    // Tables existantes...
    
    // Nouvelle table
    nouvelle_table: [
      { name: 'id', type: 'INTEGER', nullable: false },
      { name: 'nom', type: 'TEXT', nullable: false },
      { name: 'date_creation', type: 'DATETIME', nullable: false }
    ]
  };
}
```

3. (Optionnel) Ajouter à la validation rapide si critique :

```javascript
async quickValidate() {
  const criticalTables = ['stock', 'comptes_clients', 'produits', 'nouvelle_table'];
  const criticalColumns = {
    stock: 'date_modification',
    comptes_clients: 'date_modification',
    produits: 'image_url',
    nouvelle_table: 'nom'  // Colonne critique à vérifier
  };
  // ...
}
```

### Déploiement

Lors d'une mise à jour avec nouvelles colonnes :

1. **Développement** : 
   - Modifier `schema.prisma`
   - Modifier `schema-validator.js`
   - Tester localement

2. **Backend embarqué** :
   - Les fichiers sont copiés dans `%LOCALAPPDATA%\LOGESCO\backend\`
   - Au prochain démarrage, les colonnes sont ajoutées automatiquement
   - Aucune action manuelle requise ! ✅

3. **Backend cloud (PostgreSQL)** :
   - Les migrations Prisma standard s'appliquent
   - Le validateur est ignoré (détection automatique)

## Performances

- **Validation rapide** : ~10-20ms (exécutée à chaque démarrage)
- **Validation complète** : ~50-100ms (uniquement si problème détecté)
- **Ajout de colonne** : ~5-10ms par colonne
- **Impact total** : Négligeable sur le temps de démarrage

## Limitations

### SQLite
- ✅ Ajouter des colonnes : Supporté
- ❌ Supprimer des colonnes : Non supporté (nécessite recréation table)
- ❌ Modifier type colonne : Non supporté (nécessite recréation table)
- ✅ Ajouter index : Supporté mais non implémenté

### Environnements
- ✅ **SQLite local** : Validation automatique activée
- ✅ **SQLite embarqué** : Validation automatique activée
- ❌ **PostgreSQL cloud** : Validation automatique désactivée (migrations Prisma standard)

## Dépannage

### Problème : Le validateur ne s'exécute pas

**Vérifier** :
```javascript
// Dans server.js, ligne ~510
await this._validateSchema(prisma);
```

**Logs attendus** :
```
🔍 Vérification du schéma de base de données...
```

Si absent, le validateur n'est pas appelé.

### Problème : Colonne non ajoutée malgré validation

**Causes possibles** :
1. Table n'existe pas encore (sera créée par Prisma)
2. Permissions d'écriture manquantes sur la DB
3. Type de données invalide

**Solution** :
- Vérifier les logs : `backend/logs/backend-startup.log`
- Tester manuellement : `node backend/test-schema-validator.js`

### Problème : Démarrage ralenti

Le validateur est optimisé pour être rapide. Si le démarrage est lent :

1. Vérifier que la validation rapide fonctionne (doit terminer en <20ms)
2. Réduire le nombre de tables dans `getRequiredSchema()` (garder seulement les critiques)
3. Désactiver temporairement :

```javascript
async _validateSchema(prisma) {
  return; // Désactivé temporairement
  // ...
}
```

## Questions fréquentes

**Q: Faut-il exécuter manuellement les migrations ?**  
R: Non ! Le système les applique automatiquement à chaque démarrage si nécessaire.

**Q: Que se passe-t-il si j'ajoute une colonne au schema.prisma ?**  
R: Deux options :
1. Ajouter aussi dans `schema-validator.js` → Garantit l'application automatique
2. Ne rien faire → Sera ajoutée au prochain `prisma db push` (moins fiable)

**Q: Comment savoir si les migrations ont fonctionné ?**  
R: Vérifier les logs de démarrage :
```
✅ Schéma de base de données valide
```
ou
```
📊 Résumé: 3/3 problèmes corrigés
```

**Q: Puis-je forcer une validation complète ?**  
R: Oui, modifier `quickValidate()` pour retourner `false` :
```javascript
async quickValidate() {
  return false; // Force validation complète
}
```

## Support

Pour les problèmes persistants :
1. Vérifier `backend/logs/backend-startup.log`
2. Tester manuellement : `node backend/test-schema-validator.js`
3. Vérifier le schéma : `node backend/verify-tables-schema.js`
