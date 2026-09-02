# Scripts Disponibles - LOGESCO v2

## 🚀 Scripts Principaux

### 1. preparer-pour-client.bat ⭐ RECOMMANDÉ

**Usage**: Préparer un package complet pour le client

```batch
preparer-pour-client.bat
```

**Ce qu'il fait**:
- Construit le backend portable
- Construit l'application Flutter
- Crée un package complet dans `release\LOGESCO-Client\`
- Génère les scripts de démarrage
- Crée les instructions

**Résultat**: Dossier prêt à compresser et envoyer au client

---

### 2. build-portable-backend.bat

**Usage**: Construire uniquement le backend portable

```batch
build-portable-backend.bat
```

**Ce qu'il fait**:
- Installe les dépendances
- Génère le client Prisma
- Crée le package dans `dist-portable\`
- Crée les scripts de démarrage

**Résultat**: Backend prêt à distribuer

---

### 3. build-production.bat

**Usage**: Build complet (ancien système, mis à jour)

```batch
build-production.bat
```

**Ce qu'il fait**:
- Construit le backend portable
- Construit l'application Flutter
- Crée le package dans `release\LOGESCO\`

**Note**: Utilise maintenant le système portable

---

### 4. rebuild-backend-production.bat

**Usage**: Reconstruire le backend avec l'ancien système (exe)

```batch
rebuild-backend-production.bat
```

**⚠️ Attention**: Ce script utilise l'ancien système de compilation en `.exe` qui **ne fonctionne plus** avec Prisma. Utilisez plutôt `build-portable-backend.bat`.

---

## 🧪 Scripts de Test

### test-prisma-loader.js

**Usage**: Tester le chargeur Prisma

```batch
node test-prisma-loader.js
```

**Ce qu'il fait**:
- Vérifie que le loader Prisma fonctionne
- Vérifie que les fichiers Prisma sont présents
- Teste la création d'une instance Prisma

---

### fix-prisma-imports.js

**Usage**: Corriger les imports Prisma dans le code

```batch
node fix-prisma-imports.js
```

**Ce qu'il fait**:
- Remplace tous les imports `@prisma/client` par le loader compatible
- Met à jour tous les fichiers source

**Note**: Déjà exécuté, pas besoin de le relancer

---

## 📦 Scripts Backend (dans dist-portable/)

### start-backend.bat

**Usage**: Démarrer le backend manuellement

```batch
cd dist-portable
start-backend.bat
```

**Ce qu'il fait**:
- Démarre le serveur Node.js
- Crée la base de données si nécessaire
- Applique les migrations
- Crée l'utilisateur admin

---

### install-service.bat

**Usage**: Installer le backend comme service Windows

```batch
cd dist-portable
install-service.bat
```

**Prérequis**: NSSM (Non-Sucking Service Manager)

**Ce qu'il fait**:
- Installe le backend comme service Windows
- Configure le démarrage automatique
- Le backend démarre au boot

---

## 🎯 Scripts Client (dans release/LOGESCO-Client/)

### DEMARRER-LOGESCO.bat

**Usage**: Démarrer backend + application

```batch
cd release\LOGESCO-Client
DEMARRER-LOGESCO.bat
```

**Ce qu'il fait**:
- Démarre le backend en arrière-plan
- Attend 5 secondes
- Ouvre l'application Flutter

**Note**: C'est le script que le client utilise

---

## 🔧 Scripts de Développement

### backend/build-standalone.js (ancien)

**Usage**: Ancien script de build exe

```batch
cd backend
node build-standalone.js
```

**⚠️ Obsolète**: Ne fonctionne plus avec Prisma

---

### backend/build-standalone-v2.js (ancien)

**Usage**: Version 2 du build exe

```batch
cd backend
node build-standalone-v2.js
```

**⚠️ Obsolète**: Ne fonctionne plus avec Prisma

---

### backend/build-portable.js ⭐ NOUVEAU

**Usage**: Script de build portable (utilisé par build-portable-backend.bat)

```batch
cd backend
node build-portable.js
```

**Ce qu'il fait**:
- Copie les fichiers source
- Installe les dépendances de production
- Génère le client Prisma
- Crée les scripts de démarrage

---

## 📊 Comparaison des Scripts

| Script | Usage | Résultat | Recommandé |
|--------|-------|----------|------------|
| **preparer-pour-client.bat** | Package complet | `release\LOGESCO-Client\` | ⭐⭐⭐⭐⭐ |
| **build-portable-backend.bat** | Backend seul | `dist-portable\` | ⭐⭐⭐⭐ |
| **build-production.bat** | Build complet | `release\LOGESCO\` | ⭐⭐⭐ |
| rebuild-backend-production.bat | Ancien système | `dist\` (exe) | ❌ Obsolète |

---

## 🎯 Quel Script Utiliser?

### Pour Distribuer au Client

```batch
preparer-pour-client.bat
```

→ Crée un package complet prêt à envoyer

### Pour Tester le Backend Seul

```batch
build-portable-backend.bat
cd dist-portable
start-backend.bat
```

### Pour Tester l'Application Seule

```batch
cd logesco_v2
flutter run -d windows
```

### Pour Construire l'Application Flutter

```batch
cd logesco_v2
flutter build windows --release
```

---

## 🆘 Dépannage

### "Le script ne fonctionne pas"

1. Vérifier que vous êtes dans le bon dossier
2. Vérifier que Node.js est installé: `node --version`
3. Vérifier que Flutter est installé: `flutter --version`

### "Erreur lors du build"

1. Nettoyer les anciens builds:
   ```batch
   rmdir /s /q dist-portable
   rmdir /s /q release
   ```

2. Relancer le script

### "Cannot find module"

1. Installer les dépendances:
   ```batch
   cd backend
   npm install
   npx prisma generate
   ```

2. Relancer le script

---

## 📝 Notes Importantes

1. **Toujours utiliser** `preparer-pour-client.bat` pour créer un package client
2. **Ne jamais supprimer** le dossier `node_modules` dans `dist-portable`
3. **Tester localement** avant d'envoyer au client
4. **Les anciens scripts** (build-standalone.js, etc.) sont obsolètes

---

## ✅ Workflow Recommandé

```batch
# 1. Développement
cd backend
npm run dev

# 2. Test
cd logesco_v2
flutter run -d windows

# 3. Build pour client
preparer-pour-client.bat

# 4. Test du package
cd release\LOGESCO-Client
DEMARRER-LOGESCO.bat

# 5. Distribution
# Compresser release\LOGESCO-Client\ en ZIP
# Envoyer au client
```

---

**Tous les scripts sont prêts et fonctionnels!** 🚀
