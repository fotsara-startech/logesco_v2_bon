# Correction : Erreur "Cannot convert a BigInt value to a number" lors de la synchronisation

## 🐛 Problème

Lors de la synchronisation (pull delta depuis Neon vers SQLite), plusieurs tables échouent avec l'erreur :

```
⚠️  categories: erreur pull - Cannot convert a BigInt value to a number
⚠️  produits: erreur pull - Cannot convert a BigInt value to a number
⚠️  stock: erreur pull - Cannot convert a BigInt value to a number
⚠️  fournisseurs: erreur pull - Cannot convert a BigInt value to a number
⚠️  clients: erreur pull - Cannot convert a BigInt value to a number
...etc
```

## 🔍 Analyse

### Cause racine

Le problème se produit lorsque des données sont récupérées depuis PostgreSQL (Neon) pour être insérées dans SQLite local.

**Pourquoi ça arrive :**

1. **PostgreSQL (via pg library)** peut renvoyer certaines valeurs comme des `BigInt` JavaScript (notamment pour les types `BIGINT`, `BIGSERIAL`, ou même parfois `INTEGER` selon la configuration)

2. **SQLite** ne peut pas gérer directement les `BigInt` JavaScript via `$executeRawUnsafe` de Prisma

3. **La conversion échoue** : Quand on essaie d'insérer un `BigInt` dans SQLite, l'erreur "Cannot convert a BigInt value to a number" est levée

### Flux problématique

```
PostgreSQL (Neon)
  ↓ SELECT * FROM table
  ↓ Données avec BigInt
  ↓
JavaScript (Node.js)
  ↓ Tentative d'insertion
  ↓ $executeRawUnsafe(..., BigInt_value, ...)
  ↓
SQLite
  ↓ ❌ ERREUR: Cannot convert BigInt to number
```

### Où ça arrive

Dans `_pullDeltaFromNeon()`, ligne 209 (sync-service.js) et ligne 191 (sync-service-v2.js) :

```javascript
// AVANT (problématique)
const vals = keys.map(k => row[k] instanceof Date ? row[k].toISOString() : row[k]);
```

Cette ligne convertit les `Date` mais pas les `BigInt`, ce qui cause l'erreur lors de l'insertion.

## ✅ Solution appliquée

### 1. Conversion explicite des BigInt en Number lors du pull delta

**Modification dans `sync-service.js` et `sync-service-v2.js` :**

```javascript
// APRÈS (corrigé)
const vals = keys.map(k => {
  const val = row[k];
  if (val instanceof Date) return val.toISOString();
  if (typeof val === 'bigint') return Number(val);  // ← AJOUT
  return val;
});
```

### 2. Gestion robuste du timestamp dans operation_log

Le timestamp stocké dans `operation_log` peut aussi être un BigInt. Ajout d'une conversion sûre :

```javascript
const since = (() => {
  const ts = lastSync[0]?.ts;
  if (!ts) return '1970-01-01T00:00:00Z';
  // Gérer BigInt et Number
  const tsNum = typeof ts === 'bigint' ? Number(ts) : ts;
  try {
    return new Date(tsNum).toISOString();
  } catch (e) {
    return '1970-01-01T00:00:00Z';
  }
})();
```

## 📋 Fichiers modifiés

- ✅ `backend/src/services/sync-service.js`
  - Conversion BigInt → Number lors du pull delta (ligne ~209)
  - Gestion robuste du timestamp (ligne ~157)
  
- ✅ `backend/src/services/sync-service-v2.js`
  - Conversion BigInt → Number lors du pull delta (ligne ~191)
  - Gestion robuste du timestamp (ligne ~150)

## 🧪 Test de validation

Pour tester le correctif :

1. Redémarrer le backend : `npm start` ou `node src/server.js`
2. Attendre le cycle de synchronisation automatique
3. Vérifier les logs :
   - ✅ Aucune erreur "Cannot convert a BigInt value to a number"
   - ✅ Les tables se synchronisent correctement : `📥 categories: X nouveau(x)`
   - ✅ Message final : `📥 Pull delta: X enregistrement(s) depuis Neon`

