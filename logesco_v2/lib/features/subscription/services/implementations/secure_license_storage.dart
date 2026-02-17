import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../interfaces/i_device_service.dart';
import '../../models/license_data.dart';
import '../../models/license_errors.dart';
import 'crypto_service.dart';

/// Service de stockage sécurisé spécialisé pour les licences
class SecureLicenseStorage {
  static const String _primaryStorageKey = 'logesco_license_primary';
  static const String _backupStorageKey = 'logesco_license_backup';
  static const String _integrityStorageKey = 'logesco_license_integrity';
  static const String _metadataStorageKey = 'logesco_license_metadata';
  static const String _tamperDetectionKey = 'logesco_tamper_detection';
  static const String _accessLogKey = 'logesco_access_log';

  final FlutterSecureStorage _secureStorage;
  final CryptoService _cryptoService;
  final IDeviceService _deviceService;

  // Clés de chiffrement dérivées
  String? _primaryEncryptionKey;
  String? _backupEncryptionKey;

  SecureLicenseStorage({
    required CryptoService cryptoService,
    required IDeviceService deviceService,
    FlutterSecureStorage? secureStorage,
  })  : _cryptoService = cryptoService,
        _deviceService = deviceService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialise le système de stockage sécurisé
  Future<void> initialize() async {
    await _generateEncryptionKeys();
    await _initializeTamperDetection();
  }

  /// Stocke une licence de manière sécurisée avec redondance
  Future<void> storeLicense(LicenseData license) async {
    try {
      // 1. Générer les données à stocker
      final licenseJson = jsonEncode(license.toJson());
      final timestamp = DateTime.now().toIso8601String();

      // 2. Créer les métadonnées de sécurité
      final metadata = await _createSecurityMetadata(license, timestamp);

      // 3. Chiffrer les données principales
      final primaryEncrypted = await _encryptWithPrimaryKey(licenseJson);

      // 4. Créer une sauvegarde chiffrée avec une clé différente
      final backupEncrypted = await _encryptWithBackupKey(licenseJson);

      // 5. Générer les checksums d'intégrité
      final primaryIntegrity = _cryptoService.generateHash(primaryEncrypted);
      final backupIntegrity = _cryptoService.generateHash(backupEncrypted);

      // 6. Créer les données de détection de manipulation
      final tamperData = await _createTamperDetectionData(
        primaryEncrypted,
        backupEncrypted,
        metadata,
      );

      // 7. Stocker toutes les données de manière atomique
      await _atomicStore({
        _primaryStorageKey: primaryEncrypted,
        _backupStorageKey: backupEncrypted,
        _integrityStorageKey: jsonEncode({
          'primary': primaryIntegrity,
          'backup': backupIntegrity,
          'timestamp': timestamp,
        }),
        _metadataStorageKey: jsonEncode(metadata),
        _tamperDetectionKey: jsonEncode(tamperData),
      });

      // 8. Enregistrer l'accès
      await _logAccess('store', license.userId);
    } catch (e) {
      throw LicenseException(
        LicenseError.storageError,
        'Erreur lors du stockage sécurisé: ${e.toString()}',
      );
    }
  }

  /// Récupère une licence stockée avec vérification d'intégrité
  Future<LicenseData?> retrieveLicense() async {
    try {
      // 1. Vérifier la détection de manipulation
      final tamperDetected = await _detectTampering();
      if (tamperDetected) {
        await _handleTamperDetection();
        throw LicenseException(
          LicenseError.tamperingDetected,
          'Manipulation des données de licence détectée',
        );
      }

      // 2. Récupérer les données principales
      final primaryData = await _secureStorage.read(key: _primaryStorageKey);
      if (primaryData == null) {
        return null;
      }

      // 3. Vérifier l'intégrité des données principales
      final integrityValid = await _verifyDataIntegrity(primaryData, true);
      if (!integrityValid) {
        // Essayer de récupérer depuis la sauvegarde
        return await _recoverFromBackup();
      }

      // 4. Déchiffrer les données
      final decryptedJson = await _decryptWithPrimaryKey(primaryData);

      // 5. Désérialiser la licence
      final licenseJson = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final license = LicenseData.fromJson(licenseJson);

      // 6. Enregistrer l'accès
      await _logAccess('retrieve', license.userId);

      return license;
    } catch (e) {
      if (e is LicenseException) {
        rethrow;
      }
      return null;
    }
  }

