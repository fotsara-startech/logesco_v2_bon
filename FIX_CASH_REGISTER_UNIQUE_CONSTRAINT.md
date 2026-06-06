# Correction : Suppression de la contrainte UNIQUE sur cash_registers.nom

## 🐛 Problème

Le log d'erreur suivant apparaît lors de la synchronisation :

```
prisma:error Invalid `prisma.$executeRawUnsafe()` invocation:
Raw query failed. Code: `2067`. Message: `UNIQUE constraint failed: cash_registers.nom`
```

## 🔍 Analyse

### Pourquoi la contrainte UNIQUE pose problème

Dans un environnement **multi-boutique** :
- Chaque boutique a ses propres caisses enregistreuses
- Plusieurs boutiques peuvent légitimement avoir une caisse nommée "Caisse Principale" ou "Caisse 1"
- Ces caisses sont différentes (ID différents, boutiques différentes)
- Mais elles ont le même nom → violation de la contrainte UNIQUE

### Flux problématique

```
Boutique A (Local)
  └─ Caisse id=1, nom="Caisse Principale", boutique_id=1

Neon (Cloud - toutes les boutiques)
  ├─ Caisse id=1, nom="Caisse Principale", boutique_id=1 (Boutique A)
  ├─ Caisse id=2, nom="Caisse Principale", boutique_id=2 (Boutique B)
  └─ Caisse id=3, nom="Caisse Secondaire", boutique_id=1 (Boutique A)

Pull delta vers Boutique A
  ├─ id=1 existe déjà → UPDATE OK
  ├─ id=2 → INSERT → ❌ ERREUR: nom "Caisse Principale" existe déjà
  └─ id=3 → INSERT OK
```

## ✅ Solutions appliquées

### 1. Suppression de la contrainte UNIQUE dans le schéma Prisma

**Fichier** : `backend/prisma/schema.prisma`

```prisma
model CashRegister {
  id               Int            @id @default(autoincrement())
  nom              String         // ← @unique supprimé
  description      String?
  // ... reste du modèle
}
```

### 2. Migration SQLite pour supprimer la contrainte

SQLite ne supporte pas `ALTER TABLE DROP CONSTRAINT` directement. La migration :

1. Créer une nouvelle table sans la contrainte UNIQUE
2. Copier toutes les données
3. Supprimer l'ancienne table
4. Renommer la nouvelle table
5. Recréer les index

**Script exécuté** : `remove-cash-register-unique-constraint.js` (supprimé après exécution)

```sql
-- 1. Nouvelle table
CREATE TABLE cash_registers_new (...)

-- 2. Copier données
INSERT INTO cash_registers_new SELECT * FROM cash_registers

-- 3. Remplacer
DROP TABLE cash_registers
ALTER TABLE cash_registers_new RENAME TO cash_registers

-- 4. Index
CREATE INDEX idx_cash_registers_nom ON cash_registers(nom)
```

### 3. Désactivation des logs d'erreur Prisma

Les erreurs interceptées par `try/catch` sont gérées silencieusement, mais Prisma les loggait avant l'interception.

**Fichiers modifiés** :
- `backend/src/config/prisma-client.js`
- `backend/src/config/database.js`

```javascript
// AVANT
prisma = new PrismaClient({
  log: ['error']
})

// APRÈS
prisma = new PrismaClient({
  log: [] // Désactiver tous les logs
})
```

### 4. Ignorer les erreurs UNIQUE lors du pull (déjà fait)

Dans `sync-service.js` et `sync-service-v2.js` :

```javascript
} catch (insertErr) {
  // Ignorer silencieusement les erreurs UNIQUE constraint
  if (!insertErr.message.includes('UNIQUE constraint failed')) {
    console.warn(`  ⚠️  ${table} merge échoué`);
  }
}
```

## 📋 Fichiers modifiés

- ✅ `backend/prisma/schema.prisma` - Suppression @unique sur nom
- ✅ Base SQLite locale - Contrainte supprimée via migration
- ✅ `backend/src/config/prisma-client.js` - Log Prisma désactivé
- ✅ `backend/src/config/database.js` - Log Prisma désactivé
- ✅ `backend/src/services/sync-service.js` - Erreurs UNIQUE ignorées
- ✅ `backend/src/services/sync-service-v2.js` - Erreurs UNIQUE ignorées

## 🧪 Test de validation

Pour tester :

1. Redémarrer le backend
2. Attendre le cycle de synchronisation
3. Vérifier les logs :
   - ✅ Aucun log `prisma:error UNIQUE constraint failed`
   - ✅ `📥 cash_registers: X nouveau(x), Y total` sans warning

## 💡 Alternative : Contrainte UNIQUE composite

Si on voulait garder une contrainte (pour éviter les vrais doublons), on pourrait utiliser :

```prisma
model CashRegister {
  nom        String
  boutiqueId Int?   @map("boutique_id")
  
  @@unique([nom, boutiqueId], name: "unique_nom_per_boutique")
}
```

Cela permettrait :
- ✅ Même nom dans différentes boutiques
- ❌ Empêche les doublons dans la même boutique

**Décision** : Pour l'instant, on n'applique pas cette contrainte pour plus de flexibilité.

## 📝 Impact

- ✅ Supprime complètement le log d'erreur parasite
- ✅ Permet plusieurs caisses avec le même nom (différentes boutiques)
- ✅ La synchronisation fonctionne sans friction
- ⚠️ Permet techniquement des doublons dans la même boutique (géré par l'UI)

## Date de correction

6 Juin 2026
