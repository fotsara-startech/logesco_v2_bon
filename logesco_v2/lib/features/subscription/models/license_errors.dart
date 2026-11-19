import 'package:get/get.dart';
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

  /// Manipulation de l'horloge système détectée
  timeManipulation,

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
        return 'subscription_cle_activation_invalide_veuillez_verifier_cle'.tr;
      case LicenseError.expiredLicense:
        return 'subscription_votre_abonnement_expire_veuillez_renouveler_votre'.tr;
      case LicenseError.deviceMismatch:
        return 'subscription_licence_est_liee_autre_appareil_contactez'.tr;
      case LicenseError.tamperingDetected:
        return 'subscription_tentative_manipulation_detectee_application_va_se'.tr;
      case LicenseError.timeManipulation:
        return 'subscription_manipulation_horloge_systeme_detectee_veuillez_restaurer'.tr;
      case LicenseError.cryptographicFailure:
        return 'subscription_erreur_validation_securite_veuillez_reinstaller_application'.tr;
      case LicenseError.storageError:
        return 'subscription_erreur_stockage_donnees_licence_verifiez_espace'.tr;
      case LicenseError.networkError:
        return 'financialmovements_erreur_connexion_reseau_verifiez_votre_connexion'.tr;
      case LicenseError.licenseAlreadyUsed:
        return 'subscription_licence_est_deja_utilisee_sur_autre'.tr;
      case LicenseError.licenseRevoked:
        return 'subscription_licence_ete_revoquee_contactez_support'.tr;
      case LicenseError.unsupportedKeyFormat:
        return 'subscription_format_cle_non_supporte_utilisez_cle'.tr;
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
      case LicenseError.timeManipulation:
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
      case LicenseError.timeManipulation:
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
