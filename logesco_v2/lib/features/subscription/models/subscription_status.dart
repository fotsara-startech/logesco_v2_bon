import 'package:json_annotation/json_annotation.dart';
import 'license_data.dart';

part 'subscription_status.g.dart';

/// Statut actuel de l'abonnement
@JsonSerializable()
class SubscriptionStatus {
  /// Indique si l'abonnement est actif
  final bool isActive;

  /// Type d'abonnement actuel
  final SubscriptionType type;

  /// Date d'expiration de l'abonnement
  final DateTime? expirationDate;

  /// Nombre de jours restants
  final int? remainingDays;

  /// Indique si l'abonnement est dans la période de grâce
  final bool isInGracePeriod;

  /// Liste des avertissements ou messages
  final List<String> warnings;

  const SubscriptionStatus({
    required this.isActive,
    required this.type,
    this.expirationDate,
    this.remainingDays,
    this.isInGracePeriod = false,
    this.warnings = const [],
  });

  /// Crée une instance depuis JSON
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) => _$SubscriptionStatusFromJson(json);

  /// Convertit vers JSON
  Map<String, dynamic> toJson() => _$SubscriptionStatusToJson(this);

  /// Crée un statut pour une période d'essai active
  factory SubscriptionStatus.trialActive({
    required int remainingDays,
    List<String> warnings = const [],
  }) {
    return SubscriptionStatus(
      isActive: true,
      type: SubscriptionType.trial,
      remainingDays: remainingDays,
      warnings: warnings,
    );
  }

  /// Crée un statut pour un abonnement payant actif
  factory SubscriptionStatus.subscriptionActive({
    required SubscriptionType type,
    required DateTime expirationDate,
    required int remainingDays,
    List<String> warnings = const [],
  }) {
    return SubscriptionStatus(
      isActive: true,
      type: type,
      expirationDate: expirationDate,
      remainingDays: remainingDays,
      warnings: warnings,
    );
  }

  /// Crée un statut pour un abonnement expiré
  factory SubscriptionStatus.expired({
    required SubscriptionType type,
    required DateTime expirationDate,
    bool isInGracePeriod = false,
    List<String> warnings = const [],
  }) {
    return SubscriptionStatus(
      isActive: false,
      type: type,
      expirationDate: expirationDate,
      remainingDays: 0,
      isInGracePeriod: isInGracePeriod,
      warnings: warnings,
    );
  }

  /// Indique si des notifications d'expiration doivent être affichées
  bool get shouldShowExpirationWarning {
    return isActive && remainingDays != null && remainingDays! <= 3;
  }

  /// Indique si une notification urgente doit être affichée
  bool get shouldShowUrgentWarning {
    return isActive && remainingDays != null && remainingDays! <= 1;
  }

  @override
  String toString() {
    return 'SubscriptionStatus(active: $isActive, type: $type, remaining: $remainingDays days)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionStatus &&
        other.isActive == isActive &&
        other.type == type &&
        other.expirationDate == expirationDate &&
        other.remainingDays == remainingDays &&
        other.isInGracePeriod == isInGracePeriod;
  }

  @override
  int get hashCode {
    return isActive.hashCode ^ type.hashCode ^ expirationDate.hashCode ^ remainingDays.hashCode ^ isInGracePeriod.hashCode;
  }
}
