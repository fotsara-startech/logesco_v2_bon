import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/subscription/models/license_data.dart';
import '../services/interfaces/i_subscription_manager.dart';
import '../services/notification_service.dart';
import '../models/subscription_status.dart';
import '../models/license_errors.dart';
import '../../../core/config/app_config.dart';

/// Contrleur pour la gestion des abonnements dans l'interface utilisateur
class SubscriptionController extends GetxController {
  final ISubscriptionManager _subscriptionManager;

  final Rx<SubscriptionStatus?> _currentStatus = Rx<SubscriptionStatus?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxList<String> _notifications = <String>[].obs;

  SubscriptionController({required ISubscriptionManager subscriptionManager}) : _subscriptionManager = subscriptionManager;

  SubscriptionStatus? get currentStatus => _currentStatus.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<String> get notifications => _notifications;

  // Exposer les Rx directement pour les Obx widgets
  Rx<SubscriptionStatus?> get currentStatusRx => _currentStatus;
  RxBool get isLoadingRx => _isLoading;
  RxList<String> get notificationsRx => _notifications;

  bool get isSubscriptionActive => _currentStatus.value?.isActive ?? false;
  bool get isTrialActive => _currentStatus.value?.type == SubscriptionType.trial && isSubscriptionActive;
  bool get isInGracePeriod => _currentStatus.value?.isInGracePeriod ?? false;
  int get remainingDays => _currentStatus.value?.remainingDays ?? 0;
  DateTime? get expirationDate => _currentStatus.value?.expirationDate;

  @override
  void onInit() {
    super.onInit();
    _initializeSubscription();
  }

  @override
  void onClose() {
    _subscriptionManager.dispose();
    super.onClose();
  }

