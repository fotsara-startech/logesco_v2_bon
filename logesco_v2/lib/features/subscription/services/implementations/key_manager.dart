import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestionnaire des clés publiques RSA pour la validation des licences
class KeyManager {
  static const String _keyStoragePrefix = 'rsa_public_key_';
  static const String _activeKeyIdKey = 'active_key_id';
  static const String _keyIntegrityPrefix = 'key_integrity_';

  final FlutterSecureStorage _secureStorage;

  KeyManager({FlutterSecureStorage? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Clés publiques RSA intégrées dans l'application
  static const Map<String, String> _embeddedPublicKeys = {
    'key_v1': '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyKwQmX7OqiXQoGbwODjN
vEHlcjHt8RtJ9mK5pL3nF2wQ8xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9
oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6m
P4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ
3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9
oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6m
P4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ
QIDAQAB
-----END PUBLIC KEY-----''',
    'key_v2': '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1L5RnY8PrjYRpHcxPEkO
wFImcjIt9SuK0nL4oG3pG9xS4yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4
xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4
xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4
xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4
xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4
xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4xS5yS8zO7nQ5tU2wL0pG4
QIDAQAB
-----END PUBLIC KEY-----''',
    'key_v3': '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2M6TnZ9QsjZSpIcyQFlP
xGJndjJu0TvL1oM5qH4yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1
qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9
yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8
oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1
qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9
yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8oR6uR3xM1qH5rN3oG9yT6zT9yP8
QIDAQAB
-----END PUBLIC KEY-----''',
  };

  /// Checksums d'intégrité des clés publiques
  static const Map<String, String> _keyIntegrityHashes = {
    'key_v1': 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    'key_v2': 'b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567a',
    'key_v3': 'c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567ab2',
  };

  /// Initialise le gestionnaire de clés
  Future<void> initialize() async {
    await _storeEmbeddedKeys();
    await _setDefaultActiveKey();
  }

  /// Récupère la clé publique active
  Future<String?> getActivePublicKey() async {
    try {
      final activeKeyId = await _secureStorage.read(key: _activeKeyIdKey);
      if (activeKeyId == null) {
        return null;
      }

      final publicKey = await _secureStorage.read(key: '$_keyStoragePrefix$activeKeyId');

      if (publicKey != null && await _verifyKeyIntegrity(activeKeyId, publicKey)) {
        return publicKey;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère une clé publique par son ID
  Future<String?> getPublicKeyById(String keyId) async {
    try {
      final publicKey = await _secureStorage.read(key: '$_keyStoragePrefix$keyId');

      if (publicKey != null && await _verifyKeyIntegrity(keyId, publicKey)) {
        return publicKey;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Définit la clé active
  Future<bool> setActiveKey(String keyId) async {
    try {
      // Vérifier que la clé existe et est valide
      final publicKey = await getPublicKeyById(keyId);
      if (publicKey == null) {
        return false;
      }

      await _secureStorage.write(key: _activeKeyIdKey, value: keyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'ID de la clé active
  Future<String?> getActiveKeyId() async {
    try {
      return await _secureStorage.read(key: _activeKeyIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Liste toutes les clés disponibles
  Future<List<String>> getAvailableKeyIds() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final keyIds = <String>[];

      for (final entry in allKeys.entries) {
        if (entry.key.startsWith(_keyStoragePrefix)) {
          final keyId = entry.key.substring(_keyStoragePrefix.length);
          if (await _verifyKeyIntegrity(keyId, entry.value)) {
            keyIds.add(keyId);
          }
        }
      }

      return keyIds;
    } catch (e) {
      return [];
    }
  }

  /// Effectue la rotation des clés (passe à la clé suivante)
  Future<bool> rotateToNextKey() async {
    try {
      final availableKeys = await getAvailableKeyIds();
      final currentKeyId = await getActiveKeyId();

      if (availableKeys.isEmpty) {
        return false;
      }

      // Trier les clés par version
      availableKeys.sort();

      if (currentKeyId == null) {
        // Aucune clé active, prendre la première
        return await setActiveKey(availableKeys.first);
      }

      final currentIndex = availableKeys.indexOf(currentKeyId);
      if (currentIndex == -1 || currentIndex == availableKeys.length - 1) {
        // Clé actuelle non trouvée ou dernière clé, prendre la première
        return await setActiveKey(availableKeys.first);
      }

      // Passer à la clé suivante
      return await setActiveKey(availableKeys[currentIndex + 1]);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie l'intégrité de toutes les clés stockées
  Future<bool> verifyAllKeysIntegrity() async {
    try {
      final availableKeys = await getAvailableKeyIds();

      for (final keyId in availableKeys) {
        final publicKey = await _secureStorage.read(key: '$_keyStoragePrefix$keyId');

        if (publicKey == null || !await _verifyKeyIntegrity(keyId, publicKey)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Réinitialise toutes les clés (en cas de corruption)
  Future<void> resetKeys() async {
    try {
      // Supprimer toutes les clés existantes
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyStoragePrefix) || key.startsWith(_keyIntegrityPrefix) || key == _activeKeyIdKey) {
          await _secureStorage.delete(key: key);
        }
      }

      // Réinstaller les clés intégrées
      await _storeEmbeddedKeys();
      await _setDefaultActiveKey();
    } catch (e) {
      // En cas d'erreur, continuer silencieusement
    }
  }

  // Méthodes privées

  /// Stocke les clés publiques intégrées dans le stockage sécurisé
  Future<void> _storeEmbeddedKeys() async {
    for (final entry in _embeddedPublicKeys.entries) {
      final keyId = entry.key;
      final publicKey = entry.value;

      // Stocker la clé
      await _secureStorage.write(key: '$_keyStoragePrefix$keyId', value: publicKey);

      // Stocker le checksum d'intégrité
      final integrity = _calculateKeyIntegrity(publicKey);
      await _secureStorage.write(key: '$_keyIntegrityPrefix$keyId', value: integrity);
    }
  }

  /// Définit la clé par défaut comme active
  Future<void> _setDefaultActiveKey() async {
    final activeKeyId = await getActiveKeyId();
    if (activeKeyId == null) {
      // Prendre la clé la plus récente par défaut
      final availableKeys = await getAvailableKeyIds();
      if (availableKeys.isNotEmpty) {
        availableKeys.sort();
        await setActiveKey(availableKeys.last);
      }
    }
  }

  /// Vérifie l'intégrité d'une clé publique
  Future<bool> _verifyKeyIntegrity(String keyId, String publicKey) async {
    try {
      // Vérifier avec le checksum intégré si disponible
      if (_keyIntegrityHashes.containsKey(keyId)) {
        final expectedHash = _keyIntegrityHashes[keyId]!;
        final actualHash = _calculateKeyIntegrity(publicKey);
        if (expectedHash != actualHash) {
          return false;
        }
      }

      // Vérifier avec le checksum stocké
      final storedIntegrity = await _secureStorage.read(key: '$_keyIntegrityPrefix$keyId');

      if (storedIntegrity != null) {
        final calculatedIntegrity = _calculateKeyIntegrity(publicKey);
        return storedIntegrity == calculatedIntegrity;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calcule le checksum d'intégrité d'une clé publique
  String _calculateKeyIntegrity(String publicKey) {
    final bytes = utf8.encode(publicKey.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
