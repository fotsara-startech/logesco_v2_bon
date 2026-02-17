# LOGESCO v2 - Système de Gestion Commerciale

## 🎯 Vue d'Ensemble

LOGESCO v2 est un système de gestion commerciale moderne avec une architecture hybride Flutter + Node.js, conçu pour un déploiement client ultra-simplifié.

## ✨ Caractéristiques Principales

- **Interface Flutter** moderne et intuitive
- **Backend Node.js** embarqué et autonome
- **Base de données JSON** locale (pas de serveur requis)
- **Authentification JWT** complète
- **Installation en 3 clics** pour les clients
- **Fonctionnement 100% offline**

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           LOGESCO v2 Client             │
├─────────────────────────────────────────┤
│  Flutter App (logesco_v2.exe)          │
│  ├─ Interface utilisateur               │
│  ├─ Gestion d'état (GetX)              │
│  └─ Communication HTTP avec backend    │
├─────────────────────────────────────────┤
│  Backend Standalone (logesco-backend)  │
│  ├─ Serveur Express.js                 │
│  ├─ API REST complète                  │
│  ├─ Authentification JWT               │
│  └─ Base de données JSON locale        │
├─────────────────────────────────────────┤
│  Données Locales                       │
│  ├─ AppData\Local\LOGESCO\backend\     │
│  ├─ logesco.json (base de données)     │
│  └─ logs\ (fichiers de logs)           │
└─────────────────────────────────────────┘
```

## 🚀 Démarrage Rapide

### Pour les Développeurs

#### Prérequis
- Node.js 18+
- Flutter 3.5+
- InnoSetup (pour l'installeur)

#### Installation
```bash
# Cloner le projet
git clone [URL_DU_PROJET]
cd logesco_app

# Installer les dépendances backend
cd backend
npm install

# Installer les dépendances Flutter
cd ../logesco_v2
flutter pub get
```

#### Développement
```bash
# Backend (terminal 1)
cd backend
npm run dev

# Flutter (terminal 2)
cd logesco_v2
flutter run -d windows
```

#### Build Production
```bash
# Build automatique complet
build-production.bat

# Créer l'installeur
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer-setup.iss
```

### Pour les Clients

#### Installation
1. Télécharger `LOGESCO-v2-Setup.exe`
2. Double-cliquer et suivre l'assistant
3. Lancer LOGESCO depuis le bureau

#### Utilisation
- **Connexion par défaut**: admin@logesco.com / admin123
- **Aucune configuration** requise
- **Fonctionne immédiatement** après installation

## 📁 Structure du Projet

```
logesco_app/
├── backend/                     # Backend Node.js
│   ├── src/
│   │   ├── routes/             # Routes API
│   │   ├── services/           # Services métier
│   │   ├── database/           # Adaptateurs DB
│   │   ├── server-standalone.js # Point d'entrée standalone
│   │   └── server-simple.js    # Serveur Express simplifié
│   ├── build-standalone-v2.js  # Script de build
│   └── package.json            # Dépendances
│
├── logesco_v2/                 # Application Flutter
│   ├── lib/
│   │   ├── core/
│   │   │   └── services/
│   │   │       └── backend_service.dart # Service backend
│   │   ├── features/           # Modules fonctionnels
│   │   └── main.dart          # Point d'entrée
│   └── pubspec.yaml           # Dépendances Flutter
│
├── build-production.bat        # Build automatique
├── installer-setup.iss         # Script InnoSetup
├── test-deployment.bat         # Tests automatisés
└── docs/                      # Documentation
    ├── SOLUTION_FINALE_REUSSIE.md
    ├── COMMANDES_ESSENTIELLES.md
    └── TEST_FINAL_DEPLOYMENT.md
