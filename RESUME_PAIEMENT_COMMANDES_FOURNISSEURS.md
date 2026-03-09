# Résumé: Paiement de commandes spécifiques aux fournisseurs

## Fonctionnalité implémentée

Ajout de la possibilité de payer une commande spécifique d'un fournisseur, exactement comme pour les clients avec les ventes impayées.

## Composants créés

### 1. Modèle `UnpaidProcurement`
Représente une commande impayée avec:
- ID et référence de la commande
- Date de commande
- Montant total, montant payé, montant restant
- Nombre d'articles
- Méthodes de formatage pour l'affichage

### 2. Widget `UnpaidProcurementsSelectorDialog`
Dialog de sélection des commandes impayées:
- Liste toutes les commandes impayées du fournisseur
- Permet de sélectionner une commande via radio button
- Affiche les détails complets de chaque commande
- Pré-remplit le montant avec le reste à payer
- Valide que le montant ne dépasse pas le reste

### 3. Méthodes de service
- `getUnpaidProcurements(supplierId)`: Récupère les commandes impayées
- `paySupplierForProcurement(supplierId, montant, procurementId)`: Paie une commande spécifique

### 4. Méthodes de contrôleur
- `paySupplierForProcurement()`: Gère le paiement d'une commande avec feedback utilisateur

## Flux utilisateur

1. L'utilisateur ouvre le compte d'un fournisseur
2. Il clique sur "Payer le fournisseur"
3. Dans le dialog, il coche "Payer une commande spécifique"
4. Il clique sur "Sélectionner une commande"
5. Un nouveau dialog s'ouvre avec la liste des commandes impayées
6. Il sélectionne une commande
7. Le montant et la description sont automatiquement remplis
8. Il peut ajuster le montant (paiement partiel)
9. Il confirme le paiement
10. La transaction est enregistrée avec la référence de la commande
11. Le solde et les transactions sont mis à jour

## Différences avec le paiement général

### Paiement général
```json
{
  "montant": 50000,
  "typeTransaction": "paiement",
  "description": "Paiement partiel"
}
```

### Paiement d'une commande
```json
{
  "montant": 50000,
  "typeTransaction": "paiement",
  "referenceType": "approvisionnement",
  "referenceId": 123,
  "description": "Paiement Commande #CMD001"
}
```

La différence clé est l'ajout de `referenceType` et `referenceId` qui permettent de lier le paiement à une commande spécifique.

## Avantages

1. **Traçabilité**: Chaque paiement est lié à une commande spécifique
2. **Gestion précise**: Permet de suivre quelles commandes sont payées
3. **Paiements partiels**: Possibilité de payer une commande en plusieurs fois
4. **Cohérence**: Même logique que pour les clients
5. **Historique clair**: Les transactions affichent la référence de la commande

## Endpoint backend requis

L'endpoint `/accounts/suppliers/:supplierId/unpaid-procurements` doit être implémenté dans le backend pour retourner:

```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "reference": "CMD001",
      "dateCommande": "2026-02-20T10:00:00Z",
      "montantTotal": 100000,
      "montantPaye": 50000,
      "montantRestant": 50000,
      "nombreArticles": 10
    }
  ]
}
```

## Cohérence avec les clients

Cette implémentation suit exactement le même pattern que:
- `UnpaidSale` → `UnpaidProcurement`
- `UnpaidSalesSelectorDialog` → `UnpaidProcurementsSelectorDialog`
- `payCustomerDebtForSale()` → `paySupplierForProcurement()`

Cela garantit une expérience utilisateur uniforme et facilite la maintenance du code.
