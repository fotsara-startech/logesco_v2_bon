import '../interfaces/i_license_service.dart';
import '../interfaces/i_device_service.dart';
import '../../models/license_data.dart';
import '../../models/license_key.dart';
import '../../models/license_errors.dart';
import 'crypto_service.dart';
import 'secure_license_storage.dart';
import 'license_management_service.dart';
import 'secure_time_service.dart';

/// Implémentation du service de validation des licences
class LicenseService implements ILicenseService {
  final CryptoService _cryptoService;
  final IDeviceService _deviceService;
  final SecureLicenseStorage _secureStorage;
  final LicenseManagementService _managementService;
  final SecureTimeService _secureTimeService;

  // Cache pour éviter les validations répétées
  LicenseData? _cachedLicense;
  DateTime? _lastValidation;
  static const Duration _validationCacheTimeout = Duration(minutes: 5);

  // Gestion robuste des erreurs
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;
  DateTime? _lastErrorTime;

  LicenseService({
    required CryptoService cryptoService,
    required IDeviceService deviceService,
    SecureLicenseStorage? secureStorage,
    LicenseManagementService? managementService,
    SecureTimeService? secureTimeService,
  })  : _cryptoService = cryptoService,
        _deviceService = deviceService,
        _secureStorage = secureStorage ??
            SecureLicenseStorage(
              cryptoService: cryptoService,
              deviceService: deviceService,
            ),
        _managementService = managementService ??
            LicenseManagementService(
              cryptoService: cryptoService,
              deviceService: deviceService,
              secureStorage: secureStorage ??
                  SecureLicenseStorage(
                    cryptoService: cryptoService,
                    deviceService: deviceService,
                  ),
            ),
        _secureTimeService = secureTimeService ?? SecureTimeService();

  /// Initialise le service de licence
  Future<void> initialize() async {
    await _secureStorage.initialize();
    await _secureTimeService.initialize();
  }

  @override
  Future<LicenseValidationResult> validateLicense(String licenseKey) async {
    return await _executeWithErrorRecovery(() async {
      // 1. Validation du format de la clé
      final keyValidation = LicenseKeyUtils.validateLicenseKey(licenseKey);
      if (!keyValidation.isValid) {
        return LicenseValidationResult.failure(
          LicenseException(
            LicenseError.invalidKey,
            keyValidation.errorMessage ?? 'Format de clé invalide',
          ),
        );
      }

      // 2. Extraction du payload de la clé
      final payload = keyValidation.payload!;

      // Détecter si c'est une clé au format court
      final isShortFormat = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(licenseKey);

      // 3. Validation cryptographique de la signature (seulement pour format long)
      if (!isShortFormat) {
        final signatureValid = await _validateSignature(payload);
        if (!signatureValid) {
          return LicenseValidationResult.failure(
            LicenseException(
              LicenseError.cryptographicFailure,
              'Signature cryptographique invalide',
            ),
          );
        }
      }

      // 4. Vérification de l'empreinte d'appareil
      if (isShortFormat) {
        // Pour format court: vérifier le hash de l'empreinte
        final currentDeviceFingerprint = await _deviceService.generateDeviceFingerprint();
        final deviceValid = LicenseKeyUtils.verifyShortFormatDevice(licenseKey, currentDeviceFingerprint);

        if (!deviceValid) {
          return LicenseValidationResult.failure(
            LicenseException(
              LicenseError.deviceMismatch,
              'Cette licence est liée à un autre appareil',
            ),
          );
        }
      } else {
        // Pour format long: vérification classique
        final deviceValid = await _validateDeviceFingerprint(payload.device);
        if (!deviceValid) {
          return LicenseValidationResult.failure(
            LicenseException(
              LicenseError.deviceMismatch,
              'Cette licence est liée à un autre appareil',
            ),
          );
        }
      }

      // 5. Validation des dates d'expiration
      final expirationValid = await _validateExpiration(payload);
      if (!expirationValid.isValid) {
        return expirationValid;
      }

      // 6. Conversion en LicenseData
      final licenseData = payload.toLicenseData(licenseKey);

      // 7. Validation de l'unicité (vérifier qu'elle n'est pas déjà utilisée)
      final uniquenessValid = await _validateUniqueness(licenseData);
      if (!uniquenessValid) {
        return LicenseValidationResult.failure(
          LicenseException(
            LicenseError.licenseAlreadyUsed,
            'Cette licence est déjà utilisée sur un autre appareil',
          ),
        );
      }

      // 8. Vérifier que la licence n'est pas révoquée
      final isRevoked = await _managementService.isLicenseRevoked(licenseData.licenseKey);
      if (isRevoked) {
        return LicenseValidationResult.failure(
          LicenseException(
            LicenseError.licenseRevoked,
            'Cette licence a été révoquée',
          ),
        );
      }

      // 9. Mise en cache de la licence validée
      _cachedLicense = licenseData;
      _lastValidation = DateTime.now();

      return LicenseValidationResult.success(licenseData);
    }, 'validation de licence');
  }