```

## 🔧 Technologies Utilisées

### Frontend
- **Flutter 3.5+** - Framework UI multiplateforme
- **GetX** - Gestion d'état et navigation
- **HTTP** - Communication avec l'API
- **Dart** - Langage de programmation

### Backend
- **Node.js 18+** - Runtime JavaScript
- **Express.js** - Framework web
- **JWT** - Authentification
- **bcryptjs** - Hachage des mots de passe
- **pkg** - Compilation en exécutable

### Base de Données
- **JSON** - Stockage local simple et efficace
- **Pas de serveur** de base de données requis

### Outils
- **InnoSetup** - Création d'installeurs Windows
- **pkg** - Packaging Node.js en exécutable
- **Flutter Build** - Compilation multiplateforme

## 📊 Métriques

### Performance
- **Démarrage**: ~10 secondes
- **Taille mémoire**: ~100 MB
- **Taille disque**: ~50 MB installé

### Distribution
- **Installeur**: ~25 MB compressé
- **Installation**: ~1 minute
- **Configuration**: 0 (automatique)

## 🎯 Fonctionnalités

### Authentification
- [x] Connexion/Déconnexion
- [x] Gestion des sessions JWT
- [x] Tokens de rafraîchissement
- [x] Compte admin par défaut

### Gestion des Utilisateurs
- [x] Création d'utilisateurs
- [x] Rôles et permissions
- [x] Profils utilisateur

### API REST
- [x] Endpoints d'authentification
- [x] Gestion des erreurs
- [x] Validation des données
- [x] Logs détaillés

### Interface Utilisateur
- [x] Design moderne Flutter
- [x] Navigation intuitive
- [x] Responsive design
- [x] Thème cohérent

## 🔒 Sécurité

- **Authentification JWT** avec tokens sécurisés
- **Hachage bcrypt** des mots de passe
- **Validation stricte** des données d'entrée
- **Headers de sécurité** automatiques
- **Données locales** uniquement (pas de cloud)

## 📈 Évolutivité

### Modules Prévus
- [ ] Gestion des produits
- [ ] Gestion du stock
- [ ] Facturation
- [ ] Rapports et statistiques
- [ ] Import/Export de données

### Architecture Extensible
- Services modulaires
- API REST standardisée
- Base de données évolutive
- Interface componentisée

## 🆘 Support

### Documentation

#### Documentation Utilisateur
- [📖 Index de la Documentation](docs/README.md) - Point d'entrée principal
- [🎯 Guide Utilisateur](docs/GUIDE_UTILISATEUR.md) - Guide complet pour les utilisateurs
- [🎓 Guide de Formation](docs/GUIDE_FORMATION.md) - Modules de formation structurés
- [🎬 Scripts Vidéos](docs/SCRIPTS_VIDEOS_FORMATION.md) - Scripts pour vidéos tutorielles

#### Documentation Technique
- [💻 Documentation Technique](docs/DOCUMENTATION_TECHNIQUE.md) - Architecture et développement
- [🔧 Guide d'Installation](docs/GUIDE_INSTALLATION.md) - Installation Desktop et Web
- [🛠️ Guide de Maintenance](docs/GUIDE_MAINTENANCE.md) - Maintenance et optimisation
- [🚨 Guide de Dépannage](docs/GUIDE_DEPANNAGE_COMPLET.md) - Résolution de problèmes

#### Guides Rapides
- [⚡ Guide Rapide Client](GUIDE_RAPIDE_CLIENT.md) - Distribution simplifiée
- [🚀 Quick Start](QUICK_START.md) - Démarrage rapide développeur
- [📦 Fichiers pour Client](FICHIERS_POUR_CLIENT.md) - Packaging et distribution

### Dépannage
- Logs disponibles dans `AppData\Local\LOGESCO\`
- API de santé: `http://localhost:8080/health`
- Tests automatisés: `test-deployment.bat`

### Contact
- **Développeur**: [Votre nom]
- **Email**: [Votre email]
- **Documentation**: Voir dossier `docs/`

## 📄 Licence

Projet privé LOGESCO v2 - Tous droits réservés.

---

**Version**: 1.0.0  
**Dernière mise à jour**: Novembre 2025  
**Statut**: ✅ Production Ready