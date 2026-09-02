# Synchronisation Complète - Incluant Mouvements Financiers

## ✅ Status: Activé et Prêt

La synchronisation des mouvements financiers et de caisse est maintenant activée avec isolation par boutique.

## Ce Qui Est Synchronisé

### Tables Synchronisées

1. ✅ **cash_sessions** — Sessions de caisse
2. ✅ **cash_registers** — Caisses
3. ✅ **financial_movements** — Mouvements financiers (NOUVEAU)
4. ✅ **cash_movements** — Mouvements de caisse (NOUVEAU)
5. ✅ **ventes** — Ventes
6. ✅ **utilisateurs** — Utilisateurs
7. ✅ **produits** — Produits
8. ✅ **clients** — Clients
9. ✅ **boutiques** — Boutiques
10. ✅ **categories** — Catégories

## Isolation par Boutique

Chaque table contient un champ `boutiqueId` qui permet d'isoler les données:

```sql
-- Boutique 7 voit seulement ses données
SELECT * FROM financial_movements WHERE boutique_id = 7;

-- Boutique 8 voit seulement ses données
SELECT * FROM financial_movements WHERE boutique_id = 8;
```

## Flux de Synchronisation

### Création d'une Dépense

```
User (Boutique 7) crée dépense de 1000 FCFA
    ↓
Backend crée:
  1. financial_movement (boutiqueId = 7)
  2. cash_movement (boutiqueId = 7)
  3. Met à jour cash_session (boutiqueId = 7)
  4. Met à jour cash_register (boutiqueId = 7)
    ↓
Backend enqueue:
  1. financial_movements INSERT
  2. cash_movements INSERT
  3. cash_sessions UPDATE
  4. cash_registers UPDATE
    ↓
Sync Service (30 secondes)
    ↓
Neon reçoit les 4 opérations
    ↓
Autres utilisateurs (Boutique 7) voient:
  - Nouvelle dépense ✅
  - Solde mis à jour ✅
    ↓
Utilisateurs (Boutique 8) ne voient PAS:
  - La dépense de Boutique 7 ✅ (isolation)
```

## Prochaines Étapes

### 1. Redémarrer le Backend

```bash
# Arrêter le backend (Ctrl+C)
# Redémarrer:
npm start
```

**IMPORTANT**: Le backend DOIT être complètement redémarré pour charger les nouveaux modules.

### 2. Créer une Dépense

- Ouvrir l'app
- Créer un mouvement financier
- Noter le montant et l'heure

### 3. Vérifier la Synchronisation

```bash
# Attendre 30 secondes (cycle de sync)

# Vérifier la queue
node debug-sync-queue.js

# Vérifier Neon
node check-financial-movements-neon.js
```

### 4. Logs Attendus

```
✅ Mouvement financier créé: MF-20260425-XXXX - 1000€ - boutiqueId: 7
💰 Session de caisse mise à jour:
   Solde attendu avant: 180000 FCFA
   Dépense: -1000 FCFA
   Solde attendu après: 179000 FCFA
✅ Caisse mise à jour: -1000 FCFA
📤 Push 4 opération(s) vers Neon...
```

Puis après 30 secondes:

```bash
node debug-sync-queue.js
```

Devrait montrer:
```
financial_movements (INSERT): 1 ✅ synced
cash_movements (INSERT): 1 ✅ synced
cash_sessions (UPDATE): 1 ✅ synced
cash_registers (UPDATE): 1 ✅ synced
```

### 5. Vérifier dans Neon

```bash
node check-financial-movements-neon.js
```

Devrait montrer:
```
📍 LOCAL (SQLite):
   Financial Movements: X
   Cash Movements: Y

☁️  NEON (PostgreSQL):
   Financial Movements: X
   Cash Movements: Y

🔄 COMPARISON:
   ✅ Financial Movements synchronisés
   ✅ Cash Movements synchronisés
```

## Test Multi-Utilisateur

### Scénario 1: Même Boutique

1. **User A** (Boutique 7): Crée dépense 1000 FCFA
2. Attendre 30 secondes
3. **User B** (Boutique 7): Rafraîchir l'app
4. ✅ User B voit la dépense de User A

### Scénario 2: Boutiques Différentes

1. **User A** (Boutique 7): Crée dépense 1000 FCFA
2. Attendre 30 secondes
3. **User C** (Boutique 8): Rafraîchir l'app
4. ✅ User C ne voit PAS la dépense de Boutique 7

## Fichiers Modifiés

1. **backend/src/middleware/sync-middleware.js**
   - Activé financial_movements (retiré skip: true)
   - Ajouté allowedColumns pour financial_movements

2. **backend/src/services/financial-movement.js**
   - Ajouté enqueue pour cash_movements après création

3. **backend/src/services/sync-service.js**
   - Ajouté cash_movements et financial_movements à PULL_TABLES
   - Ajouté dans l'ordre de priorité du push

## Scripts de Vérification

- `debug-sync-queue.js` — Voir la queue de sync
- `check-financial-movements-neon.js` — Vérifier les mouvements dans Neon
- `check-session-balance.js` — Vérifier le solde de session
- `test-financial-movement-sync.js` — Test complet

## Résolution de Problèmes

### Problème: Mouvements pas synchronisés

**Vérifications**:
1. Backend redémarré? `npm start`
2. CLOUD_DB_URL défini? `cat .env | grep CLOUD_DB_URL`
3. Neon accessible? `node check-neon-data.js`
4. Erreurs dans les logs?

**Solution**:
```bash
# Vérifier la queue
node debug-sync-queue.js

# Si items "pending", attendre 30 secondes
# Si erreurs, vérifier les logs backend
```

### Problème: Données d'autres boutiques visibles

**Cause**: L'app ne filtre pas par boutiqueId

**Solution**: Vérifier que toutes les requêtes incluent:
```sql
WHERE boutique_id = ?
```

### Problème: Sync lent

**Cause**: Cycle de sync de 30 secondes

**Solution**: C'est normal. Pour sync immédiate, réduire l'intervalle dans sync-service.js:
```javascript
// De 30000 (30s) à 10000 (10s)
this.syncInterval = setInterval(() => this._syncCycle(), 10000);
```

## Avantages

1. ✅ **Historique Complet**: Tous les mouvements sont tracés et synchronisés
2. ✅ **Multi-Utilisateur**: Plusieurs utilisateurs voient les mêmes données
3. ✅ **Isolation**: Chaque boutique voit seulement ses données
4. ✅ **Rapports**: Rapports consolidés depuis Neon
5. ✅ **Traçabilité**: Chaque opération est enregistrée

## Conclusion

✅ **Synchronisation Complète Activée**

Les mouvements financiers et de caisse sont maintenant synchronisés vers Neon avec isolation par boutique. Le système est prêt pour un environnement multi-utilisateur et multi-boutique.

---

**Status**: ✅ Prêt à Tester

**Date**: 2026-04-25

**Action**: Redémarrer le backend et créer une dépense pour tester
