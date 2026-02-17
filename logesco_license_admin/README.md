# 🔐 LOGESCO License Admin

Interface d'administration pour la gestion des licences LOGESCO.

## ✅ Statut du projet

Le projet est **fonctionnel** et prêt à être utilisé. Tous les composants principaux sont implémentés.

## 🚀 Démarrage rapide

### Installation

```bash
cd logesco_license_admin
flutter pub get
```

### Lancement

```bash
flutter run -d windows
# ou
flutter run -d chrome
```

### Première connexion

- **Mot de passe par défaut**: `admin123`
- Changez-le immédiatement dans Paramètres

## 📦 Fonctionnalités implémentées

### ✅ Gestion des clients
- Ajout, modification, suppression de clients
- Recherche et filtrage
- Historique des licences par client

### ✅ Génération de licences
- Interface de génération intuitive
- Support de 4 types d'abonnement (Trial, Starter, Professional, Enterprise)
- Génération de clés cryptographiques sécurisées
- Validation automatique

### ✅ Dashboard
- Vue d'ensemble des statistiques
- Licences récentes
- Alertes d'expiration
- Actions rapides

### ✅ Sécurité
- Authentification par mot de passe
- Stockage local sécurisé (SQLite)
- Clés de licence signées
- Validation cryptographique

## 📁 Structure du projet

```
lib/
├── core/
│   ├── router/          # Navigation (GoRouter)
│   ├── services/        # Services métier
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   └── license_generator_service.dart
│   └── theme/           # Thème de l'application
├── models/              # Modèles de données
│   ├── client.dart
│   ├── client.g.dart
│   ├── license.dart
│   └── license.g.dart
├── pages/               # Pages de l'application
│   ├── dashboard/
│   ├── clients/
│   ├── licenses/
│   ├── login/
│   └── settings/
├── widgets/             # Composants réutilisables
└── main.dart
```

## 🔑 Types d'abonnement

| Type | Durée | Prix suggéré | Fonctionnalités |
|------|-------|--------------|-----------------|
| **Trial** | 7 jours | Gratuit | Inventaire de base, ventes |
| **Starter** | 1 mois | 29€/mois | Inventaire complet, rapports |
| **Professional** | 12 mois | 299€/an | Toutes fonctionnalités + analytics |
| **Enterprise** | Illimitée | 999€ | Tout + support premium |

## 🛠️ Technologies utilisées

- **Flutter** 3.10+
- **Riverpod** - Gestion d'état
- **GoRouter** - Navigation
- **SQLite** - Base de données locale
- **json_serializable** - Sérialisation JSON
- **crypto** & **pointycastle** - Cryptographie

## 📝 Utilisation

### Générer une licence

1. Allez dans "Clients" et ajoutez un client
2. Cliquez sur "Générer une licence"
3. Sélectionnez le client et le type d'abonnement
4. Générez et copiez la clé
5. Envoyez la clé au client

### Format de clé

```
LOGESCO_V1_eyJ1c2VySWQiOiI...
```

Les clés contiennent :
- ID utilisateur
- Type d'abonnement
- Dates d'émission et d'expiration
- Empreinte de l'appareil
- Fonctionnalités autorisées
- Signature cryptographique

## 🔒 Sécurité

⚠️ **IMPORTANT** : Cet outil est strictement réservé à l'administrateur système.

- Ne partagez jamais cet outil avec les clients
- Gardez vos clés privées en sécurité
- Changez le mot de passe par défaut
- Sauvegardez régulièrement la base de données

## 📊 Base de données

- **Emplacement** : Stockage local de l'application
- **Type** : SQLite
- **Tables** : clients, licenses
- **Sauvegarde** : Manuelle via l'interface

## 🐛 Dépannage

### Erreur de compilation

```bash
flutter clean
flutter pub get
```

### Problème de base de données

La base de données est créée automatiquement au premier lancement.

### Mot de passe oublié

Le mot de passe est stocké dans `shared_preferences`. Pour le réinitialiser, supprimez les données de l'application.

## 📞 Support

Pour toute question ou problème, contactez l'équipe de développement LOGESCO.

---

**Version** : 1.0.0  
**Dernière mise à jour** : Novembre 2025
