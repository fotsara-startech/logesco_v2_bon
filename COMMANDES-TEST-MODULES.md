# Guide de Test des Modules LOGESCO v2 - Postman & cURL

## 🚀 Configuration Préalable

**URL de base :** `http://localhost:8080`

**Headers requis pour les requêtes authentifiées :**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

---

## 1. MODULE AUTHENTIFICATION (`/auth`)

### 1.1 Inscription d'un utilisateur
**Postman :**
```
POST http://localhost:8080/auth/register
Content-Type: application/json

{
  "nomUtilisateur": "testuser",
  "email": "test@example.com",
  "motDePasse": "MotDePasseSecurise123!",
  "nom": "Dupont",
  "prenom": "Jean"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nomUtilisateur": "testuser",
    "email": "test@example.com",
    "motDePasse": "MotDePasseSecurise123!",
    "nom": "Dupont",
    "prenom": "Jean"
  }'
```

### 1.2 Connexion
**Postman :**
```
POST http://localhost:8080/auth/login
Content-Type: application/json

{
  "nomUtilisateur": "testuser",
  "motDePasse": "MotDePasseSecurise123!"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "nomUtilisateur": "testuser",
    "motDePasse": "MotDePasseSecurise123!"
  }'
```

### 1.3 Rafraîchir le token
**Postman :**
```
POST http://localhost:8080/auth/refresh
Content-Type: application/json

{
  "refreshToken": "YOUR_REFRESH_TOKEN"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

### 1.4 Informations utilisateur
**Postman :**
```
GET http://localhost:8080/auth/me
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 1.5 Vérifier le token
**Postman :**
```
GET http://localhost:8080/auth/verify
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/auth/verify \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 1.6 Changer le mot de passe
**Postman :**
```
POST http://localhost:8080/auth/change-password
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "ancienMotDePasse": "MotDePasseSecurise123!",
  "nouveauMotDePasse": "NouveauMotDePasse456!"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/auth/change-password \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ancienMotDePasse": "MotDePasseSecurise123!",
    "nouveauMotDePasse": "NouveauMotDePasse456!"
  }'
```

### 1.7 Déconnexion
**Postman :**
```
POST http://localhost:8080/auth/logout
Content-Type: application/json

{
  "refreshToken": "YOUR_REFRESH_TOKEN"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/auth/logout \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

---

## 2. MODULE CLIENTS (`/customers`)

### 2.1 Lister tous les clients
**Postman :**
```
GET http://localhost:8080/customers?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/customers?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2.2 Rechercher des clients
**Postman :**
```
GET http://localhost:8080/customers?q=Dupont&page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/customers?q=Dupont&page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2.3 Créer un client
**Postman :**
```
POST http://localhost:8080/customers
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "nom": "Martin",
  "prenom": "Marie",
  "telephone": "0123456789",
  "email": "marie.martin@email.com",
  "adresse": "123 Rue de la Paix",
  "ville": "Lyon",
  "codePostal": "69000",
  "typeClient": "particulier"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/customers \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Martin",
    "prenom": "Marie",
    "telephone": "0123456789",
    "email": "marie.martin@email.com",
    "adresse": "123 Rue de la Paix",
    "ville": "Lyon",
    "codePostal": "69000",
    "typeClient": "particulier"
  }'
```

### 2.4 Récupérer un client par ID
**Postman :**
```
GET http://localhost:8080/customers/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/customers/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2.5 Mettre à jour un client
**Postman :**
```
PUT http://localhost:8080/customers/1
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "nom": "Martin",
  "prenom": "Marie-Claire",
  "telephone": "0123456789",
  "email": "marie.martin@email.com"
}
```

**cURL :**
```bash
curl -X PUT http://localhost:8080/customers/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Martin",
    "prenom": "Marie-Claire",
    "telephone": "0123456789",
    "email": "marie.martin@email.com"
  }'
```

### 2.6 Supprimer un client
**Postman :**
```
DELETE http://localhost:8080/customers/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X DELETE http://localhost:8080/customers/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2.7 Suggestions de recherche
**Postman :**
```
GET http://localhost:8080/customers/search/suggestions?q=Mar
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/customers/search/suggestions?q=Mar" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2.8 Historique des ventes d'un client
**Postman :**
```
GET http://localhost:8080/customers/1/sales?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/customers/1/sales?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2.9 Compte d'un client
**Postman :**
```
GET http://localhost:8080/customers/1/account
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/customers/1/account \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 3. MODULE FOURNISSEURS (`/suppliers`)

### 3.1 Lister tous les fournisseurs
**Postman :**
```
GET http://localhost:8080/suppliers?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/suppliers?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3.2 Créer un fournisseur
**Postman :**
```
POST http://localhost:8080/suppliers
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "nom": "TechSupply SARL",
  "personneContact": "Jean Dupont",
  "telephone": "0145678901",
  "email": "contact@techsupply.com",
  "adresse": "456 Avenue des Entreprises",
  "ville": "Paris",
  "codePostal": "75001",
  "pays": "France"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/suppliers \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "TechSupply SARL",
    "personneContact": "Jean Dupont",
    "telephone": "0145678901",
    "email": "contact@techsupply.com",
    "adresse": "456 Avenue des Entreprises",
    "ville": "Paris",
    "codePostal": "75001",
    "pays": "France"
  }'
```

