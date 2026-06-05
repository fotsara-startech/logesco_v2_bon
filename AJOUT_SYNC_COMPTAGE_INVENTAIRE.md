# Ajout de la synchronisation pour le comptage des inventaires

## Problème identifié

Les mises à jour des items d'inventaire lors du comptage (endpoint `PUT /api/v1/stock-inventory/items/:itemId`) n'étaient **pas synchronisées vers Neon**.

Conséquences :
- ❌ Les quantités comptées restaient uniquement en local (SQLite)
- ❌ Neon ne reflétait pas l'état d'avancement du comptage
- ❌ En cas de basculement ou de consultation depuis un autre appareil, les comptages étaient perdus
- ❌ Les écarts calculés n'étaient pas synchronisés

## Contexte

### Endpoint concerné
```
PUT /api/v1/stock-inventory/items/:itemId
```

### Données mises à jour lors du comptage
```javascript
{
  quantiteComptee: Float,      // Quantité comptée par l'utilisateur
  ecart: Float,                // Différence entre système et compté
  commentaire: String,         // Commentaire optionnel
  dateComptage: DateTime,      // Timestamp du comptage
  utilisateurComptageId: Int   // ID de l'utilisateur qui a compté
}
```

## Solution implémentée

### Fichiers modifiés
- `backend/src/routes/stock-inventory.js` (ligne ~258)
- `dist-exe/src/routes/stock-inventory.js` (ligne ~258)

### Code ajouté

Après l'envoi de la réponse au client, ajout de l'enqueue pour synchronisation :

```javascript
// Enqueue pour sync vers Neon après comptage
if (syncService) {
  await syncService.enqueue('inventory_items', 'UPDATE', {
    id: updatedItem.id,
    inventaireId: updatedItem.inventaireId,
    produitId: updatedItem.produitId,
    quantiteSysteme: updatedItem.quantiteSysteme,
    quantiteComptee: updatedItem.quantiteComptee,
    ecart: updatedItem.ecart,
    prixUnitaire: updatedItem.prixUnitaire,
    prixAchat: updatedItem.prixAchat,
    commentaire: updatedItem.commentaire,
    dateComptage: updatedItem.dateComptage,
    utilisateurComptageId: updatedItem.utilisateurComptageId
  });
}
```

### Champs synchronisés

Tous les champs scalaires de l'item sont envoyés pour synchronisation :
- ✅ `quantiteComptee` - La nouvelle quantité comptée
- ✅ `ecart` - L'écart calculé automatiquement
- ✅ `commentaire` - Le commentaire de l'utilisateur
- ✅ `dateComptage` - Le timestamp du comptage
- ✅ `utilisateurComptageId` - L'utilisateur qui a effectué le comptage
- ✅ `quantiteSysteme` - Quantité système (pour référence)
- ✅ `prixUnitaire` et `prixAchat` - Valorisation

## Comportement

### Flux de comptage avec synchronisation

1. **Utilisateur compte un produit** dans l'application mobile/desktop
2. **Requête PUT** vers `/api/v1/stock-inventory/items/:itemId`
3. **Mise à jour locale** dans SQLite (table `inventory_items`)
4. **Réponse immédiate** au client avec les données mises à jour
5. **Enqueue automatique** dans `sync_queue` avec `table_name='inventory_items'`
6. **Synchronisation asynchrone** vers Neon lors du prochain cycle de sync

### Avantages

- ✅ **Performance** : L'utilisateur n'attend pas la sync vers Neon (réponse immédiate)
- ✅ **Résilience** : Si Neon est indisponible, le comptage est sauvegardé localement et sera synchronisé plus tard
- ✅ **Traçabilité** : Tous les comptages sont tracés avec date et utilisateur
- ✅ **Cohérence** : Les données locales et cloud restent synchronisées

## Impact sur le cycle de synchronisation

### Avant la correction

```
Sync queue après comptage de 5 produits:
- stock_inventories: 0 pending  (inventaire lui-même)
- inventory_items: 0 pending    ❌ (comptages non synchronisés)
```

### Après la correction

```
Sync queue après comptage de 5 produits:
- stock_inventories: 0 pending  (inventaire lui-même)
- inventory_items: 5 pending    ✅ (5 comptages en attente de sync)
```

Lors du prochain cycle de synchronisation (automatique ou manuel), ces 5 items seront pushés vers Neon.

