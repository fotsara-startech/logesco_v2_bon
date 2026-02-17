import '../../../subscription/models/subscription_status.dart';

/// Interface principale pour la gestion des abonnements
abstract class ISubscriptionManager {
  /// Obtient le statut actuel de l'abonnement
  Future<SubscriptionStatus> getCurrentStatus();

  /// Active une licence avec une clé d'activation
  Future<bool> activateLicense(String licenseKey);

  /// Démarre la période d'essai gratuite
  Future<void> startTrialPeriod();

  /// Vérifie si la période d'essai est active
  Future<bool> isTrialActive();

  /// Obtient le nombre de jours restants de la période d'essai
  Future<int> getRemainingTrialDays();

  /// Obtient la date d'expiration de l'abonnement actuel
  Future<DateTime?> getExpirationDate();

  /// Stream des changements de statut d'abonnement
  Stream<SubscriptionStatus> get statusStream;

  /// Initialise le gestionnaire d'abonnements
  Future<void> initialize();

  /// Effectue une validation périodique de la licence
  Future<void> performPeriodicValidation();

  /// Vérifie si l'application doit être bloquée
  Future<bool> shouldBlockApplication();

  /// Obtient les notifications d'expiration à afficher
  Future<List<String>> getExpirationNotifications();

  /// Récupère la licence actuellement active
  Future<dynamic> getCurrentLicense();

  /// Récupère l'empreinte de l'appareil
  Future<String> getDeviceFingerprint();

  /// Réinitialise complètement la licence et la période d'essai
  /// ⚠️ ATTENTION: Supprime toutes les données de licence
  Future<void> resetLicenseData();

  /// Libère les ressources utilisées
  Future<void> dispose();
}
