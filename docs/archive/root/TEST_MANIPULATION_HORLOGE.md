# 🧪 Guide de test - Protection contre la manipulation de l'horloge

## Objectif

Vérifier que le `SecureTimeService` détecte et bloque efficacement les tentatives de manipulation de l'horloge système.

## Prérequis

```bash
cd logesco_v2
flutter pub get
```

## Test 1: Fonctionnement normal

### Étapes

1. Lancez le script de test:
```bash
dart test-secure-time-service.dart
```

2. Vérifiez la sortie:
```
✅ Heure sécurisée obtenue: 2025-03-07 14:30:00
   Heure système fiable: true
   NTP disponible: true
   Offset système: 0 secondes
```

### Résultat attendu

- ✅ Heure NTP obtenue avec succès
- ✅ Aucune manipulation détectée
- ✅ Système fonctionne normalement

## Test 2: Détection de retour en arrière

### Étapes

1. **Première exécution** - Établir une référence:
```bash
dart test-secure-time-service.dart
```
Note: L'heure actuelle est stockée (ex: 2025-03-07 14:30)

2. **Reculer l'horloge système**:
   - Windows: Paramètres > Heure et langue > Date et heure
   - Reculez de plusieurs jours (ex: 2025-01-01)

3. **Deuxième exécution** - Tester la détection:
```bash
dart test-secure-time-service.dart
```

### Résultat attendu

```
⚠️  [SecureTimeService] Retour en arrière détecté:
   Dernière vérification: 2025-03-07 14:30:00
   Heure actuelle: 2025-01-01 10:00:00

❌ TimeValidationException: L'horloge système a été manipulée. 
   Veuillez restaurer la date et l'heure correctes.
```

- ✅ Manipulation détectée
- ✅ Exception lancée
- ✅ Accès bloqué

## Test 3: Vérification NTP vs Horloge système

### Étapes

1. **Reculer l'horloge système** de 1 heure

2. **Lancer le test**:
```bash
dart test-secure-time-service.dart
```

### Résultat attendu

```
✅ Heure NTP: 2025-03-07 14:30:00
   Heure système: 2025-03-07 13:30:00
   Différence: 3600 secondes
   ⚠️  ATTENTION: Grande différence détectée!
```

- ✅ NTP retourne l'heure réelle
- ✅ Différence avec système détectée
- ✅ Avertissement émis

## Test 4: Fonctionnement hors ligne

### Étapes

1. **Première exécution avec Internet**:
```bash
dart test-secure-time-service.dart
```
Note: Cache NTP établi

2. **Désactiver Internet**:
   - Désactivez WiFi/Ethernet
   - Mode avion

3. **Deuxième exécution sans Internet**:
```bash
dart test-secure-time-service.dart
```

### Résultat attendu

```
⚠️  [SecureTimeService] Tous les serveurs NTP ont échoué
⚠️  Serveur NTP non disponible, utilisation du temps calculé
✅ Temps calculé depuis la dernière vérification NTP
```

- ✅ Fonctionne sans Internet
- ✅ Utilise le cache NTP
- ✅ Calcule le temps écoulé

## Test 5: Détection de réinstallation

### Étapes

1. **Première installation**:
```bash
dart test-secure-time-service.dart
```
Note: sessionCounter = 1

2. **Simuler une réinstallation**:
```dart
// Dans le code de test, ajoutez:
await secureTimeService.clearAllData();
// Puis supprimez uniquement SharedPreferences
```

3. **Relancer**:
```bash
dart test-secure-time-service.dart
```

### Résultat attendu

```
⚠️  [SecureTimeService] Réinstallation potentielle détectée
🌐 [SecureTimeService] Force vérification NTP immédiate
```

- ✅ Réinstallation détectée
- ✅ Vérification NTP forcée
- ✅ Sécurité maintenue

## Test 6: Validation de licence avec manipulation

### Créer un test de licence

```dart
import 'package:logesco_v2/features/subscription/services/implementations/secure_time_service.dart';
import 'package:logesco_v2/features/subscription/models/license_data.dart';

void main() async {
  final secureTimeService = SecureTimeService();
  await secureTimeService.initialize();
  
  // Simuler une licence qui expire dans 30 jours
  final expirationDate = DateTime.now().add(Duration(days: 30));
  
  print('Date d\'expiration: $expirationDate');
  
  try {
    final timeResult = await secureTimeService.getSecureTime();
    final secureTime = timeResult.trustedTime;
    
    print('Heure sécurisée: $secureTime');
    
    if (secureTime.isAfter(expirationDate)) {
      print('❌ Licence expirée!');
    } else {
      final daysRemaining = expirationDate.difference(secureTime).inDays;
      print('✅ Licence valide - $daysRemaining jours restants');
    }
    
    if (!timeResult.isSystemTimeReliable) {
      print('⚠️  ATTENTION: Horloge système non fiable!');
      print('   L\'utilisateur a peut-être manipulé la date.');
    }
  } on TimeValidationException catch (e) {
    print('❌ ACCÈS BLOQUÉ: ${e.message}');
  }
}
```

