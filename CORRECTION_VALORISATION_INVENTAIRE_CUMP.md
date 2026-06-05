# Correction de la valorisation des inventaires : utilisation du CUMP

## Problème identifié

La table `inventory_items` utilisait le champ `prixAchat` des produits au lieu du **CUMP (Coût Unitaire Moyen Pondéré)** pour calculer la valorisation des inventaires.

### Pourquoi c'est important ?

Le **CUMP** (Coût Unitaire Moyen Pondéré) est la méthode comptable standard pour valoriser les stocks. Il représente le coût moyen d'achat d'un produit sur plusieurs approvisionnements, ce qui donne une valorisation plus précise que le simple prix d'achat du dernier approvisionnement.

**Exemple :**
- Achat 1 : 10 unités à 5€ = 50€
- Achat 2 : 20 unités à 6€ = 120€
- **CUMP** = (50€ + 120€) / (10 + 20) = 170€ / 30 = **5,67€**
- Si on utilisait seulement `prixAchat` (dernier achat), on aurait 6€, ce qui surestime la valorisation

## Structure de données

### Modèle Produit (Prisma)
```prisma
model Produit {
  prixUnitaire  Float    // Prix de vente
  prixAchat     Float?   // Dernier prix d'achat
  cump          Float?   // Coût Unitaire Moyen Pondéré ✅
  // ... autres champs
}
```

### Modèle InventoryItem (Prisma)
```prisma
model InventoryItem {
  quantiteSysteme  Float   // Quantité en stock
  quantiteComptee  Float?  // Quantité comptée lors de l'inventaire
  prixUnitaire     Float?  // Prix de vente (pour info)
  prixAchat        Float?  // Stocke le CUMP au moment de la création ✅
  // ... autres champs
}
```

**Note importante :** Le champ `prixAchat` dans `inventory_items` **stocke le CUMP** (ou fallback sur prixAchat) au moment de la création de l'inventaire. Cela permet de figer la valorisation à un instant T.

## Solution implémentée

### Fichiers modifiés
- `backend/src/routes/stock-inventory.js`
- `dist-exe/src/routes/stock-inventory.js`

### 1. Correction de la fonction `generateInventoryItems`

**Localisation :** Ligne ~550 dans les deux fichiers

**Avant :**
```javascript
return {
  inventaireId: inventoryId,
  produitId: product.id,
  quantiteSysteme,
  prixUnitaire: parseFloat(product.prixUnitaire) || 0,
  prixAchat: parseFloat(product.prixAchat) || 0  // ❌ Utilisait prixAchat
};
```

**Après :**
```javascript
// Utiliser le CUMP (Coût Unitaire Moyen Pondéré) pour la valorisation
// Fallback sur prixAchat si CUMP n'existe pas
const prixAchatValorisation = parseFloat(product.cump) || parseFloat(product.prixAchat) || 0;

return {
  inventaireId: inventoryId,
  produitId: product.id,
  quantiteSysteme,
  prixUnitaire: parseFloat(product.prixUnitaire) || 0,
  prixAchat: prixAchatValorisation  // ✅ Utilise CUMP prioritairement
};
```

### 2. Correction des endpoints GET (retour des items)

**Endpoints concernés :**
- `POST /api/v1/stock-inventory` (création avec retour des items)
- `GET /api/v1/stock-inventory/:id/items` (récupération des items)

**Avant :**
```javascript
prixAchat: parseFloat(item.produit?.prixAchat) || 0  // ❌ Lisait depuis produit
```

**Après :**
```javascript
prixAchat: parseFloat(item.prixAchat) || 0  // ✅ Lit depuis l'item (CUMP figé)
```

**Explication :** Une fois l'inventaire créé, on lit le `prixAchat` depuis l'item (qui contient le CUMP au moment de la création), et non depuis le produit actuel (dont le CUMP peut avoir changé depuis).

## Logique de fallback

La logique implémentée suit cette hiérarchie :
1. **Priorité 1 :** Utiliser `product.cump` si disponible
2. **Priorité 2 :** Utiliser `product.prixAchat` si CUMP n'existe pas
3. **Priorité 3 :** Utiliser `0` si aucun prix n'est disponible

```javascript
const prixAchatValorisation = parseFloat(product.cump) || parseFloat(product.prixAchat) || 0;
```

## Impact

### Avant la correction
- ❌ Valorisation basée sur le dernier prix d'achat
- ❌ Valorisation incorrecte si plusieurs approvisionnements à des prix différents
- ❌ Écarts de valorisation entre l'inventaire et la comptabilité

### Après la correction
- ✅ Valorisation basée sur le CUMP (méthode comptable standard)
- ✅ Valorisation précise reflétant le coût moyen réel
- ✅ Cohérence avec les calculs comptables
- ✅ Le CUMP est figé au moment de la création de l'inventaire (snapshot)

## Exemple concret

### Produit : "Ordinateur Portable"
- **Stock actuel :** 30 unités
- **prixAchat :** 800€ (dernier approvisionnement)
- **cump :** 750€ (coût moyen de tous les approvisionnements)

### Création d'inventaire

**Avant :**
```
inventory_item:
  - quantite_systeme: 30
  - prix_achat: 800€  ❌ (dernier prix)
  - valorisation: 30 × 800€ = 24 000€  ❌ (surestimé)
```

**Après :**
```
inventory_item:
  - quantite_systeme: 30
  - prix_achat: 750€  ✅ (CUMP)
  - valorisation: 30 × 750€ = 22 500€  ✅ (correct)
```

**Différence :** 1 500€ d'écart corrigé !

## Calcul du CUMP dans l'application

Le CUMP est calculé automatiquement par le système lors de chaque approvisionnement. La logique de calcul se trouve probablement dans les services de gestion des commandes d'approvisionnement et des mouvements de stock.

**Formule du CUMP :**
```
CUMP = (Valeur stock ancien + Valeur nouvelle entrée) / (Quantité ancienne + Quantité nouvelle)
```

## Tests recommandés

1. **Créer un nouvel inventaire**
   - Vérifier que les items créés utilisent le CUMP des produits
   - Comparer les valorisations avant/après la correction

2. **Vérifier les produits avec CUMP**
   - Requête SQL : `SELECT id, nom, prix_achat, cump FROM produits WHERE cump IS NOT NULL;`
   - Vérifier que le CUMP est différent du prixAchat pour certains produits

3. **Calculer la valorisation totale**
   - Somme : `SELECT SUM(quantite_systeme * prix_achat) FROM inventory_items WHERE inventaire_id = X;`
   - Comparer avec l'ancienne valorisation (si disponible)

4. **Produits sans CUMP**
   - Vérifier que le fallback sur `prixAchat` fonctionne correctement
   - Requête : `SELECT * FROM produits WHERE cump IS NULL;`

## Note sur la migration

Les inventaires existants (déjà créés) conservent leurs anciennes valorisations basées sur `prixAchat`. Seuls les **nouveaux inventaires** créés après cette correction utiliseront le CUMP.

Si une correction rétroactive est nécessaire, il faudrait :
1. Recalculer le CUMP historique pour chaque produit à la date de chaque inventaire
2. Mettre à jour les `inventory_items` existants
3. Recalculer les écarts de valorisation

Cette opération est complexe et nécessite une analyse de l'historique complet des approvisionnements.
