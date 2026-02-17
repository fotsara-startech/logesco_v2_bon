/// Types d'erreurs liées aux licences
enum LicenseError {
  /// Clé d'activation invalide ou malformée
  invalidKey,

  /// Licence expirée
  expiredLicense,

  /// L'appareil ne correspond pas à celui enregistré
  deviceMismatch,

  /// Tentative de manipulation détectée
  tamperingDetected,

  /// Échec de la validation cryptographique
  cryptographicFailure,

  /// Erreur de stockage local
  storageError,

  /// Erreur réseau (si applicable)
  networkError,

  /// Licence déjà utilisée sur un autre appareil
  licenseAlreadyUsed,

  /// Licence révoquée
  licenseRevoked,

  /// Format de clé non reconnu
  unsupportedKeyFormat,
}

/// Exception personnalisée pour les erreurs de licence
class LicenseException implements Exception {
  /// Type d'erreur
  final LicenseError error;

  /// Message d'erreur principal
  final String message;

  /// Détails additionnels sur l'erreur
  final String? details;

  /// Code d'erreur pour le support technique
  final String? errorCode;

  const LicenseException(
    this.error,
    this.message, [
    this.details,
    this.errorCode,
  ]);

  /// Messages d'erreur localisés
  String get localizedMessage {
    switch (error) {
      case LicenseError.invalidKey:
        return 'Clé d\'activation invalide. Veuillez vérifier la clé saisie.';
      case LicenseError.expiredLicense:
        return 'Votre abonnement a expiré. Veuillez renouveler votre licence.';
      case LicenseError.deviceMismatch:
        return 'Cette licence est liée à un autre appareil. Contactez le support pour un transfert.';
      case LicenseError.tamperingDetected:
        return 'Tentative de manipulation détectée. L\'application va se fermer.';
      case LicenseError.cryptographicFailure:
        return 'Erreur de validation de sécurité. Veuillez réinstaller l\'application.';
      case LicenseError.storageError:
        return 'Erreur de stockage des données de licence. Vérifiez l\'espace disponible.';
      case LicenseError.networkError:
        return 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
      case LicenseError.licenseAlreadyUsed:
        return 'Cette licence est déjà utilisée sur un autre appareil.';
      case LicenseError.licenseRevoked:
        return 'Cette licence a été révoquée. Contactez le support.';
      case LicenseError.unsupportedKeyFormat:
        return 'Format de clé non supporté. Utilisez une clé récente.';
    }
  }

  /// Indique si l'erreur est récupérable
  bool get isRecoverable {
    switch (error) {
      case LicenseError.invalidKey:
      case LicenseError.expiredLicense:
      case LicenseError.deviceMismatch:
      case LicenseError.storageError:
      case LicenseError.networkError:
        return true;
      case LicenseError.tamperingDetected:
      case LicenseError.cryptographicFailure:
      case LicenseError.licenseRevoked:
        return false;
      case LicenseError.licenseAlreadyUsed:
      case LicenseError.unsupportedKeyFormat:
        return true;
    }
  }

  /// Indique si l'application doit être bloquée
  bool get shouldBlockApp {
    switch (error) {
      case LicenseError.tamperingDetected:
      case LicenseError.cryptographicFailure:
      case LicenseError.licenseRevoked:
        return true;
      default:
        return false;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('LicenseException: $message');
    if (details != null) {
      buffer.write(' ($details)');
    }
    if (errorCode != null) {
      buffer.write(' [Code: $errorCode]');
    }
    return buffer.toString();
  }
}
