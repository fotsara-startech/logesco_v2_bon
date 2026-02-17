# Document de Conception - LOGESCO v2

## Vue d'Ensemble

LOGESCO v2 adopte une architecture hybride moderne permettant un déploiement local (hors ligne) ET cloud selon les besoins clients. L'application utilise Flutter comme client universel (desktop/web), une API REST comme couche métier, et une base de données SQL adaptable (SQLite local ou PostgreSQL cloud). Cette architecture garantit la scalabilité, la maintenabilité et la flexibilité tout en résolvant les problèmes de déploiement client.

## Architecture

### Architecture Hybride

#### Mode Local (Déploiement Client)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   API REST      │    │   SQLite        │
│   (Desktop)     │◄──►│   (Local)       │◄──►│   (Fichier)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                    Installation unique (Setup.exe)
```

#### Mode Cloud (Version Web/SaaS)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter Web   │    │   API REST      │    │  PostgreSQL     │
│   (Navigateur)  │◄──►│   (Serveur)     │◄──►│   (Cloud)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Stack Technologique Recommandé

**Frontend (Flutter):**
- Flutter 3.x pour le support desktop et web
- GetX pour la gestion d'état, navigation et injection de dépendances
- HTTP/Dio pour les appels API
- Shared Preferences pour le cache local
- Flutter Secure Storage pour les tokens

**Backend (API REST):**
- Node.js avec Express.js ou Python avec FastAPI
- JWT pour l'authentification
- Middleware de validation (Joi/Pydantic)
- Swagger/OpenAPI pour la documentation

**Base de Données Hybride:**
- **SQLite** pour déploiement local (fichier unique, pas de serveur)
- **PostgreSQL** pour version cloud/SaaS
- Prisma/TypeORM pour supporter les deux bases
- Migrations automatisées pour les deux environnements
- Backup automatique (SQLite = copie fichier, PostgreSQL = dump)

## Composants et Interfaces

### 1. Couche Présentation (Flutter)

#### Structure des Modules
```
lib/
├── core/
│   ├── api/          # Services API
│   ├── models/       # Modèles de données
│   ├── utils/        # Utilitaires
│   └── constants/    # Constantes
├── features/
│   ├── products/     # Gestion produits
│   ├── suppliers/    # Gestion fournisseurs
│   ├── customers/    # Gestion clients
│   ├── procurement/  # Approvisionnements
│   ├── sales/        # Ventes
│   ├── inventory/    # Stock
│   ├── accounts/     # Comptes clients/fournisseurs
│   └── auth/         # Authentification
└── shared/
    ├── widgets/      # Composants réutilisables
    └── themes/       # Thèmes UI
```

#### Services API avec GetX (Flutter)
```dart
abstract class ApiService {
  Future<ApiResponse<T>> get<T>(String endpoint);
  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> data);
  Future<ApiResponse<T>> put<T>(String endpoint, Map<String, dynamic> data);
  Future<ApiResponse<T>> delete<T>(String endpoint);
}

class ProductController extends GetxController {
  final ProductService _productService = Get.find<ProductService>();
  
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final result = await _productService.getProducts(search: searchQuery.value);
      products.assignAll(result);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les produits');
    } finally {
      isLoading.value = false;
    }
  }
}

class AccountController extends GetxController {
  final AccountService _accountService = Get.find<AccountService>();
  
  final RxList<CompteClient> comptesClients = <CompteClient>[].obs;
  final RxList<CompteFournisseur> comptesFournisseurs = <CompteFournisseur>[].obs;

