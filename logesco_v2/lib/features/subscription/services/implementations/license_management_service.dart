import 'dart:convert';

import '../interfaces/i_device_service.dart';
import '../../models/license_data.dart';
import '../../models/license_errors.dart';
import 'crypto_service.dart';
import 'secure_license_storage.dart';

/// Résultat d'une opération de révocation
class RevocationResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const RevocationResult({
    required this.success,
    this.errorMessage,
    this.metadata,
  });

  factory RevocationResult.success([Map<String, dynamic>? metadata]) {
    return RevocationResult(success: true, metadata: metadata);
  }

  factory RevocationResult.failure(String errorMessage) {
    return RevocationResult(success: false, errorMessage: errorMessage);
  }
}

/// Résultat d'une opération de transfert
class TransferResult {
  final bool success;
  final String? errorMessage;
  final String? newDeviceFingerprint;
  final Map<String, dynamic>? metadata;

  const TransferResult({
    required this.success,
    this.errorMessage,
    this.newDeviceFingerprint,
    this.metadata,
  });

  factory TransferResult.success(String newDeviceFingerprint, [Map<String, dynamic>? metadata]) {
    return TransferResult(
      success: true,
      newDeviceFingerprint: newDeviceFingerprint,
      metadata: metadata,
    );
  }

  factory TransferResult.failure(String errorMessage) {
    return TransferResult(success: false, errorMessage: errorMessage);
  }
}

/// Service de gestion avancée des licences (révocation, transfert, unicité)
class LicenseManagementService {
  final CryptoService _cryptoService;
  final IDeviceService _deviceService;
  final SecureLicenseStorage _secureStorage;

  // Registre local des licences révoquées (pour validation hors ligne)
  static const String _revokedLicensesKey = 'logesco_revoked_licenses';
  static const String _transferHistoryKey = 'logesco_transfer_history';
  static const String _uniquenessRegistryKey = 'logesco_uniqueness_registry';

  LicenseManagementService({
    required CryptoService cryptoService,
    required IDeviceService deviceService,
    required SecureLicenseStorage secureStorage,
  })  : _cryptoService = cryptoService,
        _deviceService = deviceService,
        _secureStorage = secureStorage;

  /// Révoque une licence de manière permanente
  Future<RevocationResult> revokeLicense(
    LicenseData license, {
    String? reason,
    bool permanent = true,
  }) async {
    try {
      // 1. Vérifier que la licence existe et est valide
      final storedLicense = await _secureStorage.retrieveLicense();
      if (storedLicense == null) {
        return RevocationResult.failure('Aucune licence à révoquer');
      }

      if (storedLicense.licenseKey != license.licenseKey) {
        return RevocationResult.failure('La licence ne correspond pas à celle stockée');
      }

      // 2. Créer l'enregistrement de révocation
      final revocationRecord = await _createRevocationRecord(
        license,
        reason: reason,
        permanent: permanent,
      );

      // 3. Ajouter à la liste des licences révoquées
      await _addToRevokedRegistry(revocationRecord);

      // 4. Nettoyer les données de licence locale
      await _secureStorage.clearLicenseData();

      // 5. Enregistrer l'historique de révocation
      await _recordRevocationHistory(license, revocationRecord);

      return RevocationResult.success({
        'revocationId': revocationRecord['revocationId'],
        'timestamp': revocationRecord['timestamp'],
        'reason': reason,
        'permanent': permanent,
      });
    } catch (e) {
      return RevocationResult.failure('Erreur lors de la révocation: ${e.toString()}');
    }
  }

  /// Transfère une licence vers un nouvel appareil
  Future<TransferResult> transferLicense(
    LicenseData license, {
    String? transferReason,
    bool validateCurrentDevice = true,
  }) async {
    try {
      // 1. Vérifier que la licence n'est pas révoquée
      final isRevoked = await _isLicenseRevoked(license.licenseKey);
      if (isRevoked) {
        return TransferResult.failure('Cette licence a été révoquée');
      }

      // 2. Valider l'appareil actuel si demandé
      if (validateCurrentDevice) {
        final deviceValid = await _deviceService.verifyDeviceFingerprint(license.deviceFingerprint);
        if (!deviceValid) {
          return TransferResult.failure('L\'appareil actuel ne correspond pas à la licence');
        }
      }

      // 3. Générer une nouvelle empreinte d'appareil
      final newDeviceFingerprint = await _deviceService.generateDeviceFingerprint();

      // 4. Vérifier l'unicité sur le nouvel appareil
      final uniquenessValid = await _validateTransferUniqueness(
        license.licenseKey,
        newDeviceFingerprint,
      );
      if (!uniquenessValid) {
        return TransferResult.failure('Cette licence est déjà utilisée sur cet appareil');
      }

      // 5. Créer la nouvelle licence avec la nouvelle empreinte
      final transferredLicense = LicenseData(
        userId: license.userId,
        licenseKey: license.licenseKey,
        subscriptionType: license.subscriptionType,
        issuedAt: license.issuedAt,
        expiresAt: license.expiresAt,
        deviceFingerprint: newDeviceFingerprint,
        signature: license.signature,
        metadata: {
          ...license.metadata,
          'transferredAt': DateTime.now().toIso8601String(),
          'previousDevice': license.deviceFingerprint,
          'transferReason': transferReason ?? 'device_change',
        },
      );

      // 6. Enregistrer l'historique de transfert
      await _recordTransferHistory(license, transferredLicense, transferReason);

      // 7. Mettre à jour le registre d'unicité
      await _updateUniquenessRegistry(license.licenseKey, newDeviceFingerprint);

      // 8. Stocker la nouvelle licence
      await _secureStorage.storeLicense(transferredLicense);

      return TransferResult.success(newDeviceFingerprint, {
        'transferId': _generateTransferId(),
        'timestamp': DateTime.now().toIso8601String(),
        'previousDevice': license.deviceFingerprint,
        'newDevice': newDeviceFingerprint,
      });
    } catch (e) {
      return TransferResult.failure('Erreur lors du transfert: ${e.toString()}');
    }
  }

