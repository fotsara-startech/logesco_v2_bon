import 'crypto_service.dart';
import 'key_manager.dart';

/// Service d'intégration pour la gestion des clés publiques RSA
/// Démontre l'utilisation sécurisée des clés publiques intégrées
class PublicKeyIntegrationService {
  final CryptoService _cryptoService;
  final KeyManager _keyManager;

  PublicKeyIntegrationService({
    CryptoService? cryptoService,
    KeyManager? keyManager,
  })  : _cryptoService = cryptoService ?? CryptoService(),
        _keyManager = keyManager ?? KeyManager();

  /// Initialise le service d'intégration
  Future<void> initialize() async {
    await _cryptoService.initialize();
  }

  /// Vérifie une signature de licence avec la clé active
  Future<bool> verifyLicenseSignature(String licenseData, String signature) async {
    try {
      return await _cryptoService.verifySignatureWithActiveKey(licenseData, signature);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie une signature avec une clé spécifique
  Future<bool> verifySignatureWithSpecificKey(String data, String signature, String keyId) async {
    try {
      return await _cryptoService.verifySignatureWithKeyId(data, signature, keyId);
    } catch (e) {
      return false;
    }
  }

  /// Effectue la rotation des clés et vérifie l'intégrité
  Future<bool> performKeyRotation() async {
    try {
      // Vérifier l'intégrité avant la rotation
      final integrityOk = await _cryptoService.verifyKeysIntegrity();
      if (!integrityOk) {
        // Réinitialiser les clés si l'intégrité est compromise
        await _cryptoService.resetKeys();
        return false;
      }

      // Effectuer la rotation
      return await _cryptoService.rotateKeys();
    } catch (e) {
      return false;
    }
  }

  /// Récupère les informations sur la clé active
  Future<Map<String, dynamic>> getActiveKeyInfo() async {
    try {
      final keyId = await _cryptoService.getActiveKeyId();
      final publicKey = await _cryptoService.getActivePublicKey();

      return {
        'keyId': keyId,
        'hasPublicKey': publicKey != null,
        'keyLength': publicKey?.length ?? 0,
      };
    } catch (e) {
      return {
        'keyId': null,
        'hasPublicKey': false,
        'keyLength': 0,
      };
    }
  }

  /// Vérifie l'état de santé du système de clés
  Future<Map<String, dynamic>> checkKeySystemHealth() async {
    try {
      final availableKeys = await _keyManager.getAvailableKeyIds();
      final integrityOk = await _cryptoService.verifyKeysIntegrity();
      final activeKeyId = await _cryptoService.getActiveKeyId();

      return {
        'status': 'healthy',
        'availableKeysCount': availableKeys.length,
        'availableKeys': availableKeys,
        'integrityOk': integrityOk,
        'activeKeyId': activeKeyId,
        'hasActiveKey': activeKeyId != null,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'availableKeysCount': 0,
        'integrityOk': false,
        'hasActiveKey': false,
      };
    }
  }

  /// Réinitialise complètement le système de clés
  Future<bool> resetKeySystem() async {
    try {
      await _cryptoService.resetKeys();
      await _cryptoService.initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Valide une licence complète avec vérification de signature
  Future<Map<String, dynamic>> validateLicense(Map<String, dynamic> licenseData) async {
    try {
      // Extraire les données de la licence
      final signature = licenseData['signature'] as String?;
      final keyId = licenseData['keyId'] as String?;

      if (signature == null) {
        return {
          'valid': false,
          'error': 'Signature manquante',
        };
      }

      // Créer les données à vérifier (sans la signature)
      final dataToVerify = Map<String, dynamic>.from(licenseData);
      dataToVerify.remove('signature');
      final dataString = dataToVerify.entries.map((e) => '${e.key}=${e.value}').join('&');

      bool signatureValid = false;

      if (keyId != null) {
        // Vérifier avec une clé spécifique
        signatureValid = await verifySignatureWithSpecificKey(dataString, signature, keyId);
      } else {
        // Vérifier avec la clé active
        signatureValid = await verifyLicenseSignature(dataString, signature);
      }

      return {
        'valid': signatureValid,
        'keyId': keyId ?? await _cryptoService.getActiveKeyId(),
        'dataVerified': dataString,
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Erreur lors de la validation: $e',
      };
    }
  }
}
