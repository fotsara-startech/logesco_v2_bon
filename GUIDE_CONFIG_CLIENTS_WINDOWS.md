# 🖥️ Guide Configuration Clients Windows - Accès Backend Réseau

**Objectif:** Configurer les postes Windows clients pour accéder au backend sur le serveur Linux distant

**Architecture:**
```
Windows Client (logesco_v2) 
    ↓
Connexion Réseau (IP:Port)
    ↓
Serveur Linux (Backend + SQLite)
```

---

## 📋 ÉTAPE 1: Connaître l'IP du Serveur Linux

Avant tout, tu dois connaître l'adresse IP du serveur Linux.

### Comment trouver l'IP du serveur Linux?

**Sur le serveur Linux:**

```bash
# Ubuntu/Debian
hostname -I

# Ou plus détaillé
ifconfig
# ou
ip addr show
```

**Résultat:** Une IP comme `192.168.1.100` ou `10.0.0.50`

**Note:** L'IP dépend de votre réseau local. Exemples:
- `192.168.0.x` (réseaux privés courants)
- `10.0.x.x` (autres réseaux privés)
- `172.16.x.x` (autres réseaux privés)

---

## 🔧 ÉTAPE 2: Modifier la Configuration du Client (Version 1)

### Méthode A: Éditer directement les fichiers Dart (Recommandé pour développement)

**Fichier:** `logesco_v2/lib/core/config/api_config.dart`

Chercher et remplacer:

```dart
// ❌ AVANT (localhost)
static const String baseUrl = 'http://localhost:8080/api/v1';

// ✅ APRÈS (IP du serveur)
static const String baseUrl = 'http://192.168.1.100:8080/api/v1';
// Remplacer 192.168.1.100 par l'IP réelle du serveur Linux
```

**Fichier:** `logesco_v2/lib/core/config/environment_config.dart`

Chercher les lignes contenant `localhost:8080` et remplacer par l'IP du serveur:

```dart
// ❌ AVANT
static String get apiBaseUrl {
  if (isLocal) {
    return 'http://localhost:8080/api/v1';
  }
  // ...
}

// ✅ APRÈS
static String get apiBaseUrl {
  if (isLocal) {
    return 'http://192.168.1.100:8080/api/v1';  // IP du serveur Linux
  }
  // ...
}
```

**Fichier:** `logesco_v2/lib/core/bindings/initial_bindings.dart`

Chercher et remplacer les références `localhost:8080`:

```dart
// ❌ AVANT
'baseUrl': 'http://localhost:8080/api/v1',

// ✅ APRÈS
'baseUrl': 'http://192.168.1.100:8080/api/v1',
```

### 📝 Détail - Tous les Fichiers à Modifier

| Fichier | À Chercher | À Remplacer | Nombre de changements |
|---------|-----------|------------|----------------------|
| `lib/core/config/api_config.dart` | `localhost:8080` | `192.168.1.100:8080` | 1 |
| `lib/core/config/environment_config.dart` | `localhost:8080` | `192.168.1.100:8080` | 2-3 |
| `lib/core/bindings/initial_bindings.dart` | `localhost:8080` | `192.168.1.100:8080` | 1-3 |
| `lib/config/local_config.dart` | `localhost:8080` | `192.168.1.100:8080` | 2 |

---

## 🎯 ÉTAPE 3: Recompiler l'Application Flutter

Une fois les fichiers modifiés, recompiler l'appli:

### Option A: Build Production (Installeur)

```bash
cd logesco_v2

# Nettoyer
flutter clean
flutter pub get

# Build pour production
flutter build windows --release

# Résultat: logesco_v2/build/windows/x64/runner/Release/
```

### Option B: Test en Développement

```bash
cd logesco_v2

# Lancer en mode dev avec la nouvelle config
flutter run -d windows
```

---

## 📦 ÉTAPE 4: Déployer sur les Postes Clients

### Option 1: Créer un Installeur Unique (Recommandé)

```bash
# À la racine du projet
./build-production.bat
```

Cela crée un installeur `LOGESCO-v2-Setup.exe` avec l'IP du serveur préconfigurée.

**Installer sur chaque poste client:**
- Double-cliquer sur `LOGESCO-v2-Setup.exe`
- Suivre les instructions
- L'appli démarre avec la config du serveur

### Option 2: Copier le Dossier Release (Plus Rapide)

```bash
# Après flutter build windows --release
xcopy /E /I /Y logesco_v2\build\windows\x64\runner\Release\* \\NOM_POSTE\C$\Program Files\LOGESCO\
```

---

## ✅ ÉTAPE 5: Vérifier la Connexion

### Vérification Depuis Un Poste Client (Windows)

#### A. Vérifier la Connectivité Réseau

```powershell
# Tester la connectivité avec le serveur Linux
ping 192.168.1.100

# Résultat attendu:
# Reply from 192.168.1.100: bytes=32 time=15ms TTL=64
```

#### B. Tester la Connexion à l'API

```powershell
# Test simple
curl http://192.168.1.100:8080/api/v1/health

# Avec PowerShell (plus lisible)
Invoke-WebRequest -Uri "http://192.168.1.100:8080/api/v1/health" -Method Get | ConvertTo-Json
```

**Réponse attendue:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-31T10:30:00Z"
}
```

#### C. Test de Login

```powershell
# Essayer la connexion avec des identifiants
$body = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://192.168.1.100:8080/api/v1/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

#### D. Lancer l'Application

```powershell
# Exécuter le programme
& "C:\Program Files\LOGESCO\logesco_v2.exe"
```