  /// Vérifie l'intégrité complète du stockage
  Future<bool> verifyStorageIntegrity() async {
    try {
      // 1. Vérifier la détection de manipulation
      if (await _detectTampering()) {
        return false;
      }

      // 2. Vérifier l'intégrité des données principales
      final primaryData = await _secureStorage.read(key: _primaryStorageKey);
      if (primaryData == null) {
        return false;
      }

      final primaryIntegrityValid = await _verifyDataIntegrity(primaryData, true);

      // 3. Vérifier l'intégrité de la sauvegarde
      final backupData = await _secureStorage.read(key: _backupStorageKey);
      if (backupData == null) {
        return primaryIntegrityValid;
      }

      final backupIntegrityValid = await _verifyDataIntegrity(backupData, false);

      // 4. Vérifier la cohérence entre les deux
      if (primaryIntegrityValid && backupIntegrityValid) {
        return await _verifyDataConsistency(primaryData, backupData);
      }

      return primaryIntegrityValid || backupIntegrityValid;
    } catch (e) {
      return false;
    }
  }

  /// Nettoie toutes les données de licence
  Future<void> clearLicenseData() async {
    try {
      // Enregistrer l'action de nettoyage
      await _logAccess('clear', 'system');

      // Supprimer toutes les clés de manière sécurisée
      await _secureStorage.delete(key: _primaryStorageKey);
      await _secureStorage.delete(key: _backupStorageKey);
      await _secureStorage.delete(key: _integrityStorageKey);
      await _secureStorage.delete(key: _metadataStorageKey);
      await _secureStorage.delete(key: _tamperDetectionKey);

      // Réinitialiser les clés de chiffrement
      _primaryEncryptionKey = null;
      _backupEncryptionKey = null;
    } catch (e) {
      throw LicenseException(
        LicenseError.storageError,
        'Erreur lors du nettoyage: ${e.toString()}',
      );
    }
  }