## Optimisation - Regroupement des syncs

**Note importante :** Les comptages d'inventaire peuvent être très fréquents (plusieurs dizaines ou centaines de produits). La synchronisation est donc :

1. **Mise en queue immédiatement** après chaque comptage
2. **Exécutée par batch** lors du cycle de sync (toutes les 30 secondes ou déclenchement manuel)
3. **Non bloquante** pour l'utilisateur

Cela évite de déclencher une synchronisation complète après chaque produit compté, ce qui serait inefficace.

## Scénarios d'usage

### Scénario 1 : Comptage en ligne
```
1. Utilisateur compte 50 produits
2. Chaque comptage est mis en queue localement
3. Cycle de sync (30s) → Push des 50 items vers Neon
4. ✅ Neon à jour avec tous les comptages
```

### Scénario 2 : Comptage hors ligne
```
1. Utilisateur compte 50 produits (Neon indisponible)
2. Chaque comptage est mis en queue localement
3. Tentatives de sync échouent (stockées en queue)
4. Connexion rétablie
5. Cycle de sync → Push des 50 items vers Neon
6. ✅ Neon rattrape son retard
```

### Scénario 3 : Multi-utilisateurs
```
1. Utilisateur A compte 20 produits sur tablette
2. Utilisateur B compte 30 produits sur mobile
3. Les deux appareils synchronisent vers Neon
4. ✅ Neon contient les 50 comptages
5. Chaque appareil peut pull les comptages de l'autre
```

## Tests recommandés

### 1. Test basique
```bash
# Compter un produit
curl -X PUT http://localhost:8080/api/v1/stock-inventory/items/1 \
  -H "Content-Type: application/json" \
  -d '{
    "quantiteComptee": 25,
    "commentaire": "Comptage test",
    "utilisateurComptageId": 1
  }'

# Vérifier la queue de sync
SELECT * FROM sync_queue WHERE table_name = 'inventory_items' ORDER BY id DESC LIMIT 1;
```

### 2. Test de charge
```bash
# Compter 100 produits rapidement
for i in {1..100}; do
  curl -X PUT http://localhost:8080/api/v1/stock-inventory/items/$i \
    -H "Content-Type: application/json" \
    -d "{\"quantiteComptee\": $((RANDOM % 100)), \"utilisateurComptageId\": 1}"
done

# Vérifier le nombre d'items en attente
SELECT COUNT(*) FROM sync_queue WHERE table_name = 'inventory_items' AND synced = 0;
```

### 3. Test de synchronisation
```bash
# Déclencher la sync manuelle
curl -X POST http://localhost:8080/api/v1/sync/trigger

# Vérifier que les items ont été marqués comme synchronisés
SELECT COUNT(*) FROM sync_queue WHERE table_name = 'inventory_items' AND synced = 1;
```

### 4. Vérification dans Neon
```sql
-- Connexion à Neon PostgreSQL
SELECT 
  ii.id,
  ii.inventaire_id,
  p.nom as produit,
  ii.quantite_systeme,
  ii.quantite_comptee,
  ii.ecart,
  ii.date_comptage,
  u.nom_utilisateur
FROM inventory_items ii
JOIN produits p ON ii.produit_id = p.id
LEFT JOIN utilisateurs u ON ii.utilisateur_comptage_id = u.id
WHERE ii.inventaire_id = 19  -- ID de votre inventaire de test
ORDER BY ii.date_comptage DESC;
```

## Relation avec les corrections précédentes

Ce correctif complète les corrections précédentes :

1. ✅ **Synchronisation des inventaires** (création, mise à jour, suppression)
2. ✅ **Correction du champ type** (PARTIEL/TOTAL)
3. ✅ **Utilisation du CUMP** pour valorisation
4. ✅ **Synchronisation des comptages** ← Cette correction

Le système de synchronisation des inventaires est maintenant complet.

## Note sur la performance

### Fréquence des comptages
Dans un inventaire typique :
- 50 à 500 produits à compter
- 1 comptage par produit en moyenne
- Durée : 10 minutes à 2 heures

### Impact sur la sync queue
- Maximum ~500 entrées en queue pour un inventaire complet
- Sync par batch toutes les 30 secondes
- ≈ 17 syncs pour un inventaire de 500 produits
- Temps total de synchronisation : ~8-10 minutes

Cela reste très acceptable et n'impacte pas les performances.
