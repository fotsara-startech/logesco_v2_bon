# Guide d'Installation - LOGESCO v2 (Production Locale)

Ce guide détaille l'installation complète de LOGESCO v2 pour un déploiement en production locale (sans Docker).

## 📋 Prérequis

### Logiciels Requis

1. **Node.js** (version 18.0.0 ou supérieure)
   - Télécharger depuis: https://nodejs.org/
   - Vérifier l'installation: `node --version`

2. **Flutter** (version 3.5.0 ou supérieure)
   - Télécharger depuis: https://flutter.dev/
   - Vérifier l'installation: `flutter --version`

3. **Git** (pour cloner le projet)
   - Télécharger depuis: https://git-scm.com/

### Configuration Système Minimale

- **RAM**: 4 GB minimum (8 GB recommandé)
- **Espace disque**: 2 GB minimum
- **Système d'exploitation**: Windows 10/11, macOS, ou Linux

## 🚀 Installation du Backend

### Étape 1: Préparation

```bash
# Naviguer vers le dossier backend
cd backend

# Installer les dépendances
npm install
```

### Étape 2: Configuration de l'Environnement

Créer un fichier `.env` dans le dossier `backend`:

```env
# Configuration Backend LOGESCO v2
NODE_ENV=production
PORT=8080

# Base de données SQLite (local)
DATABASE_URL="file:./database/logesco.db"

# JWT Configuration
JWT_SECRET=votre-cle-secrete-super-securisee-changez-moi
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# API Configuration
API_VERSION=v1
CORS_ORIGIN=*

# Logging
LOG_LEVEL=info
```


### Étape 3: Configuration de la Base de Données

```bash
# Générer le client Prisma
npx prisma generate

# Créer et initialiser la base de données
node scripts/setup-database.js

# Appliquer les migrations
npm run migrate:deploy

# Appliquer les index de performance
npm run db:indexes
```

### Étape 4: Vérification de l'Installation

```bash
# Tester la validation
npm run test:validation

# Tester l'authentification
npm run test:auth

# Démarrer le serveur
npm start
```

Le backend devrait être accessible sur: `http://localhost:8080`

### Étape 5: Script d'Installation Automatique (Windows)

Vous pouvez utiliser le script `setup-backend.bat` pour automatiser l'installation:

```bash
# Depuis la racine du projet
setup-backend.bat
```

## 📱 Installation du Frontend Flutter

### Étape 1: Préparation

```bash
# Naviguer vers le dossier Flutter
cd logesco_v2

# Installer les dépendances Flutter
flutter pub get
```

### Étape 2: Configuration de l'API

Créer ou modifier le fichier de configuration API dans `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiVersion = 'v1';
  
  static String get apiUrl => '$baseUrl/api/$apiVersion';
}
```

### Étape 3: Build de l'Application

#### Pour Windows Desktop:

```bash
# Build en mode release
flutter build windows --release

# L'exécutable sera dans: build/windows/runner/Release/
```

#### Pour Android:

```bash
# Build APK
flutter build apk --release

# Build App Bundle (pour Play Store)
flutter build appbundle --release
```

#### Pour iOS (macOS uniquement):

```bash
# Build iOS
flutter build ios --release
```


### Étape 4: Exécution en Mode Développement

```bash
# Lancer l'application en mode debug
flutter run

# Lancer sur un appareil spécifique
flutter run -d windows
flutter run -d chrome
```

## 🔧 Configuration Avancée

### Sécurité

#### 1. Changer le Secret JWT

Dans le fichier `backend/.env`, modifiez:

```env
JWT_SECRET=votre-nouvelle-cle-tres-securisee-minimum-32-caracteres
```

**Important**: Utilisez une clé aléatoire forte. Exemple de génération:

```bash
# Avec Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

#### 2. Configuration CORS

Pour limiter l'accès à des domaines spécifiques:

```env
CORS_ORIGIN=http://localhost:3000,http://192.168.1.100:8080
```

### Performance

#### 1. Optimisation de la Base de Données

Les index de performance sont automatiquement appliqués. Pour les réappliquer:

```bash
cd backend
npm run db:indexes
```

#### 2. Logs de Production

Configurer le niveau de logs:

```env
LOG_LEVEL=warn  # Options: error, warn, info, debug
```

### Sauvegarde et Restauration

#### Sauvegarde de la Base de Données

```bash
# Copier le fichier SQLite
copy backend\database\logesco.db backend\database\logesco.backup.db
```

#### Restauration

```bash
# Restaurer depuis une sauvegarde
copy backend\database\logesco.backup.db backend\database\logesco.db
```


## 🌐 Déploiement sur Réseau Local

### Configuration du Backend

1. **Identifier l'adresse IP locale**:

```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
```

2. **Modifier le port d'écoute** (optionnel):

Dans `backend/.env`:

```env
PORT=8080
```

3. **Configurer le pare-feu**:

- Windows: Autoriser le port 8080 dans le Pare-feu Windows
- Aller dans: Panneau de configuration > Pare-feu Windows > Paramètres avancés
- Créer une règle entrante pour le port 8080

### Configuration du Frontend

Modifier `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // Remplacer localhost par l'IP du serveur
  static const String baseUrl = 'http://192.168.1.100:8080';
  static const String apiVersion = 'v1';
  
  static String get apiUrl => '$baseUrl/api/$apiVersion';
}
```

### Accès depuis d'Autres Appareils

1. Le serveur backend doit être démarré sur la machine hôte
2. Les autres appareils doivent être sur le même réseau
3. Utiliser l'adresse IP de la machine hôte dans la configuration

## 🔍 Vérification et Tests

### Vérifier le Backend

```bash
# Test de santé de l'API
curl http://localhost:8080/

