import 'dart:io';
import 'package:flutter/material.dart';
import 'logesco_v2/lib/features/subscription/services/implementations/secure_time_service.dart';

/// Test du SecureTimeService
///
/// Ce script démontre comment le service protège contre la manipulation de l'horloge système
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔐 Test du SecureTimeService');
  print('=' * 60);

  final secureTimeService = SecureTimeService();
  await secureTimeService.initialize();

  // Test 1: Obtenir l'heure sécurisée normale
  print('\n📋 Test 1: Obtention de l\'heure sécurisée');
  print('-' * 60);
  try {
    final result = await secureTimeService.getSecureTime();
    print('✅ Heure sécurisée obtenue: ${result.trustedTime}');
    print('   Heure système fiable: ${result.isSystemTimeReliable}');
    print('   NTP disponible: ${result.ntpAvailable}');

    if (result.systemTimeOffset != null) {
      print('   Offset système: ${result.systemTimeOffset!.inSeconds} secondes');
    }

    if (result.hasWarnings) {
      print('   ⚠️  Avertissements:');
      for (final warning in result.warnings) {
        print('      - $warning');
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  // Test 2: Forcer une vérification NTP
  print('\n📋 Test 2: Vérification NTP forcée');
  print('-' * 60);
  try {
    final ntpTime = await secureTimeService.forceNtpCheck();
    if (ntpTime != null) {
      print('✅ Heure NTP: $ntpTime');
      final systemTime = DateTime.now();
      final offset = ntpTime.difference(systemTime);
      print('   Heure système: $systemTime');
      print('   Différence: ${offset.inSeconds} secondes');

      if (offset.abs() > const Duration(minutes: 1)) {
        print('   ⚠️  ATTENTION: Grande différence détectée!');
      }
    } else {
      print('⚠️  Serveurs NTP non disponibles');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  // Test 3: Diagnostics
  print('\n📋 Test 3: Diagnostics du système');
  print('-' * 60);
  final diagnostics = await secureTimeService.getDiagnostics();
  print('Heure système: ${diagnostics['systemTime']}');
  print('Dernière vérification: ${diagnostics['lastCheckTime'] ?? 'Aucune'}');
  print('Dernier NTP: ${diagnostics['cachedNtpTime'] ?? 'Aucun'}');
  print('Compteur sessions: ${diagnostics['sessionCounter'] ?? 0}');
  print('NTP disponible: ${diagnostics['ntpAvailable']}');
  print('Manipulation détectée: ${diagnostics['manipulationDetected']}');
  print('Réinstallation détectée: ${diagnostics['reinstallationDetected']}');

  if (diagnostics['systemTimeOffset'] != null) {
    print('Offset système: ${diagnostics['systemTimeOffset']} secondes');
  }

  // Test 4: Simulation de manipulation (pour démonstration)
  print('\n📋 Test 4: Simulation de détection de manipulation');
  print('-' * 60);
  print('ℹ️  Pour tester la détection de manipulation:');
  print('   1. Lancez ce script une première fois');
  print('   2. Reculez l\'horloge système de votre ordinateur');
  print('   3. Relancez ce script');
  print('   4. Le service devrait détecter la manipulation');

  // Test 5: Vérification avec licence (exemple)
  print('\n📋 Test 5: Exemple de validation de licence');
  print('-' * 60);

  // Simuler une date d'expiration
  final expirationDate = DateTime.now().add(const Duration(days: 30));
  print('Date d\'expiration simulée: $expirationDate');

  try {
    final timeResult = await secureTimeService.getSecureTime();
    final secureTime = timeResult.trustedTime;

    if (secureTime.isAfter(expirationDate)) {
      print('❌ Licence expirée!');
    } else {
      final daysRemaining = expirationDate.difference(secureTime).inDays;
      print('✅ Licence valide - $daysRemaining jours restants');
    }

    if (!timeResult.isSystemTimeReliable) {
      print('⚠️  ATTENTION: Horloge système non fiable!');
    }
  } catch (e) {
    print('❌ Erreur validation: $e');
  }

  print('\n' + '=' * 60);
  print('✅ Tests terminés');
  print('\n💡 Avantages du SecureTimeService:');
  print('   1. Utilise NTP pour obtenir l\'heure réelle');
  print('   2. Détecte les retours en arrière de l\'horloge');
  print('   3. Stockage multi-niveaux résistant à la suppression');
  print('   4. Détecte les réinstallations suspectes');
  print('   5. Fonctionne même hors ligne (avec cache)');
}
