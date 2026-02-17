# LOGESCO v2

Système de gestion commerciale moderne développé avec Flutter et une architecture hybride.

## Architecture

LOGESCO v2 utilise une architecture hybride permettant un déploiement local (hors ligne) ET cloud selon les besoins clients.

### Stack Technologique

- **Frontend**: Flutter (Desktop & Web)
- **State Management**: GetX
- **Backend**: API REST (Node.js/Express ou Python/FastAPI)
- **Base de données**: SQLite (local) / PostgreSQL (cloud)

### Structure du Projet

```
lib/
├── core/                    # Couche de base
│   ├── api/                # Client API et services
│   ├── config/             # Configuration d'environnement
│   ├── constants/          # Constantes globales
│   ├── models/             # Modèles de données partagés
│   ├── utils/              # Utilitaires et exceptions
│   ├── bindings/           # Injection de dépendances GetX
│   └── routes/             # Configuration des routes
├── features/               # Modules fonctionnels
│   ├── auth/               # Authentification
│   ├── dashboard/          # Tableau de bord
│   ├── products/           # Gestion des produits
│   ├── suppliers/          # Gestion des fournisseurs
│   ├── customers/          # Gestion des clients
│   ├── procurement/        # Approvisionnements
│   ├── sales/              # Ventes
│   ├── inventory/          # Gestion du stock
│   └── accounts/           # Comptes clients/fournisseurs
└── shared/                 # Composants partagés
    ├── widgets/            # Widgets réutilisables
    └── themes/             # Thèmes de l'application
```

## Fonctionnalités Implémentées

### ✅ Tâche 1 - Configuration de l'environnement de développement

- [x] Projet Flutter initialisé avec support desktop et web
- [x] GetX configuré pour la gestion d'état et l'injection de dépendances
- [x] Structure de dossiers selon l'architecture définie
- [x] Environnement de développement configuré avec hot reload
- [x] Thème de l'application personnalisé
- [x] Pages d'authentification de base (Splash, Login)
- [x] Tableau de bord principal avec navigation vers les modules
- [x] Client API centralisé avec gestion d'erreurs
- [x] Configuration d'environnement adaptative (local/cloud)

## Commandes de Développement

### Installation des dépendances
```bash
flutter pub get
```

### Lancement en mode développement
```bash
# Web
flutter run -d chrome

# Desktop Windows
flutter run -d windows
```

### Build de production
```bash
# Web
flutter build web

# Desktop Windows
flutter build windows
```

### Tests et analyse
```bash
# Analyse du code
flutter analyze

# Tests unitaires
flutter test
```

## Prochaines Étapes

Les prochaines tâches d'implémentation incluent :

1. **Tâche 2** - Implémentation de la couche API backend hybride
2. **Tâche 3** - Développement des modèles de données et migrations
3. **Tâche 4** - Implémentation de la gestion des produits
4. Et ainsi de suite selon le plan d'implémentation...

## Configuration

L'application détecte automatiquement l'environnement :
- **Mode Local** : SQLite + API locale (port 8080)
- **Mode Web** : PostgreSQL + API cloud
- **Mode Desktop** : Configuration adaptative

## Dépendances Principales

- `get: ^4.6.6` - State management et injection de dépendances
- `http: ^1.1.0` - Client HTTP pour les appels API
- `shared_preferences: ^2.2.2` - Stockage local
- `flutter_secure_storage: ^9.0.0` - Stockage sécurisé des tokens

## Contribution

Ce projet suit les spécifications définies dans `.kiro/specs/logesco-v2/` :
- `requirements.md` - Exigences fonctionnelles
- `design.md` - Architecture et conception
- `tasks.md` - Plan d'implémentation détaillé
