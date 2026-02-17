# Documentation Technique - LOGESCO v2

## Table des Matières

1. [Architecture Système](#architecture-système)
2. [Stack Technologique](#stack-technologique)
3. [Structure du Projet](#structure-du-projet)
4. [Base de Données](#base-de-données)
5. [API REST](#api-rest)
6. [Frontend Flutter](#frontend-flutter)
7. [Authentification et Sécurité](#authentification-et-sécurité)
8. [Gestion des Erreurs](#gestion-des-erreurs)
9. [Tests](#tests)
10. [Déploiement](#déploiement)
11. [Maintenance](#maintenance)
12. [Évolutions Futures](#évolutions-futures)

---

## Architecture Système

### Vue d'Ensemble

LOGESCO v2 utilise une architecture hybride en 3 couches :

```
┌─────────────────────────────────────────────────────┐
│              COUCHE PRÉSENTATION                     │
│         Flutter (Desktop + Web)                      │
│         - GetX (State Management)                    │
│         - Responsive UI                              │
└─────────────────────────────────────────────────────┘
                        ↕ HTTP/REST
┌─────────────────────────────────────────────────────┐
│              COUCHE MÉTIER                           │
│         API REST (Node.js + Express)                 │
│         - Authentification JWT                       │
│         - Validation des données                     │
│         - Logique métier                             │
└─────────────────────────────────────────────────────┘
                        ↕ SQL
┌─────────────────────────────────────────────────────┐
│              COUCHE DONNÉES                          │
│    SQLite (Local) / PostgreSQL (Cloud)               │
│         - Prisma ORM                                 │
│         - Migrations automatiques                    │
└─────────────────────────────────────────────────────┘
```

### Modes de Déploiement

**Mode Local (Desktop)**
- Application Flutter Desktop (Windows)
- API REST en service Windows (port 8080)
- Base de données SQLite (fichier local)
- Fonctionne 100% hors ligne

**Mode Cloud (Web)**
- Application Flutter Web (navigateur)
- API REST sur serveur (Docker)
- Base de données PostgreSQL
- Nécessite connexion internet

---

## Stack Technologique

### Frontend
- **Framework** : Flutter 3.x
- **Langage** : Dart 3.x
- **State Management** : GetX 4.x
- **HTTP Client** : Dio / HTTP
- **Storage** : Shared Preferences, Flutter Secure Storage
- **UI** : Material Design 3

### Backend
- **Runtime** : Node.js 18+ LTS
- **Framework** : Express.js 4.x
- **ORM** : Prisma 5.x
- **Authentification** : JWT (jsonwebtoken)
- **Validation** : Joi / Zod
- **Logging** : Winston

### Base de Données
- **Local** : SQLite 3.x
- **Cloud** : PostgreSQL 15+
- **Migrations** : Prisma Migrate

### DevOps
- **Containerisation** : Docker + Docker Compose
- **Reverse Proxy** : Nginx
- **SSL** : Let's Encrypt (Certbot)
- **CI/CD** : GitHub Actions (optionnel)

---

## Structure du Projet

### Arborescence Globale

```
logesco_v2/
├── backend/                    # API REST
│   ├── src/
│   ├── prisma/
│   ├── tests/
│   └── package.json
├── logesco_v2/                 # Application Flutter
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── docker/                     # Configuration Docker
│   ├── Dockerfile.api
│   ├── Dockerfile.web
│   └── nginx.conf
├── docs/                       # Documentation
└── scripts/                    # Scripts utilitaires
```


### Structure Backend (API)

```
backend/
├── src/
│   ├── config/                 # Configuration
│   │   ├── database.js         # Config DB (SQLite/PostgreSQL)
│   │   ├── jwt.js              # Config JWT
│   │   └── env.js              # Variables d'environnement
│   ├── middleware/             # Middlewares Express
│   │   ├── auth.js             # Authentification JWT
│   │   ├── validation.js       # Validation des données
│   │   ├── errorHandler.js     # Gestion d'erreurs
│   │   └── logger.js           # Logging
│   ├── routes/                 # Routes API
│   │   ├── auth.routes.js
│   │   ├── products.routes.js
│   │   ├── customers.routes.js
│   │   ├── suppliers.routes.js
│   │   ├── sales.routes.js
│   │   ├── procurement.routes.js
│   │   ├── inventory.routes.js
│   │   └── accounts.routes.js
│   ├── controllers/            # Contrôleurs
│   │   ├── auth.controller.js
│   │   ├── products.controller.js
│   │   └── ...
│   ├── services/               # Logique métier
│   │   ├── auth.service.js
│   │   ├── products.service.js
│   │   ├── stock.service.js
│   │   └── ...
│   ├── models/                 # Modèles de données
│   │   └── (généré par Prisma)
│   ├── utils/                  # Utilitaires
│   │   ├── errors.js           # Classes d'erreurs
│   │   ├── validators.js       # Validateurs
│   │   └── helpers.js          # Fonctions helper
│   └── app.js                  # Point d'entrée
├── prisma/
│   ├── schema.prisma           # Schéma de base de données
│   ├── migrations/             # Migrations
│   └── seed.js                 # Données initiales
├── tests/
│   ├── unit/                   # Tests unitaires
│   ├── integration/            # Tests d'intégration
│   └── e2e/                    # Tests end-to-end
├── logs/                       # Fichiers de logs
├── .env                        # Variables d'environnement
├── .env.example                # Template .env
└── package.json
```

### Structure Frontend (Flutter)

```
logesco_v2/lib/
├── core/
│   ├── api/                    # Services API
│   │   ├── api_client.dart     # Client HTTP
│   │   ├── api_endpoints.dart  # URLs des endpoints
│   │   └── api_interceptor.dart # Intercepteurs (auth, logs)
│   ├── models/                 # Modèles de données
│   │   ├── product.dart
│   │   ├── customer.dart
│   │   ├── supplier.dart
│   │   ├── sale.dart
│   │   └── ...
│   ├── utils/                  # Utilitaires
│   │   ├── formatters.dart     # Formatage (dates, nombres)
│   │   ├── validators.dart     # Validateurs
│   │   └── constants.dart      # Constantes
│   └── config/                 # Configuration
│       ├── environment.dart    # Config environnement
│       └── theme.dart          # Thème UI
├── features/                   # Modules fonctionnels
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart
│   │   ├── views/
│   │   │   ├── login_page.dart
│   │   │   └── register_page.dart
│   │   └── services/
│   │       └── auth_service.dart
│   ├── products/
│   │   ├── controllers/
│   │   │   └── product_controller.dart
│   │   ├── views/
│   │   │   ├── product_list_view.dart
│   │   │   ├── product_form_view.dart
│   │   │   └── product_detail_view.dart
│   │   └── services/
│   │       └── product_service.dart
│   ├── customers/
│   ├── suppliers/
│   ├── sales/
│   ├── procurement/
│   ├── inventory/
│   ├── accounts/
│   └── dashboard/
├── shared/
│   ├── widgets/                # Composants réutilisables
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_indicator.dart
│   │   └── ...
│   └── layouts/                # Layouts
│       ├── main_layout.dart
│       └── auth_layout.dart
├── routes/
│   └── app_routes.dart         # Configuration des routes
└── main.dart                   # Point d'entrée
```

---

## Base de Données

### Schéma Prisma

Le schéma complet est défini dans `backend/prisma/schema.prisma`.

**Tables Principales** :
- `utilisateurs` : Utilisateurs du système
- `produits` : Catalogue de produits
- `clients` : Clients
- `fournisseurs` : Fournisseurs
- `comptes_clients` : Comptes clients (crédits)
- `comptes_fournisseurs` : Comptes fournisseurs
- `stock` : Quantités en stock
- `ventes` : Ventes
- `details_ventes` : Lignes de vente
- `commandes_approvisionnement` : Commandes fournisseurs
- `details_commandes_approvisionnement` : Lignes de commande
- `transactions_comptes` : Historique des transactions
- `mouvements_stock` : Historique des mouvements de stock

### Relations Clés

```
produits ──┬── stock (1:1)
           ├── details_ventes (1:N)
           ├── details_commandes_approvisionnement (1:N)
           └── mouvements_stock (1:N)

clients ──┬── comptes_clients (1:1)
          └── ventes (1:N)

fournisseurs ──┬── comptes_fournisseurs (1:1)
               └── commandes_approvisionnement (1:N)

ventes ──── details_ventes (1:N)
commandes_approvisionnement ──── details_commandes_approvisionnement (1:N)
```

### Migrations

**Créer une Migration**
```bash
cd backend
npx prisma migrate dev --name nom_de_la_migration
```

**Appliquer les Migrations (Production)**
```bash
npx prisma migrate deploy
```

**Réinitialiser la Base (Développement)**
```bash
npx prisma migrate reset
```

### Seed (Données Initiales)

```bash
npx prisma db seed
```

Crée :
- Utilisateur admin par défaut
- Catégories de produits
- Données de démonstration (optionnel)

---

## API REST

### Endpoints Principaux

**Authentification**
```
POST   /api/v1/auth/login       # Connexion
POST   /api/v1/auth/refresh     # Rafraîchir le token
POST   /api/v1/auth/logout      # Déconnexion
```

**Produits**
```
GET    /api/v1/products         # Liste des produits
POST   /api/v1/products         # Créer un produit
GET    /api/v1/products/:id     # Détails d'un produit
PUT    /api/v1/products/:id     # Modifier un produit
DELETE /api/v1/products/:id     # Supprimer un produit
```

**Clients**
```
GET    /api/v1/customers        # Liste des clients
POST   /api/v1/customers        # Créer un client
GET    /api/v1/customers/:id    # Détails d'un client
PUT    /api/v1/customers/:id    # Modifier un client
DELETE /api/v1/customers/:id    # Supprimer un client
```

**Comptes**
```
GET    /api/v1/accounts/customers/:id              # Compte client
POST   /api/v1/accounts/customers/:id/transactions # Transaction client
GET    /api/v1/accounts/suppliers/:id              # Compte fournisseur
POST   /api/v1/accounts/suppliers/:id/transactions # Transaction fournisseur
```

**Ventes**
```
GET    /api/v1/sales            # Liste des ventes
POST   /api/v1/sales            # Créer une vente
GET    /api/v1/sales/:id        # Détails d'une vente
PUT    /api/v1/sales/:id/cancel # Annuler une vente
```

**Stock**
```
GET    /api/v1/inventory        # État du stock
POST   /api/v1/inventory/adjust # Ajuster le stock
GET    /api/v1/inventory/alerts # Alertes de stock
```

### Format des Réponses

**Succès**
```json
{
  "success": true,
  "data": {
    // Données
  },
  "message": "Opération réussi