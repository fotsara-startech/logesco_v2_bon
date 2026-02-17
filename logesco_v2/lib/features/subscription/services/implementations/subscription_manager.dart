import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../interfaces/i_subscription_manager.dart';
import '../interfaces/i_license_service.dart';
import '../interfaces/i_device_service.dart';
import '../interfaces/i_crypto_service.dart';
import '../../models/subscription_status.dart';
import '../../models/license_data.dart';

/// Modes de dégradation de l'application
enum DegradationMode {
  normal,
  warning,
  urgentWarning,
  gracePeriod,
  blocked,
}

/// Niveaux de priorité des notifications
enum NotificationPriority {
  none,
  warning,
  urgent,
  critical,
  blocking,
}

/// Implémentation principale du gestionnaire d'abonnements
class SubscriptionManager implements ISubscriptionManager {
  final ILicenseService _licenseService;
  final IDeviceService _deviceService;
  final ICryptoService _cryptoService;
  final FlutterSecureStorage _secureStorage;

  // Clés de stockage sécurisé
  static const String _trialStartKey = 'trial_start_date';
  static const String _trialActiveKey = 'trial_active';
  static const String _lastValidationKey = 'last_validation';
  static const String _gracePeriodStartKey = 'grace_period_start';

  // Configuration
  static const int _trialDurationDays = 7;
  static const int _gracePeriodDays = 3;
  static const int _validationIntervalMinutes = 30;
  static const int _warningDaysThreshold = 3;
  static const int _urgentWarningDaysThreshold = 1;

  // Contrôleurs de stream
  final StreamController<SubscriptionStatus> _statusController = StreamController<SubscriptionStatus>.broadcast();

  // Timer pour les validations périodiques
  Timer? _periodicValidationTimer;

  // Cache du statut actuel avec optimisations
  SubscriptionStatus? _cachedStatus;
  DateTime? _lastCacheUpdate;

  // Cache en mémoire pour les validations fréquentes
  final Map<String, dynamic> _validationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Configuration du cache
  static const int _cacheValidityMinutes = 5;
  static const int _fastCacheValiditySeconds = 30;

  SubscriptionManager({
    required ILicenseService licenseService,
    required IDeviceService deviceService,
    required ICryptoService cryptoService,
    FlutterSecureStorage? secureStorage,
  })  : _licenseService = licenseService,
        _deviceService = deviceService,
        _cryptoService = cryptoService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize() async {
    try {
      // Vérifier si c'est le premier lancement
      final isFirstLaunch = await _isFirstLaunch();

      if (isFirstLaunch) {
        // Démarrer automatiquement la période d'essai
        await startTrialPeriod();
      } else {
        // Mettre à jour le statut de la période d'essai existante
        await updateTrialStatus();
      }

      // Effectuer une validation initiale
      await performPeriodicValidation();

      // Démarrer les validations périodiques
      _startPeriodicValidation();
    } catch (e) {
      // En cas d'erreur, créer un statut d'erreur
      final errorStatus = SubscriptionStatus(
        isActive: false,
        type: SubscriptionType.trial,
        warnings: ['Erreur d\'initialisation: ${e.toString()}'],
      );
      _updateStatus(errorStatus);
    }
  }

  @override
  Future<SubscriptionStatus> getCurrentStatus() async {
    // Utiliser le cache rapide si très récent (moins de 30 secondes)
    if (_cachedStatus != null && _lastCacheUpdate != null) {
      final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
      if (cacheAge.inSeconds < _fastCacheValiditySeconds) {
        return _cachedStatus!;
      }
      // Utiliser le cache normal si récent (moins de 5 minutes)
      if (cacheAge.inMinutes < _cacheValidityMinutes) {
        return _cachedStatus!;
      }
    }

    try {
      // Vérifier d'abord s'il y a une licence active
      final storedLicense = await _licenseService.getStoredLicense();

      if (storedLicense != null) {
        return await _getSubscriptionStatus(storedLicense);
      }

      // Sinon, vérifier la période d'essai
      final isTrialActive = await this.isTrialActive();
      if (isTrialActive) {
        final remainingDays = await getRemainingTrialDays();
        final warnings = _generateTrialWarnings(remainingDays);

        final status = SubscriptionStatus.trialActive(
          remainingDays: remainingDays,
          warnings: warnings,
        );

        _updateCachedStatus(status);
        return status;
      }

      // Aucun abonnement actif
      final expiredStatus = SubscriptionStatus(
        isActive: false,
        type: SubscriptionType.trial,
        remainingDays: 0,
        warnings: ['Aucun abonnement actif'],
      );

      _updateCachedStatus(expiredStatus);
      return expiredStatus;
    } catch (e) {
      final errorStatus = SubscriptionStatus(
        isActive: false,
        type: SubscriptionType.trial,
        warnings: ['Erreur de validation: ${e.toString()}'],
      );

      _updateCachedStatus(errorStatus);
      return errorStatus;
    }
  }