  Future<void> updateSoldeClient(int clientId, double montant, String type) async {
    try {
      await _accountService.updateSoldeClient(clientId, montant, type);
      await loadComptesClients();
      Get.snackbar('Succès', 'Solde client mis à jour');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour le solde');
    }
  }
}
```

### 2. Couche API (Backend)

#### Architecture REST
```
/api/v1/
├── /auth
│   ├── POST /login
│   ├── POST /refresh
│   └── POST /logout
├── /products
│   ├── GET    /products
│   ├── POST   /products
│   ├── GET    /products/:id
│   ├── PUT    /products/:id
│   └── DELETE /products/:id
├── /suppliers
│   ├── GET    /suppliers
│   ├── POST   /suppliers
│   ├── GET    /suppliers/:id
│   └── PUT    /suppliers/:id
├── /customers
│   ├── GET    /customers
│   ├── POST   /customers
│   ├── GET    /customers/:id
│   └── PUT    /customers/:id
├── /accounts
│   ├── GET    /accounts/customers
│   ├── GET    /accounts/suppliers
│   ├── POST   /accounts/customers/:id/transactions
│   ├── POST   /accounts/suppliers/:id/transactions
│   └── GET    /accounts/:type/:id/balance
├── /procurement
│   ├── GET    /orders
│   ├── POST   /orders
│   ├── PUT    /orders/:id/receive
│   └── GET    /orders/:id
├── /sales
│   ├── GET    /sales
│   ├── POST   /sales
│   ├── PUT    /sales/:id/cancel
│   └── GET    /sales/:id
└── /inventory
    ├── GET    /stock
    ├── POST   /stock/adjust
    └── GET    /stock/alerts
```

#### Middleware Stack
1. **Authentification JWT** - Validation des tokens
2. **Validation des données** - Schémas de validation
3. **Logging** - Audit des actions
4. **Rate Limiting** - Protection contre les abus
5. **CORS** - Support multi-origine
6. **Error Handling** - Gestion centralisée des erreurs

### 3. Couche Données

#### Schéma de Base de Données (Tables en Français)
```sql
-- Utilisateurs et authentification
CREATE TABLE utilisateurs (
    id SERIAL PRIMARY KEY,
    nom_utilisateur VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fournisseurs
CREATE TABLE fournisseurs (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    personne_contact VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    adresse TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clients
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    adresse TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comptes fournisseurs (pour les achats à crédit)
CREATE TABLE comptes_fournisseurs (
    id SERIAL PRIMARY KEY,
    fournisseur_id INTEGER REFERENCES fournisseurs(id),
    solde_actuel DECIMAL(12,2) DEFAULT 0.00, -- Montant dû au fournisseur
    limite_credit DECIMAL(12,2) DEFAULT 0.00,
    date_derniere_maj TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fournisseur_id)
);

-- Comptes clients (pour les ventes à crédit)
CREATE TABLE comptes_clients (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    solde_actuel DECIMAL(12,2) DEFAULT 0.00, -- Montant dû par le client
    limite_credit DECIMAL(12,2) DEFAULT 0.00,
    date_derniere_maj TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id)
);

