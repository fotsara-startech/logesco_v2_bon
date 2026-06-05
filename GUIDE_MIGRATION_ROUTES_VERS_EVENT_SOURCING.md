# Guide Migration Routes — Event Sourcing V2

## 🎯 Objectif

Remplacer tous les appels `syncService.enqueue()` par `syncService.logOperation()` dans les routes

## 🔍 Comment identifier les routes à migrer

```bash
# Trouve tous les appels enqueue
grep -r "syncService.enqueue" backend/src/routes/

# Devrait afficher:
# backend/src/routes/accounts.js:xxxx:await syncService.enqueue(...)
```

## ✏️ Pattern de migration

### AVANT (V1)
```javascript
await syncService.enqueue('fournisseurs', 'INSERT', fournisseur);
await syncService.enqueue('transactions_comptes', 'INSERT', transaction);
```

### APRÈS (V2)
```javascript
await syncService.logOperation('fournisseurs', 'INSERT', fournisseur, req.user.id);
await syncService.logOperation('transactions_comptes', 'INSERT', transaction, req.user.id);
```

**Différence clé**: Ajouter `req.user.id` pour l'audit trail

---

## 📝 Routes déjà migrées

### ✅ accounts.js
```javascript
// Line ~891
await syncService.logOperation('comptes_fournisseurs', 'UPDATE', result.compte, req.user.id);
await syncService.logOperation('transactions_comptes', 'INSERT', result.transaction, req.user.id);
await syncService.logOperation('cash_sessions', 'UPDATE', result.updatedSession, req.user.id);
await syncService.logOperation('cash_registers', 'UPDATE', result.updatedCaisse, req.user.id);
await syncService.logOperation('cash_movements', 'INSERT', result.mouvementFinancier, req.user.id);
await syncService.logOperation('financial_movements', 'INSERT', result.mouvementFinancierRecord, req.user.id);
```

---

## 🔧 Routes à migrer (liste complète)

### 1. **cash-sessions.js** 
```javascript
// Line ~250 (ouverture de session)
// AVANT:
if (syncService) {
  await syncService.enqueue('cash_movements', 'INSERT', openingMovement);
}

// APRÈS:
if (syncService) {
  await syncService.logOperation('cash_movements', 'INSERT', openingMovement, userId);
}
```

```javascript
// Line ~445 (clôture de session)
// AVANT:
if (syncService) {
  await syncService.enqueue('cash_movements', 'INSERT', closingMovement);
}

// APRÈS:
if (syncService) {
  await syncService.logOperation('cash_movements', 'INSERT', closingMovement, activeSession.utilisateurId);
}
```

### 2. **products.js** (si sync de produits)
```javascript
// Chercher tous les enqueue
// PATTERN: Replace enqueue → logOperation with user context
```

### 3. **sales.js** (ventes)
```javascript
// Chercher tous les enqueue pour:
// - ventes
// - details_ventes
// - mouvements_stock
// - transactions_comptes
```

### 4. **inventory.js** (inventaires)
```javascript
// Chercher tous les enqueue pour:
// - stock_inventories
// - inventory_items
// - mouvements_stock
```

### 5. **procurement.js** (approvisionnement)
```javascript
// Chercher tous les enqueue pour:
// - commandes_approvisionnement
// - details_commandes_approvisionnement
// - mouvements_stock
```

---

## ⚙️ Script automatisé de migration (optionnel)

Si tu veux que je crée un script qui remplace automatiquement:

```bash
#!/bin/bash
# migrate-to-event-sourcing.sh

cd backend/src/routes

# Remplacer tous les enqueue par logOperation
# ATTENTION: À faire avec prudence!

for file in *.js; do
  sed -i.bak 's/syncService\.enqueue(/syncService.logOperation(/g' "$file"
  # Ajouter req.user.id ou userId manuellement après
done
```

**⚠️ Recommandation**: Faire les migrations manuellement pour valider le contexte utilisateur

---

## ✅ Checklist migration

