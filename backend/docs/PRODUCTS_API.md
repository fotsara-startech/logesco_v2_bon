# API Produits - LOGESCO v2

## Vue d'ensemble

L'API des produits fournit des endpoints CRUD complets pour la gestion des produits avec recherche avancée, filtrage, pagination et validation stricte.

## Base URL
```
http://localhost:8080/api/v1/products
```

## Authentification

La plupart des endpoints nécessitent une authentification JWT. Incluez le token dans le header :
```
Authorization: Bearer <access_token>
```

## Endpoints

### 1. Liste des produits - `GET /products`

Récupère la liste des produits avec recherche, filtrage et pagination.

**Paramètres de requête :**
- `page` (optionnel) - Numéro de page (défaut: 1)
- `limit` (optionnel) - Nombre d'éléments par page (défaut: 20, max: 100)
- `q` (optionnel) - Terme de recherche (nom, référence)
- `categorie` (optionnel) - Filtrer par catégorie
- `estActif` (optionnel) - Filtrer par statut actif (true/false)

**Exemple de requête :**
```bash
GET /products?page=1&limit=10&q=ordinateur&categorie=Informatique&estActif=true
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Produits récupérés avec succès",
  "data": [
    {
      "id": 1,
      "reference": "ORD001",
      "nom": "Ordinateur portable",
      "description": "Ordinateur portable 15 pouces",
      "prixUnitaire": 1200.00,
      "categorie": "Informatique",
      "seuilStockMinimum": 5,
      "estActif": true,
      "dateCreation": "2024-01-01T00:00:00.000Z",
      "dateModification": "2024-01-01T00:00:00.000Z",
      "stock": {
        "id": 1,
        "produitId": 1,
        "quantiteDisponible": 15,
        "quantiteReservee": 2,
        "quantiteTotale": 17,
        "derniereMaj": "2024-01-01T00:00:00.000Z",
        "stockFaible": false
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "totalPages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### 2. Détails d'un produit - `GET /products/:id`

Récupère les détails d'un produit spécifique.

**Paramètres :**
- `id` (requis) - ID du produit

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Produit récupéré avec succès",
  "data": {
    "id": 1,
    "reference": "ORD001",
    "nom": "Ordinateur portable",
    "description": "Ordinateur portable 15 pouces",
    "prixUnitaire": 1200.00,
    "categorie": "Informatique",
    "seuilStockMinimum": 5,
    "estActif": true,
    "dateCreation": "2024-01-01T00:00:00.000Z",
    "dateModification": "2024-01-01T00:00:00.000Z",
    "stock": {
      "quantiteDisponible": 15,
      "quantiteReservee": 2,
      "stockFaible": false
    }
  }
}
```

**Erreurs :**
- `404` - Produit non trouvé

### 3. Créer un produit - `POST /products` 🔒

Crée un nouveau produit avec stock initial.

**Authentification requise**

**Corps de la requête :**
```json
{
  "reference": "ORD002",
  "nom": "Ordinateur de bureau",
  "description": "Ordinateur de bureau haute performance",
  "prixUnitaire": 1500.00,
  "categorie": "Informatique",
  "seuilStockMinimum": 3
}
```

**Validation :**
- `reference` - Requis, unique, 1-50 caractères alphanumériques
- `nom` - Requis, 1-100 caractères
- `description` - Optionnel, max 500 caractères
- `prixUnitaire` - Requis, nombre positif avec 2 décimales max
- `categorie` - Optionnel, max 50 caractères
- `seuilStockMinimum` - Optionnel, entier positif (défaut: 0)

**Réponse (201) :**
```json
{
  "success": true,
  "message": "Produit créé avec succès",
  "data": {
    "id": 2,
    "reference": "ORD002",
    "nom": "Ordinateur de bureau",
    "description": "Ordinateur de bureau haute performance",
    "prixUnitaire": 1500.00,
    "categorie": "Informatique",
    "seuilStockMinimum": 3,
    "estActif": true,
    "dateCreation": "2024-01-01T00:00:00.000Z",
    "dateModification": "2024-01-01T00:00:00.000Z",
    "stock": {
      "quantiteDisponible": 0,
      "quantiteReservee": 0,
      "stockFaible": true
    }
  }
}
```

**Erreurs :**
- `400` - Données de validation invalides
- `401` - Non authentifié
- `409` - Référence déjà utilisée

### 4. Mettre à jour un produit - `PUT /products/:id` 🔒

Met à jour un produit existant.

**Authentification requise**

**Paramètres :**
- `id` (requis) - ID du produit

**Corps de la requête :**
```json
{
  "nom": "Ordinateur portable gaming",
  "description": "Ordinateur portable pour jeux",
  "prixUnitaire": 1800.00,
  "categorie": "Gaming"
}
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Produit mis à jour avec succès",
  "data": {
    "id": 1,
    "reference": "ORD001",
    "nom": "Ordinateur portable gaming",
    "description": "Ordinateur portable pour jeux",
    "prixUnitaire": 1800.00,
    "categorie": "Gaming",
    "seuilStockMinimum": 5,
    "estActif": true,
    "dateCreation": "2024-01-01T00:00:00.000Z",
    "dateModification": "2024-01-01T12:00:00.000Z"
  }
}
```

