# Route API: Commandes impayées des fournisseurs

## Endpoint créé

### GET `/accounts/suppliers/:id/unpaid-procurements`

Récupère la liste des commandes (approvisionnements) impayées d'un fournisseur.

## Paramètres

- **id** (path parameter): ID du fournisseur

## Réponse

### Succès (200)

```json
{
  "success": true,
  "message": "Commandes impayées récupérées avec succès",
  "data": [
    {
      "id": 123,
      "reference": "CMD20260222001",
      "dateCommande": "2026-02-22T10:00:00.000Z",
      "montantTotal": 100000,
      "montantPaye": 50000,
      "montantRestant": 50000,
      "nombreArticles": 10
    }
  ]
}
```

### Erreur (404)

```json
{
  "success": false,
  "message": "Fournisseur non trouvé"
}
```

### Erreur (500)

```json
{
  "success": false,
  "message": "Erreur lors de la récupération des commandes impayées"
}
```

## Logique métier

1. Récupère toutes les commandes du fournisseur où:
   - `montantRestant > 0`
   - `statut != 'annulee'`

2. Trie par date de commande décroissante (plus récentes en premier)

3. Retourne les informations essentielles:
   - Référence de la commande
   - Date de commande
   - Montants (total, payé, restant)
   - Nombre d'articles

## Utilisation dans le frontend

Cette route est appelée par:
- `ApiSupplierService.getUnpaidProcurements(supplierId)`
- Utilisée dans `UnpaidProcurementsSelectorDialog`
- Permet de sélectionner une commande spécifique à payer

## Fichier modifié

- `backend/src/routes/accounts.js`: Ajout de la route après `/suppliers/:id/transactions`

## Redémarrage requis

Après l'ajout de cette route, le backend doit être redémarré:

```bash
cd backend
npm start
```

## Test de la route

Vous pouvez tester la route avec:

```bash
curl -X GET http://localhost:3002/api/v1/accounts/suppliers/10/unpaid-procurements \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Cohérence avec les clients

Cette route suit exactement le même pattern que:
- `/accounts/customers/:id/unpaid-sales` pour les clients

Cela garantit une API cohérente et prévisible.
