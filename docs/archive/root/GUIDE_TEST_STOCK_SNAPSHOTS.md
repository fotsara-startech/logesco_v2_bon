# Guide de Test - Snapshots Stock Initial/Final

## Étape 1: Vérifier la Migration
```bash
cd backend
npx prisma migrate status
```
Vous devriez voir: `1 migration found in prisma/migrations` (la migration `20260602145015_add_stock_snapshots` doit être appliquée)

## Étape 2: Redémarrer le Backend
```bash
# Redémarrer le serveur backend
npm run dev
```

## Étape 3: Tester avec un Achat/Approvisionnement

1. Ouvrir l'application mobile
2. Aller à **Approvisionnement** → **Nouvelles Commandes**
3. Créer une commande d'approvisionnement avec au moins 1 produit
4. Valider et recevoir la commande (cliquer sur "Recevoir")
5. Vérifier dans la base de données:

```sql
-- Exécuter sur la base sqlite
SELECT id, produit_id, type_mouvement, changement_quantite, stock_initial, stock_final 
FROM mouvements_stock 
WHERE type_reference = 'approvisionnement'
ORDER BY date_mouvement DESC
LIMIT 5;
```

**Résultat attendu:**
- `stock_initial`: Valeur du stock avant l'approvisionnement
- `stock_final`: Valeur du stock après l'approvisionnement
- `stock_final - stock_initial`: Doit égaler `changement_quantite`

**Exemple:**
```
id | produit_id | type_mouvement | changement_quantite | stock_initial | stock_final
1  | 5          | achat          | 10                  | 5             | 15
```

## Étape 4: Tester avec une Vente

1. Ouvrir l'application mobile
2. Aller à **Ventes** → **Créer Vente**
3. Ajouter un produit (vérifier que le stock initial est correct)
4. Valider la vente
5. Vérifier dans la base de données:

```sql
SELECT id, produit_id, type_mouvement, changement_quantite, stock_initial, stock_final 
FROM mouvements_stock 
WHERE type_reference = 'vente'
ORDER BY date_mouvement DESC
LIMIT 5;
```

**Résultat attendu:**
- `stock_initial`: Valeur du stock avant la vente
- `stock_final`: Valeur du stock après la vente (inférieur à `stock_initial`)
- `stock_final - stock_initial`: Doit égaler `changement_quantite` (négatif)

## Étape 5: Tester avec un Transfert

1. Ouvrir l'application mobile
2. Aller à **Boutiques** → **Transfert de Stock**
3. Créer un transfert d'une boutique à une autre
4. Vérifier dans la base de données:

```sql
SELECT id, produit_id, boutique_id, type_mouvement, changement_quantite, stock_initial, stock_final 
FROM mouvements_stock 
WHERE type_reference = 'transfert'
ORDER BY date_mouvement DESC
LIMIT 10;
```

**Résultat attendu:**
- 2 mouvements pour chaque transfert (TRANSFERT_SORTIE et TRANSFERT_ENTREE)
- TRANSFERT_SORTIE: `changement_quantite` négatif, `stock_final < stock_initial`
- TRANSFERT_ENTREE: `changement_quantite` positif, `stock_final > stock_initial`

## Étape 6: Vérifier l'Affichage Frontend

1. Ouvrir l'application mobile
2. Aller à **Inventaire** → **Mouvements**
3. Afficher l'historique des mouvements
4. Vérifier que le format affichage est: **Stock: X → ±Y → Z**

Exemple:
```
Stock: 5 → +10 → 15  (Achat de 10 unités)
Stock: 15 → -5 → 10  (Vente de 5 unités)
```

## Étape 7: Tester avec un Inventaire

1. Ouvrir l'application mobile
2. Aller à **Inventaire** → **Nouveau Comptage**
3. Créer un inventaire et ajouter des écarts (ex: système 10, compté 8)
4. Clôturer l'inventaire
5. Vérifier dans la base de données:

```sql
SELECT id, produit_id, type_mouvement, changement_quantite, stock_initial, stock_final 
FROM mouvements_stock 
WHERE type_reference = 'inventaire'
ORDER BY date_mouvement DESC
LIMIT 5;
```

**Résultat attendu:**
- Pour un écart détecté: `changement_quantite` doit être l'écart détecté
- `stock_final - stock_initial = changement_quantite`

## Validation Finale

Tous les tests doivent satisfaire cette équation:
```
stock_final = stock_initial + changement_quantite
```

Si cette équation n'est pas respectée, il y a un bug à corriger.

## Données de Test Recommandées

Pour tester complètement, créer des mouvements de différents types:

| Type | Stock Initial | Changement | Stock Final | Notes |
|------|---------------|-----------|-----------|-------|
| Achat | 10 | +5 | 15 | Augmentation |
| Vente | 15 | -3 | 12 | Diminution |
| Transfert OUT | 12 | -4 | 8 | Sortie |
| Transfert IN | 20 | +4 | 24 | Entrée |
| Inventaire ajust | 8 | +2 | 10 | Correction |

## Dépannage

Si les snapshots ne sont pas populés:

1. Vérifier que la migration a bien été appliquée:
   ```bash
   cd backend
   npx prisma db push
   ```

2. Vérifier que les changements de code ont bien été déployés

3. Vérifier les logs du backend pour les erreurs

4. Réinitialiser la base de données (développement uniquement):
   ```bash
   npx prisma migrate reset
   ```
