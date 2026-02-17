import '../interfaces/i_crypto_service.dart';
import 'crypto_service.dart';
import 'key_manager.dart';

/// Service cryptographique amélioré avec gestion intégrée des clés
class EnhancedCryptoService implements ICryptoService {
  final CryptoService _cryptoService;
  final KeyManager _keyManager;

  EnhancedCryptoService({
    CryptoService? cryptoService,
    KeyManager? keyManager,
  })  : _cryptoService = cryptoService ?? CryptoService(),
        _keyManager = keyManager ?? KeyManager();

  /// Initialise le service cryptographique
  Future<void> initialize() async {
    await _keyManager.initialize();
  }

  /// Vérifie une signature RSA avec la clé publique active
  @override
  bool verifySignature(String data, String signature, String publicKey) {
    return _cryptoService.verifySignature(data, signature, publicKey);
  }

  /// Vérifie une signature RSA avec la clé publique active automatiquement
  Future<bool> verifySignatureWithActiveKey(String data, String signature) async {
    try {
      final publicKey = await _keyManager.getActivePublicKey();
      if (publicKey == null) {
        return false;
      }

      return verifySignature(data, signature, publicKey);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie une signature avec une clé spécifique par ID
  Future<bool> verifySignatureWithKeyId(String data, String signature, String keyId) async {
    try {
      final publicKey = await _keyManager.getPublicKeyById(keyId);
      if (publicKey == null) {
        return false;
      }

      return verifySignature(data, signature, publicKey);
    } catch (e) {
      return false;
    }
  }

  /// Tente de vérifier une signature avec toutes les clés disponibles
  Future<bool> verifySignatureWithAnyKey(String data, String signature) async {
    try {
      final keyIds = await _keyManager.getAvailableKeyIds();

      for (final keyId in keyIds) {
        if (await verifySignatureWithKeyId(data, signature, keyId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Effectue la rotation des clés
  Future<bool> rotateKeys() async {
    return await _keyManager.rotateToNextKey();
  }

  /// Vérifie l'intégrité de toutes les clés
  Future<bool> verifyKeysIntegrity() async {
    return await _keyManager.verifyAllKeysIntegrity();
  }

  /// Réinitialise les clés en cas de corruption
  Future<void> resetKeys() async {
    await _keyManager.resetKeys();
  }

  /// Récupère l'ID de la clé active
  Future<String?> getActiveKeyId() async {
    return await _keyManager.getActiveKeyId();
  }

  // Délégation des autres méthodes au service cryptographique de base

  @override
  String generateHash(String input) {
    return _cryptoService.generateHash(input);
  }

  @override
  String encryptData(String data, String key) {
    return _cryptoService.encryptData(data, key);
  }

  @override
  String decryptData(String encryptedData, String key) {
    return _cryptoService.decryptData(encryptedData, key);
  }

  @override
  bool verifyIntegrity(String data, String checksum) {
    return _cryptoService.verifyIntegrity(data, checksum);
  }

  @override
  String generateRandomKey([int length = 32]) {
    return _cryptoService.generateRandomKey(length);
  }

  @override
  String encodeBase64(List<int> bytes) {
    return _cryptoService.encodeBase64(bytes);
  }

  @override
  List<int> decodeBase64(String encoded) {
    return _cryptoService.decodeBase64(encoded);
  }

  @override
  String generateHmac(String data, String key) {
    return _cryptoService.generateHmac(data, key);
  }

  @override
  bool verifyHmac(String data, String key, String expectedHmac) {
    return _cryptoService.verifyHmac(data, key, expectedHmac);
  }
}
