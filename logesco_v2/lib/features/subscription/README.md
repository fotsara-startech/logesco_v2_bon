# Module de Gestion des Abonnements

Ce module implémente le système de gestion des abonnements pour Logesco V2, incluant la validation de licences, la gestion des périodes d'essai et les contrôles de sécurité.

## Structure du Module

```
subscription/
├── models/                     # Modèles de données
│   ├── license_data.dart      # Données de licence
│   ├── subscription_status.dart # Statut d'abonnement
│   ├── device_fingerprint.dart # Empreinte d'appareil
│   ├── license_errors.dart    # Types d'erreurs
│   └── models.dart           # Export des modèles
├── services/
│   ├── interfaces/           # Interfaces des services
│   │   ├── i_subscription_manager.dart
│   │   ├── i_license_service.dart
│   │   ├── i_crypto_service.dart
│   │   ├── i_device_service.dart
│   │   └── interfaces.dart
│   └── implementations/      # Implémentations (à venir)
├── controllers/              # Contrôleurs (à venir)
├── views/                   # Interfaces utilisateur (à venir)
└── subscription.dart        # Export principal
```

## Fonctionnalités Principales

### 1. Types d'Abonnement
- **Trial**: Période d'essai gratuite de 7 jours
- **Monthly**: Abonnement mensuel
- **Annual**: Abonnement annuel
- **Lifetime**: Abonnement à vie

### 2. Modèles de Données

#### LicenseData
Contient toutes les informations d'une licence d'activation :
- Identifiant utilisateur
- Clé de licence
- Type d'abonnement
- Dates d'émission et d'expiration
- Empreinte d'appareil
- Signature cryptographique

#### SubscriptionStatus
Représente l'état actuel de l'abonnement :
- Statut actif/inactif
- Type d'abonnement
- Jours restants
- Période de grâce
- Avertissements

#### DeviceFingerprint
Empreinte unique de l'appareil :
- Identifiants matériels
- Informations système
- Hash combiné
- Date de génération

### 3. Services (Interfaces)

#### ISubscriptionManager
Gestionnaire principal orchestrant tous les services :
- Gestion des statuts d'abonnement
- Activation de licences
- Contrôles périodiques
- Notifications

#### ILicenseService
Service de validation des licences :
- Validation cryptographique
- Stockage sécurisé
- Vérification d'intégrité

#### ICryptoService
Service cryptographique :
- Signatures RSA
- Chiffrement AES
- Génération de hash
- Vérification d'intégrité

#### IDeviceService
Service d'empreinte d'appareil :
- Génération d'empreinte unique
- Détection de changements
- Stockage sécurisé

## Dépendances Ajoutées

- `crypto: ^3.0.3` - Fonctions cryptographiques
- `device_info_plus: ^10.1.0` - Informations d'appareil
- `flutter_secure_storage: ^9.0.0` - Stockage sécurisé (déjà présent)

## Prochaines Étapes

1. Implémenter les services cryptographiques
2. Développer le service d'empreinte d'appareil
3. Créer le service de validation des licences
4. Implémenter le gestionnaire principal
5. Développer les interfaces utilisateur
6. Ajouter les mesures de sécurité avancées

## Sécurité

Le module est conçu avec plusieurs couches de sécurité :
- Validation cryptographique RSA 2048 bits
- Empreinte d'appareil unique
- Stockage chiffré des données
- Détection de manipulation
- Obfuscation du code (à implémenter)

## Usage

```dart
import 'package:logesco_v2/features/subscription/subscription.dart';

// Les implémentations seront disponibles dans les prochaines tâches
```