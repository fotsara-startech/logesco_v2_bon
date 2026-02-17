import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/subscription/models/license_data.dart';
import '../services/interfaces/i_subscription_manager.dart';
import '../services/notification_service.dart';
import '../models/subscription_status.dart';
import '../models/license_errors.dart';

/// Contrôleur pour la gestion des abonnements dans l'interface utilisateur
class SubscriptionController extends GetxController {
  final ISubscriptionManager _subscriptionManager;

  // État observable
  final Rx<SubscriptionStatus?> _currentStatus = Rx<SubscriptionStatus?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxList<String> _notifications = <String>[].obs;

  SubscriptionController({required ISubscriptionManager subscriptionManager}) : _subscriptionManager = subscriptionManager;

  // Getters pour l'état observable
  SubscriptionStatus? get currentStatus => _currentStatus.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<String> get notifications => _notifications;

  // Getters pour l'état de l'abonnement
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

  /// Initialise le gestionnaire d'abonnements et écoute les changements
  Future<void> _initializeSubscription() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Initialiser le gestionnaire
      await _subscriptionManager.initialize();

      // Écouter les changements de statut
      _subscriptionManager.statusStream.listen(
        (status) {
          _currentStatus.value = status;
          _updateNotifications();
        },
        onError: (error) {
          _errorMessage.value = 'Erreur de surveillance: ${error.toString()}';
        },
      );

