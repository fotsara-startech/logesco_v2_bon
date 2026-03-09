# Guide d'utilisation du SecureTimeService

## 🔐 Problème résolu

Le système de licence se basait sur `DateTime.now()` qui utilise l'horloge système locale. Un utilisateur pouvait simplement reculer la date de sa machine pour prolonger indéfiniment sa licence.

## ✅ Solution implémentée

Le `SecureTimeService` protège contre la manipulation de l'horloge système avec 3 niveaux de sécurité:

### 1. Vérification NTP (Network Time Protocol)
- Interroge des serveurs de temps publics (Google, Cloudflare, etc.)
- Obtient l'heure réelle, impossible à manipuler par l'utilisateur
- Cache l'heure NTP pendant 24h pour réduire les requêtes réseau

### 2. Détection de manipulation
- Stocke la dernière heure de vérification
- Détecte si l'horloge système recule dans le temps
- Bloque l'application si manipulation détectée

### 3. Stockage multi-niveaux
- `FlutterSecureStorage` (chiffré, difficile à supprimer)
- `SharedPreferences` (backup)
- Compteur de sessions pour détecter les réinstallations

## 📦 Installation

Le package NTP a déjà été ajouté au `pubspec.yaml`:

```yaml
dependencies:
  ntp: ^2.0.0
```

Installez les dépendances:

```bash
cd logesco_v2
flutter pub get
```

## 🚀 Utilisation

### Initialisation

```dart
import 'package:logesco_v2/features/subscription/services/implementations/secure_time_service.dart';

final secureTimeService = SecureTimeService();
await secureTimeService.initialize();
```

### Obtenir l'heure sécurisée

```dart
try {
  final result = await secureTimeService.getSecureTime();
  
  print('Heure sécurisée: ${result.trustedTime}');
  print('NTP disponible: ${result.ntpAvailable}');
  print('Heure système fiable: ${result.isSystemTimeReliable}');
  
  if (result.hasWarnings) {
    for (final warning in result.warnings) {
      print('⚠️  $warning');
    }
  }
} on TimeValidationException catch (e) {
  // Manipulation détectée!
  print('❌ ${e.message}');
  // Bloquer l'accès à l'application
}
```

### Valider une licence

```dart
// Ancienne méthode (NON SÉCURISÉE)
if (license.isExpired) {
  // ❌ Peut être contourné en reculant l'horloge
}

// Nouvelle méthode (SÉCURISÉE)
final timeResult = await secureTimeService.getSecureTime();
if (license.isExpiredSecure(timeResult.trustedTime)) {
  // ✅ Utilise l'heure NTP, impossible à manipuler
}
```

### Options avancées

```dart
// Forcer une vérification NTP immédiate
final ntpTime = await secureTimeService.forceNtpCheck();

// Ne pas bloquer si manipulation détectée (mode permissif)
final result = await secureTimeService.getSecureTime(
  throwOnManipulation: false,
);

// Forcer une nouvelle vérification NTP
final result = await secureTimeService.getSecureTime(
  forceNtpCheck: true,
);

// Obtenir des diagnostics
final diagnostics = await secureTimeService.getDiagnostics();
print('Manipulation détectée: ${diagnostics['manipulationDetected']}');
print('Réinstallation détectée: ${diagnostics['reinstallationDetected']}');
```

## 🔄 Intégration dans LicenseService

Le `LicenseService` a été mis à jour pour utiliser automatiquement le `SecureTimeService`:

```dart
// Dans license_service.dart
Future<LicenseValidationResult> _validateExpiration(LicenseKeyPayload payload) async {
  // Obtenir l'heure sécurisée
  final timeResult = await _secureTimeService.getSecureTime(
    throwOnManipulation: true,
  );
  
  final secureTime = timeResult.trustedTime;
  final expirationDate = DateTime.parse(payload.expires);
  
  if (secureTime.isAfter(expirationDate)) {
    // Licence expirée
  }
}
```

## 🛡️ Scénarios de protection

### Scénario 1: Utilisateur recule l'horloge

```
Jour 1: Lancement de l'app
- Heure système: 2025-03-07 10:00
- Stocké: lastCheckTime = 2025-03-07 10:00

Jour 2: Utilisateur recule à 2025-01-01
- Heure système: 2025-01-01 08:00
- lastCheckTime: 2025-03-07 10:00
- ⚠️ DÉTECTION: 2025-01-01 < 2025-03-07
- ❌ BLOQUÉ: TimeValidationException lancée
```

