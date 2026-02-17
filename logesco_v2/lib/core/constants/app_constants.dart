/// Constantes globales de l'application LOGESCO v2
class AppConstants {
  // Informations de l'application
  static const String appName = 'LOGESCO v2';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Système de gestion commerciale moderne';

  // Configuration API
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  // Configuration de session
  static const int sessionDurationMinutes = 30;
  static const int maxLoginAttempts = 3;
  static const int lockoutDurationMinutes = 15;

  // Configuration de pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuration de recherche
  static const int searchDebounceMilliseconds = 500;
  static const int minSearchLength = 2;

  // Configuration de stock
  static const int defaultStockMinimum = 5;
  static const int stockAlertThreshold = 10;

  // Formats de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Clés de stockage local
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // Messages d'erreur par défaut
  static const String networkErrorMessage = 'Erreur de connexion réseau';
  static const String serverErrorMessage = 'Erreur du serveur';
  static const String unknownErrorMessage = 'Erreur inconnue';
  static const String sessionExpiredMessage = 'Session expirée, veuillez vous reconnecter';

  // Statuts des transactions
  static const String statusPending = 'en_attente';
  static const String statusPartial = 'partielle';
  static const String statusCompleted = 'terminee';
  static const String statusCancelled = 'annulee';

  // Modes de paiement
  static const String paymentCash = 'comptant';
  static const String paymentCredit = 'credit';

  // Types de mouvements de stock
  static const String stockMovementPurchase = 'achat';
  static const String stockMovementSale = 'vente';
  static const String stockMovementAdjustment = 'ajustement';
  static const String stockMovementReturn = 'retour';

  // Types de transactions de compte
  static const String transactionDebit = 'debit';
  static const String transactionCredit = 'credit';
  static const String transactionPayment = 'paiement';
  static const String transactionPurchase = 'achat';
}
