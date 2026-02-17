#!/usr/bin/env dart

/// Exemple de générateur de clés de licence pour LOGESCO
///
/// Ce script montre comment générer des clés de licence pour vos clients
/// en utilisant le système de licence intégré dans l'application.

import 'dart:convert';
import 'dart:io';
import '../lib/features/subscription/models/license_key.dart';
import '../lib/features/subscription/models/license_data.dart';

void main(List<String> args) {
  print('🔐 Générateur de Clés de Licence LOGESCO');
  print('========================================\n');

  if (args.isEmpty) {
    showUsage();
    return;
  }

  final command = args[0];

  switch (command) {
    case 'generate':
      generateLicense(args);
      break;
    case 'validate':
      validateLicense(args);
      break;
    case 'info':
      showLicenseInfo(args);
      break;
    default:
      print('❌ Commande inconnue: $command');
      showUsage();
  }
}

void showUsage() {
  print('Usage:');
  print('  dart license_generator_example.dart generate <client-id> <type> <months> <device-hash>');
  print('  dart license_generator_example.dart validate <license-key>');
  print('  dart license_generator_example.dart info <license-key>');
  print('');
  print('Types d\'abonnement:');
  print('  trial    - Période d\'essai (7 jours)');
  print('  monthly  - Abonnement mensuel');
  print('  annual   - Abonnement annuel');
  print('  lifetime - Licence à vie');
  print('');
  print('Exemples:');
  print('  dart license_generator_example.dart generate CLIENT001 annual 12 ABC123DEF456');
  print('  dart license_generator_example.dart validate LOGESCO_V1_...');
}

void generateLicense(List<String> args) {
  if (args.length < 5) {
    print('❌ Arguments manquants pour la génération');
    print('Usage: generate <client-id> <type> <months> <device-hash>');
    return;
  }

  final clientId = args[1];
  final typeStr = args[2];
  final monthsStr = args[3];
  final deviceHash = args[4];

  // Valider le type d'abonnement
  SubscriptionType? subscriptionType;
  switch (typeStr.toLowerCase()) {
    case 'trial':
      subscriptionType = SubscriptionType.trial;
      break;
    case 'monthly':
      subscriptionType = SubscriptionType.monthly;
      break;
    case 'annual':
      subscriptionType = SubscriptionType.annual;
      break;
    case 'lifetime':
      subscriptionType = SubscriptionType.lifetime;
      break;
    default:
      print('❌ Type d\'abonnement invalide: $typeStr');
      return;
  }

  // Valider la durée
  final months = int.tryParse(monthsStr);
  if (months == null || months <= 0) {
    print('❌ Durée invalide: $monthsStr');
    return;
  }

  // Calculer les dates
  final now = DateTime.now();
  final expirationDate = subscriptionType == SubscriptionType.lifetime
      ? DateTime(2099, 12, 31) // Date très lointaine pour lifetime
      : now.add(Duration(days: months * 30));

  // Générer une signature factice (en production, utilisez une vraie signature RSA)
  final signature = _generateMockSignature(clientId, typeStr, deviceHash);

  // Créer la clé de licence
  final licenseKey = LicenseKeyUtils.generateLicenseKey(
    userId: clientId,
    subscriptionType: subscriptionType,
    issuedAt: now,
    expiresAt: expirationDate,
    deviceFingerprint: deviceHash,
    signature: signature,
    features: _getDefaultFeatures(subscriptionType),
  );

  // Afficher les résultats
  print('✅ Clé de licence générée avec succès!');
  print('');
  print('📋 Informations de la licence:');
  print('   Client ID: $clientId');
  print('   Type: ${subscriptionType.name}');
  print('   Émise le: ${_formatDate(now)}');
  print('   Expire le: ${_formatDate(expirationDate)}');
  print('   Appareil: $deviceHash');
  print('');
  print('🔑 Clé de licence:');
  print('   $licenseKey');
  print('');
  print('📝 Instructions pour le client:');
  print('   1. Copiez la clé de licence ci-dessus');
  print('   2. Dans LOGESCO, allez dans Paramètres > Abonnement');
  print('   3. Cliquez sur "Activer une licence"');
  print('   4. Collez la clé et validez');
  print('');

  // Sauvegarder dans un fichier
  _saveLicenseToFile(clientId, licenseKey, {
    'clientId': clientId,
    'type': subscriptionType.name,
    'issuedAt': now.toIso8601String(),
    'expiresAt': expirationDate.toIso8601String(),
    'deviceFingerprint': deviceHash,
    'licenseKey': licenseKey,
  });
}

