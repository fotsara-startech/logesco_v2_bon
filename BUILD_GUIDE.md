# Guide de Build - LOGESCO v2 (Déploiement Client Simplifié)

Ce guide explique comment créer un package d'installation simple pour vos clients.

## 🎯 Objectif

Créer un installeur Windows qui permet à un client sans connaissances techniques d'installer LOGESCO v2 en quelques clics.

## 📋 Prérequis pour le Build

### Logiciels Nécessaires

1. **Node.js** (v18+) - https://nodejs.org/
2. **Flutter** (v3.5+) - https://flutter.dev/
3. **InnoSetup** (v6+) - https://jrsoftware.org/isinfo.php
4. **pkg** (installé automatiquement)

### Vérification

```bash
node --version
flutter --version
```

## 🚀 Processus de Build Complet

### Méthode 1: Script Automatique (Recommandé)

```bash
# Depuis la racine du projet
build-production.bat
```

Ce script va:
1. ✅ Compiler le backend en .exe standalone
2. ✅ Copier le backend dans les assets Flutter
4. ✅ Créer le package dans `release/LOGESCO/`

### Méthode 2: Étape par Étape

#### Étape 1: Build du Backend

```bash
cd backend
npm install
npm run build:standalone
cd ..
```

Résultat: `dist/logesco-backend.exe`

#### Étape 2: Préparer les Assets Flutter

```bash
# Créer le dossier assets
mkdir logesco_v2\assets\backend

# Copier le backend
xcopy /E /I /Y dist\* logesco_v2\assets\backend\
```

#### Étape 3: Build Flutter

```bash
cd logesco_v2
flutter clean
flutter pub get
flutter build windows --release
cd ..
```

Résultat: `logesco_v2/build/windows/x64/runner/Release/`

#### Étape 4: Créer le Package

```bash
# Créer le dossier de distribution
mkdir release\LOGESCO

# Copier l'application
xcopy /E /I /Y logesco_v2\build\windows\x64\runner\Release\* release\LOGESCO\

# Copier le backend dans les assets
xcopy /E /I /Y dist\* release\LOGESCO\data\flutter_assets\backend\
```

## 📦 Créer l'Installeur Windows

### Avec InnoSetup

1. **Ouvrir InnoSetup Compiler**
2. **Charger le script**: `installer-setup.iss`
3. **Compiler**: Build > Compile
4. **Résultat**: `release/LOGESCO-v2-Setup.exe`

### En Ligne de Commande

```bash
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer-setup.iss
```

## 📤 Distribution

### Option A: Installeur (Recommandé)

Distribuer uniquement: `release/LOGESCO-v2-Setup.exe`

**Avantages:**
- Un seul fichier
- Installation professionnelle
- Désinstallation propre
- Raccourcis automatiques

### Option B: Dossier Portable

Distribuer le dossier: `release/LOGESCO/`

**Avantages:**
- Pas d'installation requise
- Portable (USB, etc.)
- Aucun privilège admin nécessaire

## 👥 Instructions pour le Client

### Avec l'Installeur

1. Double-cliquer sur `LOGESCO-v2-Setup.exe`
2. Suivre l'assistant d'installation (Suivant > Suivant > Installer)
3. Lancer LOGESCO depuis le menu Démarrer ou le bureau
4. C'est tout! L'application est prête à l'emploi

### Version Portable

1. Extraire le dossier LOGESCO
2. Double-cliquer sur `logesco_v2.exe`
3. C'est tout! Aucune installation requise

## 🔧 Fonctionnement Interne

### Au Premier Démarrage

L'application va automatiquement:

1. ✅ Détecter le backend embarqué
2. ✅ Créer le fichier de configuration (.env)
3. ✅ Initialiser la base de données SQLite
4. ✅ Démarrer le serveur backend en arrière-plan
5. ✅ Créer le compte administrateur par défaut
6. ✅ Afficher l'interface de connexion

**Temps total: ~5-10 secondes**

### Architecture

```
LOGESCO v2.exe (Application Flutter)
  │
  ├─ Au démarrage: Lance backend.exe (invisible)
  │   └─ Backend écoute sur localhost:8080
  │
  ├─ Base de données: SQLite locale
  │   └─ Stockée dans: AppData/backend/database/
  │
  └─ Interface utilisateur Flutter
      └─ Communique avec le backend via HTTP
```

## 🐛 Dépannage du Build

### Erreur: pkg non trouvé

```bash
npm install -g pkg
```

### Erreur: Flutter build échoue

```bash
cd logesco_v2
flutter clean
flutter pub get
flutter build windows --release
```

### Erreur: Backend ne démarre pas

Vérifier que tous les fichiers sont copiés:
- `logesco-backend.exe`
- `.env.example`
- `schema.prisma`

## 📊 Taille du Package

- **Backend standalone**: ~50 MB
- **Application Flutter**: ~30 MB
- **Total**: ~80 MB
- **Installeur compressé**: ~40 MB

## 🔄 Mises à Jour

Pour créer une mise à jour:

1. Modifier le code source
2. Incrémenter la version dans `installer-setup.iss`
3. Relancer `build-production.bat`
4. Créer le nouvel installeur
5. Distribuer aux clients

## ✅ Checklist de Build

Avant de distribuer:

- [ ] Tests complets effectués
- [ ] Version incrémentée
- [ ] Backend compilé sans erreur
- [ ] Flutter compilé en mode release
- [ ] Installeur créé et testé
- [ ] Installation testée sur machine vierge
- [ ] Premier démarrage testé
- [ ] Fonctionnalités principales testées
- [ ] Documentation utilisateur à jour

## 🎉 Résultat Final

Votre client reçoit:
- **Un fichier**: `LOGESCO-v2-Setup.exe` (~40 MB)
- **Installation**: 3 clics (Suivant > Suivant > Installer)
- **Configuration**: Aucune! Tout est automatique
- **Utilisation**: Immédiate après installation

---

**Temps total de build**: ~5-10 minutes  
**Temps d'installation client**: ~1 minute  
**Expérience utilisateur**: ⭐⭐⭐⭐⭐ (Aucune compétence technique requise)
