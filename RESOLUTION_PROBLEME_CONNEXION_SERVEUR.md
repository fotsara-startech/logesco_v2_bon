# Résolution du Problème de Connexion au Serveur

## 🎯 Problème Identifié

Au premier démarrage, le client LOGESCO tentait de se connecter à `localhost:8080` au lieu de l'adresse du serveur configurée (`192.168.100.101:8080`).

### Cause Racine

L'adresse du serveur était définie en dur dans deux endroits:

1. **`ApiConfig.dart`** - Configuration par défaut
2. **`InitialBindings.dart`** - Création du service API au démarrage

Le problème: `InitialBindings` créait `ApiService` avec `localhost` **AVANT** que `ServerConfigService` ne charge la configuration depuis le fichier.

## ✅ Solution Implémentée

### 1. Configuration Dynamique de l'URL

**Fichier:** `logesco_v2/lib/core/config/api_config.dart`

```dart
static String _customBaseUrl = baseUrl;

static String get currentBaseUrl => _customBaseUrl;

static void setBaseUrl(String url) {
  _customBaseUrl = url;
  print('🔄 [ApiConfig] URL du serveur changée à: $_customBaseUrl');
}
```

### 2. Service de Configuration du Serveur

**Fichier:** `logesco_v2/lib/core/services/server_config_service.dart`

- Charge l'URL depuis `Documents/server_config.txt` au démarrage
- Permet de sauvegarder une nouvelle URL dynamiquement
- Stocke la configuration de manière persistante

### 3. Ordre d'Initialisation Correct

**Fichier:** `logesco_v2/lib/main.dart`

```dart
// ⚠️ IMPORTANT: Charger la configuration AVANT les bindings
await ServerConfigService.loadServerConfig();
```

### 4. Utilisation de la Configuration dans les Bindings

**Fichier:** `logesco_v2/lib/core/bindings/initial_bindings.dart`

```dart
// Utiliser l'URL configurée (qui peut être surchargée dynamiquement)
final baseUrl = ApiConfig.currentBaseUrl;
Get.put<ApiService>(ApiService(baseUrl: baseUrl), permanent: true);
```

## 📋 Fichiers Modifiés

1. ✅ `logesco_v2/lib/core/config/api_config.dart` - Ajout de `setBaseUrl()`
2. ✅ `logesco_v2/lib/main.dart` - Chargement de la config avant les bindings
3. ✅ `logesco_v2/lib/core/bindings/initial_bindings.dart` - Utilisation de `ApiConfig.currentBaseUrl`

## 📁 Fichiers Créés

1. ✅ `logesco_v2/lib/core/services/server_config_service.dart` - Service de configuration
2. ✅ `logesco_v2/lib/features/settings/pages/server_config_page.dart` - Page de configuration UI
3. ✅ `configure-server.bat` - Script de configuration (Batch)
4. ✅ `configure-server.ps1` - Script de configuration (PowerShell)
5. ✅ `setup-client-reseau.bat` - Script complet de déploiement
6. ✅ `GUIDE_CONFIGURATION_SERVEUR.md` - Guide utilisateur
7. ✅ `DEPLOIEMENT_CLIENT_RESEAU.md` - Guide de déploiement
8. ✅ `README_INSTALLATION_CLIENT.md` - Guide rapide

## 🚀 Utilisation pour les Clients

### Méthode 1: Script Automatique (RECOMMANDÉ)

```bash
setup-client-reseau.bat
```

Le script:
- Demande l'adresse IP du serveur
- Teste la connexion
- Crée le fichier de configuration
- Lance l'application

### Méthode 2: Script Simple

```bash
configure-server.bat
```

Crée simplement le fichier de configuration.

### Méthode 3: Configuration Manuelle

1. Créez `C:\Users\[VotreNom]\Documents\server_config.txt`
2. Écrivez: `http://192.168.100.101:8080/api/v1`
3. Redémarrez l'application

### Méthode 4: Configuration dans l'App

1. Lancez l'application
2. Allez dans Paramètres → Configuration du serveur
3. Entrez l'adresse du serveur
4. Cliquez sur Sauvegarder

## 🔄 Flux d'Initialisation

```
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
AppLogger.initialize()
  ↓
GetStorage.init()
  ↓
ServerConfigService.loadServerConfig()  ← ⭐ IMPORTANT: Avant les bindings
  ↓
BackendService.initialize()
  ↓
runApp(LogescoApp)
  ↓
InitialBindings.dependencies()
  ↓
ApiService(baseUrl: ApiConfig.currentBaseUrl)  ← Utilise l'URL chargée
```

## ✅ Vérification

Pour vérifier que la solution fonctionne:

1. **Créez le fichier de configuration:**
   ```
   C:\Users\[VotreNom]\Documents\server_config.txt
   http://192.168.100.101:8080/api/v1
   ```

2. **Lancez l'application**

3. **Vérifiez les logs:**
   - Vous devriez voir: `✅ Configuration du serveur chargée: http://192.168.100.101:8080/api/v1`
   - Vous devriez voir: `🔍 Configuration API - URL de base: http://192.168.100.101:8080/api/v1`

4. **Testez la connexion:**
   - L'écran de connexion devrait s'afficher
   - Vous devriez pouvoir vous connecter

## 🎯 Résultat

- ✅ Le client se connecte à l'adresse configurée au premier démarrage
- ✅ L'URL peut être changée sans recompiler l'app
- ✅ Configuration persistante entre les redémarrages
- ✅ Configuration facile pour les clients non-techniques

## 📝 Notes

- Le fichier de configuration est stocké dans `Documents/server_config.txt`
- Si le fichier n'existe pas, l'app utilise l'URL par défaut compilée
- L'URL peut être changée à tout moment via les paramètres de l'app
- Les scripts batch facilitent le déploiement en masse
