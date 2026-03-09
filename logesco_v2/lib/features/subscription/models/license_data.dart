import 'package:json_annotation/json_annotation.dart';

part 'license_data.g.dart';

/// Types d'abonnement disponibles
enum SubscriptionType {
  @JsonValue('trial')
  trial,
  @JsonValue('monthly')
  monthly,
  @JsonValue('annual')
  annual,
  @JsonValue('lifetime')
  lifetime,
}

/// Modèle de données pour une licence d'abonnement
@JsonSerializable()
class LicenseData {
  /// Identifiant unique de l'utilisateur
  final String userId;

  /// Clé de licence d'activation
  final String licenseKey;

  /// Type d'abonnement
  final SubscriptionType subscriptionType;

  /// Date d'émission de la licence
  final DateTime issuedAt;

  /// Date d'expiration de la licence
  final DateTime expiresAt;

  /// Empreinte unique de l'appareil
  final String deviceFingerprint;

  /// Signature cryptographique de la licence
  final String signature;

  /// Métadonnées additionnelles
  final Map<String, dynamic> metadata;

  const LicenseData({
    required this.userId,
    required this.licenseKey,
    required this.subscriptionType,
    required this.issuedAt,
    required this.expiresAt,
    required this.deviceFingerprint,
    required this.signature,
    this.metadata = const {},
  });

  /// Crée une instance depuis JSON
  factory LicenseData.fromJson(Map<String, dynamic> json) => _$LicenseDataFromJson(json);

  /// Convertit vers JSON
  Map<String, dynamic> toJson() => _$LicenseDataToJson(this);

  /// Vérifie si la licence est expirée
  ///
  /// ATTENTION: Cette méthode utilise DateTime.now() qui peut être manipulé.
  /// Pour une vérification sécurisée, utilisez isExpiredSecure() avec SecureTimeService.
  @Deprecated('Utilisez isExpiredSecure() avec SecureTimeService pour une validation sécurisée')
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Vérifie si la licence est expirée avec un temps sécurisé
  bool isExpiredSecure(DateTime secureTime) => secureTime.isAfter(expiresAt);

  /// Vérifie si la licence est dans la période de grâce (3 jours après expiration)
  ///
  /// ATTENTION: Cette méthode utilise DateTime.now() qui peut être manipulé.
  /// Pour une vérification sécurisée, utilisez isInGracePeriodSecure() avec SecureTimeService.
  @Deprecated('Utilisez isInGracePeriodSecure() avec SecureTimeService pour une validation sécurisée')
  bool get isInGracePeriod {
    if (!isExpired) return false;
    final gracePeriodEnd = expiresAt.add(const Duration(days: 3));
    return DateTime.now().isBefore(gracePeriodEnd);
  }

  /// Vérifie si la licence est dans la période de grâce avec un temps sécurisé
  bool isInGracePeriodSecure(DateTime secureTime) {
    if (!isExpiredSecure(secureTime)) return false;
    final gracePeriodEnd = expiresAt.add(const Duration(days: 3));
    return secureTime.isBefore(gracePeriodEnd);
  }

  /// Calcule les jours restants avant expiration
  ///
  /// ATTENTION: Cette méthode utilise DateTime.now() qui peut être manipulé.
  /// Pour un calcul sécurisé, utilisez remainingDaysSecure() avec SecureTimeService.
  @Deprecated('Utilisez remainingDaysSecure() avec SecureTimeService pour un calcul sécurisé')
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// Calcule les jours restants avant expiration avec un temps sécurisé
  int remainingDaysSecure(DateTime secureTime) {
    if (secureTime.isAfter(expiresAt)) return 0;
    return expiresAt.difference(secureTime).inDays;
  }

  @override
  String toString() {
    return 'LicenseData(userId: $userId, type: $subscriptionType, expires: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LicenseData && other.userId == userId && other.licenseKey == licenseKey && other.subscriptionType == subscriptionType;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ licenseKey.hashCode ^ subscriptionType.hashCode;
  }
}