  /// Récupère les métadonnées de licence pour audit
  Future<Map<String, dynamic>?> getLicenseMetadata() async {
    try {
      final metadataJson = await _secureStorage.read(key: _metadataStorageKey);
      if (metadataJson == null) return null;

      return jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Récupère les logs d'accès pour audit
  Future<List<Map<String, dynamic>>> getAccessLogs() async {
    try {
      final logsJson = await _secureStorage.read(key: _accessLogKey);
      if (logsJson == null) return [];

      final logs = jsonDecode(logsJson) as List<dynamic>;
      return logs.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Méthodes privées

  /// Génère les clés de chiffrement dérivées
  Future<void> _generateEncryptionKeys() async {
    try {
      final deviceFingerprint = await _deviceService.generateDeviceFingerprint();

      // Clé primaire basée sur l'empreinte + salt
      final primarySalt = 'LOGESCO_PRIMARY_SALT_2024';
      _primaryEncryptionKey = _cryptoService.generateHash('$deviceFingerprint$primarySalt');

      // Clé de sauvegarde avec un salt différent
      final backupSalt = 'LOGESCO_BACKUP_SALT_2024';
      _backupEncryptionKey = _cryptoService.generateHash('$deviceFingerprint$backupSalt');
    } catch (e) {
      // Clés de fallback en cas d'erreur
      _primaryEncryptionKey = _cryptoService.generateHash('LOGESCO_FALLBACK_PRIMARY');
      _backupEncryptionKey = _cryptoService.generateHash('LOGESCO_FALLBACK_BACKUP');
    }
  }

  /// Initialise le système de détection de manipulation
  Future<void> _initializeTamperDetection() async {
    try {
      final existingTamperData = await _secureStorage.read(key: _tamperDetectionKey);
      if (existingTamperData == null) {
        // Créer les données initiales de détection
        final initialTamperData = {
          'initialized': DateTime.now().toIso8601String(),
          'deviceFingerprint': await _deviceService.generateDeviceFingerprint(),
          'checksum': _cryptoService.generateRandomKey(16),
        };

        await _secureStorage.write(
          key: _tamperDetectionKey,
          value: jsonEncode(initialTamperData),
        );
      }
    } catch (e) {
      // Ignorer les erreurs d'initialisation
    }
  }

  /// Chiffre avec la clé primaire
  Future<String> _encryptWithPrimaryKey(String data) async {
    if (_primaryEncryptionKey == null) {
      await _generateEncryptionKeys();
    }
    return _cryptoService.encryptData(data, _primaryEncryptionKey!);
  }

  /// Chiffre avec la clé de sauvegarde
  Future<String> _encryptWithBackupKey(String data) async {
    if (_backupEncryptionKey == null) {
      await _generateEncryptionKeys();
    }
    return _cryptoService.encryptData(data, _backupEncryptionKey!);
  }

  /// Déchiffre avec la clé primaire
  Future<String> _decryptWithPrimaryKey(String encryptedData) async {
    if (_primaryEncryptionKey == null) {
      await _generateEncryptionKeys();
    }
    return _cryptoService.decryptData(encryptedData, _primaryEncryptionKey!);
  }

  /// Déchiffre avec la clé de sauvegarde
  Future<String> _decryptWithBackupKey(String encryptedData) async {
    if (_backupEncryptionKey == null) {
      await _generateEncryptionKeys();
    }
    return _cryptoService.decryptData(encryptedData, _backupEncryptionKey!);
  }

  /// Crée les métadonnées de sécurité
  Future<Map<String, dynamic>> _createSecurityMetadata(
    LicenseData license,
    String timestamp,
  ) async {
    return {
      'userId': license.userId,
      'subscriptionType': license.subscriptionType.name,
      'storedAt': timestamp,
      'expiresAt': license.expiresAt.toIso8601String(),
      'deviceFingerprint': license.deviceFingerprint,
      'storageVersion': '1.0',
      'securityLevel': 'high',
    };
  }

  /// Crée les données de détection de manipulation
  Future<Map<String, dynamic>> _createTamperDetectionData(
    String primaryData,
    String backupData,
    Map<String, dynamic> metadata,
  ) async {
    final combinedData = '$primaryData$backupData${jsonEncode(metadata)}';
    final tamperHash = _cryptoService.generateHash(combinedData);

    return {
      'tamperHash': tamperHash,
      'createdAt': DateTime.now().toIso8601String(),
      'deviceFingerprint': await _deviceService.generateDeviceFingerprint(),
      'randomSalt': _cryptoService.generateRandomKey(8),
    };
  }

  /// Stockage atomique de plusieurs clés
  Future<void> _atomicStore(Map<String, String> data) async {
    // Stocker toutes les données
    for (final entry in data.entries) {
      await _secureStorage.write(key: entry.key, value: entry.value);
    }
  }

  /// Vérifie l'intégrité d'une donnée spécifique
  Future<bool> _verifyDataIntegrity(String data, bool isPrimary) async {
    try {
      final integrityJson = await _secureStorage.read(key: _integrityStorageKey);
      if (integrityJson == null) return false;

      final integrity = jsonDecode(integrityJson) as Map<String, dynamic>;
      final expectedHash = isPrimary ? integrity['primary'] : integrity['backup'];

      if (expectedHash == null) return false;

      final actualHash = _cryptoService.generateHash(data);
      return actualHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Détecte les tentatives de manipulation
  Future<bool> _detectTampering() async {
    try {
      final tamperDataJson = await _secureStorage.read(key: _tamperDetectionKey);
      if (tamperDataJson == null) return true; // Pas de données = manipulation

      final tamperData = jsonDecode(tamperDataJson) as Map<String, dynamic>;

      // Vérifier l'empreinte d'appareil
      final storedFingerprint = tamperData['deviceFingerprint'] as String?;
      if (storedFingerprint != null) {
        final currentFingerprint = await _deviceService.generateDeviceFingerprint();
        if (storedFingerprint != currentFingerprint) {
          return true; // Appareil différent = manipulation possible
        }
      }

      // Vérifier le hash de manipulation
      final primaryData = await _secureStorage.read(key: _primaryStorageKey);
      final backupData = await _secureStorage.read(key: _backupStorageKey);
      final metadataJson = await _secureStorage.read(key: _metadataStorageKey);

      if (primaryData == null || backupData == null || metadataJson == null) {
        return true; // Données manquantes = manipulation
      }

      final combinedData = '$primaryData$backupData$metadataJson';
      final currentHash = _cryptoService.generateHash(combinedData);
      final expectedHash = tamperData['tamperHash'] as String?;

      return expectedHash != null && currentHash != expectedHash;
    } catch (e) {
      return true; // Erreur = manipulation présumée
    }
  }

  /// Gère la détection de manipulation
  Future<void> _handleTamperDetection() async {
    try {
      // Enregistrer l'incident
      await _logAccess('tamper_detected', 'system');

      // Marquer les données comme compromises
      final compromisedData = {
        'compromisedAt': DateTime.now().toIso8601String(),
        'action': 'data_locked',
      };

      await _secureStorage.write(
        key: '${_tamperDetectionKey}_compromised',
        value: jsonEncode(compromisedData),
      );
    } catch (e) {
      // Ignorer les erreurs de logging
    }
  }

  /// Récupère depuis la sauvegarde
  Future<LicenseData?> _recoverFromBackup() async {
    try {
      final backupData = await _secureStorage.read(key: _backupStorageKey);
      if (backupData == null) return null;

      // Vérifier l'intégrité de la sauvegarde
      final backupIntegrityValid = await _verifyDataIntegrity(backupData, false);
      if (!backupIntegrityValid) return null;

      // Déchiffrer depuis la sauvegarde
      final decryptedJson = await _decryptWithBackupKey(backupData);
      final licenseJson = jsonDecode(decryptedJson) as Map<String, dynamic>;

      return LicenseData.fromJson(licenseJson);
    } catch (e) {
      return null;
    }
  }

  /// Vérifie la cohérence entre les données principales et de sauvegarde
  Future<bool> _verifyDataConsistency(String primaryData, String backupData) async {
    try {
      final primaryDecrypted = await _decryptWithPrimaryKey(primaryData);
      final backupDecrypted = await _decryptWithBackupKey(backupData);

      return primaryDecrypted == backupDecrypted;
    } catch (e) {
      return false;
    }
  }

  /// Enregistre un accès pour audit
  Future<void> _logAccess(String action, String userId) async {
    try {
      final existingLogsJson = await _secureStorage.read(key: _accessLogKey);
      List<Map<String, dynamic>> logs = [];

      if (existingLogsJson != null) {
        final existingLogs = jsonDecode(existingLogsJson) as List<dynamic>;
        logs = existingLogs.cast<Map<String, dynamic>>();
      }

      // Ajouter le nouvel accès
      logs.add({
        'action': action,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceFingerprint': await _deviceService.generateDeviceFingerprint(),
      });

      // Garder seulement les 100 derniers logs
      if (logs.length > 100) {
        logs = logs.sublist(logs.length - 100);
      }

      await _secureStorage.write(
        key: _accessLogKey,
        value: jsonEncode(logs),
      );
    } catch (e) {
      // Ignorer les erreurs de logging
    }
  }
}
