# Guide de Test - LOGESCO v2

## Configuration Actuelle

L'application est maintenant configurée pour démarrer directement sur le **Dashboard** en mode développement.

### Fonctionnalités Disponibles

#### ✅ Modules Implémentés et Testables

1. **Produits** (`/products`)
   - Liste des produits avec pagination
   - Recherche et filtres
   - Création/modification/suppression de produits
   - Gestion des catégories

2. **Clients** (`/customers`)
   - Liste des clients avec pagination
   - Recherche par nom, téléphone, email
   - Création/modification/suppression de clients
   - Gestion des informations de contact

3. **Fournisseurs** (`/suppliers`)
   - Liste des fournisseurs avec pagination
   - Recherche par nom, téléphone, email
   - Création/modification/suppression de fournisseurs
   - Gestion des informations de contact

4. **Comptes** (`/accounts`)
   - Gestion des comptes clients et fournisseurs
   - Visualisation des soldes et limites de crédit
   - Création de transactions (crédit/débit/paiement)
   - Historique des transactions
   - Alertes de dépassement de crédit
   - Modification des limites de crédit

#### 🚧 Modules à Implémenter

- Approvisionnements
- Ventes
- Stock/Inventaire
- Rapports

## Comment Tester

### 1. Démarrage de l'Application

```bash
cd logesco_v2
flutter run
```

L'application démarrera directement sur le Dashboard avec un utilisateur fictif (`admin`).

### 2. Navigation

- **Dashboard** : Page d'accueil avec tous les modules
- **Produits** : Cliquez sur la carte "Produits" pour accéder à la gestion des produits
- **Clients** : Cliquez sur la carte "Clients" pour accéder à la gestion des clients
- **Fournisseurs** : Cliquez sur la carte "Fournisseurs" pour accéder à la gestion des fournisseurs
- **Comptes** : Cliquez sur la carte "Comptes" pour accéder à la gestion des comptes

### 3. Test des Fonctionnalités

#### Module Produits
1. Voir la liste des produits
2. Utiliser la recherche
3. Créer un nouveau produit
4. Modifier un produit existant
5. Voir les détails d'un produit

#### Module Clients
1. Voir la liste des clients
2. Utiliser la recherche par nom, téléphone, email
3. Créer un nouveau client
4. Modifier les informations d'un client
5. Voir l'historique des transactions du client

#### Module Fournisseurs
1. Voir la liste des fournisseurs
2. Utiliser la recherche par nom, téléphone, email
3. Créer un nouveau fournisseur
4. Modifier les informations d'un fournisseur
5. Voir l'historique des transactions du fournisseur

#### Module Comptes
1. Voir les comptes clients et fournisseurs (onglets)
2. Utiliser les filtres (solde min/max, dépassement)
3. Cliquer sur un compte pour voir les détails
4. Créer une transaction (paiement, débit, crédit)
5. Modifier la limite de crédit
6. Voir l'historique des transactions

### 4. Configuration Backend

Pour tester avec de vraies données, démarrez le backend :

```bash
cd backend
npm start
```

Puis modifiez `app_config.dart` :
```dart
static const bool useMockServices = false; // Utiliser l'API réelle
```

## Structure de Navigation

```
Dashboard (/)
├── Produits (/products) ✅
│   ├── Liste des produits
│   ├── Créer produit (/products/create)
│   ├── Modifier produit (/products/:id/edit)
│   └── Détails produit (/products/:id)
├── Clients (/customers) ✅
│   └── Liste des clients
├── Fournisseurs (/suppliers) ✅
│   └── Liste des fournisseurs
├── Comptes (/accounts) ✅
│   ├── Liste des comptes (clients/fournisseurs)
│   ├── Détails compte client (/accounts/clients/:id)
│   └── Détails compte fournisseur (/accounts/suppliers/:id)
├── Approvisionnements (/procurement) 🚧
├── Ventes (/sales) 🚧
├── Stock (/inventory) 🚧
└── Rapports (/reports) 🚧
```

## Notes Techniques

- **Mode Développement** : Authentification bypassée avec utilisateur fictif
- **Services Mock** : Données simulées pour les tests sans backend
- **GetX** : Gestion d'état et navigation
- **Responsive Design** : Interface adaptative selon la taille d'écran
- **Material Design** : Interface moderne et cohérente

## Prochaines Étapes

1. Implémenter les modules manquants (Clients, Fournisseurs, etc.)
2. Ajouter plus de données de test
3. Implémenter la synchronisation avec le backend
4. Ajouter les tests unitaires et d'intégration