# Configuration de l'API Backend

## Endpoints requis pour le module Stock

### 1. Authentification
- `POST /api/v1/auth/login` - Connexion utilisateur
- `POST /api/v1/auth/refresh` - Rafraîchissement du token

### 2. Produits
- `GET /api/v1/products` - Liste des produits
  - Query params: `page`, `limit`, `search`, `isActive`
  - Response: 
    ```json
    {
      "data": [
        {
          "id": 1,
          "reference": "REF001",
          "nom": "iPhone 15 Pro",
          "description": "Smartphone Apple",
          "prixUnitaire": 1299.99,
          "prixAchat": 999.99,
          "codeBarre": "1234567890123",
          "categorie": "Smartphones",
          "seuilStockMinimum": 10,
          "estActif": true,
          "estService": false,
          "dateCreation": "2024-01-01T00:00:00Z",
          "dateModification": "2024-01-01T00:00:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 20,
        "total": 100,
        "pages": 5,
        "hasNext": true,
        "hasPrev": false
      }
    }
    ```

- `GET /api/v1/products/:id` - Détails d'un produit

### 3. Inventaire
- `GET /api/v1/inventory` - Liste des stocks
  - Query params: `page`, `limit`, `alerteStock`, `produitId`
  - Response:
    ```json
    {
      "data": [
        {
          "id": 1,
          "produitId": 1,
          "quantiteDisponible": 50,
          "quantiteReservee": 5,
          "derniereMaj": "2024-01-01T12:00:00Z",
          "stockFaible": false,
          "produit": {
            "id": 1,
            "reference": "REF001",
            "nom": "iPhone 15 Pro",
            "seuilStockMinimum": 10,
            "estActif": true
          }
        }
      ],
      "pagination": { ... }
    }
    ```

- `GET /api/v1/inventory/summary` - Résumé des stocks
- `GET /api/v1/inventory/movements` - Mouvements de stock
- `POST /api/v1/inventory/adjust` - Ajuster le stock
  - Body:
    ```json
    {
      "produitId": 1,
      "changementQuantite": 10,
      "notes": "Réception fournisseur"
    }
    ```

## Configuration de l'application

1. L'URL de base est configurée dans `lib/core/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:3002/api/v1';
   ```
   
   Modifiez cette URL selon votre serveur de production.

2. Assurez-vous que votre serveur accepte les requêtes CORS depuis votre application mobile.

3. Configurez l'authentification avec de vrais tokens JWT.

## Mode développement

Si votre API n'est pas encore prête, vous pouvez temporairement réactiver les données de test en modifiant:
```dart
static const bool useTestData = true;
```

## Headers requis

Toutes les requêtes authentifiées doivent inclure:
```
Authorization: Bearer <token>
Content-Type: application/json
```