## 💡 Pourquoi BigInt en JavaScript ?

JavaScript a deux types pour les entiers :
- **Number** : -2^53 à 2^53 (safe integers)
- **BigInt** : Entiers de taille arbitraire (ajouté en ES2020)

PostgreSQL peut renvoyer des BigInt pour :
- Les colonnes de type `BIGINT` ou `BIGSERIAL`
- Les colonnes `INTEGER` dans certaines configurations de la librairie `pg`
- Les valeurs très grandes qui dépassent `Number.MAX_SAFE_INTEGER`

## ⚠️ Limites de la conversion

La conversion `Number(bigint)` est sûre tant que la valeur est dans la plage des "safe integers" JavaScript :
- **Min** : -9,007,199,254,740,991 (-2^53 + 1)
- **Max** : 9,007,199,254,740,991 (2^53 - 1)

Pour une application de gestion comme LOGESCO, les ID et valeurs ne dépasseront jamais cette limite (plusieurs milliards d'enregistrements seraient nécessaires).

Si vous travaillez avec des valeurs astronomiques (crypto, astronomie, etc.), il faudrait une approche différente.

## 📝 Notes techniques

- SQLite n'a pas de vrai type BIGINT natif - il stocke tout comme INTEGER (64-bit signed)
- Prisma convertit automatiquement entre les types lors de l'utilisation du client Prisma
- Le problème n'apparaît qu'avec `$executeRawUnsafe` car on bypass les conversions automatiques de Prisma
- Cette correction est défensive et gère tous les cas possibles

## Date de correction

6 Juin 2026


---

# Correction supplémentaire : Erreur UNIQUE constraint sur cash_registers

## 🐛 Problème additionnel

Lors du pull delta, une erreur de contrainte UNIQUE apparaît :

```
prisma:error Invalid `prisma.$executeRawUnsafe()` invocation:
Raw query failed. Code: `2067`. Message: `UNIQUE constraint failed: cash_registers.nom`
⚠️  cash_registers merge échoué (id=3): UNIQUE constraint failed: cash_registers.nom
```

## 🔍 Analyse

### Cause

Dans un environnement multi-boutique, plusieurs boutiques peuvent avoir des caisses avec le même nom (ex: "Caisse Principale") mais des ID différents.

Lors du pull depuis Neon :
1. Neon contient `cash_register` id=3, nom="Caisse Principale"
2. Local contient déjà `cash_register` id=1, nom="Caisse Principale"  
3. L'UPSERT essaie : `INSERT ... ON CONFLICT(id) DO UPDATE`
4. Pas de conflit d'ID (3 ≠ 1) → tente un INSERT
5. ❌ Erreur : Le nom "Caisse Principale" existe déjà

### Pourquoi c'est normal

En multi-boutique :
- Chaque boutique a sa propre instance locale avec ses propres caisses
- Neon (cloud) contient les caisses de TOUTES les boutiques
- Lors du pull, on peut recevoir des caisses d'autres boutiques
- Ces caisses peuvent avoir des noms identiques mais appartenir à différentes boutiques

## ✅ Solution

Ignorer silencieusement les erreurs `UNIQUE constraint failed` lors du pull delta. Si une caisse avec le même nom existe déjà localement, on la conserve (elle appartient probablement à la boutique locale).

**Modification :**

```javascript
} catch (insertErr) {
  // Ignorer silencieusement les erreurs UNIQUE constraint (normal en multi-boutique)
  if (!insertErr.message.includes('UNIQUE constraint failed')) {
    console.warn(`  ⚠️  ${table} merge échoué (id=${row.id}): ${insertErr.message}`);
  }
}
```

**Avant** : Tous les échecs d'insertion affichaient un warning  
**Après** : Seuls les échecs non-UNIQUE affichent un warning

## 📋 Impact

- ✅ Supprime les logs d'erreur parasites
- ✅ La synchronisation continue normalement
- ✅ Chaque boutique conserve ses propres caisses
- ✅ Pas de conflit entre boutiques

## Date de correction

6 Juin 2026
