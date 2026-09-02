# Prisma Extensions et Transactions - Limitation

## 🐛 Problème Découvert

Les hooks Prisma créés avec `$extends` **ne s'appliquent PAS** aux opérations effectuées dans les transactions (`$transaction`).

### Symptôme

```javascript
// ❌ Les hooks ne se déclenchent PAS ici
await prisma.$transaction(async (tx) => {
  await tx.mouvementStock.create({ ... }); // Hook ignoré
  await tx.stockBoutique.update({ ... });  // Hook ignoré
});
```

### Logs Observés

```
📤 Push 2 opération(s) vers Neon...
📥 stock_boutiques: 1 récupéré(s), 1 inséré(s) au total
📥 ventes: 1 récupéré(s), 2 inséré(s) au total
```

**Manquant**: `mouvements_stock` n'est pas synchronisé!

## 🔍 Cause Technique

C'est une **limitation connue de Prisma**:

1. Les extensions Prisma (`$extends`) créent une nouvelle instance de client
2. Les transactions (`$transaction`) créent leur propre contexte isolé
3. Le contexte de transaction (`tx`) **n'hérite PAS** des extensions du client parent

### Documentation Prisma

> "Extensions are not inherited by interactive transactions. The transaction context (`tx`) is a separate Prisma Client instance."

Source: https://www.prisma.io/docs/concepts/components/prisma-client/client-extensions

## ✅ Solution Implémentée

### Synchronisation Manuelle Après Transaction

Au lieu de compter sur les hooks, on synchronise manuellement après la transaction:

```javascript
// 1. Transaction (sans hooks)
const vente = await prisma.$transaction(async (tx) => {
  await tx.mouvementStock.create({ ... });
  await tx.stockBoutique.update({ ... });
  return nouvelleVente;
});

// 2. Synchronisation manuelle APRÈS la transaction
if (process.env.CLOUD_DB_URL) {
  const syncService = require('../services/sync-service');
  
  // Récupérer les données créées/modifiées
  const mouvement = await prisma.mouvementStock.findFirst({
    where: { referenceId: vente.id, typeReference: 'vente' }
  });
  
  // Envoyer à la queue de sync
  await syncService.enqueue('mouvements_stock', 'INSERT', {
    id: mouvement.id,
    produit_id: mouvement.produitId,
    // ... autres colonnes
  });
}
```

## 📁 Fichiers Modifiés

### `backend/src/routes/sales.js`

Ajout de la synchronisation manuelle après la transaction de vente:

```javascript
// Après la transaction
for (const detail of details) {
  if (detail.type !== 'service') {
    // Récupérer le mouvement de stock créé
    const mouvement = await prisma.mouvementStock.findFirst({
      where: {
        produitId: detail.produitId,
        referenceId: vente.id,
        typeReference: 'vente'
      }
    });
    
    // Synchroniser vers Neon
    await syncService.enqueue('mouvements_stock', 'INSERT', { ... });
    
    // Synchroniser stock_boutiques ou stock
    if (boutiqueId) {
      const stockBoutique = await prisma.stockBoutique.findUnique({ ... });
      await syncService.enqueue('stock_boutiques', 'UPDATE', { ... });
    } else {
      const stock = await prisma.stock.findUnique({ ... });
      await syncService.enqueue('stock', 'UPDATE', { ... });
    }
  }
}
```

## 🎯 Avantages de cette Approche

### ✅ Avantages

1. **Fonctionne avec les transactions** - Pas de limitation Prisma
2. **Contrôle total** - On sait exactement ce qui est synchronisé
3. **Debugging facile** - Logs explicites pour chaque sync
4. **Performance** - Sync après transaction, pas pendant

### ⚠️ Inconvénients

1. **Code dupliqué** - Besoin de sync manuelle dans chaque route avec transaction
2. **Maintenance** - Si on ajoute des champs, il faut mettre à jour la sync
3. **Oublis possibles** - Risque d'oublier de synchroniser certaines tables

## 🔄 Alternatives Considérées

### Alternative 1: Extensions de Transaction (Complexe)

```javascript
const extendedPrisma = prisma.$extends({
  client: {
    async $transaction(fn, options) {
      // Créer un client étendu pour la transaction
      const extendedTx = this.$extends({ ... });
      return this.$transaction((tx) => fn(extendedTx), options);
    }
  }
});
```

**Problème**: Très complexe, risque de bugs, non documenté officiellement

### Alternative 2: Triggers PostgreSQL (Idéal pour Production)

```sql
CREATE OR REPLACE FUNCTION sync_mouvements_stock()
RETURNS TRIGGER AS $$
BEGIN
  -- Logique de sync
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_mouvements_stock_trigger
AFTER INSERT OR UPDATE ON mouvements_stock
FOR EACH ROW EXECUTE FUNCTION sync_mouvements_stock();
```

**Avantage**: Fonctionne toujours, même hors de l'application
**Inconvénient**: Nécessite PostgreSQL (pas SQLite local)

### Alternative 3: Sync Manuelle (Choix Actuel)

**Avantage**: Simple, fonctionne partout, contrôle total
**Inconvénient**: Code dupliqué, maintenance

## 🧪 Tests

### Test 1: Vérifier la Sync Manuelle

```powershell
# 1. Redémarrer le backend
npm start

# 2. Créer une vente
# 3. Vérifier les logs:
```

**Logs attendus**:
```
POST /api/v1/sales 200 150 ms
🔄 [Manual Sync] mouvements_stock (INSERT): 640
🔄 [Manual Sync] stock_boutiques (UPDATE): 122
📤 Push 3 opération(s) vers Neon...
```

### Test 2: Vérifier Neon

```sql
-- Mouvements de stock
SELECT * FROM mouvements_stock 
WHERE date_modification > NOW() - INTERVAL '1 minute'
ORDER BY date_modification DESC;

-- Stock boutiques
SELECT * FROM stock_boutiques 
WHERE date_modification > NOW() - INTERVAL '1 minute'
ORDER BY date_modification DESC;
```

**Résultat attendu**: Données synchronisées correctement

## 📊 Impact

### Avant (Hooks Prisma Seuls)

```
Vente créée → Transaction → Hooks ignorés → ❌ Pas de sync
```

### Après (Sync Manuelle)

```
Vente créée → Transaction → Sync manuelle → ✅ Sync complète
```

## 🚀 Prochaines Étapes

1. ✅ Redémarrer le backend
2. ✅ Créer une vente de test
3. ✅ Vérifier les logs pour voir "🔄 [Manual Sync]"
4. ✅ Vérifier dans Neon que mouvements_stock est synchronisé
5. 🔄 Appliquer la même logique aux autres routes avec transactions:
   - Achats/Approvisionnements
   - Ajustements de stock manuels
   - Inventaires

## 📚 Documentation Associée

- `FIX_TRANSACTION_TIMEOUT.md` - Correction du timeout
- `SYNC_STOCK_MOUVEMENTS_SOLUTION.md` - Solution complète
- `HOOKS_PRISMA_STATUS.md` - Status des hooks

## 🎓 Leçon Apprise

**Les extensions Prisma sont puissantes mais ont des limitations:**
- ✅ Fonctionnent pour les opérations directes
- ❌ Ne fonctionnent PAS dans les transactions
- 💡 Solution: Sync manuelle après les transactions

Pour un système de production à grande échelle, considérer l'utilisation de **triggers PostgreSQL** sur Neon pour une synchronisation automatique et fiable.
