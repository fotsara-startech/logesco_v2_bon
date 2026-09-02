# Paramètres Configurables - Système de Licence Offline

## 🔧 Fichier: `secure_time_service.dart`

### Timeouts NTP
```dart
static const Duration _ntpTimeout = Duration(seconds: 2); // Ajuster pour un réseau lent
```
**Valeurs recommandées:**
- `2 secondes` (défaut) - Équilibre vitesse/fiabilité
- `3 secondes` - Si réseau très lent (3G/satellite)
- `1 seconde` - Si réseau rapide

---

### Nombre de Retries NTP
```dart
static const int _maxNtpRetries = 2; // Nombre de tentatives par serveur
```
**Valeurs recommandées:**
- `2` (défaut) - Rapide et fiable
- `3` - Si réseau instable
- `1` - Si très peu de patience (pas recommandé)

---

### Serveurs NTP
```dart
static const List<String> _ntpServers = [
  'time.google.com',
  'pool.ntp.org',
  'time.cloudflare.com',
];
```
**Comment ajouter un serveur:**
```dart
static const List<String> _ntpServers = [
  'time.google.com',
  'pool.ntp.org',
  'time.cloudflare.com',
  'time.windows.com',  // ← Nouveau serveur
];
```

---

### Durée du Cache NTP
```dart
static const Duration _ntpCacheDuration = Duration(hours: 24); // Réduire pour plus de fraîcheur
```
**Valeurs recommandées:**
- `24 heures` (défaut) - Offline mode optimal
- `12 heures` - Plus de validations
- `6 heures` - Très fréquentes validations
- `1 heure` - Validation quasi-quotidienne

---

### Tolérance Décalage Horloge
```dart
static const Duration _maxAcceptableOffset = Duration(minutes: 5); // Alerte si > 5 min de décalage
```
**Valeurs recommandées:**
- `5 minutes` (défaut) - Standard
- `10 minutes` - Plus tolérant
- `1 minute` - Strict

---

### Seuil Mode Offline
```dart
static const int _maxNtpFailuresBeforeOffline = 5; // Après 5 échecs → mode offline
```
**Valeurs recommandées:**
- `5` (défaut) - Équilibré
- `3` - Passage rapide en offline
- `10` - Persistance avant offline

---

## 🔧 Fichier: `subscription_manager.dart`

### Intervalle Validation Périodique
```dart
static const int _validationIntervalMinutes = 30; // Revalider toutes les 30 min
```
**Valeurs recommandées:**
- `30 minutes` (défaut) - Équilibre charge/fraîcheur
- `15 minutes` - Plus fréquent
- `60 minutes` - Moins fréquent (économe)

---

### Durée Essai
```dart
static const int _trialDurationDays = 7; // Période d'essai gratuit
```
**Valeurs recommandées:**
- `7 jours` (défaut) - Standard marché
- `14 jours` - Plus généreux
- `30 jours` - Très généreux
- `3 jours` - Court essai

---

### Période de Grâce
```dart
static const int _gracePeriodDays = 3; // 3 jours de travail après expiration
```
**Valeurs recommandées:**
- `3 jours` (défaut) - Temps d'action
- `7 jours` - Très généreux
- `1 jour` - Très strict
- `0 jours` - Aucun délai

---

### Seuils d'Avertissement
```dart
static const int _warningDaysThreshold = 3;           // Avertissement à 3 jours
static const int _urgentWarningDaysThreshold = 1;     // Urgent à 1 jour
```
**Valeurs recommandées:**
- `3 et 1` (défaut) - Standard
- `7 et 3` - Plus d'avance prévue
- `1 et 0` - Minimal

---

### Caches de Performance
```dart
static const int _cacheValidityMinutes = 5;       // Cache normal = 5 min
static const int _fastCacheValiditySeconds = 30;  // Cache rapide = 30 sec
```
**Stratégie:**
- **Cache rapide (30s)**: Pour `shouldBlockApplication()`
- **Cache normal (5 min)**: Pour `getCurrentStatus()`