  Future<void> _initializeSubscription() async {
    // Contrle de licence dÊtesactiv - statut "actif  vie" par dfaut
    if (!AppConfig.enableLicenseControl) {
      _currentStatus.value = SubscriptionStatus(
        isActive: true,
        type: SubscriptionType.lifetime,
        remainingDays: null,
        warnings: [],
      );
      return;
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _subscriptionManager.initialize();

      _subscriptionManager.statusStream.listen(
        (status) {
          _currentStatus.value = status;
          _updateNotifications();
        },
        onError: (error) {
          _errorMessage.value = 'Erreur de surveillance: ${error.toString()}';
        },
      );

      await refreshStatus();
    } catch (e) {
      _errorMessage.value = 'Erreur d\'initialisation: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshStatus() async {
    // Contrle de licence dÊtesactiv
    if (!AppConfig.enableLicenseControl) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final status = await _subscriptionManager.getCurrentStatus();
      _currentStatus.value = status;
      await _updateNotifications();
    } catch (e) {
      _errorMessage.value = 'Erreur de rafraîchissement: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> activateLicense(String licenseKey) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final success = await _subscriptionManager.activateLicense(licenseKey);

      if (success) {
        await refreshStatus();
        await SubscriptionNotificationService.resetNotificationCounters();
        return true;
      } else {
        throw LicenseException(LicenseError.invalidKey, 'Clé d\'activation invalide');
      }
    } catch (e) {
      if (e is LicenseException) {
        _errorMessage.value = e.localizedMessage;
      } else {
        _errorMessage.value = 'Erreur d\'activation: ${e.toString()}';
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startTrial() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _subscriptionManager.startTrialPeriod();
      await refreshStatus();
    } catch (e) {
      _errorMessage.value = 'Erreur de démarrage d\'essai: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> shouldBlockApplication() async {
    // Contrle de licence dÊtesactiv - ne jamais bloquer
    if (!AppConfig.enableLicenseControl) return false;

    try {
      return await _subscriptionManager.shouldBlockApplication();
    } catch (e) {
      return true;
    }
  }

  Future<void> checkAndShowNotifications(BuildContext context) async {
    if (!AppConfig.enableLicenseControl) return;

    final status = _currentStatus.value;
    if (status != null) {
      await SubscriptionNotificationService.checkAndShowNotifications(context, status);
    }
  }

  bool isInDegradedMode() {
    if (!AppConfig.enableLicenseControl) return false;
    return SubscriptionNotificationService.isInDegradedMode(_currentStatus.value);
  }

  Future<List<String>> getExpirationNotifications() async {
    if (!AppConfig.enableLicenseControl) return [];
    try {
      return await _subscriptionManager.getExpirationNotifications();
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateNotifications() async {
    if (!AppConfig.enableLicenseControl) {
      _notifications.clear();
      return;
    }
    try {
      final notificationList = await _subscriptionManager.getExpirationNotifications();
      _notifications.assignAll(notificationList);
    } catch (e) {
      _notifications.clear();
    }
  }

  bool shouldShowNotifications() => _notifications.isNotEmpty;

  bool shouldShowCriticalNotifications() {
    if (!AppConfig.enableLicenseControl) return false;
    if (_currentStatus.value == null) return false;
    final status = _currentStatus.value!;
    if (status.remainingDays == null) return false; // lifetime, jamais d'alerte
    return !status.isActive || status.isInGracePeriod || status.remainingDays! <= 1;
  }

  String getStatusMessage() {
    if (!AppConfig.enableLicenseControl) return 'Licence à vie - accès complet';

    final status = _currentStatus.value;
    if (status == null) return 'Statut inconnu';
    if (!status.isActive) {
      return status.isInGracePeriod ? 'Période de grâce active - Renouvelez maintenant' : 'Abonnement expir - Activation requise';
    }
    if (status.type == SubscriptionType.trial) {
      final days = status.remainingDays ?? 0;
      return days <= 1 ? 'Période d\'essai expire ${days == 0 ? 'aujourd\'hui' : 'demain'}' : 'Période d\'essai - $days jours restants';
    }
    final days = status.remainingDays ?? 0;
    if (days <= 3) return 'Abonnement expire dans $days jour${days > 1 ? 's' : ''}';
    return 'Abonnement actif';
  }

  void clearError() => _errorMessage.value = '';

  Future<void> forceValidation() async {
    if (!AppConfig.enableLicenseControl) return;
    try {
      _isLoading.value = true;
      await _subscriptionManager.performPeriodicValidation();
      await refreshStatus();
    } catch (e) {
      _errorMessage.value = 'Erreur de validation: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> canStartTrial() async {
    if (isSubscriptionActive) return false;
    return true;
  }

  Map<String, dynamic> getSubscriptionDetails() {
    if (!AppConfig.enableLicenseControl) {
      return {'type': 'Lifetime', 'status': 'Actif', 'isActive': true, 'remainingDays': null};
    }
    final status = _currentStatus.value;
    if (status == null) {
      return {'type': 'Inconnu', 'status': 'Non disponible', 'isActive': false};
    }
    return {
      'type': _getSubscriptionTypeLabel(status.type),
      'status': status.isActive ? 'Actif' : 'Expir',
      'expirationDate': status.expirationDate,
      'remainingDays': status.remainingDays,
      'isActive': status.isActive,
      'isInGracePeriod': status.isInGracePeriod,
      'warnings': status.warnings,
    };
  }

  String _getSubscriptionTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 'Période d\'essai';
      case SubscriptionType.monthly:
        return 'Mensuel';
      case SubscriptionType.annual:
        return 'Annuel';
      case SubscriptionType.lifetime:
        return 'Vie entière';
    }
  }

  Future<String?> getCurrentLicenseKey() async {
    try {
      final license = await _subscriptionManager.getCurrentLicense();
      return license?.key;
    } catch (e) {
      return null;
    }
  }

  Future<void> copyLicenseKeyToClipboard(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
  }

  Future<String?> getDeviceFingerprint() async {
    try {
      return await _subscriptionManager.getDeviceFingerprint();
    } catch (e) {
      return null;
    }
  }

  Future<void> resetLicenseData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _subscriptionManager.resetLicenseData();
      await refreshStatus();
    } catch (e) {
      _errorMessage.value = 'Erreur de rinitialisation: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Vérifie si l'application peut continuer en mode offline (dégradé)
  bool canContinueOffline() {
    // Si contrôle de licence désactivé, toujours laisser passer
    if (!AppConfig.enableLicenseControl) return true;

    final status = _currentStatus.value;
    if (status == null) return false;

    // Peut continuer si:
    // 1. Abonnement actif
    // 2. En période de grâce
    // 3. Période d'essai non expirée
    return status.isActive || status.isInGracePeriod;
  }
}
