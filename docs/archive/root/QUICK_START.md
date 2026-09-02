# 🚀 Démarrage Rapide - LOGESCO v2

## Pour les Développeurs

### Build Complet en 1 Commande

```bash
build-production.bat
```

**Résultat**: Package prêt dans `release/LOGESCO/`

### Créer l'Installeur

1. Installer InnoSetup: https://jrsoftware.org/isinfo.php
2. Compiler le script:
```bash
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer-setup.iss
```

**Résultat**: `release/LOGESCO-v2-Setup.exe`

### Tester Localement

```bash
cd release\LOGESCO
logesco_v2.exe
```

## Pour les Clients

### Installation

1. Double-cliquer sur `LOGESCO-v2-Setup.exe`
2. Suivre l'assistant (3 clics)
3. Lancer LOGESCO

**Temps total: ~1 minute**

### Utilisation

1. Ouvrir LOGESCO depuis le bureau ou menu Démarrer
2. Se connecter avec les identifiants
3. Commencer à travailler

**Aucune configuration requise!**

## 📁 Structure du Projet

```
logesco_app/
├── backend/                          # Backend Node.js
│   ├── build-standalone.js          # Script de build backend
│   └── package.json                 # Dépendances
│
├── logesco_v2/                      # Application Flutter
│   ├── lib/
│   │   └── core/services/
│   │       └── backend_service.dart # Gestion du backend
│   ├── assets/backend/              # Backend embarqué
│   └── pubspec.yaml                 # Configuration
│
├── build-production.bat             # Build automatique
├── installer-setup.iss              # Script InnoSetup
├── BUILD_GUIDE.md                   # Guide détaillé
└── CLIENT_README.md                 # Guide utilisateur
```

## 🎯 Workflow de Développement

### 1. Développement

```bash
# Backend
cd backend
npm run dev

# Flutter (autre terminal)
cd logesco_v2
flutter run
```

### 2. Tests

```bash
# Backend
cd backend
npm test

# Flutter
cd logesco_v2
flutter test
```

### 3. Build Production

```bash
# Tout en une fois
build-production.bat

# Ou étape par étape
cd backend && npm run build:standalone
cd ../logesco_v2 && flutter build windows --release
```

### 4. Distribution

```bash
# Créer l'installeur
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer-setup.iss

# Distribuer
# Envoyer: release/LOGESCO-v2-Setup.exe
```

## 🔑 Points Clés

### Architecture

- **Backend**: Node.js compilé en .exe standalone
- **Frontend**: Flutter Windows application
- **Base de données**: SQLite embarquée
- **Communication**: HTTP localhost:8080

### Avantages

✅ **Un seul fichier** à distribuer (installeur)  
✅ **Aucune configuration** requise  
✅ **Fonctionne offline** (100% local)  
✅ **Installation simple** (3 clics)  
✅ **Pas de dépendances** externes  
✅ **Portable** (peut fonctionner sans installation)

### Expérience Client

1. **Téléchargement**: 1 fichier (~40 MB)
2. **Installation**: 3 clics, ~30 secondes
3. **Premier démarrage**: Automatique, ~10 secondes
4. **Utilisation**: Immédiate

## 📊 Checklist de Release

Avant de distribuer aux clients:

- [ ] Code testé et validé
- [ ] Version incrémentée
- [ ] Build production créé
- [ ] Installeur testé sur machine vierge
- [ ] Documentation à jour
- [ ] Notes de version préparées

## 🆘 Dépannage Rapide

### Build échoue

```bash
# Nettoyer et recommencer
cd backend && npm install && npm run build:standalone
cd ../logesco_v2 && flutter clean && flutter pub get && flutter build windows
```

### Backend ne démarre pas

Vérifier:
1. `logesco-backend.exe` existe dans `assets/backend/`
2. `.env.example` est présent
3. Dossiers `database/` et `logs/` créés

### Application ne se connecte pas

Vérifier:
1. Backend est démarré (vérifier les logs)
2. Port 8080 est libre
3. Pare-feu n'est pas bloquant

## 📞 Support

- **Documentation complète**: `BUILD_GUIDE.md`
- **Guide client**: `CLIENT_README.md`
- **Installation production**: `GUIDE_INSTALLATION_PRODUCTION_LOCAL.md`

---

**Temps de build**: ~5-10 minutes  
**Temps d'installation client**: ~1 minute  
**Complexité pour le client**: ⭐ (Très simple)