  @override
  Future<bool> activateLicense(String licenseKey) async {
    try {
      // Valider la clé de licence
      final validationResult = await _licenseService.validateLicense(licenseKey);

      if (!validationResult.isValid) {
        return false;
      }

      // Stocker la licence validée
      await _licenseService.storeLicense(validationResult.licenseData!);

      // Désactiver la période d'essai
      await _secureStorage.write(key: _trialActiveKey, value: 'false');

      // Mettre à jour le statut
      final newStatus = await _getSubscriptionStatus(validationResult.licenseData!);
      _updateStatus(newStatus);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> startTrialPeriod() async {
    final now = DateTime.now();

    // Vérifier s'il y a déjà une licence active
    final storedLicense = await _licenseService.getStoredLicense();
    if (storedLicense != null) {
      // Il y a déjà une licence, ne pas démarrer d'essai
      return;
    }

    // Vérifier si une période d'essai est déjà active
    final isCurrentlyTrialActive = await isTrialActive();
    if (isCurrentlyTrialActive) {
      // Une période d'essai est déjà en cours
      return;
    }

    // CORRECTION: Permettre de redémarrer un essai si aucune licence n'est présente
    // Cela corrige le problème d'accès gratuit de 7 jours qui ne fonctionne pas

    // Stocker la date de début d'essai (écrase l'ancienne si elle existe)
    await _secureStorage.write(
      key: _trialStartKey,
      value: now.toIso8601String(),
    );

    // Marquer l'essai comme actif
    await _secureStorage.write(key: _trialActiveKey, value: 'true');

    // Nettoyer toute période de grâce précédente
    await _secureStorage.delete(key: _gracePeriodStartKey);

    // Mettre à jour le statut
    final status = SubscriptionStatus.trialActive(
      remainingDays: _trialDurationDays,
      warnings: ['Période d\'essai de $_trialDurationDays jours activée'],
    );

    _updateStatus(status);
  }

  @override
  Future<bool> isTrialActive() async {
    try {
      final trialActiveStr = await _secureStorage.read(key: _trialActiveKey);
      if (trialActiveStr != 'true') return false;

      final trialStartStr = await _secureStorage.read(key: _trialStartKey);
      if (trialStartStr == null) return false;

      final trialStart = DateTime.parse(trialStartStr);
      final now = DateTime.now();
      final daysSinceStart = now.difference(trialStart).inDays;

      return daysSinceStart < _trialDurationDays;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getRemainingTrialDays() async {
    try {
      final trialStartStr = await _secureStorage.read(key: _trialStartKey);
      if (trialStartStr == null) return 0;

      final trialStart = DateTime.parse(trialStartStr);
      final now = DateTime.now();
      final daysSinceStart = now.difference(trialStart).inDays;

      final remaining = _trialDurationDays - daysSinceStart;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<DateTime?> getExpirationDate() async {
    try {
      final storedLicense = await _licenseService.getStoredLicense();
      if (storedLicense != null) {
        return storedLicense.expiresAt;
      }

      // Pour la période d'essai
      final trialStartStr = await _secureStorage.read(key: _trialStartKey);
      if (trialStartStr != null) {
        final trialStart = DateTime.parse(trialStartStr);
        return trialStart.add(Duration(days: _trialDurationDays));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> performPeriodicValidation() async {
    await _executeWithErrorRecovery(() async {
      // Enregistrer l'heure de la dernière validation
      await _secureStorage.write(
        key: _lastValidationKey,
        value: DateTime.now().toIso8601String(),
      );

      // Nettoyer les entrées de cache expirées
      _cleanupExpiredCacheEntries();

      // Vérifier l'intégrité des licences stockées avec récupération
      await _executeWithErrorRecovery(
        () => _validateStoredLicenseIntegrity(),
        'validation intégrité licence',
      );

      // Mettre à jour le statut de la période d'essai si nécessaire
      await _executeWithErrorRecovery(
        () => updateTrialStatus(),
        'mise à jour statut essai',
      );

      // Obtenir le statut actuel
      final status = await getCurrentStatus();

      // Vérifier et appliquer les modes de dégradation
      await _executeWithErrorRecovery(
        () => _applyDegradationMode(status),
        'application mode dégradation',
      );

      // Vérifier si l'application doit être bloquée
      final shouldBlock = await shouldBlockApplication();

      if (shouldBlock && status.isActive) {
        // Forcer la mise à jour du statut si nécessaire
        final updatedStatus = SubscriptionStatus(
          isActive: false,
          type: status.type,
          expirationDate: status.expirationDate,
          remainingDays: 0,
          isInGracePeriod: status.isInGracePeriod,
          warnings: [...status.warnings, 'Abonnement expiré'],
        );

        _updateStatus(updatedStatus);
      }

      // Nettoyer le cache si nécessaire
      await _cleanupExpiredCache();

      print('✅ [SubscriptionManager] Validation périodique terminée avec succès');
    }, 'validation périodique');
  }

  @override
  Future<bool> shouldBlockApplication() async {
    const cacheKey = 'should_block_application';

    // Vérifier le cache rapide pour cette vérification critique
    if (_isValidCacheEntry(cacheKey, _fastCacheValiditySeconds)) {
      return _validationCache[cacheKey] as bool;
    }

    try {
      final status = await getCurrentStatus();

      bool shouldBlock = true;

      // Ne pas bloquer si l'abonnement est actif
      if (status.isActive) {
        shouldBlock = false;
      }
      // Vérifier la période de grâce
      else if (status.isInGracePeriod) {
        shouldBlock = false;
      }
      // Bloquer si aucun abonnement actif et pas de période de grâce
      else {
        shouldBlock = true;
      }

      // Mettre en cache le résultat
      _setCacheEntry(cacheKey, shouldBlock);

      return shouldBlock;
    } catch (e) {
      // En cas d'erreur, bloquer par sécurité mais ne pas mettre en cache
      print('❌ [SubscriptionManager] Erreur shouldBlockApplication: $e');
      return true;
    }
  }

  @override
  Future<List<String>> getExpirationNotifications() async {
    try {
      final status = await getCurrentStatus();
      final notifications = <String>[];

      if (!status.isActive) {
        if (status.isInGracePeriod) {
          final gracePeriodStart = await _getGracePeriodStart();
          if (gracePeriodStart != null) {
            final graceDaysRemaining = _gracePeriodDays - DateTime.now().difference(gracePeriodStart).inDays;
            if (graceDaysRemaining > 0) {
              notifications.add('Période de grâce: $graceDaysRemaining jour(s) restant(s) - Renouvelez maintenant');
            } else {
              notifications.add('Période de grâce expirée - Activez une licence immédiatement');
            }
          } else {
            notifications.add('Période de grâce active - Renouvelez votre abonnement');
          }
        } else {
          notifications.add('Abonnement expiré - Activez une licence pour continuer');
        }
        return notifications;
      }

      final remainingDays = status.remainingDays ?? 0;
      final expirationDate = status.expirationDate;

      if (remainingDays <= _urgentWarningDaysThreshold) {
        if (remainingDays == 0) {
          notifications.add('CRITIQUE: Votre abonnement expire aujourd\'hui!');
        } else {
          notifications.add('URGENT: Votre abonnement expire dans $remainingDays jour(s)');
        }

        if (expirationDate != null) {
          notifications.add('Date d\'expiration: ${_formatDate(expirationDate)}');
        }

        notifications.add('Renouvelez maintenant pour éviter l\'interruption du service');
      } else if (remainingDays <= _warningDaysThreshold) {
        notifications.add('Attention: Votre abonnement expire dans $remainingDays jours');

        if (expirationDate != null) {
          notifications.add('Date d\'expiration: ${_formatDate(expirationDate)}');
        }

        notifications.add('Pensez à renouveler votre abonnement');
      }

      // Ajouter des notifications spécifiques au type d'abonnement
      if (status.type == SubscriptionType.trial && remainingDays <= 2) {
        notifications.add('Fin de période d\'essai - Choisissez votre abonnement');
      }

      return notifications;
    } catch (e) {
      return ['Erreur lors de la vérification des notifications'];
    }
  }

  /// Obtient les notifications critiques qui nécessitent une action immédiate
  Future<List<String>> getCriticalNotifications() async {
    try {
      final status = await getCurrentStatus();
      final notifications = <String>[];

      if (!status.isActive && !status.isInGracePeriod) {
        notifications.add('ACCÈS BLOQUÉ: Activez une licence pour continuer');
        return notifications;
      }

      if (status.isInGracePeriod) {
        notifications.add('PÉRIODE DE GRÂCE: Renouvelez immédiatement');
        return notifications;
      }

      final remainingDays = status.remainingDays ?? 0;
      if (remainingDays == 0) {
        notifications.add('EXPIRATION AUJOURD\'HUI: Renouvelez maintenant');
      } else if (remainingDays == 1) {
        notifications.add('EXPIRATION DEMAIN: Action requise');
      }

      return notifications;
    } catch (e) {
      return ['Erreur critique du système de licence'];
    }
  }

  /// Vérifie si des notifications doivent être affichées
  Future<bool> shouldShowNotifications() async {
    final notifications = await getExpirationNotifications();
    return notifications.isNotEmpty;
  }

  /// Vérifie si des notifications critiques doivent être affichées
  Future<bool> shouldShowCriticalNotifications() async {
    final criticalNotifications = await getCriticalNotifications();
    return criticalNotifications.isNotEmpty;
  }

  /// Obtient le niveau de priorité des notifications
  Future<NotificationPriority> getNotificationPriority() async {
    try {
      final status = await getCurrentStatus();

      if (!status.isActive) {
        if (status.isInGracePeriod) {
          return NotificationPriority.critical;
        } else {
          return NotificationPriority.blocking;
        }
      }

      final remainingDays = status.remainingDays ?? 0;
      if (remainingDays <= _urgentWarningDaysThreshold) {
        return NotificationPriority.urgent;
      } else if (remainingDays <= _warningDaysThreshold) {
        return NotificationPriority.warning;
      }

      return NotificationPriority.none;
    } catch (e) {
      return NotificationPriority.critical;
    }
  }

  /// Marque une notification comme vue par l'utilisateur
  Future<void> markNotificationAsSeen(String notificationId) async {
    final seenNotifications = await _getSeenNotifications();
    seenNotifications.add(notificationId);

    await _secureStorage.write(
      key: 'seen_notifications',
      value: seenNotifications.join(','),
    );
  }

  /// Vérifie si une notification a déjà été vue
  Future<bool> isNotificationSeen(String notificationId) async {
    final seenNotifications = await _getSeenNotifications();
    return seenNotifications.contains(notificationId);
  }

  /// Nettoie les notifications vues anciennes
  Future<void> cleanupSeenNotifications() async {
    // Nettoyer les notifications vues de plus de 7 jours
    await _secureStorage.delete(key: 'seen_notifications');
  }

  /// Obtient les jours restants dans la période de grâce
  Future<int> getGracePeriodRemainingDays() async {
    final gracePeriodStart = await _getGracePeriodStart();
    if (gracePeriodStart == null) return 0;

    final daysSinceGraceStart = DateTime.now().difference(gracePeriodStart).inDays;
    final remaining = _gracePeriodDays - daysSinceGraceStart;
    return remaining > 0 ? remaining : 0;
  }

  /// Vérifie si la période d'essai peut être démarrée
  Future<bool> canStartTrial() async {
    final storedLicense = await _licenseService.getStoredLicense();
    final isCurrentlyTrialActive = await isTrialActive();

    // CORRECTION: Peut démarrer un essai si aucune licence et pas d'essai actif
    // Cela permet de redémarrer l'accès gratuit même si un essai a déjà été utilisé
    return storedLicense == null && !isCurrentlyTrialActive;
  }

  /// Obtient la date de début de la période d'essai
  Future<DateTime?> getTrialStartDate() async {
    try {
      final trialStartStr = await _secureStorage.read(key: _trialStartKey);
      return trialStartStr != null ? DateTime.parse(trialStartStr) : null;
    } catch (e) {
      return null;
    }
  }

  /// Obtient la date de fin de la période d'essai
  Future<DateTime?> getTrialEndDate() async {
    final startDate = await getTrialStartDate();
    return startDate?.add(Duration(days: _trialDurationDays));
  }

  /// Force l'expiration de la période d'essai
  Future<void> expireTrial() async {
    await _secureStorage.write(key: _trialActiveKey, value: 'false');

    // Mettre à jour le statut
    final expiredStatus = SubscriptionStatus(
      isActive: false,
      type: SubscriptionType.trial,
      remainingDays: 0,
      warnings: ['Période d\'essai expirée'],
    );

    _updateStatus(expiredStatus);
  }

  /// Gère la transition automatique vers l'abonnement payant
  Future<void> handleTrialToSubscriptionTransition() async {
    final isTrialActive = await this.isTrialActive();

    if (!isTrialActive) {
      // La période d'essai est expirée, vérifier s'il y a une licence
      final storedLicense = await _licenseService.getStoredLicense();

      if (storedLicense != null) {
        // Transition vers l'abonnement payant
        final newStatus = await _getSubscriptionStatus(storedLicense);
        _updateStatus(newStatus);
      } else {
        // Aucune licence, marquer comme expiré
        await expireTrial();
      }
    }
  }

  /// Vérifie et met à jour automatiquement le statut de la période d'essai
  Future<void> updateTrialStatus() async {
    final isTrialActive = await this.isTrialActive();

    if (isTrialActive) {
      final remainingDays = await getRemainingTrialDays();

      if (remainingDays <= 0) {
        // La période d'essai vient d'expirer
        await handleTrialToSubscriptionTransition();
      } else {
        // Mettre à jour le statut avec les jours restants
        final warnings = _generateTrialWarnings(remainingDays);
        final status = SubscriptionStatus.trialActive(
          remainingDays: remainingDays,
          warnings: warnings,
        );

        _updateStatus(status);
      }
    }
  }

  /// Valide l'intégrité des licences stockées
  Future<void> _validateStoredLicenseIntegrity() async {
    try {
      final storedLicense = await _licenseService.getStoredLicense();
      if (storedLicense != null) {
        final isIntegrityValid = await _licenseService.verifyLicenseIntegrity();
        if (!isIntegrityValid) {
          // Licence corrompue, la nettoyer
          await _licenseService.cleanupCorruptedLicense();
        }
      }
    } catch (e) {
      // En cas d'erreur, nettoyer les données corrompues
      await _licenseService.cleanupCorruptedLicense();
    }
  }

  /// Applique les modes de dégradation selon le statut
  Future<void> _applyDegradationMode(SubscriptionStatus status) async {
    if (!status.isActive) {
      if (status.isInGracePeriod) {
        // Mode dégradé : fonctionnalités limitées
        await _setDegradationMode(DegradationMode.gracePeriod);
      } else {
        // Mode bloqué : lecture seule
        await _setDegradationMode(DegradationMode.blocked);
      }
    } else if (status.shouldShowUrgentWarning) {
      // Mode avertissement urgent
      await _setDegradationMode(DegradationMode.urgentWarning);
    } else if (status.shouldShowExpirationWarning) {
      // Mode avertissement
      await _setDegradationMode(DegradationMode.warning);
    } else {
      // Mode normal
      await _setDegradationMode(DegradationMode.normal);
    }
  }

  /// Définit le mode de dégradation actuel
  Future<void> _setDegradationMode(DegradationMode mode) async {
    await _secureStorage.write(
      key: 'degradation_mode',
      value: mode.toString(),
    );
  }

  /// Obtient le mode de dégradation actuel
  Future<DegradationMode> getDegradationMode() async {
    try {
      final modeStr = await _secureStorage.read(key: 'degradation_mode');
      if (modeStr != null) {
        return DegradationMode.values.firstWhere(
          (mode) => mode.toString() == modeStr,
          orElse: () => DegradationMode.normal,
        );
      }
      return DegradationMode.normal;
    } catch (e) {
      return DegradationMode.normal;
    }
  }

  /// Nettoie le cache expiré
  Future<void> _cleanupExpiredCache() async {
    if (_lastCacheUpdate != null) {
      final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
      if (cacheAge.inHours > 1) {
        // Nettoyer le cache s'il est trop ancien
        _cachedStatus = null;
        _lastCacheUpdate = null;
      }
    }
  }

  /// Obtient la dernière validation effectuée
  Future<DateTime?> getLastValidationTime() async {
    try {
      final lastValidationStr = await _secureStorage.read(key: _lastValidationKey);
      return lastValidationStr != null ? DateTime.parse(lastValidationStr) : null;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une validation périodique est nécessaire
  Future<bool> isPeriodicValidationDue() async {
    final lastValidation = await getLastValidationTime();
    if (lastValidation == null) return true;

    final timeSinceLastValidation = DateTime.now().difference(lastValidation);
    return timeSinceLastValidation.inMinutes >= _validationIntervalMinutes;
  }

  /// Force une validation immédiate
  Future<void> forceValidation() async {
    await performPeriodicValidation();
  }

  // Méthodes d'aide privées

  /// Formate une date pour l'affichage
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Obtient la liste des notifications vues
  Future<List<String>> _getSeenNotifications() async {
    try {
      final seenStr = await _secureStorage.read(key: 'seen_notifications');
      if (seenStr != null && seenStr.isNotEmpty) {
        return seenStr.split(',');
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _periodicValidationTimer?.cancel();
    await _statusController.close();
  }

  // Méthodes privées

  Future<bool> _isFirstLaunch() async {
    final trialStartStr = await _secureStorage.read(key: _trialStartKey);
    final storedLicense = await _licenseService.getStoredLicense();

    return trialStartStr == null && storedLicense == null;
  }

  void _startPeriodicValidation() {
    _periodicValidationTimer = Timer.periodic(
      Duration(minutes: _validationIntervalMinutes),
      (_) => performPeriodicValidation(),
    );
  }

  Future<SubscriptionStatus> _getSubscriptionStatus(LicenseData license) async {
    final isExpired = license.isExpired;
    final isInGracePeriod = license.isInGracePeriod;
    final remainingDays = license.remainingDays;

    List<String> warnings = [];

    if (isExpired) {
      if (isInGracePeriod) {
        warnings.add('Période de grâce active');
        final gracePeriodStart = await _getGracePeriodStart();
        if (gracePeriodStart == null) {
          await _setGracePeriodStart(license.expiresAt);
        }
      } else {
        warnings.add('Abonnement expiré');
      }

      return SubscriptionStatus.expired(
        type: license.subscriptionType,
        expirationDate: license.expiresAt,
        isInGracePeriod: isInGracePeriod,
        warnings: warnings,
      );
    }

    // Générer les avertissements d'expiration
    if (remainingDays <= _urgentWarningDaysThreshold) {
      warnings.add('Expiration imminente dans $remainingDays jour(s)');
    } else if (remainingDays <= _warningDaysThreshold) {
      warnings.add('Expiration dans $remainingDays jours');
    }

    final status = SubscriptionStatus.subscriptionActive(
      type: license.subscriptionType,
      expirationDate: license.expiresAt,
      remainingDays: remainingDays,
      warnings: warnings,
    );

    _updateCachedStatus(status);
    return status;
  }

  List<String> _generateTrialWarnings(int remainingDays) {
    final warnings = <String>[];

    if (remainingDays <= _urgentWarningDaysThreshold) {
      warnings.add('Période d\'essai expire dans $remainingDays jour(s)');
    } else if (remainingDays <= _warningDaysThreshold) {
      warnings.add('Période d\'essai expire dans $remainingDays jours');
    }

    return warnings;
  }

  void _updateStatus(SubscriptionStatus status) {
    _updateCachedStatus(status);
    _statusController.add(status);
  }

  void _updateCachedStatus(SubscriptionStatus status) {
    _cachedStatus = status;
    _lastCacheUpdate = DateTime.now();
  }

  Future<DateTime?> _getGracePeriodStart() async {
    try {
      final gracePeriodStartStr = await _secureStorage.read(key: _gracePeriodStartKey);
      return gracePeriodStartStr != null ? DateTime.parse(gracePeriodStartStr) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _setGracePeriodStart(DateTime expirationDate) async {
    await _secureStorage.write(
      key: _gracePeriodStartKey,
      value: expirationDate.toIso8601String(),
    );
  }

  // Méthodes de gestion du cache en mémoire

  /// Vérifie si une entrée de cache est valide
  bool _isValidCacheEntry(String key, int validitySeconds) {
    if (!_validationCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final age = DateTime.now().difference(timestamp);
    return age.inSeconds < validitySeconds;
  }

  /// Définit une entrée dans le cache
  void _setCacheEntry(String key, dynamic value) {
    _validationCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Nettoie les entrées de cache expirées
  void _cleanupExpiredCacheEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      final age = now.difference(entry.value);
      if (age.inMinutes > _cacheValidityMinutes) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _validationCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Invalide tout le cache
  void _invalidateCache() {
    _validationCache.clear();
    _cacheTimestamps.clear();
    _cachedStatus = null;
    _lastCacheUpdate = null;
  }

  /// Optimise les opérations cryptographiques avec mise en cache
  Future<bool> _optimizedCryptoValidation(String data, String signature, String publicKey) async {
    final cacheKey = 'crypto_validation_${data.hashCode}_${signature.hashCode}_${publicKey.hashCode}';

    // Vérifier le cache pour éviter les recalculs coûteux
    if (_isValidCacheEntry(cacheKey, _cacheValidityMinutes * 60)) {
      return _validationCache[cacheKey] as bool;
    }

    try {
      // Effectuer la validation cryptographique
      // Cette opération est coûteuse, donc on la met en cache
      final isValid = _cryptoService.verifySignature(data, signature, publicKey);

      // Mettre en cache le résultat
      _setCacheEntry(cacheKey, isValid);

      return isValid;
    } catch (e) {
      print('❌ [SubscriptionManager] Erreur validation crypto: $e');
      return false;
    }
  }

  /// Gestion robuste des erreurs avec récupération automatique
  Future<T?> _executeWithErrorRecovery<T>(Future<T> Function() operation, String operationName, {T? fallbackValue}) async {
    try {
      return await operation();
    } catch (e) {
      print('❌ [SubscriptionManager] Erreur $operationName: $e');

      // Tentative de récupération automatique
      try {
        print('🔄 [SubscriptionManager] Tentative de récupération pour $operationName...');

        // Nettoyer le cache en cas d'erreur
        _invalidateCache();

        // Réessayer une fois
        await Future.delayed(const Duration(milliseconds: 500));
        return await operation();
      } catch (recoveryError) {
        print('❌ [SubscriptionManager] Échec de récupération pour $operationName: $recoveryError');

        // Retourner la valeur de fallback si disponible
        if (fallbackValue != null) {
          return fallbackValue;
        }

        // Créer un statut d'erreur sécurisé
        if (T == SubscriptionStatus) {
          return SubscriptionStatus(
            isActive: false,
            type: SubscriptionType.trial,
            warnings: ['Erreur système: $operationName'],
          ) as T;
        }

        rethrow;
      }
    }
  }

  /// Récupère la licence actuellement active
  @override
  Future<LicenseData?> getCurrentLicense() async {
    try {
      return await _licenseService.getStoredLicense();
    } catch (e) {
      return null;
    }
  }

  /// Récupère l'empreinte de l'appareil
  @override
  Future<String> getDeviceFingerprint() async {
    return await _deviceService.generateDeviceFingerprint();
  }

  /// Réinitialise complètement la licence et la période d'essai
  /// ⚠️ ATTENTION: Cette méthode supprime toutes les données de licence
  /// À utiliser uniquement pour les tests ou le support client
  Future<void> resetLicenseData() async {
    try {
      print('🔄 Réinitialisation de la licence...');

      // Supprimer la licence stockée
      await _licenseService.revokeLicense();

      // Supprimer les données de période d'essai
      await _secureStorage.delete(key: _trialStartKey);
      await _secureStorage.delete(key: _trialActiveKey);
      await _secureStorage.delete(key: 'trial_ever_used');

      // Supprimer les données de validation
      await _secureStorage.delete(key: _lastValidationKey);
      await _secureStorage.delete(key: _gracePeriodStartKey);

      // Supprimer le cache
      await _secureStorage.delete(key: 'degradation_mode');
      await _secureStorage.delete(key: 'seen_notifications');

      // Invalider le cache en mémoire
      _cachedStatus = null;
      _lastCacheUpdate = null;
      _validationCache.clear();
      _cacheTimestamps.clear();

      print('✅ Réinitialisation terminée');

      // Émettre un statut vide
      final emptyStatus = SubscriptionStatus(
        isActive: false,
        type: SubscriptionType.trial,
        remainingDays: 0,
        warnings: ['Licence réinitialisée'],
      );
      _statusController.add(emptyStatus);

      print('📝 Redémarrez l\'application pour démarrer une nouvelle période d\'essai');
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }
}