- [ ] Identifier toutes les routes qui usent syncService
- [ ] Pour chaque route:
  - [ ] Remplacer `enqueue` → `logOperation`
  - [ ] Ajouter le `userId` context (req.user.id ou equivalent)
  - [ ] Valider qu'userId existe
  - [ ] Tester la synchronisation
- [ ] Vérifier pas de "enqueue" restant: `grep -r "\.enqueue"`
- [ ] Déployer et monitorer logs

---

## 🧪 Validation post-migration

### 1. Vérifier compilation
```bash
npx eslint backend/src/routes/
```

### 2. Vérifier pas de syntax errors
```bash
node -c backend/src/routes/accounts.js
node -c backend/src/routes/cash-sessions.js
# etc...
```

### 3. Vérifier logs
```bash
npm start 2>&1 | grep -E "logOperation|Logged:|operation_log"
```

**Expected output:**
```
📋 Logged: INSERT fournisseurs (id=123)
📋 Logged: UPDATE cash_sessions (id=456)
```

### 4. Vérifier operation_log
```sql
SELECT COUNT(*) FROM operation_log;  -- Devrait avoir des rows
SELECT status, COUNT(*) FROM operation_log GROUP BY status;
-- Devrait montrer some 'synced', maybe some 'pending'
```

---

## 🚨 Troubleshooting

### Erreur: "req.user.id is undefined"
```javascript
// Vérifier que req.user est défini (après auth middleware)
// Si pas d'user: utiliser null
await syncService.logOperation('table', 'INSERT', data, req.user?.id || null);
```

### Erreur: "syncService is not defined"
```javascript
// Vérifier l'import en haut du fichier
const syncService = require('../services/sync-service');
```

### Opérations pas synchronisées
```sql
-- Vérifier qu'elles sont dans operation_log
SELECT * FROM operation_log WHERE table_name = 'xxx' LIMIT 5;

-- Si status='failed', voir le message d'erreur
SELECT * FROM operation_log WHERE status = 'failed' LIMIT 5;
```

---

## 📊 Template migration par fichier

### cash-sessions.js

```javascript
// FIND: syncService.enqueue
// REPLACE: syncService.logOperation

// Opening movement (line ~250)
- await syncService.enqueue('cash_movements', 'INSERT', openingMovement);
+ await syncService.logOperation('cash_movements', 'INSERT', openingMovement, userId);

// Closing movement (line ~445)
- await syncService.enqueue('cash_movements', 'INSERT', closingMovement);
+ await syncService.logOperation('cash_movements', 'INSERT', closingMovement, activeSession.utilisateurId);
```

---

## ✨ Bénéfices après migration

Une fois toutes les routes migrées:

✅ **Audit trail complet**
- Qui a créé quelle opération? `user_id` dans operation_log
- Quand? `timestamp` dans operation_log
- Quoi? `data` (JSON snapshot) dans operation_log

✅ **Replay automatique**
- Si une opération échoue: automatiquement rejouée
- Pas de perte de données

✅ **Monitoring**
- Dashboard operation_log
- Alertes sur failed operations
- Support facile: "Rejoue cette opération"

---

## 📋 Routes status

| Route | File | Status | Notes |
|---|---|---|---|
| Supplier payments | accounts.js | ✅ Done | All enqueue replaced |
| Cash sessions open | cash-sessions.js | ⏳ TODO | Need to migrate |
| Cash sessions close | cash-sessions.js | ✅ Done | closingMovement fixed |
| Sales | sales.js | ⏳ TODO | Search for enqueue |
| Inventory | inventory.js | ⏳ TODO | Search for enqueue |
| Procurement | procurement.js | ⏳ TODO | Search for enqueue |

---

## 🎯 Prochaines étapes

1. **Faire une recherche complète** des `enqueue` restants
2. **Migrer cash-sessions.js** (important pour audit)
3. **Migrer les autres routes** progressivement
4. **Tester chaque migration** avant deploiement
5. **Valider operation_log** en production

---

**Version**: Event Sourcing V2
**Last updated**: 2026-06-05
**Status**: 🟢 Guide complète
