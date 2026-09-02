# Système de Rôles et Permissions - LOGESCO v2

## 🎯 Objectif
Implémenter un système complet de contrôle d'accès basé sur les rôles utilisateur, où chaque utilisateur ne voit que les modules auxquels il a accès selon son rôle.

## ✅ Fonctionnalités Implémentées

### 1. Service d'Autorisation (`AuthorizationService`)
- **Localisation**: `logesco_v2/lib/core/services/authorization_service.dart`
- **Fonctionnalités**:
  - Gestion de l'utilisateur actuel
  - Vérification des permissions par rôle
  - Méthodes de vérification granulaires
  - Support pour la simulation d'utilisateurs (mode test)

### 2. Modèles Utilisateur Complets
- **Localisation**: `logesco_v2/lib/features/users/models/user_model.dart`
- **Fonctionnalités**:
  - Modèle `User` avec rôle intégré
  - Modèle `UserRole` avec privilèges
  - Modèle `UserPrivileges` avec permissions granulaires
  - Support pour les formats API (List) et détaillés (Map)

### 3. Widgets Conditionnels
- **Localisation**: `logesco_v2/lib/core/widgets/permission_widget.dart`
- **Widgets disponibles**:
  - `PermissionWidget`: Affichage conditionnel basé sur les permissions
  - `PermissionButton`: Bouton avec contrôle d'accès
  - `PermissionFAB`: FloatingActionButton conditionnel

### 4. Dashboard avec Contrôle d'Accès
- **Localisation**: `logesco_v2/lib/features/dashboard/views/dashboard_page.dart`
- **Fonctionnalités**:
  - Filtrage automatique des modules selon les permissions
  - Affichage conditionnel des modules
  - Messages d'erreur pour accès refusé
  - Indicateurs visuels pour les modules admin

### 5. Vue de Test des Rôles
- **Localisation**: `logesco_v2/lib/features/users/views/role_test_view.dart`
- **Fonctionnalités**:
  - Affichage de l'utilisateur actuel et ses privilèges
  - Simulation de connexion avec différents utilisateurs
  - Matrice des permissions en temps réel
  - Interface de test interactive

## 🔐 Rôles Configurés

### 👑 Administrateur
- **Privilèges**: Tous les droits
- **Modules accessibles**: Tous les modules
- **Utilisateur test**: `admin`

### 👨‍💼 Gestionnaire
- **Privilèges**: Gestion produits, ventes, inventaire, stock, rapports
- **Modules accessibles**: Produits, Fournisseurs, Clients, Approvisionnements, Ventes, Stock, Impression, Comptes, Rapports, Inventaire Stock
- **Utilisateur test**: `TATIANA MEDOUMA`

### 🛒 Vendeur
- **Privilèges**: Ventes et consultation rapports
- **Modules accessibles**: Clients, Ventes, Impression, Comptes, Rapports
- **Utilisateur test**: `vendeur`

### 📦 Magasinier
- **Privilèges**: Inventaire, stock, produits
- **Modules accessibles**: Produits, Fournisseurs, Approvisionnements, Stock, Inventaire Stock

### 📊 Comptable
- **Privilèges**: Rapports et paramètres entreprise
- **Modules accessibles**: Rapports, Paramètres

### 👤 Utilisateur
- **Privilèges**: Consultation rapports uniquement
- **Modules accessibles**: Rapports

## 🔧 Permissions Définies

| Permission | Description |
|------------|-------------|
| `products.view` | Voir les produits |
| `products.manage` | Gérer les produits |
| `suppliers.view` | Voir les fournisseurs |
| `customers.view` | Voir les clients |
| `sales.make` | Effectuer des ventes |
| `sales.view` | Voir les ventes |
| `stock.view` | Voir le stock |
| `inventory.view` | Voir l'inventaire |
| `reports.view` | Voir les rapports |
| `settings.company` | Paramètres entreprise |
| `users.manage` | Gérer les utilisateurs |
| `cash.manage` | Gérer les caisses |

## 🚀 Comment Tester

### 1. Via l'Application Flutter
```bash
flutter run
```
1. Naviguez vers le Dashboard
2. Cliquez sur le bouton "Test Rôles" (icône sécurité rouge)
3. Changez d'utilisateur avec les boutons disponibles
4. Observez que les modules du dashboard changent selon le rôle

### 2. Via le Script de Test
```bash
dart test_permissions_simple.dart
```

### 3. Utilisateurs de Test Disponibles
- **admin**: Administrateur avec tous les droits
- **vendeur**: Vendeur avec droits limités
- **TATIANA MEDOUMA**: Gestionnaire avec droits étendus

## 📁 Structure des Fichiers

```
logesco_v2/
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   └── authorization_service.dart
│   │   ├── widgets/
│   │   │   └── permission_widget.dart
│   │   └── middleware/
│   │       └── auth_middleware.dart
│   └── features/
│       ├── users/
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── views/
│       │       └── role_test_view.dart
│       └── dashboard/
│           └── views/
│               └── dashboard_page.dart
```

## 🔄 Flux de Fonctionnement

1. **Initialisation**: L'`AuthorizationService` charge l'utilisateur actuel
2. **Vérification**: Chaque module vérifie les permissions requises
3. **Filtrage**: Le dashboard affiche uniquement les modules autorisés
4. **Navigation**: Les tentatives d'accès non autorisées sont bloquées
5. **Feedback**: Messages d'erreur explicites pour les accès refusés

## 🎉 Résultat

Le système de rôles est maintenant **entièrement fonctionnel** :
- ✅ Les utilisateurs ne voient que les modules autorisés
- ✅ Les permissions sont vérifiées à chaque navigation
- ✅ Interface de test disponible pour validation
- ✅ Système extensible pour de nouveaux rôles/permissions
- ✅ Intégration complète avec l'API backend

Le problème initial est **résolu** : les modules n'apparaissent plus si l'utilisateur n'a pas les permissions correspondantes.