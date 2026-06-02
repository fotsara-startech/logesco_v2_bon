# Corrections des Mouvements de Stock - Snapshots stockInitial et stockFinal

## Résumé
Toutes les routes et modèles créant des mouvements de stock ont été corrigés pour enregistrer `stockInitial` et `stockFinal`, permettant ainsi d'afficher correctement l'historique des stocks.

## Migration
- ✅ Migration appliquée: `20260602145015_add_stock_snapshots`
- Colonnes ajoutées à `mouvements_stock`:
  - `stock_initial` (INTEGER DEFAULT 0)
  - `stock_final` (INTEGER DEFAULT 0)

## Fichiers Modifiés

### 1. Backend Routes

#### `backend/src/routes/sales.js`
- **POST /sales** - Création de vente: Ajout de `stockInitial` et `stockFinal`
  - Capture le stock avant la vente
  - Calcule le stock après la déduction
  - Enregistre les snapshots dans le mouvement
  
- **POST /sales/:id/cancel** - Annulation de vente: Ajout de `stockInitial` et `stockFinal`
  - Capture le stock avant la restauration
  - Calcule le stock après l'ajout
  - Enregistre les snapshots pour le mouvement de retour

#### `backend/src/routes/procurement.js`
- **POST /commandes/:id/receive** - Réception de commande: Changement de `createMany` à création individuelle
  - Récupère le stock avant chaque réception
  - Calcule le stock après l'ajout
  - Crée chaque mouvement avec snapshots
  - Suppression de la boucle `createMany` (impossible avec snapshots)

#### `backend/src/routes/stock-inventory.js`
- **POST /inventory/:id/count** - Clôture d'inventaire: Ajout de `stockInitial` et `stockFinal`
  - Capture le stock avant l'ajustement
  - Calcule le stock après l'ajustement
  - Enregistre les snapshots pour chaque écart détecté

#### `backend/src/routes/boutiques.js`
- **POST /transfer** - Transfert de stock entre boutiques: Ajout de `stockInitial` et `stockFinal`
  - Capture les stocks source et destination avant les mouvements
  - Calcule les stocks source et destination après les mouvements
  - Enregistre les snapshots pour les deux mouvements (sortie et entrée)

### 2. Backend Models

#### `backend/src/models/index.js`
- **adjustStock()** - Méthode d'ajustement de stock: Ajout de `stockInitial` et `stockFinal`
- **createSale()** - Création de vente: Ajout de `stockInitial` et `stockFinal`
- **Reception stock** (ligne ~574): Ajout de `stockInitial` et `stockFinal`

### 3. Frontend Models

#### `logesco_v2/lib/features/inventory/models/stock_model.dart`
- Propriétés `stockInitial` et `stockFinal` ajoutées à la classe `StockMovement`
- Utilise maintenant ces snapshots au lieu de les calculer

#### `logesco_v2/lib/features/inventory/widgets/stock_movements_getx_view.dart`
- Widget affichage historique: Utilise maintenant les snapshots du serveur
- Format: `Stock: 0 → +8 → 8` (au lieu de `Stock: 0 +8 +8`)
- Affichage amélioré et plus clair

## Vérification

Pour tester que les corrections fonctionnent correctement:

1. Créer un nouveau mouvement (achat, vente, transfert, ou inventaire)
2. Vérifier dans la base de données que `stockInitial` et `stockFinal` sont populés
3. Afficher l'historique des mouvements et vérifier que les snapshots sont corrects
4. Confirmer que le calcul `stockFinal - stockInitial = changementQuantite`

## Notes

- Les mouvements créés avant cette correction auront `stockInitial = 0` et `stockFinal = 0`, ce qui est acceptable
- Les nouveaux mouvements afficheront les snapshots corrects
- La migration SQLite est compatible avec SQLite (pas de `IF NOT EXISTS` en une seule ligne)
- Toutes les créations de mouvements utilisent des transactions atomiques pour garantir la cohérence

## Tests Effectués

- Migration: ✅ Appliquée avec succès
- Routes corrigées: ✅ 5 routes (sales x2, procurement, inventory, boutiques)
- Modèles corrigés: ✅ 3 méthodes (adjustStock, createSale, reception)
- Frontend: ✅ Affichage des snapshots