      // Obtenir le statut initial
      await refreshStatus();
    } catch (e) {
      _errorMessage.value = 'Erreur d\'initialisation: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Actualise le statut de l'abonnement
  Future<void> refreshStatus() async {
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

  /// Active une licence avec la clé fournie
  Future<bool> activateLicense(String licenseKey) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final success = await _subscriptionManager.activateLicense(licenseKey);

      if (success) {
        // Actualiser le statut après activation
        await refreshStatus();
        // Réinitialiser les compteurs de notification
        await SubscriptionNotificationService.resetNotificationCounters();
        return true;
      } else {
        throw LicenseException(
          LicenseError.invalidKey,
          'Clé d\'activation invalide',
        );
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

  /// Démarre la période d'essai
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

  /// Vérifie si l'application doit être bloquée
  Future<bool> shouldBlockApplication() async {
    try {
      return await _subscriptionManager.shouldBlockApplication();
    } catch (e) {
      // En cas d'erreur, bloquer par sécurité
      return true;
    }
  }

  /// Vérifie et affiche les notifications appropriées
  Future<void> checkAndShowNotifications(BuildContext context) async {
    final status = _currentStatus.value;
    if (status != null) {
      await SubscriptionNotificationService.checkAndShowNotifications(context, status);
    }
  }

  /// Vérifie si l'application est en mode dégradé
  bool isInDegradedMode() {
    return SubscriptionNotificationService.isInDegradedMode(_currentStatus.value);
  }

  /// Obtient les notifications d'expiration
  Future<List<String>> getExpirationNotifications() async {
    try {
      return await _subscriptionManager.getExpirationNotifications();
    } catch (e) {
      return ['Erreur lors de la récupération des notifications'];
    }
  }

  /// Met à jour les notifications
  Future<void> _updateNotifications() async {
    try {
      final notificationList = await _subscriptionManager.getExpirationNotifications();
      _notifications.assignAll(notificationList);
    } catch (e) {
      _notifications.clear();
    }
  }

  /// Vérifie si des notifications doivent être affichées
  bool shouldShowNotifications() {
    return _notifications.isNotEmpty;
  }

  /// Vérifie si des notifications critiques doivent être affichées
  bool shouldShowCriticalNotifications() {
    if (_currentStatus.value == null) return false;

    final status = _currentStatus.value!;

    // Notifications critiques si:
    // - Abonnement expiré sans période de grâce
    // - En période de grâce
    // - Expire aujourd'hui ou demain
    return !status.isActive || status.isInGracePeriod || (status.remainingDays != null && status.remainingDays! <= 1);
  }

  /// Obtient le message de statut principal
  String getStatusMessage() {
    final status = _currentStatus.value;
    if (status == null) return 'Statut inconnu';

    if (!status.isActive) {
      if (status.isInGracePeriod) {
        return 'Période de grâce active - Renouvelez maintenant';
      } else {
        return 'Abonnement expiré - Activation requise';
      }
    }

    if (status.type == SubscriptionType.trial) {
      final days = status.remainingDays ?? 0;
      if (days <= 1) {
        return 'Période d\'essai expire ${days == 0 ? 'aujourd\'hui' : 'demain'}';
      } else {
        return 'Période d\'essai - $days jours restants';
      }
    }

    final days = status.remainingDays ?? 0;
    if (days <= 3) {
      return 'Abonnement expire dans $days jour${days > 1 ? 's' : ''}';
    }

    return 'Abonnement actif';
  }

  /// Obtient la couleur du statut
  String getStatusColor() {
    final status = _currentStatus.value;
    if (status == null || !status.isActive) return 'error';

    final days = status.remainingDays ?? 0;
    if (days <= 1) return 'error';
    if (days <= 3) return 'warning';

    return 'success';
  }

  /// Obtient l'icône du statut
  String getStatusIcon() {
    final status = _currentStatus.value;
    if (status == null || !status.isActive) return 'error';

    final days = status.remainingDays ?? 0;
    if (days <= 1) return 'warning';
    if (days <= 3) return 'info';

    return 'check_circle';
  }

  /// Efface les messages d'erreur
  void clearError() {
    _errorMessage.value = '';
  }

  /// Force une validation périodique
  Future<void> forceValidation() async {
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

  /// Vérifie si une période d'essai peut être démarrée
  Future<bool> canStartTrial() async {
    try {
      // Vérifier s'il n'y a pas déjà un abonnement actif
      if (isSubscriptionActive) return false;

      // Vérifier via le gestionnaire si un essai peut être démarré
      // Cette méthode devrait être ajoutée à l'interface si nécessaire
      return true; // Pour l'instant, autoriser si pas d'abonnement actif
    } catch (e) {
      return false;
    }
  }

  /// Obtient des informations détaillées sur l'abonnement
  Map<String, dynamic> getSubscriptionDetails() {
    final status = _currentStatus.value;
    if (status == null) {
      return {
        'type': 'Inconnu',
        'status': 'Non disponible',
        'expirationDate': null,
        'remainingDays': null,
        'isActive': false,
      };
    }

    return {
      'type': _getSubscriptionTypeLabel(status.type),
      'status': status.isActive ? 'Actif' : 'Expiré',
      'expirationDate': status.expirationDate,
      'remainingDays': status.remainingDays,
      'isActive': status.isActive,
      'isInGracePeriod': status.isInGracePeriod,
      'warnings': status.warnings,
    };
  }

  /// Obtient le libellé du type d'abonnement
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

  /// Récupère la clé de licence actuelle
  Future<String?> getCurrentLicenseKey() async {
    try {
      // Récupérer la licence depuis le gestionnaire
      final license = await _subscriptionManager.getCurrentLicense();
      return license?.key;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la clé: $e');
      return null;
    }
  }

  /// Copie la clé de licence dans le presse-papiers
  Future<void> copyLicenseKeyToClipboard(String key) async {
    try {
      await Clipboard.setData(ClipboardData(text: key));
    } catch (e) {
      debugPrint('Erreur lors de la copie de la clé: $e');
      rethrow;
    }
  }

  /// Récupère l'empreinte de l'appareil
  Future<String?> getDeviceFingerprint() async {
    try {
      return await _subscriptionManager.getDeviceFingerprint();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'empreinte: $e');
      return null;
    }
  }

  /// Réinitialise complètement la licence (pour tests uniquement)
  Future<void> resetLicenseData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _subscriptionManager.resetLicenseData();
      await refreshStatus();

      debugPrint('✅ Licence réinitialisée avec succès');
    } catch (e) {
      _errorMessage.value = 'Erreur de réinitialisation: ${e.toString()}';
      debugPrint('❌ Erreur réinitialisation: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }
}
