# Modèles et Validation - LOGESCO v2

## Vue d'ensemble

Ce document décrit l'architecture des modèles de données et du système de validation pour LOGESCO v2. Le système utilise Prisma ORM avec des couches d'abstraction métier et des validations Joi robustes.

## Architecture

```
src/
├── models/           # Modèles métier avec logique d'affaires
├── validation/       # Schémas de validation Joi
├── dto/             # Data Transfer Objects pour l'API
├── middleware/      # Middleware de validation Express
└── utils/           # Utilitaires de transformation
```

## Modèles de Données

### BaseModel

Classe de base fournissant les opérations CRUD communes :
- `findById(id, options)` - Trouve par ID
- `findMany(options)` - Liste avec options
- `count(where)` - Compte les enregistrements
- `create(data, options)` - Crée un enregistrement
- `update(id, data, options)` - Met à jour
- `delete(id)` - Supprime

### Modèles Spécialisés

#### UtilisateurModel
- `createUser(userData)` - Crée avec hash du mot de passe
- `findByUsername(nomUtilisateur)` - Recherche par nom d'utilisateur
- `findByEmail(email)` - Recherche par email
- `verifyPassword(motDePasse, hash)` - Vérifie le mot de passe
- `updatePassword(id, nouveauMotDePasse)` - Met à jour le mot de passe

#### ProduitModel
- `createWithStock(produitData)` - Crée produit avec stock initial
- `findLowStock()` - Trouve les produits en stock faible
- `search(searchParams, options)` - Recherche avancée

#### StockModel
- `adjustStock(produitId, changement, typeReference, referenceId, notes)` - Ajuste le stock
- `reserveStock(details)` - Réserve du stock pour vente
- `confirmSale(details)` - Confirme la vente et retire le stock réservé

#### VenteModel
- `createSale(venteData)` - Crée une vente complète avec détails
- `updateClientAccount(tx, clientId, montant, venteId)` - Met à jour le compte client

#### CommandeApprovisionnementModel
- `createOrder(commandeData)` - Crée une commande avec détails
- `receiveOrder(commandeId, receptions)` - Réceptionne une commande

## Validation avec Joi

### Schémas Disponibles

#### Produits
```javascript
// Création
schemas.produitSchemas.create.validate(data)

// Mise à jour
schemas.produitSchemas.update.validate(data)

// Recherche
schemas.produitSchemas.search.validate(queryParams)
```

#### Clients
```javascript
schemas.clientSchemas.create.validate(data)
schemas.clientSchemas.update.validate(data)
schemas.clientSchemas.search.validate(queryParams)
```

#### Ventes
```javascript
schemas.venteSchemas.create.validate(data)
schemas.venteSchemas.update.validate(data)
schemas.venteSchemas.paiement.validate(data)
```

### Middleware de Validation

#### Utilisation de Base
```javascript
const { validate, validateId, validatePagination } = require('../middleware/validation');

// Validation du body avec schéma Joi
router.post('/products', validate(schemas.produitSchemas.create), createProduct);

// Validation des paramètres d'ID
router.get('/products/:id', validateId, getProduct);

// Validation de la pagination
router.get('/products', validatePagination, listProducts);
```

#### Validations Spécialisées
```javascript
// Validation des dates
validateDates(['dateDebut', 'dateFin'])

// Validation des montants
validateAmounts(['prixUnitaire', 'montantTotal'])

// Validation des quantités
validateQuantities(['quantite', 'seuilStockMinimum'])

// Validation d'unicité
validateUnique(checkFunction, 'reference', 'Référence déjà utilisée')
```

## DTOs (Data Transfer Objects)

### Utilisation
```javascript
const { ProduitDTO, ClientDTO, VenteDTO, BaseResponseDTO } = require('../dto');

// Transformer une entité
const produitDTO = ProduitDTO.fromEntity(produit);

// Transformer un tableau
const produitsDTO = ProduitDTO.fromEntities(produits);

// Réponse API succès
const response = BaseResponseDTO.success(produitDTO, 'Produit créé');

// Réponse API erreur
const errorResponse = BaseResponseDTO.error('Erreur validation', errors);
```

### DTOs Disponibles