-- Produits
CREATE TABLE produits (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(50) UNIQUE NOT NULL,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    categorie VARCHAR(50),
    seuil_stock_minimum INTEGER DEFAULT 0,
    est_actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Configuration Base de Données Adaptative

#### Support SQLite + PostgreSQL
```javascript
// Configuration ORM adaptative (Node.js + Prisma)
const getDatabaseConfig = () => {
  const isLocal = process.env.NODE_ENV === 'local';
  
  return {
    provider: isLocal ? 'sqlite' : 'postgresql',
    url: isLocal 
      ? 'file:./database/logesco.db'
      : process.env.DATABASE_URL,
    migrations: {
      dir: isLocal ? './migrations/sqlite' : './migrations/postgresql'
    }
  };
};
```

## Modèles de Données Unifiés

### Modèles Flutter avec GetX (Dart)
```dart
class Produit {
  final int id;
  final String reference;
  final String nom;
  final String? description;
  final double prixUnitaire;
  final String? categorie;
  final int seuilStockMinimum;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime dateModification;

  Produit({
    required this.id,
    required this.reference,
    required this.nom,
    this.description,
    required this.prixUnitaire,
    this.categorie,
    required this.seuilStockMinimum,
    required this.estActif,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Produit.fromJson(Map<String, dynamic> json) => Produit(
    id: json['id'],
    reference: json['reference'],
    nom: json['nom'],
    description: json['description'],
    prixUnitaire: json['prix_unitaire'].toDouble(),
    categorie: json['categorie'],
    seuilStockMinimum: json['seuil_stock_minimum'],
    estActif: json['est_actif'],
    dateCreation: DateTime.parse(json['date_creation']),
    dateModification: DateTime.parse(json['date_modification']),
  );
}

class Stock {
  final int produitId;
  final Produit produit;
  final int quantiteDisponible;
  final int quantiteReservee;
  final DateTime derniereMaj;

  Stock({
    required this.produitId,
    required this.produit,
    required this.quantiteDisponible,
    required this.quantiteReservee,
    required this.derniereMaj,
  });

  int get quantiteTotale => quantiteDisponible + quantiteReservee;
  bool get stockFaible => quantiteDisponible <= produit.seuilStockMinimum;
}
```

## G
estion des Erreurs

### Stratégie de Gestion d'Erreurs

#### Côté API
```javascript
// Middleware de gestion d'erreurs centralisé
const errorHandler = (err, req, res, next) => {
  const error = {
    message: err.message,
    status: err.status || 500,
    timestamp: new Date().toISOString(),
    path: req.path
  };

  // Log pour audit
  logger.error(error);

  // Réponse standardisée
  res.status(error.status).json({
    success: false,
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.message,
      details: process.env.NODE_ENV === 'development' ? err.stack : undefined
    }
  });
};

// Types d'erreurs métier
class BusinessError extends Error {
  constructor(message, code, status = 400) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

// Exemples d'erreurs spécifiques
class InsufficientStockError extends BusinessError {
  constructor(productName, available, requested) {
    super(
      `Stock insuffisant pour ${productName}. Disponible: ${available}, Demandé: ${requested}`,
      'INSUFFICIENT_STOCK',
      400
    );
  }
}
```

#### Côté Flutter
```dart
class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  ApiException({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  factory ApiException.fromResponse(http.Response response) {
    final body = json.decode(response.body);
    return ApiException(
      message: body['error']['message'],
      code: body['error']['code'],
      statusCode: response.statusCode,
    );
  }
}

// Gestion d'erreurs dans les services
class ProductService {
  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiClient.get('/products');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        throw ApiException.fromResponse(response);
      }
    } on SocketException {
      throw ApiException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
        statusCode: 0,
      );
    } catch (e) {
      throw ApiException(
        message: 'Erreur inattendue: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }
}
```

## Stratégie de Tests

### Tests Backend (API)
- **Tests unitaires** : Logique métier et services
- **Tests d'intégration** : Endpoints API avec base de données de test
- **Tests de performance** : Charge et temps de réponse
- **Tests de sécurité** : Authentification et autorisation

### Tests Frontend (Flutter)
- **Tests unitaires** : Modèles et services
- **Tests de widgets** : Composants UI isolés
- **Tests d'intégration** : Flux utilisateur complets
- **Tests golden** : Cohérence visuelle

### Outils de Test Recommandés
- **Backend** : Jest/Mocha (Node.js) ou pytest (Python)
- **Frontend** : Flutter Test framework
- **API Testing** : Postman/Newman ou REST Client
- **Performance** : Artillery ou JMeter

## Architecture de Déploiement Hybride

### Déploiement Local (Client Hors Ligne)

#### Structure du Package d'Installation
```
LOGESCO-Setup.exe
├── flutter_app/
│   ├── logesco_desktop.exe
│   └── data/
├── api_server/
│   ├── logesco_api.exe (Node.js compilé)
│   ├── config/
│   │   └── local.json
│   └── database/
│       └── logesco.db (SQLite vide avec structure)
├── installer/
│   ├── install.bat
│   └── service_installer.exe
└── docs/
    └── guide_installation.pdf
```

#### Processus d'Installation Automatique
1. **Copie des fichiers** dans `C:\Program Files\LOGESCO\`
2. **Installation de l'API comme service Windows** (port 8080)
3. **Création de la base SQLite** avec structure complète
4. **Configuration automatique** des connexions locales
5. **Création des raccourcis** bureau et menu démarrer
6. **Test de connectivité** API ↔ Base de données

#### Avantages du Mode Local
- ✅ **Installation en un clic** - Plus de déplacements techniques
- ✅ **Fonctionne 100% hors ligne** - Pas de dépendance internet
- ✅ **Données sécurisées** - Restent chez le client
- ✅ **Performance optimale** - Tout en local
- ✅ **Pas de coûts récurrents** - Pas d'abonnement cloud

### Déploiement Cloud (Version Web)

#### Architecture SaaS Multi-Tenant
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Flutter Web    │    │   Load Balancer │    │   PostgreSQL    │
│  (Multi-tenant) │◄──►│   + API Cluster │◄──►│   (Multi-DB)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Environnements Cloud
1. **Développement** : Local avec Docker Compose
2. **Test/Staging** : Serveur de test avec CI/CD  
3. **Production** : Cloud (AWS/Azure/GCP) avec haute disponibilité

### Impact sur la Version Web

**Aucun impact négatif - Au contraire, des avantages :**

1. **Même codebase Flutter** - Web et Desktop partagent le code
2. **API unifiée** - Même endpoints, différentes bases de données
3. **Flexibilité client** - Choix entre local et cloud
4. **Migration facile** - Possibilité de passer de local à cloud
5. **Développement simplifié** - Une seule architecture à maintenir

### Configuration Adaptative

#### Détection Automatique d'Environnement
```dart
class EnvironmentConfig {
  static bool get isLocal => Platform.isWindows && _hasLocalAPI();
  static bool get isWeb => kIsWeb;
  
  static String get apiBaseUrl {
    if (isLocal) return 'http://localhost:8080/api/v1';
    if (isWeb) return 'https://api.logesco.com/v1';
    return _getConfiguredUrl();
  }
  
  static DatabaseType get dbType {
    return isLocal ? DatabaseType.sqlite : DatabaseType.postgresql;
  }
}
```

### Configuration Docker
```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/logesco
      - JWT_SECRET=your-secret-key
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=logesco
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

### Stratégie de Sauvegarde Hybride

#### Mode Local (SQLite)
- **Sauvegarde automatique** : Copie quotidienne du fichier .db
- **Sauvegarde manuelle** : Bouton "Exporter données" dans l'app
- **Restauration** : Remplacement du fichier SQLite
- **Synchronisation cloud** : Export/Import optionnel vers cloud

#### Mode Cloud (PostgreSQL)  
- **Sauvegardes automatiques** quotidiennes
- **Rétention** de 30 jours minimum
- **Tests de restauration** mensuels
- **Réplication** en temps réel pour haute disponibilité

## Avantages de l'Architecture Hybride

### Pour Vous (Développeur/Éditeur)
- ✅ **Déploiement simplifié** - Plus de déplacements clients
- ✅ **Support réduit** - Installation automatisée
- ✅ **Scalabilité** - Même code pour local et cloud
- ✅ **Revenus diversifiés** - Licence locale + SaaS cloud
- ✅ **Maintenance centralisée** - Mises à jour automatiques

### Pour Vos Clients
- ✅ **Choix de déploiement** - Local ou cloud selon besoins
- ✅ **Données sécurisées** - Contrôle total en mode local
- ✅ **Performance optimale** - Pas de latence réseau
- ✅ **Coûts prévisibles** - Licence unique vs abonnement
- ✅ **Migration possible** - Passage local → cloud facilité

### Impact sur le Développement
- ✅ **Même codebase Flutter** - Web et Desktop identiques
- ✅ **API unifiée** - Endpoints identiques, bases différentes
- ✅ **Tests simplifiés** - Même logique métier
- ✅ **Déploiement flexible** - Adaptation automatique environnement
- Stock
CREATE TABLE stock (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER REFERENCES produits(id),
    quantite_disponible INTEGER NOT NULL DEFAULT 0,
    quantite_reservee INTEGER NOT NULL DEFAULT 0,
    derniere_maj TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(produit_id)
);

-- Commandes d'approvisionnement
CREATE TABLE commandes_approvisionnement (
    id SERIAL PRIMARY KEY,
    numero_commande VARCHAR(50) UNIQUE NOT NULL,
    fournisseur_id INTEGER REFERENCES fournisseurs(id),
    statut VARCHAR(20) DEFAULT 'en_attente', -- en_attente, partielle, terminee, annulee
    date_commande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_livraison_prevue DATE,
    montant_total DECIMAL(12,2),
    mode_paiement VARCHAR(20) DEFAULT 'credit', -- comptant, credit
    notes TEXT
);

-- Détails des commandes d'approvisionnement
CREATE TABLE details_commandes_approvisionnement (
    id SERIAL PRIMARY KEY,
    commande_id INTEGER REFERENCES commandes_approvisionnement(id),
    produit_id INTEGER REFERENCES produits(id),
    quantite_commandee INTEGER NOT NULL,
    quantite_recue INTEGER DEFAULT 0,
    cout_unitaire DECIMAL(10,2) NOT NULL
);

-- Ventes
CREATE TABLE ventes (
    id SERIAL PRIMARY KEY,
    numero_vente VARCHAR(50) UNIQUE NOT NULL,
    client_id INTEGER REFERENCES clients(id),
    date_vente TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sous_total DECIMAL(12,2) NOT NULL,
    montant_remise DECIMAL(12,2) DEFAULT 0,
    montant_total DECIMAL(12,2) NOT NULL,
    statut VARCHAR(20) DEFAULT 'terminee', -- terminee, annulee
    mode_paiement VARCHAR(20) DEFAULT 'comptant', -- comptant, credit
    montant_paye DECIMAL(12,2) DEFAULT 0,
    montant_restant DECIMAL(12,2) DEFAULT 0
);

-- Détails des ventes
CREATE TABLE details_ventes (
    id SERIAL PRIMARY KEY,
    vente_id INTEGER REFERENCES ventes(id),
    produit_id INTEGER REFERENCES produits(id),
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    prix_total DECIMAL(10,2) NOT NULL
);

-- Transactions de comptes (pour le suivi des crédits)
CREATE TABLE transactions_comptes (
    id SERIAL PRIMARY KEY,
    type_compte VARCHAR(20) NOT NULL, -- client, fournisseur
    compte_id INTEGER NOT NULL, -- ID du compte client ou fournisseur
    type_transaction VARCHAR(20) NOT NULL, -- debit, credit, paiement, achat
    montant DECIMAL(12,2) NOT NULL,
    description TEXT,
    reference_id INTEGER, -- ID de la vente/achat source
    reference_type VARCHAR(20), -- vente, achat, paiement
    date_transaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    solde_apres DECIMAL(12,2) NOT NULL
);

-- Mouvements de stock (audit trail)
CREATE TABLE mouvements_stock (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER REFERENCES produits(id),
    type_mouvement VARCHAR(20) NOT NULL, -- achat, vente, ajustement, retour
    changement_quantite INTEGER NOT NULL, -- positif ou négatif
    reference_id INTEGER, -- ID de la transaction source
    type_reference VARCHAR(20), -- approvisionnement, vente, ajustement
    date_mouvement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);
```

## Modèles de Données Mis à Jour

### Modèles Flutter avec GetX (Dart)
```dart
class Produit {
  final int id;
  final String reference;
  final String nom;
  final String? description;
  final double prixUnitaire;
  final String? categorie;
  final int seuilStockMinimum;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime dateModification;

  Produit({
    required this.id,
    required this.reference,
    required this.nom,
    this.description,
    required this.prixUnitaire,
    this.categorie,
    required this.seuilStockMinimum,
    required this.estActif,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Produit.fromJson(Map<String, dynamic> json) => Produit(
    id: json['id'],
    reference: json['reference'],
    nom: json['nom'],
    description: json['description'],
    prixUnitaire: json['prix_unitaire'].toDouble(),
    categorie: json['categorie'],
    seuilStockMinimum: json['seuil_stock_minimum'],
    estActif: json['est_actif'],
    dateCreation: DateTime.parse(json['date_creation']),
    dateModification: DateTime.parse(json['date_modification']),
  );
}

class Client {
  final int id;
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final DateTime dateCreation;

  Client({
    required this.id,
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.adresse,
    required this.dateCreation,
  });

  String get nomComplet => prenom != null ? '$nom $prenom' : nom;
}

class CompteClient {
  final int id;
  final int clientId;
  final Client client;
  final double soldeActuel;
  final double limiteCredit;
  final DateTime dateDerniereMaj;

  CompteClient({
    required this.id,
    required this.clientId,
    required this.client,
    required this.soldeActuel,
    required this.limiteCredit,
    required this.dateDerniereMaj,
  });

  bool get estEnDepassement => soldeActuel > limiteCredit;
  double get creditDisponible => limiteCredit - soldeActuel;
}

class Vente {
  final int id;
  final String numeroVente;
  final int? clientId;
  final Client? client;
  final DateTime dateVente;
  final double sousTotal;
  final double montantRemise;
  final double montantTotal;
  final String statut;
  final String modePaiement;
  final double montantPaye;
  final double montantRestant;
  final List<DetailVente> details;

  Vente({
    required this.id,
    required this.numeroVente,
    this.clientId,
    this.client,
    required this.dateVente,
    required this.sousTotal,
    required this.montantRemise,
    required this.montantTotal,
    required this.statut,
    required this.modePaiement,
    required this.montantPaye,
    required this.montantRestant,
    required this.details,
  });

  bool get estACredit => modePaiement == 'credit';
  bool get estSoldee => montantRestant <= 0;
}
```