---

## 🌐 Configuration Alternative: Utiliser un Nom DNS Local

Si tu veux utiliser un nom au lieu de l'IP, tu peux configurer un DNS local:

### Éditer le Fichier hosts (Windows)

```
C:\Windows\System32\drivers\etc\hosts
```

Ajouter une ligne:

```
192.168.1.100  logesco-server
```

Puis dans la config Dart, utiliser le nom:

```dart
static const String baseUrl = 'http://logesco-server:8080/api/v1';
```

---

## 🔒 Configuration Avancée: HTTPS (Optionnel)

Pour plus de sécurité avec HTTPS, modifier:

```dart
// Au lieu de http://
static const String baseUrl = 'https://192.168.1.100:443/api/v1';
```

**Nécessite:**
- Certificat SSL sur le serveur Linux
- Configuration HTTPS dans le backend
- Acceptation du certificat auto-signé (développement)

*(Voir guide Déploiement Linux pour HTTPS)*

---

## 🚀 Script Automatisé de Configuration

Créer un script batch pour automatiser la modification:

**Fichier:** `configurer-client-reseau.bat`

```batch
@echo off
REM Configuration automatique du client pour serveur distant
REM Usage: configurer-client-reseau.bat 192.168.1.100

if "%1"=="" (
    echo Usage: configurer-client-reseau.bat ^<IP_SERVEUR^>
    echo Exemple: configurer-client-reseau.bat 192.168.1.100
    exit /b 1
)

set SERVER_IP=%1
set PROJECT_DIR=%~dp0

echo Configuration du client pour serveur: %SERVER_IP%

REM Modifier api_config.dart
echo Modification de api_config.dart...
powershell -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\core\config\api_config.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\core\config\api_config.dart'"

REM Modifier environment_config.dart
echo Modification de environment_config.dart...
powershell -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\core\config\environment_config.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\core\config\environment_config.dart'"

REM Modifier initial_bindings.dart
echo Modification de initial_bindings.dart...
powershell -Command "(Get-Content '%PROJECT_DIR%logesco_v2\lib\core\bindings\initial_bindings.dart') -replace 'localhost:8080', '%SERVER_IP%:8080' | Set-Content '%PROJECT_DIR%logesco_v2\lib\core\bindings\initial_bindings.dart'"

echo.
echo Configuration terminée!
echo IP du serveur: %SERVER_IP%
echo.
echo Prochaines étapes:
echo  1. flutter clean
echo  2. flutter pub get
echo  3. flutter build windows --release
echo.
pause
```

**Utilisation:**

```batch
configurer-client-reseau.bat 192.168.1.100
```

---

## 📋 Checklist Configuration

- [ ] IP du serveur Linux identifiée (ex: 192.168.1.100)
- [ ] Firewall du serveur Linux autorise le port 8080
- [ ] Backend lancé sur le serveur Linux
- [ ] Health check réussit: `curl http://192.168.1.100:8080/api/v1/health`
- [ ] Fichiers Dart modifiés avec la bonne IP
- [ ] `flutter clean` exécuté
- [ ] `flutter pub get` exécuté
- [ ] `flutter build windows --release` compilé
- [ ] Ping vers le serveur réussit
- [ ] Login test réussit
- [ ] Application lancée et connectée

---

## 🆘 Troubleshooting

### Problème: "Cannot connect to server"

```powershell
# Vérifier la connectivité
ping 192.168.1.100

# Si ping échoue: problème réseau ou firewall
# Vérifier le firewall du serveur Linux
sudo ufw allow 8080/tcp

# Relancer le backend sur le serveur
sudo systemctl restart logesco-backend
```

### Problème: "Connection Timeout"

```powershell
# Tester directement l'API
curl http://192.168.1.100:8080/api/v1/health --max-time 5

# Si timeout: backend pas en écoute
# Sur serveur Linux:
sudo systemctl status logesco-backend
sudo journalctl -u logesco-backend -n 20
```

### Problème: "SSL Certificate Error" (Si HTTPS)

Dans Dart, ajouter:

```dart
// Accepter les certificats auto-signés (DEV seulement!)
HttpClient.defaultHttpClient.badCertificateCallback = (cert, host, port) => true;
```

### Problème: "Health check passe mais login échoue"

```powershell
# Vérifier les données de connexion
curl -X POST http://192.168.1.100:8080/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{"username":"admin","password":"admin123"}'

# Vérifier la base de données sur le serveur
ssh user@192.168.1.100
cd /opt/logesco-backend
npx prisma studio
```

---

## 📊 Exemple Configuration Réseau

```
Réseau: 192.168.1.0/24

Serveur Linux:
  Hostname: logesco-server (optionnel)
  IP: 192.168.1.100
  Port: 8080
  Service: logesco-backend (systemd)

Postes Clients:
  Poste 1: 192.168.1.10 (Caisse 1)
  Poste 2: 192.168.1.11 (Caisse 2)
  Poste 3: 192.168.1.12 (Gestion)
  ...

Tous les clients se connectent à: http://192.168.1.100:8080/api/v1
```

---

## 📞 Résumé des Modifications

**Avant:**
```dart
// Client se connecte à localhost (machine locale)
static const String baseUrl = 'http://localhost:8080/api/v1';
```

**Après:**
```dart
// Client se connecte au serveur distant via réseau
static const String baseUrl = 'http://192.168.1.100:8080/api/v1';
```

C'est tout! L'appli Flutter communiquera maintenant avec le backend sur le serveur Linux. 🚀