**Ajustement:**
```dart
// Si app est très chargée:
static const int _cacheValidityMinutes = 10;       // ↑ 10 min
static const int _fastCacheValiditySeconds = 60;   // ↑ 1 min

// Si validations très fraîches requises:
static const int _cacheValidityMinutes = 2;        // ↓ 2 min
static const int _fastCacheValiditySeconds = 10;   // ↓ 10 sec
```

---

## 🔧 Fichier: `app_config.dart`

### Activation/Désactivation Système de Licence
```dart
static const bool enableLicenseControl = true;  // Activer le système de licence
```
**Utilisation:**
- `true` - Production (validation active)
- `false` - Développement (accès complet gratuit)

---

## 📊 Profils Recommandés

### 📱 Profil "Performance" (Connexion Instable)
```dart
// secure_time_service.dart
static const Duration _ntpTimeout = Duration(seconds: 3);
static const int _maxNtpRetries = 2;
static const int _maxNtpFailuresBeforeOffline = 3;

// subscription_manager.dart
static const int _validationIntervalMinutes = 60;
static const int _cacheValidityMinutes = 15;
static const int _fastCacheValiditySeconds = 60;
```

### 🔒 Profil "Sécurité" (Connexion Fiable)
```dart
// secure_time_service.dart
static const Duration _ntpTimeout = Duration(seconds: 1);
static const int _maxNtpRetries = 3;
static const Duration _ntpCacheDuration = Duration(hours: 6);

// subscription_manager.dart
static const int _validationIntervalMinutes = 15;
static const int _cacheValidityMinutes = 2;
static const int _fastCacheValiditySeconds = 10;
```

### 💰 Profil "Essai Généreux" (Freemium)
```dart
// subscription_manager.dart
static const int _trialDurationDays = 14;
static const int _gracePeriodDays = 7;
static const int _warningDaysThreshold = 7;
static const int _urgentWarningDaysThreshold = 3;
```

### 🏢 Profil "Entreprise" (Offline d'Équipe)
```dart
// secure_time_service.dart
static const Duration _ntpCacheDuration = Duration(hours: 48);
static const int _maxNtpFailuresBeforeOffline = 2;

// subscription_manager.dart
static const int _validationIntervalMinutes = 120;  // 2h
static const int _gracePeriodDays = 14;
```

---

## 🚀 Exemple: Configuration pour "Réseau Très Lent"

**Situation:** Clients avec 2G/Edge fréquent

**Modifications:**
```dart
// secure_time_service.dart
static const Duration _ntpTimeout = Duration(seconds: 5); // ↑
static const int _maxNtpRetries = 1;  // ↓ Moins de retries
static const int _maxNtpFailuresBeforeOffline = 2;  // ↓ Offline rapide

// subscription_manager.dart
static const int _validationIntervalMinutes = 60;  // ↑ Moins fréquent
static const Duration _ntpCacheDuration = Duration(hours: 48);  // ↑ Cache long
```

**Résultat:**
- Validations moins fréquentes (economie batterie)
- Mode offline plus rapide
- Cache utilisé plus longtemps

---

## 📊 Métriques à Surveiller

Ajouter du monitoring pour ajuster:

```dart
// À implémenter: Logger ces événements
- NTP timeout count (diagnostiquer problèmes réseau)
- Mode offline activations (fréquence d'offline)
- Cache hit rate (efficacité du cache)
- Validation durations (perf du système)
- License block events (usagers complètement bloqués)
```

---

## ⚡ Quick Reference

| Besoin | Paramètre | Valeur |
|--------|-----------|---------|
| Moins de gels UI | `_ntpTimeout` | ↓ 1-2s |
| Offline tolérant | `_ntpCacheDuration` | ↑ 48h |
| Offline agressif | `_maxNtpFailuresBeforeOffline` | ↓ 2 |
| Moins de retries | `_maxNtpRetries` | 1 |
| Plus de validations | `_validationIntervalMinutes` | ↓ 15 |
| Moins de validations | `_validationIntervalMinutes` | ↑ 60 |
| Essai plus long | `_trialDurationDays` | ↑ 14 |
| Grâce plus long | `_gracePeriodDays` | ↑ 7 |

---

**Note:** Tous les changements sont hot-reload compatibles. Redéployer l'app n'est pas obligatoire pour les tests.