  @override
  Future<bool> isLicenseValid() async {
    try {
      // Utiliser le cache si disponible et récent
      if (_cachedLicense != null && _lastValidation != null) {
        final cacheAge = DateTime.now().difference(_lastValidation!);
        if (cacheAge < _validationCacheTimeout) {
          return !_cachedLicense!.isExpired;
        }
      }

      // Récupérer la licence stockée
      final storedLicense = await getStoredLicense();
      if (storedLicense == null) {
        return false;
      }

      // Valider la licence complète
      final validation = await validateLicense(storedLicense.licenseKey);
      return validation.isValid;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> storeLicense(LicenseData license) async {
    try {
      // Utiliser le stockage sécurisé avec chiffrement et redondance
      await _secureStorage.storeLicense(license);

      // Mettre à jour le cache
      _cachedLicense = license;
      _lastValidation = DateTime.now();
    } catch (e) {
      throw LicenseException(
        LicenseError.storageError,
        'Erreur lors du stockage de la licence: ${e.toString()}',
      );
    }
  }

  @override
  Future<LicenseData?> getStoredLicense() async {
    try {
      // Utiliser le stockage sécurisé avec vérification d'intégrité
      final license = await _secureStorage.retrieveLicense();

      // Mettre à jour le cache si récupération réussie
      if (license != null) {
        _cachedLicense = license;
      }

      return license;
    } catch (e) {
      if (e is LicenseException) {
        rethrow;
      }
      return null;
    }
  }

  @override
  Future<void> revokeLicense() async {
    try {
      // Récupérer la licence actuelle
      final currentLicense = await getStoredLicense();
      if (currentLicense == null) {
        throw LicenseException(
          LicenseError.storageError,
          'Aucune licence à révoquer',
        );
      }

      // Utiliser le service de gestion pour la révocation
      final revocationResult = await _managementService.revokeLicense(
        currentLicense,
        reason: 'manual_revocation',
        permanent: true,
      );

      if (!revocationResult.success) {
        throw LicenseException(
          LicenseError.storageError,
          revocationResult.errorMessage ?? 'Erreur lors de la révocation',
        );
      }

      // Nettoyer le cache
      _cachedLicense = null;
      _lastValidation = null;
    } catch (e) {
      if (e is LicenseException) {
        rethrow;
      }
      throw LicenseException(
        LicenseError.storageError,
        'Erreur lors de la révocation: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> verifyLicenseIntegrity() async {
    try {
      // Utiliser la vérification d'intégrité du stockage sécurisé
      return await _secureStorage.verifyStorageIntegrity();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<LicenseData?> getLicenseInfo() async {
    try {
      // Utiliser le cache si disponible
      if (_cachedLicense != null) {
        return _cachedLicense;
      }

      // Sinon récupérer depuis le stockage
      return await getStoredLicense();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cleanupCorruptedLicense() async {
    try {
      // Utiliser le nettoyage sécurisé
      await _secureStorage.clearLicenseData();

      // Nettoyer le cache
      _cachedLicense = null;
      _lastValidation = null;
    } catch (e) {
      // En cas d'erreur critique, forcer le nettoyage du cache
      _cachedLicense = null;
      _lastValidation = null;
    }
  }

  // Méthodes privées de validation

  /// Valide la signature cryptographique du payload
  Future<bool> _validateSignature(LicenseKeyPayload payload) async {
    try {
      // Créer les données à signer selon le format spécifié dans la documentation
      // Format: userId-type-issued-expires-device
      final dataToSign = '${payload.userId}-${payload.subscriptionType}-${payload.issued}-${payload.expires}-${payload.device}';

      print('🔐 [LicenseService] Validation de signature');
      print('   Données à signer: $dataToSign');
      print('   Longueur signature: ${payload.signature.length} caractères');

      // MODE DÉVELOPPEMENT : Essayer d'abord la vérification sans clé publique
      // Cela permet de valider les signatures de développement directement
      final devModeValid = await _cryptoService.verifySignatureWithActiveKey(dataToSign, payload.signature);
      if (devModeValid) {
        print('✅ [LicenseService] Signature validée (mode développement)');
        return true;
      }

      // MODE PRODUCTION : Vérifier avec la clé publique
      final publicKey = await _cryptoService.getActivePublicKey();
      if (publicKey == null) {
        print('⚠️  [LicenseService] Aucune clé publique active trouvée');
        print('   Tentative de vérification en mode développement pur...');

        // Dernier recours : vérification directe en mode développement
        return _cryptoService.verifySignature(dataToSign, payload.signature, '');
      }

      print('🔑 [LicenseService] Utilisation de la clé publique active');
      final isValid = _cryptoService.verifySignature(dataToSign, payload.signature, publicKey);

      if (isValid) {
        print('✅ [LicenseService] Signature validée (mode production)');
      } else {
        print('❌ [LicenseService] Signature invalide');
      }

      return isValid;
    } catch (e) {
      print('❌ [LicenseService] Erreur validation signature: $e');
      return false;
    }
  }

  /// Valide l'empreinte d'appareil
  Future<bool> _validateDeviceFingerprint(String expectedFingerprint) async {
    try {
      return await _deviceService.verifyDeviceFingerprint(expectedFingerprint);
    } catch (e) {
      return false;
    }
  }

  /// Valide les dates d'expiration avec temps sécurisé
  Future<LicenseValidationResult> _validateExpiration(LicenseKeyPayload payload) async {
    try {
      // Obtenir l'heure sécurisée
      final timeResult = await _secureTimeService.getSecureTime(
        throwOnManipulation: true,
      );

      final secureTime = timeResult.trustedTime;
      final expirationDate = DateTime.parse(payload.expires);

      print('🕐 [LicenseService] Validation expiration:');
      print('   Heure sécurisée: $secureTime');
      print('   Date expiration: $expirationDate');
      print('   NTP disponible: ${timeResult.ntpAvailable}');
      print('   Heure système fiable: ${timeResult.isSystemTimeReliable}');

      if (timeResult.hasWarnings) {
        print('   ⚠️  Avertissements:');
        for (final warning in timeResult.warnings) {
          print('      - $warning');
        }
      }

      if (secureTime.isAfter(expirationDate)) {
        // Vérifier si on est dans la période de grâce
        final gracePeriodEnd = expirationDate.add(const Duration(days: 3));
        if (secureTime.isBefore(gracePeriodEnd)) {
          final warnings = ['Licence expirée mais dans la période de grâce'];
          if (timeResult.hasWarnings) {
            warnings.addAll(timeResult.warnings);
          }

          return LicenseValidationResult.success(
            payload.toLicenseData(''),
            warnings,
          );
        } else {
          return LicenseValidationResult.failure(
            LicenseException(
              LicenseError.expiredLicense,
              'Licence expirée le ${expirationDate.toLocal()}',
            ),
          );
        }
      }

      // Licence valide
      final warnings = <String>[];
      if (timeResult.hasWarnings) {
        warnings.addAll(timeResult.warnings);
      }

      return LicenseValidationResult.success(
        payload.toLicenseData(''),
        warnings,
      );
    } on TimeValidationException catch (e) {
      print('❌ [LicenseService] Erreur validation temps: $e');
      return LicenseValidationResult.failure(
        LicenseException(
          LicenseError.expiredLicense,
          e.message,
        ),
      );
    } catch (e) {
      print('❌ [LicenseService] Erreur validation expiration: $e');
      return LicenseValidationResult.failure(
        LicenseException(
          LicenseError.invalidKey,
          'Erreur lors de la validation de la date d\'expiration',
        ),
      );
    }
  }

  /// Valide l'unicité de la licence
  Future<bool> _validateUniqueness(LicenseData license) async {
    try {
      // Utiliser le service de gestion pour valider l'unicité
      return await _managementService.validateLicenseUniqueness(
        license.licenseKey,
        license.deviceFingerprint,
      );
    } catch (e) {
      return false;
    }
  }

  // Méthodes utilitaires et d'audit

  /// Récupère les métadonnées de licence pour audit
  Future<Map<String, dynamic>?> getLicenseMetadata() async {
    try {
      return await _secureStorage.getLicenseMetadata();
    } catch (e) {
      return null;
    }
  }

  /// Récupère les logs d'accès pour audit
  Future<List<Map<String, dynamic>>> getAccessLogs() async {
    try {
      return await _secureStorage.getAccessLogs();
    } catch (e) {
      return [];
    }
  }

  /// Transfère une licence vers un nouvel appareil
  Future<TransferResult> transferLicense({
    String? transferReason,
    bool validateCurrentDevice = true,
  }) async {
    try {
      final currentLicense = await getStoredLicense();
      if (currentLicense == null) {
        return TransferResult.failure('Aucune licence à transférer');
      }

      return await _managementService.transferLicense(
        currentLicense,
        transferReason: transferReason,
        validateCurrentDevice: validateCurrentDevice,
      );
    } catch (e) {
      return TransferResult.failure('Erreur lors du transfert: ${e.toString()}');
    }
  }

  /// Vérifie si une licence est révoquée
  Future<bool> isLicenseRevoked(String licenseKey) async {
    try {
      return await _managementService.isLicenseRevoked(licenseKey);
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'historique des révocations
  Future<List<Map<String, dynamic>>> getRevocationHistory() async {
    try {
      return await _managementService.getRevocationHistory();
    } catch (e) {
      return [];
    }
  }

  /// Récupère l'historique des transferts
  Future<List<Map<String, dynamic>>> getTransferHistory() async {
    try {
      return await _managementService.getTransferHistory();
    } catch (e) {
      return [];
    }
  }

  /// Nettoie les données de révocation expirées
  Future<void> cleanupExpiredRevocations() async {
    try {
      await _managementService.cleanupExpiredRevocations();
    } catch (e) {
      // Ignorer les erreurs de nettoyage
    }
  }

  // Méthodes de gestion robuste des erreurs

  /// Exécute une opération avec récupération automatique en cas d'erreur
  Future<T> _executeWithErrorRecovery<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    try {
      final result = await operation();

      // Réinitialiser le compteur d'erreurs en cas de succès
      _consecutiveErrors = 0;
      _lastErrorTime = null;

      return result;
    } catch (e) {
      _consecutiveErrors++;
      _lastErrorTime = DateTime.now();

      print('❌ [LicenseService] Erreur $operationName (tentative $_consecutiveErrors): $e');

      // Si on a atteint le maximum d'erreurs consécutives, ne pas réessayer
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        print('🚫 [LicenseService] Nombre maximum d\'erreurs atteint pour $operationName');

        // Créer une réponse d'erreur appropriée selon le type de retour
        if (T == LicenseValidationResult) {
          return LicenseValidationResult.failure(
            LicenseException(
              LicenseError.cryptographicFailure,
              'Erreur système répétée: $operationName',
            ),
          ) as T;
        }

        rethrow;
      }

      // Tentative de récupération automatique
      try {
        print('🔄 [LicenseService] Tentative de récupération pour $operationName...');

        // Attendre un délai progressif avant de réessayer
        final delay = Duration(milliseconds: 500 * _consecutiveErrors);
        await Future.delayed(delay);

        // Nettoyer le cache en cas d'erreur
        _cachedLicense = null;
        _lastValidation = null;

        // Réessayer l'opération
        final result = await operation();

        // Succès de la récupération
        _consecutiveErrors = 0;
        _lastErrorTime = null;
        print('✅ [LicenseService] Récupération réussie pour $operationName');

        return result;
      } catch (recoveryError) {
        print('❌ [LicenseService] Échec de récupération pour $operationName: $recoveryError');

        // Si c'est une LicenseValidationResult, retourner un échec
        if (T == LicenseValidationResult) {
          return LicenseValidationResult.failure(
            LicenseException(
              LicenseError.cryptographicFailure,
              'Erreur système: $operationName - $recoveryError',
            ),
          ) as T;
        }

        rethrow;
      }
    }
  }

  /// Réinitialise les compteurs d'erreur
  void resetErrorCounters() {
    _consecutiveErrors = 0;
    _lastErrorTime = null;
  }

  /// Obtient les statistiques d'erreur
  Map<String, dynamic> getErrorStats() {
    return {
      'consecutiveErrors': _consecutiveErrors,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'isInErrorState': _consecutiveErrors >= _maxConsecutiveErrors,
    };
  }
}
