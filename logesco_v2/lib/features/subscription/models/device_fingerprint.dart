import 'package:json_annotation/json_annotation.dart';

part 'device_fingerprint.g.dart';

/// Empreinte unique d'un appareil
@JsonSerializable()
class DeviceFingerprint {
  /// Identifiant unique de l'appareil
  final String deviceId;

  /// Plateforme (Android, iOS, Windows, etc.)
  final String platform;

  /// Version du système d'exploitation
  final String osVersion;

  /// Version de l'application
  final String appVersion;

  /// Identifiant matériel unique
  final String hardwareId;

  /// Hash combiné de toutes les caractéristiques
  final String combinedHash;

  /// Date de génération de l'empreinte
  final DateTime generatedAt;

  const DeviceFingerprint({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.hardwareId,
    required this.combinedHash,
    required this.generatedAt,
  });

  /// Crée une instance depuis JSON
  factory DeviceFingerprint.fromJson(Map<String, dynamic> json) => _$DeviceFingerprintFromJson(json);

  /// Convertit vers JSON
  Map<String, dynamic> toJson() => _$DeviceFingerprintToJson(this);

  /// Vérifie si l'empreinte correspond à une autre
  bool matches(DeviceFingerprint other) {
    return combinedHash == other.combinedHash;
  }

  /// Vérifie si l'empreinte est encore valide (pas trop ancienne)
  bool get isValid {
    final maxAge = DateTime.now().subtract(const Duration(days: 30));
    return generatedAt.isAfter(maxAge);
  }

  @override
  String toString() {
    return 'DeviceFingerprint(platform: $platform, hash: ${combinedHash.substring(0, 8)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceFingerprint && other.combinedHash == combinedHash;
  }

  @override
  int get hashCode => combinedHash.hashCode;
}