**Erreurs :**
- `400` - Données invalides
- `401` - Non authentifié
- `404` - Produit non trouvé
- `409` - Référence déjà utilisée

### 5. Supprimer un produit - `DELETE /products/:id` 🔒

Supprime ou désactive un produit.

**Authentification requise**

**Paramètres :**
- `id` (requis) - ID du produit

**Comportement :**
- Si le produit a des transactions liées → **Soft delete** (désactivation)
- Si aucune transaction → **Suppression complète**

**Réponse (200) - Suppression complète :**
```json
{
  "success": true,
  "message": "Produit supprimé avec succès"
}
```

**Réponse (200) - Soft delete :**
```json
{
  "success": true,
  "message": "Produit désactivé (des transactions existent)",
  "data": {
    "id": 1,
    "estActif": false
  }
}
```

**Erreurs :**
- `401` - Non authentifié
- `404` - Produit non trouvé

### 6. Suggestions de recherche - `GET /products/search/suggestions`

Fournit des suggestions pour l'autocomplétion.

**Paramètres de requête :**
- `q` (requis) - Terme de recherche (min 2 caractères)

**Exemple :**
```bash
GET /products/search/suggestions?q=ord
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Suggestions récupérées",
  "data": [
    {
      "id": 1,
      "reference": "ORD001",
      "nom": "Ordinateur portable",
      "prixUnitaire": 1200.00
    },
    {
      "id": 2,
      "reference": "ORD002",
      "nom": "Ordinateur de bureau",
      "prixUnitaire": 1500.00
    }
  ]
}
```

### 7. Liste des catégories - `GET /products/categories`

Récupère la liste des catégories de produits disponibles.

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Catégories récupérées",
  "data": [
    "Informatique",
    "Gaming",
    "Bureautique",
    "Électronique"
  ]
}
```

### 8. Produits en stock faible - `GET /products/low-stock` 🔒

Récupère les produits dont le stock est inférieur au seuil minimum.

**Authentification requise**

**Paramètres de requête :**
- `page` (optionnel) - Numéro de page (défaut: 1)
- `limit` (optionnel) - Nombre d'éléments par page (défaut: 20)

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Produits en stock faible récupérés",
  "data": [
    {
      "id": 3,
      "reference": "TAB001",
      "nom": "Tablette",
      "stock": {
        "quantiteDisponible": 2,
        "seuilStockMinimum": 5,
        "stockFaible": true
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```

## Codes d'erreur

### Erreurs de validation (400)
```json
{
  "success": false,
  "message": "Données de validation invalides",
  "errors": [
    {
      "field": "reference",
      "message": "La référence est requise",
      "value": ""
    },
    {
      "field": "prixUnitaire",
      "message": "Le prix doit être positif",
      "value": -100
    }
  ]
}
```

### Erreur d'authentification (401)
```json
{
  "success": false,
  "message": "Token invalide ou expiré"
}
```

### Produit non trouvé (404)
```json
{
  "success": false,
  "message": "Produit non trouvé"
}
```

### Conflit de référence (409)
```json
{
  "success": false,
  "message": "Cette référence produit existe déjà"
}
```

### Erreur serveur (500)
```json
{
  "success": false,
  "message": "Erreur lors de la création du produit"
}
```

## Exemples d'utilisation

### Recherche avancée
```bash
# Rechercher des ordinateurs en informatique
GET /products?q=ordinateur&categorie=Informatique&estActif=true&page=1&limit=10

# Produits avec stock faible
GET /products/low-stock?page=1&limit=20

# Suggestions pour autocomplétion
GET /products/search/suggestions?q=ord
```

### Création complète
```bash
curl -X POST http://localhost:8080/api/v1/products \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "reference": "LAPTOP001",
    "nom": "Laptop Dell XPS 13",
    "description": "Ultrabook haute performance",
    "prixUnitaire": 1299.99,
    "categorie": "Informatique",
    "seuilStockMinimum": 5
  }'
```

### Mise à jour partielle
```bash
curl -X PUT http://localhost:8080/api/v1/products/1 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "prixUnitaire": 1199.99,
    "description": "Prix réduit - Ultrabook haute performance"
  }'
```

## Intégration avec le stock

Chaque produit est automatiquement lié à son stock :
- **Création** → Stock initial à 0
- **Consultation** → Informations de stock incluses
- **Alertes** → Détection automatique du stock faible
- **Suppression** → Vérification des transactions liées

## Bonnes pratiques

1. **Références uniques** - Utilisez un système de référencement cohérent
2. **Pagination** - Limitez les résultats pour de meilleures performances
3. **Recherche** - Utilisez les suggestions pour l'UX
4. **Validation** - Vérifiez toujours les erreurs de validation
5. **Authentification** - Gérez l'expiration des tokens
6. **Stock** - Surveillez les alertes de stock faible

## Rate Limiting

- **Général** : 100 requêtes / 15 minutes par utilisateur authentifié
- **Création/Modification** : Incluses dans la limite générale
- **Recherche** : Pas de limite spécifique (incluse dans la limite générale)