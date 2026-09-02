# Fichiers à Envoyer au Client - LOGESCO v2

## Option 1: Package Complet (Recommandé)

### Étape 1: Construire le Package

```batch
build-production.bat
```

Cela crée automatiquement:
- Backend portable dans `dist-portable\`
- Application Flutter dans `release\LOGESCO\`

### Étape 2: Fichiers à Envoyer

Envoyer **tout le dossier** `release\LOGESCO\` qui contient:

```
release\LOGESCO/
├── logesco_v2.exe              # Application Flutter
├── data/                       # Données Flutter
├── flutter_windows.dll         # DLL Flutter
├── *.dll                       # Autres DLLs nécessaires
└── README.txt                  # Instructions
```

**Taille approximative**: ~50-100 MB

---

## Option 2: Backend Séparé (Pour Serveur Dédié)

Si le client veut installer le backend sur un serveur séparé:

### Construire le Backend

```batch
build-portable-backend.bat
```

### Fichiers à Envoyer

Envoyer **tout le dossier** `dist-portable\`:

```
dist-portable/
├── start-backend.bat           # Démarrage manuel
├── install-service.bat         # Installation comme service
├── src/                        # Code source (REQUIS)
├── node_modules/               # Dépendances (REQUIS)
├── prisma/                     # Schéma DB (REQUIS)
├── scripts/                    # Scripts utilitaires
├── package.json                # Configuration npm
├── .env.example                # Configuration exemple
└── README.txt                  # Instructions
```

**Taille approximative**: ~150-200 MB (à cause de node_modules)

**⚠️ IMPORTANT**: Le dossier `node_modules` est **OBLIGATOIRE** - ne pas le supprimer!

---

## Option 3: Application Flutter Seule

Si le backend est déjà installé ailleurs:

### Construire Flutter

```batch
cd logesco_v2
flutter build windows --release
```

### Fichiers à Envoyer

Envoyer le dossier `logesco_v2\build\windows\x64\runner\Release\`:

```
Release/
├── logesco_v2.exe
├── data/
├── flutter_windows.dll
└── *.dll
```

**Taille approximative**: ~50 MB

---

## Prérequis Client

### Pour le Backend

- **Node.js 18+** (obligatoire)
  - Télécharger: https://nodejs.org/
  - Vérifier: `node --version`

### Pour l'Application Flutter

- **Windows 10/11** (64-bit)
- Aucune dépendance supplémentaire

---

## Instructions d'Installation pour le Client

### Installation Complète (Backend + Application)

1. **Extraire** le dossier `LOGESCO` reçu
2. **Installer Node.js** si pas déjà installé
3. **Démarrer le backend**:
   ```
   Double-cliquer sur: backend\start-backend.bat
   ```
4. **Démarrer l'application**:
   ```
   Double-cliquer sur: logesco_v2.exe
   ```

### Installation Backend Seul

1. **Extraire** le dossier `dist-portable` reçu
2. **Installer Node.js** si pas déjà installé
3. **Démarrer le backend**:
   ```
   Double-cliquer sur: start-backend.bat
   ```
4. **Pour démarrage automatique**:
   ```
   Exécuter en admin: install-service.bat
   ```

---

## Configuration Réseau Local

Si le client veut accéder au backend depuis plusieurs machines:

### Sur le Serveur (Machine avec Backend)

1. Modifier `dist-portable\.env`:
   ```env
   PORT=8080
   CORS_ORIGIN=*
   ```

2. Autoriser le port dans le pare-feu Windows:
   ```powershell
   netsh advfirewall firewall add rule name="LOGESCO Backend" dir=in action=allow protocol=TCP localport=8080
   ```

3. Noter l'adresse IP du serveur:
   ```powershell
   ipconfig
   ```
   Exemple: `192.168.1.100`

### Sur les Clients (Machines avec Application Flutter)

Configurer l'URL du backend dans l'application:
```
http://192.168.1.100:8080
```

---

## Vérification Post-Installation

### Vérifier le Backend

```powershell
curl http://localhost:8080/health
```

Réponse attendue:
```json
{"status":"OK","database":"sqlite"}
```

### Vérifier l'Application

1. Lancer `logesco_v2.exe`
2. Se connecter avec:
   - **Username**: admin
   - **Password**: admin123

---

## Dépannage

### Backend ne démarre pas

1. Vérifier Node.js: `node --version`
2. Vérifier les logs: `dist-portable\logs\error.log`
3. Vérifier le port: `netstat -ano | findstr :8080`

### Application ne se connecte pas

1. Vérifier que le backend est démarré
2. Vérifier l'URL dans l'application
3. Vérifier le pare-feu Windows

### "Cannot find module"

Le dossier `node_modules` est manquant ou incomplet.
**Solution**: Reconstruire avec `build-portable-backend.bat`

---

## Fichiers à NE PAS Envoyer

❌ `backend/node_modules/` (du dossier source)  
❌ `backend/.env` (contient des secrets)  
❌ `backend/database/` (données de développement)  
❌ `backend/logs/` (logs de développement)  
❌ `.git/` (historique Git)  
❌ `dist/` (ancien build avec exe)  

✅ Envoyer uniquement `dist-portable/` ou `release/LOGESCO/`

---

## Résumé Rapide

### Pour un Client Standard

```batch
# 1. Construire
build-production.bat

# 2. Envoyer
release\LOGESCO\  (tout le dossier)

# 3. Client installe Node.js et lance
start-backend.bat
logesco_v2.exe
```

### Pour un Serveur Dédié

```batch
# 1. Construire
build-portable-backend.bat

# 2. Envoyer
dist-portable\  (tout le dossier)

# 3. Client installe Node.js et lance
start-backend.bat
# ou
install-service.bat (en admin)
```

---

**Taille totale du package**: ~150-200 MB  
**Prérequis client**: Node.js 18+ et Windows 10/11  
**Support**: Voir GUIDE_DEPLOIEMENT_BACKEND_FINAL.md
