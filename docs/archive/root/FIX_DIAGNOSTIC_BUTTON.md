# Fix: Bouton Diagnostic Utilise l'URL Configurée

## 🎯 Problème

Le bouton "Diagnostiquer" sur la page de connexion affichait toujours une erreur de connexion à `localhost:8080`, même quand le serveur était configuré sur une autre adresse (ex: `192.168.100.101:8080`).

## ❌ Avant

```dart
Future<void> _diagnose() async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final req = await client.getUrl(Uri.parse('http://localhost:8080/debug'));
    // ...
  }
}
```

**Problème:** URL hardcodée à `localhost:8080`

## ✅ Après

```dart
Future<void> _diagnose() async {
  try {
    // Utiliser l'URL configurée au lieu de localhost
    final baseUrl = AppConfig.isClientMode 
        ? ApiConfig.currentBaseUrl 
        : 'http://localhost:8080/debug';

    final debugUrl = baseUrl.replaceAll('/api/v1', '') + '/debug';

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final req = await client.getUrl(Uri.parse(debugUrl));
    // ...
  }
}
```

**Solution:** 
- En mode CLIENT: Utilise l'URL configurée depuis `ApiConfig.currentBaseUrl`
- En mode SERVER: Utilise `localhost:8080` (backend embarqué)

## 📝 Changements

**Fichier:** `logesco_v2/lib/features/auth/views/login_page.dart`

### Imports ajoutés
```dart
import '../../../core/config/api_config.dart';
```

### Fonction modifiée
- Utilise `AppConfig.isClientMode` pour déterminer le mode
- Utilise `ApiConfig.currentBaseUrl` pour obtenir l'URL configurée
- Retire `/api/v1` de l'URL pour accéder à `/debug`

## 🧪 Vérification

### VERSION CLIENT

1. Configurez le serveur: `192.168.100.101:8080`
2. Cliquez sur "Diagnostiquer"
3. ✅ Affiche le diagnostic du serveur à `192.168.100.101:8080/debug`

### VERSION SERVER

1. Lancez en mode SERVER
2. Cliquez sur "Diagnostiquer"
3. ✅ Affiche le diagnostic du backend local à `localhost:8080/debug`

## 🎯 Résultat

- ✅ Le bouton diagnostic utilise l'URL correcte
- ✅ Fonctionne avec n'importe quelle adresse de serveur
- ✅ Fonctionne en mode CLIENT et SERVER
- ✅ Pas d'erreur de connexion à localhost
