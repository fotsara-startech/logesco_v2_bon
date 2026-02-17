import '../../../subscription/models/device_fingerprint.dart';

/// Interface pour le service d'empreinte d'appareil
abstract class IDeviceService {
  /// Génère une empreinte unique de l'appareil
  Future<String> generateDeviceFingerprint();

  /// Vérifie si l'empreinte stockée correspond à l'appareil actuel
  Future<bool> verifyDeviceFingerprint(String storedFingerprint);

  /// Obtient les informations détaillées de l'appareil
  Future<Map<String, String>> getDeviceInfo();

  /// Crée un objet DeviceFingerprint complet
  Future<DeviceFingerprint> createDeviceFingerprint();

  /// Stocke l'empreinte de manière sécurisée
  Future<void> storeDeviceFingerprint(DeviceFingerprint fingerprint);

  /// Récupère l'empreinte stockée
  Future<DeviceFingerprint?> getStoredFingerprint();

  /// Détecte si l'appareil a changé significativement
  Future<bool> hasDeviceChanged();

  /// Met à jour l'empreinte si nécessaire
  Future<void> updateFingerprintIfNeeded();

  /// Nettoie les données d'empreinte
  Future<void> clearStoredFingerprint();

  /// Valide l'intégrité de l'empreinte stockée
  Future<bool> validateStoredFingerprintIntegrity();

  /// Récupère l'empreinte archivée pour audit
  Future<Map<String, dynamic>?> getArchivedFingerprint();

  /// Effectue une vérification complète de cohérence
  Future<Map<String, dynamic>> performConsistencyCheck();
}
