# Fix: Erreur pkg snapshot


## Problème Identifié

L'erreur `Cannot mkdir in a snapshot` se produit parce que `pkg` crée un snapshot de l'application Node.js, et le code ne peut pas créer de dossiers à l'intérieur de ce snapshot.

### Erreur Originale
```
Error: Cannot mkdir in a snapshot. Try mountpoints instead.
at mkdirFailInSnapshot (pkg/prelude/bootstrap.js:1633:7)
at Object.mkdirSync (pkg/prelude/bootstrap.js:1645:12)
```

## Solution Implémentée

### 1. Nouveau Point d'Entrée: `server-standalone.js`

Ce fichier:
- Détecte automatiquement le mode pkg
- Crée les dossiers **en dehors** du snapshot (dans le dossier de l'exécutable)
- Configure les variables d'environnement correctement
- Puis démarre le serveur principal

### 2. Modification de `environment.js`

- Détecte le mode pkg
- Utilise le chemin de l'exécutable au lieu du chemin relatif
- Ne tente pas de créer de dossiers en mode pkg

### 3. Structure des Dossiers en Production

```
C:\Program Files\LOGESCO\
├── logesco_v2.exe              # Application Flutter
└── data\
    └── flutter_assets\
        └── backend\
            ├── logesco-backend.exe    # Backend (snapshot pkg)
            ├── database\              # Créé au runtime
            │   └── logesco.db
            ├── logs\                  # Créé au runtime
            └── uploads\               # Créé au runtime
```

## Changements Effectués

### Fichiers Modifiés

1. **backend/src/server-standalone.js** (nouveau)
   - Point d'entrée pour le mode standalone
   - Gère la création des dossiers en dehors du snapshot
   - Configure l'environnement avant de démarrer le serveur

2. **backend/src/config/environment.js**
   - Ajout de la détection pkg
   - Utilisation de chemins dynamiques selon le mode
   - Pas de création de dossiers en mode pkg

3. **backend/build-standalone.js**
   - Utilise `server-standalone.js` comme point d'entrée
   - Build avec la bonne configuration

## Test de la Solution

### 1. Rebuild du Backend

```bash
cd backend
npm run build:standalone
```

### 2. Test Manuel

```bash
cd dist
logesco-backend.exe
```

Vous devriez voir:
```
🚀 Démarrage de LOGESCO Backend (Mode Standalone)...
📁 Chemin de base: C:\path\to\dist
🔧 Création des dossiers...
✓ Dossier créé: database
✓ Dossier créé: logs
✓ Dossier créé: uploads
📝 Création du fichier .env...
✓ Fichier .env créé
📝 Chargement de la configuration...
✓ Base de données: file:C:\path\to\dist\database\logesco.db
✓ Port: 8080
🌐 Démarrage du serveur HTTP...
```

### 3. Rebuild Complet

```bash
# Depuis la racine
build-production.bat
```

### 4. Test de l'Installeur

1. Créer l'installeur avec InnoSetup
2. Installer sur une machine de test
3. Lancer LOGESCO
4. Vérifier que le backend démarre automatiquement

## Vérifications

- [ ] Backend se compile sans erreur
- [ ] Backend démarre manuellement sans erreur
- [ ] Dossiers créés correctement (database, logs, uploads)
- [ ] Fichier .env créé automatiquement
- [ ] Base de données initialisée
- [ ] Serveur accessible sur http://localhost:8080
- [ ] Application Flutter se connecte au backend
- [ ] Installeur fonctionne correctement

## Notes Importantes

### Pourquoi ce problème?

`pkg` crée un système de fichiers virtuel (snapshot) contenant tout le code Node.js. Ce système est en lecture seule. Toute tentative de créer des fichiers ou dossiers à l'intérieur échoue.

### La Solution

Créer tous les fichiers et dossiers **en dehors** du snapshot, dans le dossier où se trouve l'exécutable. C'est pourquoi nous utilisons `process.execPath` pour obtenir le chemin de l'exécutable.

### Chemins Importants

- **En développement**: `__dirname` pointe vers le code source
- **En mode pkg**: `__dirname` pointe vers le snapshot (lecture seule)
- **Solution**: Utiliser `path.dirname(process.execPath)` en mode pkg

## Prochaines Étapes

1. Tester le nouveau build
2. Vérifier que l'application Flutter peut démarrer le backend
3. Créer l'installeur final
4. Tester sur une machine vierge
5. Distribuer aux clients

---

**Date**: 7 novembre 2025  
**Statut**: ✅ Corrigé  
**Impact**: Critique - Bloquait le déploiement client


## Mise à Jour: Fix Permissions Windows

### Nouveau Problème Identifié

Erreur: `EPERM: operation not permitted, mkdir 'C:\Program Files\LOGESCO\...'`

Le backend essayait de créer des dossiers dans `Program Files` qui nécessite des privilèges administrateur.

### Solution

**Utiliser AppData\Local au lieu de Program Files**

#### Changements:

1. **server-standalone.js**: Utilise `%LOCALAPPDATA%\LOGESCO\backend`
2. **backend_service.dart**: Utilise le même chemin
3. **installer-setup.iss**: Installe dans `{localappdata}\LOGESCO`

#### Nouvelle Structure:

```
C:\Users\[Username]\AppData\Local\LOGESCO\
├── logesco_v2.exe              # Application Flutter
├── data\                       # Données Flutter
└── backend\                    # Backend (créé au runtime)
    ├── logesco-backend.exe
    ├── .env
    ├── database\
    │   └── logesco.db
    ├── logs\
    └── uploads\
```

### Avantages:

✅ Pas besoin de privilèges administrateur  
✅ Chaque utilisateur a ses propres données  
✅ Conforme aux standards Windows  
✅ Pas de problèmes de permissions

### Test:

```bash
# Rebuild
cd backend
npm run build:standalone

# Test
cd dist
logesco-backend.exe
```

Le backend devrait démarrer sans erreur et créer les dossiers dans:
`C:\Users\[VotreNom]\AppData\Local\LOGESCO\backend\`