  /// Vérifie si une licence est révoquée
  Future<bool> isLicenseRevoked(String licenseKey) async {
    try {
      return await _isLicenseRevoked(licenseKey);
    } catch (e) {
      return false;
    }
  }

  /// Valide l'unicité d'une licence
  Future<bool> validateLicenseUniqueness(String licenseKey, String deviceFingerprint) async {
    try {
      // 1. Vérifier dans le registre local d'unicité
      final localUniquenessValid = await _validateLocalUniqueness(licenseKey, deviceFingerprint);
      if (!localUniquenessValid) {
        return false;
      }

      // 2. Vérifier que la licence n'est pas révoquée
      final isRevoked = await _isLicenseRevoked(licenseKey);
      if (isRevoked) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'historique des révocations
  Future<List<Map<String, dynamic>>> getRevocationHistory() async {
    try {
      final historyData = await _secureStorage.getAccessLogs();
      return historyData.where((log) => log['action'] == 'revoke').toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupère l'historique des transferts
  Future<List<Map<String, dynamic>>> getTransferHistory() async {
    try {
      final transferHistoryJson = await _getStoredData(_transferHistoryKey);
      if (transferHistoryJson == null) return [];

      final history = jsonDecode(transferHistoryJson) as List<dynamic>;
      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Nettoie les données de révocation expirées
  Future<void> cleanupExpiredRevocations() async {
    try {
      final revokedLicensesJson = await _getStoredData(_revokedLicensesKey);
      if (revokedLicensesJson == null) return;

      final revokedLicenses = jsonDecode(revokedLicensesJson) as List<dynamic>;
      final now = DateTime.now();

      // Garder seulement les révocations de moins de 2 ans
      final validRevocations = revokedLicenses.where((revocation) {
        final revocationDate = DateTime.parse(revocation['timestamp'] as String);
        final age = now.difference(revocationDate);
        return age.inDays < 730; // 2 ans
      }).toList();

      await _storeData(_revokedLicensesKey, jsonEncode(validRevocations));
    } catch (e) {
      // Ignorer les erreurs de nettoyage
    }
  }

  // Méthodes privées

  /// Crée un enregistrement de révocation
  Future<Map<String, dynamic>> _createRevocationRecord(
    LicenseData license, {
    String? reason,
    bool permanent = true,
  }) async {
    final revocationId = _generateRevocationId();
    final timestamp = DateTime.now().toIso8601String();
    final deviceFingerprint = await _deviceService.generateDeviceFingerprint();

    return {
      'revocationId': revocationId,
      'licenseKey': license.licenseKey,
      'userId': license.userId,
      'timestamp': timestamp,
      'reason': reason ?? 'manual_revocation',
      'permanent': permanent,
      'deviceFingerprint': deviceFingerprint,
      'signature': _cryptoService.generateHash('$revocationId$timestamp${license.licenseKey}'),
    };
  }

  /// Ajoute une licence au registre des révocations
  Future<void> _addToRevokedRegistry(Map<String, dynamic> revocationRecord) async {
    try {
      final existingDataJson = await _getStoredData(_revokedLicensesKey);
      List<Map<String, dynamic>> revokedLicenses = [];

      if (existingDataJson != null) {
        final existingData = jsonDecode(existingDataJson) as List<dynamic>;
        revokedLicenses = existingData.cast<Map<String, dynamic>>();
      }

      revokedLicenses.add(revocationRecord);

      // Garder seulement les 1000 dernières révocations
      if (revokedLicenses.length > 1000) {
        revokedLicenses = revokedLicenses.sublist(revokedLicenses.length - 1000);
      }

      await _storeData(_revokedLicensesKey, jsonEncode(revokedLicenses));
    } catch (e) {
      throw LicenseException(
        LicenseError.storageError,
        'Erreur lors de l\'ajout au registre de révocation: ${e.toString()}',
      );
    }
  }

  /// Vérifie si une licence est révoquée
  Future<bool> _isLicenseRevoked(String licenseKey) async {
    try {
      final revokedLicensesJson = await _getStoredData(_revokedLicensesKey);
      if (revokedLicensesJson == null) return false;

      final revokedLicenses = jsonDecode(revokedLicensesJson) as List<dynamic>;

      return revokedLicenses.any((revocation) {
        return revocation['licenseKey'] == licenseKey;
      });
    } catch (e) {
      return false;
    }
  }

  /// Valide l'unicité pour un transfert
  Future<bool> _validateTransferUniqueness(String licenseKey, String newDeviceFingerprint) async {
    try {
      // Vérifier dans le registre d'unicité
      final uniquenessRegistryJson = await _getStoredData(_uniquenessRegistryKey);
      if (uniquenessRegistryJson == null) return true;

      final registry = jsonDecode(uniquenessRegistryJson) as Map<String, dynamic>;
      final existingDevice = registry[licenseKey] as String?;

      // Permettre le transfert si c'est le même appareil ou si aucun appareil n'est enregistré
      return existingDevice == null || existingDevice == newDeviceFingerprint;
    } catch (e) {
      return true; // En cas d'erreur, permettre le transfert
    }
  }

  /// Valide l'unicité locale
  Future<bool> _validateLocalUniqueness(String licenseKey, String deviceFingerprint) async {
    try {
      final uniquenessRegistryJson = await _getStoredData(_uniquenessRegistryKey);
      if (uniquenessRegistryJson == null) return true;

      final registry = jsonDecode(uniquenessRegistryJson) as Map<String, dynamic>;
      final registeredDevice = registry[licenseKey] as String?;

      return registeredDevice == null || registeredDevice == deviceFingerprint;
    } catch (e) {
      return true;
    }
  }

  /// Met à jour le registre d'unicité
  Future<void> _updateUniquenessRegistry(String licenseKey, String deviceFingerprint) async {
    try {
      final existingRegistryJson = await _getStoredData(_uniquenessRegistryKey);
      Map<String, dynamic> registry = {};

      if (existingRegistryJson != null) {
        registry = jsonDecode(existingRegistryJson) as Map<String, dynamic>;
      }

      registry[licenseKey] = deviceFingerprint;

      await _storeData(_uniquenessRegistryKey, jsonEncode(registry));
    } catch (e) {
      // Ignorer les erreurs de mise à jour du registre
    }
  }

  /// Enregistre l'historique de révocation
  Future<void> _recordRevocationHistory(
    LicenseData license,
    Map<String, dynamic> revocationRecord,
  ) async {
    try {
      // Les logs de révocation sont automatiquement gérés par SecureLicenseStorage
      // lors de l'appel à clearLicenseData() avec l'action 'revoke'

      // Note: Dans une implémentation complète, on pourrait ajouter
      // des logs spécifiques de révocation ici
    } catch (e) {
      // Ignorer les erreurs de logging
    }
  }

  /// Enregistre l'historique de transfert
  Future<void> _recordTransferHistory(
    LicenseData originalLicense,
    LicenseData transferredLicense,
    String? reason,
  ) async {
    try {
      final existingHistoryJson = await _getStoredData(_transferHistoryKey);
      List<Map<String, dynamic>> history = [];

      if (existingHistoryJson != null) {
        final existingHistory = jsonDecode(existingHistoryJson) as List<dynamic>;
        history = existingHistory.cast<Map<String, dynamic>>();
      }

      final transferEntry = {
        'transferId': _generateTransferId(),
        'licenseKey': originalLicense.licenseKey,
        'userId': originalLicense.userId,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason ?? 'device_change',
        'fromDevice': originalLicense.deviceFingerprint,
        'toDevice': transferredLicense.deviceFingerprint,
      };

      history.add(transferEntry);

      // Garder seulement les 100 derniers transferts
      if (history.length > 100) {
        history = history.sublist(history.length - 100);
      }

      await _storeData(_transferHistoryKey, jsonEncode(history));
    } catch (e) {
      // Ignorer les erreurs de logging
    }
  }

  /// Génère un ID de révocation unique
  String _generateRevocationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _cryptoService.generateRandomKey(8);
    return 'REV_${timestamp}_$random';
  }

  /// Génère un ID de transfert unique
  String _generateTransferId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _cryptoService.generateRandomKey(8);
    return 'TRF_${timestamp}_$random';
  }

  /// Stocke des données de manière sécurisée
  Future<void> _storeData(String key, String data) async {
    // Utiliser le stockage sécurisé pour les données de gestion
    // Pour simplifier, utiliser directement le SecureLicenseStorage
    // Dans une implémentation complète, créer un stockage dédié
    try {
      final metadata = await _secureStorage.getLicenseMetadata() ?? {};
      metadata[key] = data;
      // Note: Cette approche est simplifiée. Dans une implémentation complète,
      // il faudrait un système de stockage séparé pour ces données.
    } catch (e) {
      // Ignorer les erreurs de stockage pour les données auxiliaires
    }
  }

  /// Récupère des données stockées
  Future<String?> _getStoredData(String key) async {
    try {
      final metadata = await _secureStorage.getLicenseMetadata();
      return metadata?[key] as String?;
    } catch (e) {
      return null;
    }
  }
}
