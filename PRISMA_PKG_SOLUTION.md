# Solution: Prisma + pkg

## Problème

Prisma génère des fichiers natifs (.node) qui ne peuvent pas être inclus dans le snapshot pkg. L'erreur:
```
Cannot find module 'C:\snapshot\backend\node_modules\.prisma\client\index.js'
```

## Solutions Possibles

### Option 1: Distribuer node_modules avec l'exe (RECOMMANDÉ)

**Avantages:**
- Simple à implémenter
- Fonctionne à coup sûr
- Pas de modification du code

**Inconvénients:**
- Package plus volumineux (~50 MB au lieu de ~40 MB)

**Implémentation:**
1. Build avec `build-standalone-v2.js` (copie node_modules)
2. Distribuer tout le dossier `dist/` (exe + node_modules)
3. L'application Flutter copie tout le dossier au premier démarrage

### Option 2: Utiliser Prisma en mode binaire externe

Configurer Prisma pour utiliser un binaire externe au lieu du client généré.

**Avantages:**
- Package plus petit

**Inconvénients:**
- Configuration complexe
- Peut causer d'autres problèmes

### Option 3: Utiliser une autre solution que pkg

Alternatives à pkg:
- **nexe**: Similaire à pkg
- **node-packer**: Plus moderne
- **Electron**: Si on veut une vraie app desktop

## Solution Choisie: Option 1

C'est la plus fiable et la plus simple.

### Structure de Distribution

```
dist/
├── logesco-backend.exe          # Exécutable principal
├── node_modules/                # Dépendances Prisma (REQUIS)
│   ├── .prisma/
│   │   └── client/
│   │       ├── index.js
│   │       ├── libquery_engine-*.node
│   │       └── schema.prisma
│   └── @prisma/
│       └── client/
├── database/                    # Base de données
├── logs/                        # Logs
├── uploads/                     # Uploads
├── .env.example                 # Configuration
└── README.txt                   # Instructions
```

### Mise à Jour du Workflow

#### 1. Build Backend

```bash
cd backend
npm run build:standalone
```

Résultat: `dist/` contient exe + node_modules

#### 2. Pour Flutter

Au lieu de copier dans assets (trop volumineux), on peut:

**Option A**: Inclure le backend complet dans l'installeur
- L'installeur copie tout dans AppData au moment de l'installation

**Option B**: Télécharger le backend au premier démarrage
- L'app télécharge le backend depuis un serveur

**Option C**: Inclure un zip dans les assets
- L'app décompresse le zip au premier démarrage

### Recommandation: Option A (Installeur)

Modifier `installer-setup.iss` pour:
1. Copier l'exe dans le dossier d'installation
2. Copier node_modules dans AppData\Local\LOGESCO\backend\

### Nouveau Workflow

```
Installation:
1. Utilisateur lance LOGESCO-v2-Setup.exe
2. InnoSetup installe:
   - Application Flutter dans LocalAppData\LOGESCO\
   - Backend (exe + node_modules) dans LocalAppData\LOGESCO\backend\
3. Utilisateur lance LOGESCO
4. L'app démarre le backend qui est déjà en place

Premier démarrage:
1. Backend crée database/, logs/, uploads/
2. Backend crée .env
3. Backend initialise la base de données
4. Application prête
```

## Implémentation

### 1. Modifier build-production.bat

```batch
REM Ne pas copier dans assets Flutter
REM À la place, préparer pour l'installeur

REM Créer le package d'installation
mkdir release\installer-files\backend
xcopy /E /I /Y dist\* release\installer-files\backend\
```

### 2. Modifier installer-setup.iss

```iss
[Files]
; Application Flutter
Source: "release\LOGESCO\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; Backend dans AppData
Source: "release\installer-files\backend\*"; DestDir: "{localappdata}\LOGESCO\backend"; Flags: ignoreversion recursesubdirs
```

### 3. Modifier backend_service.dart

```dart
Future<String> _getBackendPath() async {
  // Le backend est déjà installé par InnoSetup
  final localAppData = Platform.environment['LOCALAPPDATA'] ?? 
                      path.join(Platform.environment['USERPROFILE']!, 'AppData', 'Local');
  return path.join(localAppData, 'LOGESCO', 'backend');
}

Future<void> _extractBackend() async {
  // Plus besoin d'extraire, déjà installé par InnoSetup
  debugPrint('✓ Backend déjà installé');
}
```

## Avantages de cette Approche

✅ Pas de problème avec Prisma  
✅ Installation propre et professionnelle  
✅ Pas de copie au runtime (plus rapide)  
✅ Mise à jour facile (réinstaller)  
✅ Désinstallation propre  

## Test

```bash
# 1. Build backend
cd backend
npm run build:standalone

# 2. Vérifier que node_modules est présent
dir dist\node_modules

# 3. Tester manuellement
cd dist
logesco-backend.exe

# Devrait démarrer sans erreur
```

---

**Prochaine étape**: Implémenter cette solution dans les scripts de build et l'installeur.