### 3.3 Récupérer un fournisseur par ID
**Postman :**
```
GET http://localhost:8080/suppliers/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/suppliers/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3.4 Mettre à jour un fournisseur
**Postman :**
```
PUT http://localhost:8080/suppliers/1
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "nom": "TechSupply Pro SARL",
  "personneContact": "Jean Dupont",
  "telephone": "0145678901",
  "email": "contact@techsupply.com"
}
```

**cURL :**
```bash
curl -X PUT http://localhost:8080/suppliers/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "TechSupply Pro SARL",
    "personneContact": "Jean Dupont",
    "telephone": "0145678901",
    "email": "contact@techsupply.com"
  }'
```

### 3.5 Supprimer un fournisseur
**Postman :**
```
DELETE http://localhost:8080/suppliers/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X DELETE http://localhost:8080/suppliers/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3.6 Suggestions de recherche fournisseurs
**Postman :**
```
GET http://localhost:8080/suppliers/search/suggestions?q=Tech
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/suppliers/search/suggestions?q=Tech" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3.7 Historique des commandes d'un fournisseur
**Postman :**
```
GET http://localhost:8080/suppliers/1/orders?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/suppliers/1/orders?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 4. MODULE PRODUITS (`/products`)

### 4.1 Lister tous les produits
**Postman :**
```
GET http://localhost:8080/products?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/products?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4.2 Rechercher des produits
**Postman :**
```
GET http://localhost:8080/products?q=MacBook&categorie=Informatique&page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/products?q=MacBook&categorie=Informatique&page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4.3 Créer un produit
**Postman :**
```
POST http://localhost:8080/products
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "reference": "MAC-PRO-16-2024",
  "nom": "MacBook Pro 16 M3 Pro",
  "description": "MacBook Pro 16 pouces avec puce M3 Pro",
  "categorie": "Informatique",
  "prixUnitaire": 2899.00,
  "seuilStockMinimum": 5,
  "estActif": true,
  "quantiteInitiale": 10
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/products \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reference": "MAC-PRO-16-2024",
    "nom": "MacBook Pro 16 M3 Pro",
    "description": "MacBook Pro 16 pouces avec puce M3 Pro",
    "categorie": "Informatique",
    "prixUnitaire": 2899.00,
    "seuilStockMinimum": 5,
    "estActif": true,
    "quantiteInitiale": 10
  }'
```

### 4.4 Récupérer un produit par ID
**Postman :**
```
GET http://localhost:8080/products/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/products/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4.5 Mettre à jour un produit
**Postman :**
```
PUT http://localhost:8080/products/1
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "nom": "MacBook Pro 16 M3 Pro - Édition 2024",
  "prixUnitaire": 2799.00,
  "description": "MacBook Pro 16 pouces avec puce M3 Pro - Nouvelle édition"
}
```

**cURL :**
```bash
curl -X PUT http://localhost:8080/products/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "MacBook Pro 16 M3 Pro - Édition 2024",
    "prixUnitaire": 2799.00,
    "description": "MacBook Pro 16 pouces avec puce M3 Pro - Nouvelle édition"
  }'
```

### 4.6 Supprimer un produit
**Postman :**
```
DELETE http://localhost:8080/products/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X DELETE http://localhost:8080/products/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4.7 Suggestions de recherche produits
**Postman :**
```
GET http://localhost:8080/products/search/suggestions?q=Mac
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/products/search/suggestions?q=Mac" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4.8 Liste des catégories
**Postman :**
```
GET http://localhost:8080/products/categories
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/products/categories \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4.9 Produits en stock faible
**Postman :**
```
GET http://localhost:8080/products/low-stock?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/products/low-stock?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 5. MODULE INVENTAIRE/STOCK (`/inventory`)

### 5.1 Lister tous les stocks
**Postman :**
```
GET http://localhost:8080/inventory?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/inventory?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 5.2 Stock d'un produit spécifique
**Postman :**
```
GET http://localhost:8080/inventory/1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/inventory/1 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 5.3 Ajuster le stock d'un produit
**Postman :**
```
POST http://localhost:8080/inventory/adjust
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "produitId": 1,
  "changementQuantite": 5,
  "notes": "Réapprovisionnement manuel"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/inventory/adjust \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "produitId": 1,
    "changementQuantite": 5,
    "notes": "Réapprovisionnement manuel"
  }'
