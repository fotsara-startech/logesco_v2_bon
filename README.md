# LOGESCO v2 - Backend API

API REST hybride pour le système de gestion commerciale LOGESCO v2 avec authentification JWT complète.

## ✅ Fonctionnalités Implémentées

### 🏗️ Architecture de Base
- ✅ Support hybride SQLite (local) et PostgreSQL (cloud)
- ✅ Détection automatique de l'environnement
- ✅ Architecture modulaire et extensible
- ✅ Middlewares de sécurité intégrés (CORS, Helmet, Rate Limiting)

### 🗄️ Base de Données
- ✅ Schéma Prisma complet avec toutes les entités en français
- ✅ Migrations SQLite et PostgreSQL
- ✅ 20 index de performance optimisés
- ✅ Relations et contraintes définies

### 🔐 Authentification JWT
- ✅ Inscription et connexion utilisateur
- ✅ Tokens JWT avec refresh automatique
- ✅ Middleware d'authentification
- ✅ Rate limiting par utilisateur
- ✅ Gestion sécurisée des sessions
- ✅ Changement de mot de passe
- ✅ Déconnexion globale

### 📊 Modèles et Validation
- ✅ Modèles métier avec logique d'affaires
- ✅ Validation Joi complète pour toutes les entités
- ✅ DTOs standardisés pour les réponses API
- ✅ Utilitaires de transformation de données
- ✅ Factory de modèles pour l'injection de dépendances

### 🧪 Tests et Qualité
- ✅ Tests unitaires des services d'authentification
- ✅ Tests de validation des schémas
- ✅ Tests HTTP des endpoints
- ✅ Scripts de nettoyage automatisés

## 🚀 Installation et Démarrage

```bash
# Installation des dépendances
npm install

# Configuration de la base de données
npm run db:setup

# Démarrage du serveur
npm start

# Mode développement
npm run dev
```

## 🔧 Configuration

### Variables d'Environnement

```bash
# Base de données (détection automatique)
DATABASE_URL=file:./database/logesco.db  # SQLite local
# ou
DATABASE_URL=postgresql://user:pass@host:5432/db  # PostgreSQL cloud

# JWT (optionnel, valeurs par défaut fournies)
JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Serveur
PORT=8080
NODE_ENV=development
```

### Détection d'Environnement

L'API détecte automatiquement l'environnement :
- **Local** : SQLite avec fichier `database/logesco.db`
- **Cloud** : PostgreSQL via `DATABASE_URL`

## 📡 Endpoints Disponibles

### Authentification (`/api/v1/auth`)
- `POST /register` - Inscription utilisateur
- `POST /login` - Connexion utilisateur
- `POST /refresh` - Rafraîchissement token
- `POST /logout` - Déconnexion
- `POST /logout-all` - Déconnexion globale
- `GET /me` - Informations utilisateur
- `POST /change-password` - Changement mot de passe
- `GET /verify` - Vérification token
- `GET /stats` - Statistiques d'authentification

### Système
- `GET /` - Status de l'API
- `GET /api/v1/stats` - Statistiques de la base de données

### Modules à Venir
- `/api/v1/products` - Gestion des produits
- `/api/v1/suppliers` - Gestion des fournisseurs
- `/api/v1/customers` - Gestion des clients
- `/api/v1/inventory` - Gestion du stock
- `/api/v1/sales` - Gestion des ventes
- `/api/v1/procurement` - Gestion des approvisionnements

## 🧪 Tests

```bash
# Tous les tests
npm test

# Tests spécifiques
npm run test:validation  # Tests de validation
npm run test:auth       # Tests d'authentification
npm run test:auth-http  # Tests HTTP (serveur requis)

# Validation rapide
npm run validate
```

## 🛠️ Scripts de Développement

```bash
# Base de données
npm run migrate         # Exécuter les migrations
npm run generate        # Générer le client Prisma
npm run studio          # Interface Prisma Studio
npm run db:indexes      # Appliquer les index de performance
npm run db:setup        # Configuration complète
npm run db:reset        # Reset complet
npm run db:cleanup      # Nettoyer les utilisateurs de test

# Développement
npm run dev            # Mode développement avec nodemon
npm start              # Mode production
```

## 📚 Documentation

- [Authentification JWT](./docs/AUTHENTICATION.md) - Guide complet d'authentification
- [Modèles et Validation](./docs/MODELS_AND_VALIDATION.md) - Architecture des données

## 🔒 Sécurité

### Fonctionnalités Implémentées
- ✅ Authentification JWT avec refresh tokens
- ✅ Rate limiting par endpoint et utilisateur
- ✅ Validation stricte des données d'entrée
- ✅ Headers de sécurité automatiques
- ✅ Hachage sécurisé des mots de passe (bcrypt)
- ✅ Protection CORS configurée
- ✅ Helmet.js pour les headers de sécurité

### Rate Limiting
- **Login** : 5 tentatives / 15 minutes
- **Register** : 3 inscriptions / heure
- **Refresh** : 10 rafraîchissements / 15 minutes
- **Général** : 100 requêtes / 15 minutes par utilisateur

## 🏗️ Architecture

```
backend/
├── src/
│   ├── config/          # Configuration (DB, environnement)
│   ├── middleware/      # Middlewares Express
│   ├── models/          # Modèles métier Prisma
│   ├── routes/          # Routes API
│   ├── services/        # Services métier (Auth, etc.)
│   ├── validation/      # Schémas de validation Joi
│   ├── dto/            # Data Transfer Objects
│   └── utils/          # Utilitaires et transformers
├── prisma/             # Schémas et migrations Prisma
├── scripts/            # Scripts utilitaires
└── docs/              # Documentation
```

## 🚦 Status du Projet

### ✅ Terminé
- [x] Configuration environnement hybride
- [x] API REST avec Express
- [x] Authentification JWT complète
- [x] Modèles de données et migrations
- [x] Validation et DTOs
- [x] Tests automatisés

### 🔄 En Cours
- [ ] Endpoints de gestion des produits
- [ ] Endpoints de gestion des clients/fournisseurs
- [ ] Système de gestion du stock
- [ ] Gestion des ventes et approvisionnements

### 📋 À Venir
- [ ] Interface Flutter
- [ ] Rapports et analytics
- [ ] Déploiement cloud
- [ ] Documentation utilisateur

## 🤝 Contribution

Le projet suit une architecture modulaire permettant l'ajout facile de nouvelles fonctionnalités. Chaque module est indépendant et testé.

## 📄 Licence

Projet privé LOGESCO v2.