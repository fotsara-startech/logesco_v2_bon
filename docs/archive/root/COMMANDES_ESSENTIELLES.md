# Commandes Essentielles - LOGESCO v2

## 🚀 Build et Déploiement

### Build Complet (Automatique)
```bash
# Depuis la racine du projet
build-production.bat
```

### Build Étape par Étape

#### 1. Backend Standalone
```bash
cd backend
npm install
npm run build:standalone
```

#### 2. Application Flutter
```bash
cd logesco_v2
flutter pub get
flutter build windows --release
```

#### 3. Package de Distribution
```bash
# Copier les fichiers dans release/
xcopy /E /I /Y logesco_v2\build\windows\x64\runner\Release\* release\LOGESCO\
```

#### 4. Installeur InnoSetup
```bash
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer-setup.iss
```

## 🧪 Tests

### Test Rapide du Déploiement
```bash
test-deployment.bat
```

### Test Manuel du Backend
```bash
cd dist
.\logesco-backend.exe
```

### Test de l'API
```bash
# Santé
curl http://localhost:8080/health

# Authentification
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@logesco.com","password":"admin123"}'
```

## 🔧 Développement

### Démarrage en Mode Dev

#### Backend
```bash
cd backend
npm run dev
```

#### Flutter
```bash
cd logesco_v2
flutter run -d windows
```

### Tests Unitaires

#### Backend
```bash
cd backend
npm test
```

#### Flutter
```bash
cd logesco_v2
flutter test
```

## 📦 Structure des Fichiers

### Fichiers de Build
- `build-production.bat` - Build automatique complet
- `test-deployment.bat` - Test du déploiement
- `installer-setup.iss` - Script InnoSetup

### Backend
- `backend/build-standalone-v2.js` - Script de build backend
- `backend/src/server-standalone.js` - Point d'entrée standalone
- `backend/src/server-simple.js` - Serveur Express simplifié
- `backend/src/database/json-db.js` - Base de données JSON

### Frontend
- `logesco_v2/lib/core/services/backend_service.dart` - Service backend
- `logesco_v2/lib/main.dart` - Point d'entrée Flutter

## 🎯 Commandes Client

### Installation
1. Télécharger `LOGESCO-v2-Setup.exe`
2. Double-cliquer et suivre l'assistant
3. Lancer LOGESCO depuis le bureau

### Utilisation
- **Connexion**: admin@logesco.com / admin123
- **URL Backend**: http://localhost:8080 (automatique)
- **Données**: Stockées dans AppData\Local\LOGESCO\

### Dépannage
```bash
# Vérifier si le backend tourne
netstat -ano | findstr :8080

# Redémarrer l'application
taskkill /F /IM logesco_v2.exe
taskkill /F /IM logesco-backend.exe
# Puis relancer LOGESCO
```

## 📊 Métriques

### Tailles
- Backend exe: ~15 MB
- Application Flutter: ~30 MB
- Installeur: ~25 MB

### Temps
- Build complet: ~6 minutes
- Installation: ~1 minute
- Premier démarrage: ~10 secondes

## 🔍 Logs et Débogage

### Emplacements des Logs
```
AppData\Local\LOGESCO\
├── backend\
│   ├── logs\           # Logs du serveur
│   ├── logesco.json    # Base de données
│   └── .env            # Configuration
└── logs\               # Logs de l'application
```

### Commandes de Débogage
```bash
# Voir les logs backend
type "%LOCALAPPDATA%\LOGESCO\backend\logs\combined.log"

# Vérifier la base de données
type "%LOCALAPPDATA%\LOGESCO\backend\logesco.json"

# Vérifier la configuration
type "%LOCALAPPDATA%\LOGESCO\backend\.env"
```

## 🚨 Dépannage Rapide

### Backend ne démarre pas
```bash
cd dist
.\logesco-backend.exe
# Lire les erreurs affichées
```

### Port 8080 occupé
```bash
netstat -ano | findstr :8080
taskkill /F /PID [PID_TROUVÉ]
```

### Application Flutter ne se connecte pas
1. Vérifier que le backend tourne
2. Vérifier l'URL dans le code Flutter
3. Redémarrer l'application

### Réinstallation propre
1. Désinstaller via Panneau de configuration
2. Supprimer `%LOCALAPPDATA%\LOGESCO\`
3. Réinstaller avec le setup

## 📞 Support

### Informations à Collecter
- Version de Windows
- Logs d'erreur
- Étapes pour reproduire le problème
- Capture d'écran si applicable

### Commandes de Diagnostic
```bash
# Version Windows
winver

# Processus LOGESCO
tasklist | findstr logesco

# Ports utilisés
netstat -ano | findstr :8080

# Espace disque
dir "%LOCALAPPDATA%\LOGESCO\" /s
```

---

**Aide-mémoire pour le développement et le support de LOGESCO v2**