```

### 5.4 Alertes de stock
**Postman :**
```
GET http://localhost:8080/inventory/alerts?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/inventory/alerts?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 5.5 Mouvements de stock
**Postman :**
```
GET http://localhost:8080/inventory/movements?page=1&limit=10&produitId=1
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/inventory/movements?page=1&limit=10&produitId=1" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 5.6 Résumé global du stock
**Postman :**
```
GET http://localhost:8080/inventory/summary
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/inventory/summary \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 5.7 Ajustement en lot
**Postman :**
```
POST http://localhost:8080/inventory/bulk-adjust
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "ajustements": [
    {
      "produitId": 1,
      "changementQuantite": 10,
      "notes": "Réapprovisionnement produit 1"
    },
    {
      "produitId": 2,
      "changementQuantite": -2,
      "notes": "Correction stock produit 2"
    }
  ],
  "notes": "Ajustement en lot du 22/10/2025"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/inventory/bulk-adjust \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ajustements": [
      {
        "produitId": 1,
        "changementQuantite": 10,
        "notes": "Réapprovisionnement produit 1"
      },
      {
        "produitId": 2,
        "changementQuantite": -2,
        "notes": "Correction stock produit 2"
      }
    ],
    "notes": "Ajustement en lot du 22/10/2025"
  }'
```

---

## 6. MODULE COMPTES (`/accounts`)

### 6.1 Lister les comptes clients
**Postman :**
```
GET http://localhost:8080/accounts/customers?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/accounts/customers?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6.2 Lister les comptes fournisseurs
**Postman :**
```
GET http://localhost:8080/accounts/suppliers?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/accounts/suppliers?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6.3 Solde d'un client
**Postman :**
```
GET http://localhost:8080/accounts/customers/1/balance
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/accounts/customers/1/balance \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6.4 Solde d'un fournisseur
**Postman :**
```
GET http://localhost:8080/accounts/suppliers/1/balance
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET http://localhost:8080/accounts/suppliers/1/balance \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6.5 Créer une transaction client
**Postman :**
```
POST http://localhost:8080/accounts/customers/1/transactions
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "montant": 150.00,
  "typeTransaction": "debit",
  "description": "Achat produits divers"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/accounts/customers/1/transactions \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "montant": 150.00,
    "typeTransaction": "debit",
    "description": "Achat produits divers"
  }'
```

### 6.6 Créer une transaction fournisseur
**Postman :**
```
POST http://localhost:8080/accounts/suppliers/1/transactions
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "montant": 500.00,
  "typeTransaction": "debit",
  "description": "Commande d'approvisionnement"
}
```

**cURL :**
```bash
curl -X POST http://localhost:8080/accounts/suppliers/1/transactions \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "montant": 500.00,
    "typeTransaction": "debit",
    "description": "Commande d'\''approvisionnement"
  }'
```

### 6.7 Historique transactions client
**Postman :**
```
GET http://localhost:8080/accounts/customers/1/transactions?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/accounts/customers/1/transactions?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6.8 Historique transactions fournisseur
**Postman :**
```
GET http://localhost:8080/accounts/suppliers/1/transactions?page=1&limit=10
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**cURL :**
```bash
curl -X GET "http://localhost:8080/accounts/suppliers/1/transactions?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6.9 Mettre à jour limite de crédit client
**Postman :**
```
PUT http://localhost:8080/accounts/customers/1/credit-limit
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "limiteCredit": 1000.00
}
```

**cURL :**
```bash
curl -X PUT http://localhost:8080/accounts/customers/1/credit-limit \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "limiteCredit": 1000.00
  }'
```

### 6.10 Mettre à jour limite de crédit fournisseur
**Postman :**
```
PUT http://localhost:8080/accounts/suppliers/1/credit-limit
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "limiteCredit": 5000.00
}
```

**cURL :**
```bash
curl -X PUT http://localhost:8080/accounts/suppliers/1/credit-limit \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "limiteCredit": 5000.00
  }'
```

---

## 📋 Ordre de Test Recommandé

1. **Authentification** - Créer un utilisateur et se connecter
2. **Fournisseurs** - Créer des fournisseurs
3. **Produits** - Créer des produits
4. **Inventaire** - Ajuster les stocks
5. **Clients** - Créer des clients
6. **Comptes** - Gérer les transactions

## 🔧 Variables d'Environnement Postman

Créez ces variables dans Postman :
- `baseUrl`: `http://localhost:8080`
- `accessToken`: (à remplir après login)
- `refreshToken`: (à remplir après login)

## 📝 Notes Importantes

- Remplacez `YOUR_ACCESS_TOKEN` par le token obtenu lors de la connexion
- Les IDs dans les URLs (comme `/customers/1`) doivent correspondre aux entités créées
- Certains endpoints nécessitent que des données existent (ex: un client doit exister pour créer une transaction)
- Les réponses incluent toujours un format standardisé avec `success`, `data`, `message`

## 🚨 Codes de Réponse

- `200`: Succès
- `201`: Créé avec succès
- `400`: Erreur de validation
- `401`: Non authentifié
- `403`: Non autorisé
- `404`: Ressource non trouvée
- `409`: Conflit (ex: email déjà utilisé)
- `500`: Erreur serveur