void validateLicense(List<String> args) {
  if (args.length < 2) {
    print('❌ Clé de licence manquante');
    print('Usage: validate <license-key>');
    return;
  }

  final licenseKey = args[1];

  print('🔍 Validation de la clé de licence...');
  print('');

  final result = LicenseKeyUtils.validateLicenseKey(licenseKey);

  if (result.isValid) {
    print('✅ Clé de licence VALIDE');
    print('');
    _displayLicenseDetails(result.payload!);
  } else {
    print('❌ Clé de licence INVALIDE');
    print('   Raison: ${result.errorMessage}');

    if (result.isExpired) {
      print('   ⏰ La licence a expiré');
    }
  }
}

void showLicenseInfo(List<String> args) {
  if (args.length < 2) {
    print('❌ Clé de licence manquante');
    print('Usage: info <license-key>');
    return;
  }

  final licenseKey = args[1];

  print('📋 Informations de la clé de licence:');
  print('');

  final metadata = LicenseKeyUtils.extractKeyMetadata(licenseKey);

  if (metadata != null) {
    print('   Client ID: ${metadata['userId']}');
    print('   Type: ${metadata['type']}');
    print('   Émise le: ${_formatDate(DateTime.parse(metadata['issued']!))}');
    print('   Expire le: ${_formatDate(DateTime.parse(metadata['expires']!))}');
    print('   Version: ${metadata['version']}');

    final expirationDate = DateTime.parse(metadata['expires']!);
    final now = DateTime.now();

    if (now.isAfter(expirationDate)) {
      print('   ❌ Statut: EXPIRÉE');
    } else {
      final daysRemaining = expirationDate.difference(now).inDays;
      print('   ✅ Statut: ACTIVE ($daysRemaining jours restants)');
    }
  } else {
    print('❌ Impossible de lire les informations de la licence');
  }
}

void _displayLicenseDetails(LicenseKeyPayload payload) {
  print('📋 Détails de la licence:');
  print('   Client ID: ${payload.userId}');
  print('   Type: ${payload.subscriptionType}');
  print('   Émise le: ${_formatDate(DateTime.parse(payload.issued))}');
  print('   Expire le: ${_formatDate(DateTime.parse(payload.expires))}');
  print('   Appareil: ${payload.device}');
  print('   Fonctionnalités: ${payload.features.join(', ')}');

  final expirationDate = DateTime.parse(payload.expires);
  final now = DateTime.now();

  if (now.isAfter(expirationDate)) {
    print('   ❌ Statut: EXPIRÉE');
  } else {
    final daysRemaining = expirationDate.difference(now).inDays;
    print('   ✅ Statut: ACTIVE ($daysRemaining jours restants)');
  }
}

String _generateMockSignature(String clientId, String type, String device) {
  // ATTENTION: Ceci est une signature factice pour la démonstration
  // En production, vous devez utiliser une vraie signature RSA avec votre clé privée
  final data = '$clientId-$type-$device-${DateTime.now().millisecondsSinceEpoch}';
  final bytes = utf8.encode(data);
  return base64Encode(bytes);
}

List<String> _getDefaultFeatures(SubscriptionType type) {
  switch (type) {
    case SubscriptionType.trial:
      return ['basic_inventory', 'basic_sales'];
    case SubscriptionType.monthly:
      return ['full_inventory', 'sales', 'reports'];
    case SubscriptionType.annual:
      return ['full_inventory', 'sales', 'reports', 'advanced_analytics'];
    case SubscriptionType.lifetime:
      return ['full_inventory', 'sales', 'reports', 'advanced_analytics', 'premium_support'];
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

void _saveLicenseToFile(String clientId, String licenseKey, Map<String, dynamic> metadata) {
  try {
    final directory = Directory('generated_licenses');
    if (!directory.existsSync()) {
      directory.createSync();
    }

    final filename = 'license_${clientId}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('generated_licenses/$filename');

    final licenseData = {
      'generatedAt': DateTime.now().toIso8601String(),
      'licenseKey': licenseKey,
      'metadata': metadata,
    };

    file.writeAsStringSync(jsonEncode(licenseData));
    print('💾 Licence sauvegardée dans: generated_licenses/$filename');
  } catch (e) {
    print('⚠️  Impossible de sauvegarder la licence: $e');
  }
}
