# Compilation des Versions CLIENT et SERVER

## 🎯 Objectif

Créer deux versions distinctes de LOGESCO:
- **VERSION CLIENT**: Se connecte à un serveur réseau (pas de backend embarqué)
- **VERSION SERVER**: Démarre le backend embarqué (pour développement/test)

## 📋 Configuration

### Version CLIENT (Par défaut)

**Fichier:** `logesco_v2/lib/core/config/app_config.dart`

```dart
// MODE 1: Version CLIENT (se connecte à un serveur réseau)
static const bool isClientMode = true;

// MODE 2: Version SERVER (démarre le backend embarqué)
// static const bool isClientMode = false;
```

**Caractéristiques:**
- ✅ Ne démarre pas le backend embarqué
- ✅ Se connecte à un serveur réseau
- ✅ Pas de messages d'initialisation du serveur
- ✅ Démarrage rapide

### Version SERVER

**Fichier:** `logesco_v2/lib/core/config/app_config.dart`

```dart
// MODE 1: Version CLIENT (se connecte à un serveur réseau)
// static const bool isClientMode = true;

// MODE 2: Version SERVER (démarre le backend embarqué)
static const bool isClientMode = false;
```

**Caractéristiques:**
- ✅ Démarre le backend embarqué
- ✅ Affiche les messages d'initialisation
- ✅ Crée l'utilisateur admin automatiquement
- ✅ Peut fonctionner en standalone

## 🔨 Compilation

### Étape 1: Configurer le mode

Modifiez `logesco_v2/lib/core/config/app_config.dart`:

```dart
// Pour CLIENT:
static const bool isClientMode = true;

// Pour SERVER:
static const bool isClientMode = false;
```

### Étape 2: Nettoyer les builds précédents

```bash
cd logesco_v2
flutter clean
```

### Étape 3: Compiler

#### Pour Windows (CLIENT)

```bash
flutter build windows --release
```

L'exécutable sera dans: `build/windows/runner/Release/logesco.exe`

#### Pour Windows (SERVER)

```bash
flutter build windows --release
```

L'exécutable sera dans: `build/windows/runner/Release/logesco.exe`

### Étape 4: Renommer les exécutables

```bash
# Version CLIENT
copy build\windows\runner\Release\logesco.exe logesco-client.exe

# Version SERVER
copy build\windows\runner\Release\logesco.exe logesco-server.exe
```

## 📦 Distribution

### Package CLIENT

1. Compilez en mode CLIENT
2. Créez un dossier `LOGESCO-Client`
3. Copiez:
   - `logesco-client.exe`
   - `configure-server.bat`
   - `setup-client-reseau.bat`
   - `README_INSTALLATION_CLIENT.md`
   - `DEPLOIEMENT_CLIENT_RESEAU.md`

4. Créez un ZIP: `LOGESCO-Client.zip`

### Package SERVER

1. Compilez en mode SERVER
2. Créez un dossier `LOGESCO-Server`
3. Copiez:
   - `logesco-server.exe`
   - `README_INSTALLATION_SERVER.md`

4. Créez un ZIP: `LOGESCO-Server.zip`

## 🚀 Utilisation

### Version CLIENT

```bash
# Configurer le serveur
setup-client-reseau.bat

# Lancer l'application
logesco-client.exe
```

### Version SERVER

```bash
# Lancer directement
logesco-server.exe
```

## ✅ Vérification

### Version CLIENT

- ✅ Pas de message "Démarrage du backend"
- ✅ Pas de message "Initialisation du serveur"
- ✅ Affiche "Mode CLIENT - Pas de backend embarqué"
- ✅ Écran de connexion s'affiche rapidement
- ✅ Se connecte au serveur réseau

### Version SERVER

- ✅ Affiche "Mode SERVER - Démarrage du backend embarqué"
- ✅ Affiche "Backend service started successfully"
- ✅ Affiche "Utilisateur admin: Disponible"
- ✅ Affiche "Identifiants par défaut: admin / admin123"
- ✅ Peut fonctionner en standalone

## 🔧 Dépannage

### L'app affiche toujours les messages du serveur

1. Vérifiez que `isClientMode = true` dans `app_config.dart`
2. Exécutez `flutter clean`
3. Recompilez

### L'app ne démarre pas le backend en mode SERVER

1. Vérifiez que `isClientMode = false` dans `app_config.dart`
2. Vérifiez que le backend est disponible
3. Vérifiez les logs

## 📝 Notes

- Les deux versions utilisent le même code source
- Seule la configuration change
- Pas besoin de deux projets séparés
- Facile à maintenir et à mettre à jour
