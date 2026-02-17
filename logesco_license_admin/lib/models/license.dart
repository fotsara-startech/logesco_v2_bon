import 'package:json_annotation/json_annotation.dart';

part 'license.g.dart';

enum SubscriptionType {
  trial, // 7 jours
  monthly, // 30 jours
  annual, // 365 jours
  lifetime, // Jusqu'au 31/12/2099
}

enum LicenseStatus {
  active,
  expired,
  revoked,
  suspended,
}

@JsonSerializable()
class License {
  final String id;
  final String clientId;
  final String licenseKey;
  final SubscriptionType type;
  final LicenseStatus status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String deviceFingerprint;
  final List<String> features;
  final double? price;
  final String? currency;
  final String? notes;
  final DateTime? revokedAt;
  final String? revocationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const License({
    required this.id,
    required this.clientId,
    required this.licenseKey,
    required this.type,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    required this.deviceFingerprint,
    this.features = const [],
    this.price,
    this.currency = 'EUR',
    this.notes,
    this.revokedAt,
    this.revocationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory License.fromJson(Map<String, dynamic> json) => _$LicenseFromJson(json);
  Map<String, dynamic> toJson() => _$LicenseToJson(this);

  License copyWith({
    String? id,
    String? clientId,
    String? licenseKey,
    SubscriptionType? type,
    LicenseStatus? status,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? deviceFingerprint,
    List<String>? features,
    double? price,
    String? currency,
    String? notes,
    DateTime? revokedAt,
    String? revocationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return License(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      licenseKey: licenseKey ?? this.licenseKey,
      type: type ?? this.type,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      features: features ?? this.features,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      revokedAt: revokedAt ?? this.revokedAt,
      revocationReason: revocationReason ?? this.revocationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters utiles
  bool get isActive => status == LicenseStatus.active && !isExpired;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isRevoked => status == LicenseStatus.revoked;

  int get daysRemaining {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  String get statusLabel {
    switch (status) {
      case LicenseStatus.active:
        return isExpired ? 'Expirée' : 'Active';
      case LicenseStatus.expired:
        return 'Expirée';
      case LicenseStatus.revoked:
        return 'Révoquée';
      case LicenseStatus.suspended:
        return 'Suspendue';
    }
  }

  String get typeLabel {
    switch (type) {
      case SubscriptionType.trial:
        return 'Essai (7 jours)';
      case SubscriptionType.monthly:
        return 'Mensuel (30 jours)';
      case SubscriptionType.annual:
        return 'Annuel (365 jours)';
      case SubscriptionType.lifetime:
        return 'À vie';
    }
  }

  @override
  String toString() {
    return 'License(id: $id, clientId: $clientId, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is License && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
