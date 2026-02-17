import '../services/implementations/public_key_integration_service.dart';

/// Exemple d'utilisation du système de clés publiques intégré
class PublicKeyUsageExample {
  final PublicKeyIntegrationService _integrationService;

  PublicKeyUsageExample() : _integrationService = PublicKeyIntegrationService();

  /// Démontre l'initialisation et l'utilisation du système de clés
  Future<void> demonstrateKeySystem() async {
    print('=== Démonstration du système de clés publiques ===\n');

    // 1. Initialisation du système
    print('1. Initialisation du système...');
    await _integrationService.initialize();
    print('✓ Système initialisé\n');

    // 2. Vérification de l'état de santé
    print('2. Vérification de l\'état de santé...');
    final health = await _integrationService.checkKeySystemHealth();
    print('Status: ${health['status']}');
    print('Clés disponibles: ${health['availableKeysCount']}');
    print('Intégrité OK: ${health['integrityOk']}');
    print('Clé active: ${health['activeKeyId']}\n');

    // 3. Informations sur la clé active
    print('3. Informations sur la clé active...');
    final keyInfo = await _integrationService.getActiveKeyInfo();
    print('ID de la clé: ${keyInfo['keyId']}');
    print('Clé publique disponible: ${keyInfo['hasPublicKey']}');
    print('Taille de la clé: ${keyInfo['keyLength']} caractères\n');

    // 4. Validation d'une licence d'exemple
    print('4. Validation d\'une licence d\'exemple...');
    final sampleLicense = {
      'userId': 'user123',
      'productId': 'logesco_pro',
      'expiryDate': '2025-12-31',
      'features': ['advanced_logging', 'export_data'],
      'signature': 'exemple_signature_invalide',
    };

    final validationResult = await _integrationService.validateLicense(sampleLicense);
    print('Licence valide: ${validationResult['valid']}');
    print('Clé utilisée: ${validationResult['keyId']}');
    if (!validationResult['valid']) {
      print('Raison: ${validationResult['error'] ?? 'Signature invalide'}');
    }
    print('');

    // 5. Rotation des clés
    print('5. Rotation des clés...');
    final rotationSuccess = await _integrationService.performKeyRotation();
    print('Rotation réussie: $rotationSuccess');

    if (rotationSuccess) {
      final newKeyInfo = await _integrationService.getActiveKeyInfo();
      print('Nouvelle clé active: ${newKeyInfo['keyId']}\n');
    }

    // 6. Vérification finale de l'intégrité
    print('6. Vérification finale de l\'intégrité...');
    final finalHealth = await _integrationService.checkKeySystemHealth();
    print('Système en bon état: ${finalHealth['status'] == 'healthy'}');
    print('Toutes les clés intègres: ${finalHealth['integrityOk']}\n');

    print('=== Démonstration terminée ===');
  }

  /// Exemple de validation de licence avec différentes clés
  Future<void> demonstrateLicenseValidation() async {
    print('=== Validation de licence avec différentes clés ===\n');

    await _integrationService.initialize();

    // Licence avec clé spécifique
    final licenseWithKeyId = {
      'userId': 'user456',
      'productId': 'logesco_basic',
      'expiryDate': '2024-12-31',
      'keyId': 'key_v1',
      'signature': 'signature_pour_key_v1',
    };

    print('Validation avec clé spécifique (key_v1)...');
    final result1 = await _integrationService.validateLicense(licenseWithKeyId);
    print('Résultat: ${result1['valid']} (clé: ${result1['keyId']})\n');

    // Licence sans clé spécifique (utilise la clé active)
    final licenseWithoutKeyId = {
      'userId': 'user789',
      'productId': 'logesco_enterprise',
      'expiryDate': '2026-01-31',
      'signature': 'signature_pour_cle_active',
    };

    print('Validation avec clé active...');
    final result2 = await _integrationService.validateLicense(licenseWithoutKeyId);
    print('Résultat: ${result2['valid']} (clé: ${result2['keyId']})\n');

    print('=== Validation terminée ===');
  }

  /// Exemple de gestion d'erreurs et de récupération
  Future<void> demonstrateErrorHandling() async {
    print('=== Gestion d\'erreurs et récupération ===\n');

    await _integrationService.initialize();

    // Simuler une corruption en réinitialisant le système
    print('1. Réinitialisation du système (simulation de corruption)...');
    final resetSuccess = await _integrationService.resetKeySystem();
    print('Réinitialisation réussie: $resetSuccess\n');

    // Vérifier l'état après réinitialisation
    print('2. Vérification de l\'état après réinitialisation...');
    final healthAfterReset = await _integrationService.checkKeySystemHealth();
    print('Status: ${healthAfterReset['status']}');
    print('Clés disponibles: ${healthAfterReset['availableKeysCount']}');
    print('Système fonctionnel: ${healthAfterReset['hasActiveKey']}\n');

    // Test avec une licence malformée
    print('3. Test avec une licence malformée...');
    final malformedLicense = {
      'userId': 'test_user',
      // Signature manquante intentionnellement
    };

    final malformedResult = await _integrationService.validateLicense(malformedLicense);
    print('Validation licence malformée: ${malformedResult['valid']}');
    print('Erreur: ${malformedResult['error']}\n');

    print('=== Gestion d\'erreurs terminée ===');
  }
}