### Étapes

1. **Exécution normale**:
```bash
dart test_licence_manipulation.dart
```
Résultat: ✅ Licence valide - 30 jours restants

2. **Reculer l'horloge de 40 jours**

3. **Réexécution**:
```bash
dart test_licence_manipulation.dart
```

### Résultat attendu

```
❌ ACCÈS BLOQUÉ: L'horloge système a été manipulée. 
   Veuillez restaurer la date et l'heure correctes.
```

- ✅ Manipulation détectée avant validation
- ✅ Accès bloqué immédiatement
- ✅ Licence non contournable

## Test 7: Performance et cache

### Étapes

1. **Test de performance**:
```dart
void main() async {
  final secureTimeService = SecureTimeService();
  await secureTimeService.initialize();
  
  // Premier appel (avec NTP)
  final start1 = DateTime.now();
  await secureTimeService.getSecureTime(forceNtpCheck: true);
  final duration1 = DateTime.now().difference(start1);
  print('Premier appel (NTP): ${duration1.inMilliseconds}ms');
  
  // Deuxième appel (cache)
  final start2 = DateTime.now();
  await secureTimeService.getSecureTime();
  final duration2 = DateTime.now().difference(start2);
  print('Deuxième appel (cache): ${duration2.inMilliseconds}ms');
}
```

### Résultat attendu

```
Premier appel (NTP): 500-2000ms
Deuxième appel (cache): 1-10ms
```

- ✅ Cache fonctionne efficacement
- ✅ Performance optimale
- ✅ Pas de latence pour l'utilisateur

## Test 8: Diagnostics complets

### Étapes

```bash
dart test-secure-time-service.dart
```

Examinez la section "Diagnostics":

### Résultat attendu

```json
{
  "systemTime": "2025-03-07T14:30:00.000",
  "lastCheckTime": "2025-03-07T14:30:00.000",
  "cachedNtpTime": "2025-03-07T14:30:00.000",
  "sessionCounter": 5,
  "ntpAvailable": true,
  "systemTimeOffset": 0,
  "manipulationDetected": false,
  "reinstallationDetected": false
}
```

## Checklist de validation

### Sécurité

- [ ] Détecte le retour en arrière de l'horloge
- [ ] Bloque l'accès si manipulation détectée
- [ ] Utilise NTP pour l'heure réelle
- [ ] Détecte les réinstallations suspectes
- [ ] Stockage multi-niveaux fonctionne

### Fonctionnalité

- [ ] Fonctionne avec Internet
- [ ] Fonctionne sans Internet (cache)
- [ ] Cache NTP pendant 24h
- [ ] Fallback sur plusieurs serveurs NTP
- [ ] Logs détaillés disponibles

### Performance

- [ ] Premier appel < 2 secondes
- [ ] Appels suivants < 10ms (cache)
- [ ] Pas de blocage de l'UI
- [ ] Consommation réseau minimale

### Robustesse

- [ ] Gère les erreurs réseau
- [ ] Récupère après échec NTP
- [ ] Survit aux redémarrages
- [ ] Résiste aux suppressions de données

## Scénarios de contournement testés

### ❌ Tentative 1: Reculer l'horloge
**Résultat**: Détecté et bloqué ✅

### ❌ Tentative 2: Désinstaller/Réinstaller
**Résultat**: Détecté, force NTP ✅

### ❌ Tentative 3: Supprimer les données de l'app
**Résultat**: Stockage multi-niveaux résiste ✅

### ❌ Tentative 4: Bloquer l'accès NTP
**Résultat**: Utilise cache + détection manipulation ✅

### ❌ Tentative 5: Modifier les fichiers de stockage
**Résultat**: Chiffrement + vérification intégrité ✅

## Conclusion

Si tous les tests passent, le système est **sécurisé** contre la manipulation de l'horloge. Les utilisateurs ne peuvent plus:

❌ Prolonger leur licence en reculant l'horloge
❌ Contourner l'expiration par réinstallation
❌ Manipuler les fichiers de stockage

La protection est **robuste**, **multi-niveaux** et **transparente** pour les utilisateurs légitimes.

## Commandes rapides

```bash
# Test complet
dart test-secure-time-service.dart

# Installer les dépendances
cd logesco_v2 && flutter pub get

# Nettoyer les données de test
# (Ajoutez dans le code: await secureTimeService.clearAllData())

# Vérifier les logs
# Les logs sont affichés dans la console avec préfixes:
# 🌐 = NTP
# ⚠️  = Avertissement
# ❌ = Erreur
# ✅ = Succès
```