# Test d'authentification
npm run test:auth

# Tests complets
npm test
```

### Vérifier le Frontend

```bash
# Analyser le code
flutter analyze

# Lancer les tests
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📊 Monitoring et Maintenance

### Logs du Backend

Les logs sont stockés dans `backend/logs/`:

```bash
# Voir les logs en temps réel
tail -f backend/logs/combined.log

# Windows PowerShell
Get-Content backend\logs\combined.log -Wait
```

### Nettoyage

```bash
# Nettoyer les utilisateurs de test
cd backend
npm run db:cleanup

# Reset complet de la base (ATTENTION: supprime toutes les données)
npm run db:reset
```


## 🚨 Dépannage

### Problème: Le backend ne démarre pas

**Solution 1**: Vérifier les dépendances

```bash
cd backend
npm install
npx prisma generate
```

**Solution 2**: Vérifier le port

```bash
# Vérifier si le port 8080 est utilisé
netstat -ano | findstr :8080

# Changer le port dans .env si nécessaire
PORT=8081
```

### Problème: Erreur de base de données

**Solution**: Réinitialiser la base de données

```bash
cd backend
npm run db:setup
```

### Problème: Erreur JWT

**Solution**: Vérifier la configuration JWT dans `.env`

```env
JWT_SECRET=votre-cle-secrete-minimum-32-caracteres
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
```

### Problème: Flutter ne trouve pas l'API

**Solution 1**: Vérifier l'URL de l'API dans `api_config.dart`

**Solution 2**: Vérifier que le backend est démarré

```bash
curl http://localhost:8080/
```

**Solution 3**: Désactiver temporairement le pare-feu pour tester

### Problème: Erreur de build Flutter

**Solution**: Nettoyer et reconstruire

```bash
flutter clean
flutter pub get
flutter build windows --release
```

## 📦 Structure des Fichiers

```
logesco_app/
├── backend/                    # API Backend Node.js
│   ├── src/                   # Code source
│   ├── prisma/                # Schémas et migrations
│   ├── database/              # Base de données SQLite
│   ├── logs/                  # Fichiers de logs
│   ├── .env                   # Configuration (à créer)
│   └── package.json           # Dépendances Node.js
│
├── logesco_v2/                # Application Flutter
│   ├── lib/                   # Code source Flutter
│   ├── build/                 # Builds compilés
│   ├── pubspec.yaml           # Dépendances Flutter
│   └── integration_test/      # Tests d'intégration
│
├── docker/                    # Configuration Docker (optionnel)
├── setup-backend.bat          # Script d'installation Windows
└── GUIDE_INSTALLATION_PRODUCTION_LOCAL.md  # Ce guide
```


## 🔐 Sécurité en Production

### Checklist de Sécurité

- [ ] Changer le `JWT_SECRET` par une valeur forte et unique
- [ ] Configurer `CORS_ORIGIN` avec les domaines autorisés uniquement
- [ ] Activer HTTPS si accessible depuis Internet
- [ ] Configurer le pare-feu pour limiter l'accès
- [ ] Mettre en place des sauvegardes régulières
- [ ] Définir `NODE_ENV=production`
- [ ] Limiter les logs sensibles (`LOG_LEVEL=warn`)
- [ ] Changer les mots de passe par défaut des utilisateurs

### Recommandations

1. **Sauvegardes automatiques**: Planifier des sauvegardes quotidiennes de `backend/database/logesco.db`
2. **Mises à jour**: Vérifier régulièrement les mises à jour de sécurité
3. **Monitoring**: Surveiller les logs pour détecter les activités suspectes
4. **Accès réseau**: Limiter l'accès au réseau local uniquement si possible

## 📞 Support et Documentation

### Documentation Technique

- [Backend README](backend/README.md) - Documentation complète du backend
- [Authentification JWT](backend/docs/AUTHENTICATION.md) - Guide d'authentification
- [Modèles et Validation](backend/docs/MODELS_AND_VALIDATION.md) - Architecture des données

### Commandes Utiles

```bash
# Backend
cd backend
npm start                    # Démarrer le serveur
npm run dev                  # Mode développement
npm test                     # Lancer les tests
npm run db:setup             # Configuration DB
npm run db:cleanup           # Nettoyer les données de test

# Frontend
cd logesco_v2
flutter run                  # Lancer en mode debug
flutter build windows        # Build Windows
flutter test                 # Lancer les tests
flutter analyze              # Analyser le code
```

## ✅ Checklist d'Installation

### Backend

- [ ] Node.js installé (v18+)
- [ ] Dépendances installées (`npm install`)
- [ ] Fichier `.env` configuré
- [ ] Base de données initialisée (`npm run db:setup`)
- [ ] Tests passés (`npm test`)
- [ ] Serveur démarré (`npm start`)
- [ ] API accessible sur http://localhost:8080

### Frontend

- [ ] Flutter installé (v3.5+)
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Configuration API mise à jour
- [ ] Application compilée (`flutter build`)
- [ ] Tests passés (`flutter test`)
- [ ] Application fonctionnelle

### Production

- [ ] JWT_SECRET changé
- [ ] CORS configuré
- [ ] Pare-feu configuré
- [ ] Sauvegardes planifiées
- [ ] Documentation lue
- [ ] Tests de bout en bout effectués

## 🎉 Félicitations!

Votre installation de LOGESCO v2 est maintenant complète. L'application est prête à être utilisée en production locale.

Pour toute question ou problème, consultez la documentation technique ou les logs d'erreur.

---

**Version du guide**: 1.0.0  
**Dernière mise à jour**: Novembre 2024  
**Projet**: LOGESCO v2 - Système de gestion commerciale