- **UtilisateurDTO** - Utilisateur sans mot de passe
- **ProduitDTO** - Produit avec stock optionnel
- **ClientDTO** - Client avec nom complet calculé
- **FournisseurDTO** - Fournisseur avec compte optionnel
- **VenteDTO** - Vente avec calculs automatiques
- **CommandeApprovisionnementDTO** - Commande avec détails
- **StockDTO** - Stock avec alertes calculées

## Utilitaires de Transformation

### Fonctions Disponibles

```javascript
const transformers = require('../utils/transformers');

// Construction de requêtes Prisma
const options = transformers.buildPrismaQuery(queryParams);

// Conditions de recherche
const conditions = transformers.buildProductSearchConditions(searchParams);

// Génération de numéros
const numeroVente = transformers.generateSaleNumber();
const numeroCommande = transformers.generateOrderNumber();

// Calculs
const totaux = transformers.calculateSaleTotals(details);

// Formatage
const montantFormate = transformers.formatCurrency(1234.56);
const dateFormatee = transformers.formatDate(new Date());

// Nettoyage
const donneesNettes = transformers.sanitizeInput(data);
```

## Utilisation avec ModelFactory

### Initialisation
```javascript
const { ModelFactory } = require('../models');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const models = new ModelFactory(prisma);

// Utilisation des modèles
const produit = await models.produit.createWithStock(produitData);
const vente = await models.vente.createSale(venteData);
const stock = await models.stock.adjustStock(produitId, changement, 'ajustement');
```

### Services Intégrés
```javascript
const { initializeServices } = require('../src');

// Initialisation complète
const services = await initializeServices();

// Utilisation
const produit = await services.models.produit.findById(1);
const validation = services.schemas.produitSchemas.create.validate(data);
const dto = services.dto.ProduitDTO.fromEntity(produit);
```

## Tests et Validation

### Exécution des Tests
```bash
# Test complet des validations
npm run test:validation

# ou
npm run validate
```

### Tests Inclus
- ✅ Validation des schémas Joi
- ✅ Transformation des DTOs
- ✅ Connexion base de données
- ✅ Utilitaires de transformation
- ✅ Factory de modèles

## Bonnes Pratiques

### Validation
1. **Toujours valider** les données d'entrée avec Joi
2. **Utiliser les middleware** pour la validation automatique
3. **Nettoyer les données** avec `sanitizeInput`
4. **Vérifier l'unicité** pour les champs critiques

### Modèles
1. **Utiliser les transactions** pour les opérations complexes
2. **Inclure les relations** nécessaires dans les requêtes
3. **Gérer les erreurs** métier dans les modèles
4. **Enregistrer les mouvements** pour l'audit

### DTOs
1. **Transformer toujours** les données de sortie
2. **Calculer les champs dérivés** dans les DTOs
3. **Masquer les données sensibles** (mots de passe, etc.)
4. **Utiliser les réponses standardisées** avec BaseResponseDTO

## Exemples d'Utilisation

### Création d'un Produit
```javascript
// Validation
const { error, value } = schemas.produitSchemas.create.validate(req.body);
if (error) return res.status(400).json(BaseResponseDTO.error('Validation échouée', error.details));

// Création avec stock
const produit = await models.produit.createWithStock(value);

// Réponse
const response = BaseResponseDTO.success(
  ProduitDTO.fromEntity(produit),
  'Produit créé avec succès'
);
res.status(201).json(response);
```

### Création d'une Vente
```javascript
// Validation
const { error, value } = schemas.venteSchemas.create.validate(req.body);
if (error) return res.status(400).json(BaseResponseDTO.error('Validation échouée', error.details));

// Vérification du stock
const stockItems = await Promise.all(
  value.details.map(d => models.stock.findById(d.produitId))
);
const stockValidation = validateStockAvailability(value.details, stockItems);
if (!stockValidation.isValid) {
  return res.status(400).json(BaseResponseDTO.error('Stock insuffisant', stockValidation.errors));
}

// Création de la vente
const vente = await models.vente.createSale(value);

// Réponse
const response = BaseResponseDTO.success(
  VenteDTO.fromEntity(vente),
  'Vente créée avec succès'
);
res.status(201).json(response);
```

## Configuration

### Variables d'Environnement
- `DATABASE_URL` - URL de la base de données
- `NODE_ENV` - Environnement (development/production)

### Support Multi-Base
Le système supporte automatiquement :
- **SQLite** pour le déploiement local
- **PostgreSQL** pour le déploiement cloud

La détection se fait automatiquement via la configuration d'environnement.