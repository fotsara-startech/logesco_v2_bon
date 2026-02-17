import '../services/implementations/implementations.dart';
import '../services/interfaces/interfaces.dart';
import '../models/models.dart';

/// Exemple d'utilisation du SubscriptionManager
class SubscriptionManagerUsageExample {
  late final ISubscriptionManager _subscriptionManager;

  /// Initialise le gestionnaire d'abonnements
  Future<void> initializeSubscriptionManager() async {
    // Créer les services nécessaires dans le bon ordre (dépendances)
    final cryptoService = CryptoService();
    final deviceService = DeviceService();
    final licenseService = LicenseService(
      cryptoService: cryptoService,
      deviceService: deviceService,
    );

    // Créer le gestionnaire d'abonnements
    _subscriptionManager = SubscriptionManager(
      licenseService: licenseService,
      deviceService: deviceService,
      cryptoService: cryptoService,
    );

    // Initialiser le gestionnaire
    await _subscriptionManager.initialize();

    // Écouter les changements de statut
    _subscriptionManager.statusStream.listen((status) {
      print('Statut d\'abonnement mis à jour: $status');
      _handleStatusChange(status);
    });
  }

  /// Gère les changements de statut d'abonnement
  void _handleStatusChange(SubscriptionStatus status) {
    if (!status.isActive) {
      if (status.isInGracePeriod) {
        print('Mode dégradé: Période de grâce active');
        _showGracePeriodUI();
      } else {
        print('Application bloquée: Abonnement expiré');
        _showBlockedUI();
      }
    } else if (status.shouldShowUrgentWarning) {
      print('Avertissement urgent: Expiration imminente');
      _showUrgentWarning();
    } else if (status.shouldShowExpirationWarning) {
      print('Avertissement: Expiration prochaine');
      _showExpirationWarning();
    }
  }

  /// Vérifie le statut actuel
  Future<void> checkCurrentStatus() async {
    final status = await _subscriptionManager.getCurrentStatus();
    print('Statut actuel: ${status.isActive ? 'Actif' : 'Inactif'}');
    print('Type: ${status.type}');
    print('Jours restants: ${status.remainingDays}');

    if (status.warnings.isNotEmpty) {
      print('Avertissements: ${status.warnings.join(', ')}');
    }
  }

  /// Active une licence avec une clé
  Future<bool> activateLicense(String licenseKey) async {
    final success = await _subscriptionManager.activateLicense(licenseKey);

    if (success) {
      print('Licence activée avec succès');
      return true;
    } else {
      print('Échec de l\'activation de la licence');
      return false;
    }
  }

  /// Vérifie les notifications d'expiration
  Future<void> checkNotifications() async {
    final notifications = await _subscriptionManager.getExpirationNotifications();

    if (notifications.isNotEmpty) {
      print('Notifications:');
      for (final notification in notifications) {
        print('- $notification');
      }
    } else {
      print('Aucune notification');
    }
  }

  /// Démarre une période d'essai
  Future<void> startTrial() async {
    final canStart = await (_subscriptionManager as SubscriptionManager).canStartTrial();

    if (canStart) {
      await _subscriptionManager.startTrialPeriod();
      print('Période d\'essai démarrée');
    } else {
      print('Impossible de démarrer la période d\'essai');
    }
  }

  /// Vérifie si l'application doit être bloquée
  Future<void> checkApplicationAccess() async {
    final shouldBlock = await _subscriptionManager.shouldBlockApplication();

    if (shouldBlock) {
      print('Accès bloqué - Licence requise');
      _showBlockedUI();
    } else {
      print('Accès autorisé');
    }
  }

  /// Affiche l'interface de période de grâce
  void _showGracePeriodUI() {
    // Implémenter l'interface de période de grâce
    print('Affichage de l\'interface de période de grâce');
  }

  /// Affiche l'interface d'application bloquée
  void _showBlockedUI() {
    // Implémenter l'interface d'application bloquée
    print('Affichage de l\'interface d\'application bloquée');
  }

  /// Affiche un avertissement urgent
  void _showUrgentWarning() {
    // Implémenter l'avertissement urgent
    print('Affichage de l\'avertissement urgent');
  }

  /// Affiche un avertissement d'expiration
  void _showExpirationWarning() {
    // Implémenter l'avertissement d'expiration
    print('Affichage de l\'avertissement d\'expiration');
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await _subscriptionManager.dispose();
  }
}

/// Exemple d'utilisation complète
Future<void> main() async {
  final example = SubscriptionManagerUsageExample();

  try {
    // Initialiser le gestionnaire
    await example.initializeSubscriptionManager();

    // Vérifier le statut
    await example.checkCurrentStatus();

    // Vérifier les notifications
    await example.checkNotifications();

    // Vérifier l'accès à l'application
    await example.checkApplicationAccess();

    // Exemple d'activation de licence
    // await example.activateLicense('VOTRE_CLE_DE_LICENCE');
  } catch (e) {
    print('Erreur: $e');
  } finally {
    // Nettoyer les ressources
    await example.dispose();
  }
}
