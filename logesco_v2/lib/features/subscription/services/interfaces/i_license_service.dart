import '../../../subscription/models/license_data.dart';
import '../../../subscription/models/license_errors.dart';

/// Résultat de la validation d'une licence
class LicenseValidationResult {
  /// Indique si la validation a réussi
  final bool isValid;

  /// Données de la licence si valide
  final LicenseData? licenseData;

  /// Erreur si la validation a échoué
  final LicenseException? error;

  /// Messages d'avertissement
  final List<String> warnings;

  const LicenseValidationResult({
    required this.isValid,
    this.licenseData,
    this.error,
    this.warnings = const [],
  });

  /// Crée un résultat de validation réussie
  factory LicenseValidationResult.success(
    LicenseData licenseData, [
    List<String> warnings = const [],
  ]) {
    return LicenseValidationResult(
      isValid: true,
      licenseData: licenseData,
      warnings: warnings,
    );
  }

  /// Crée un résultat de validation échouée
  factory LicenseValidationResult.failure(
    LicenseException error, [
    List<String> warnings = const [],
  ]) {
    return LicenseValidationResult(
      isValid: false,
      error: error,
      warnings: warnings,
    );
  }
}

/// Interface pour le service de validation des licences
abstract class ILicenseService {
  /// Valide une clé de licence
  Future<LicenseValidationResult> validateLicense(String licenseKey);

  /// Vérifie si la licence stockée est valide
  Future<bool> isLicenseValid();

  /// Stocke une licence de manière sécurisée
  Future<void> storeLicense(LicenseData license);

  /// Récupère la licence stockée
  Future<LicenseData?> getStoredLicense();

  /// Révoque la licence actuelle
  Future<void> revokeLicense();

  /// Vérifie l'intégrité de la licence stockée
  Future<bool> verifyLicenseIntegrity();

  /// Obtient les informations de la licence sans validation complète
  Future<LicenseData?> getLicenseInfo();

  /// Nettoie les données de licence corrompues
  Future<void> cleanupCorruptedLicense();
}