### Scénario 2: Utilisateur désinstalle/réinstalle

```
1. Désinstallation
   - SharedPreferences effacé
   - FlutterSecureStorage peut persister (selon OS)

2. Réinstallation
   - Compteur de sessions réinitialisé dans SharedPreferences
   - Mais existe encore dans FlutterSecureStorage
   - ⚠️ DÉTECTION: Réinstallation suspecte
   - Force vérification NTP
```

### Scénario 3: Pas de connexion Internet

```
1. Première utilisation
   - NTP échoue
   - Utilise DateTime.now() avec avertissement
   - Stocke l'heure pour référence future

2. Utilisations suivantes
   - Calcule le temps écoulé depuis dernière vérification
   - Détecte les retours en arrière
   - Force NTP dès que connexion disponible
```

## 📊 Flux de validation

```
┌─────────────────────────────────────────┐
│  Demande d'heure sécurisée              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Vérifier manipulation horloge          │
│  (comparer avec lastCheckTime)          │
└──────────────┬──────────────────────────┘
               │
               ├─── Manipulation? ──► BLOQUER
               │
               ▼
┌─────────────────────────────────────────┐
│  Essayer NTP (cache 24h)                │
└──────────────┬──────────────────────────┘
               │
               ├─── NTP OK? ──► Retourner heure NTP
               │
               ▼
┌─────────────────────────────────────────┐
│  Calculer depuis dernière NTP           │
│  ou utiliser heure système              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Retourner TimeValidationResult         │
└─────────────────────────────────────────┘
```

## 🧪 Tests

Exécutez le script de test:

```bash
dart test-secure-time-service.dart
```

### Test manuel de manipulation

1. Lancez l'application normalement
2. Notez l'heure affichée
3. Reculez l'horloge système de votre ordinateur
4. Relancez l'application
5. ✅ Le service devrait détecter la manipulation et bloquer

## ⚙️ Configuration

### Serveurs NTP utilisés (par ordre de priorité)

```dart
static const List<String> _ntpServers = [
  'time.google.com',      // Google (très fiable)
  'pool.ntp.org',         // Pool NTP mondial
  'time.windows.com',     // Microsoft
  'time.cloudflare.com',  // Cloudflare
];
```

### Paramètres ajustables

```dart
// Durée du cache NTP
static const Duration _ntpCacheDuration = Duration(hours: 24);

// Différence maximale acceptable entre système et NTP
static const Duration _maxAcceptableOffset = Duration(minutes: 5);

// Nombre de tentatives NTP par serveur
static const int _maxNtpRetries = 3;
```

## 🔧 Maintenance

### Nettoyer les données (développement uniquement)

```dart
await secureTimeService.clearAllData();
```

### Diagnostics

```dart
final diagnostics = await secureTimeService.getDiagnostics();
print(diagnostics);
```

## 📝 Migration du code existant

### Avant (NON SÉCURISÉ)

```dart
// ❌ Vulnérable à la manipulation
if (DateTime.now().isAfter(license.expiresAt)) {
  showExpiredDialog();
}

final daysRemaining = license.remainingDays;
```

### Après (SÉCURISÉ)

```dart
// ✅ Protégé contre la manipulation
final timeResult = await secureTimeService.getSecureTime();
if (license.isExpiredSecure(timeResult.trustedTime)) {
  showExpiredDialog();
}

final daysRemaining = license.remainingDaysSecure(timeResult.trustedTime);
```

## ⚠️ Notes importantes

1. **Première connexion Internet requise**: L'application doit se connecter au moins une fois à Internet pour obtenir l'heure NTP initiale.

2. **Période de grâce**: Le système continue de fonctionner 3 jours après expiration (période de grâce).

3. **Avertissements vs Blocage**: Le service peut retourner des avertissements sans bloquer (mode permissif) ou bloquer immédiatement (mode strict).

4. **Performance**: Les requêtes NTP sont mises en cache pendant 24h pour éviter les appels réseau répétés.

5. **Compatibilité**: Fonctionne sur Windows, Linux, macOS, Android et iOS.

## 🎯 Résumé

Le `SecureTimeService` rend pratiquement impossible la manipulation de la date pour prolonger une licence:

✅ Utilise NTP pour l'heure réelle
✅ Détecte les retours en arrière
✅ Stockage persistant multi-niveaux
✅ Détecte les réinstallations
✅ Fonctionne hors ligne (avec cache)
✅ Logs détaillés pour debugging

La sécurité de votre système de licence est maintenant considérablement renforcée!
