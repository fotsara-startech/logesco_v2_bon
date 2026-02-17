import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'license_data.dart';

part 'license_key.g.dart';

/// Structure interne d'une clé de licence avant chiffrement
@JsonSerializable()
class LicenseKeyPayload {
  /// Identifiant unique de l'utilisateur
  final String userId;

  /// Type d'abonnement
  @JsonKey(name: 'type')
  final String subscriptionType;

  /// Date d'émission (ISO 8601)
  final String issued;

  /// Date d'expiration (ISO 8601)
  final String expires;

  /// Hash de l'empreinte de l'appareil
  final String device;

  /// Liste des fonctionnalités activées
  final List<String> features;

  /// Signature RSA de la clé
  final String signature;

  const LicenseKeyPayload({
    required this.userId,
    required this.subscriptionType,
    required this.issued,
    required this.expires,
    required this.device,
    required this.features,
    required this.signature,
  });

  /// Crée une instance depuis JSON
  factory LicenseKeyPayload.fromJson(Map<String, dynamic> json) => _$LicenseKeyPayloadFromJson(json);

  /// Convertit vers JSON
  Map<String, dynamic> toJson() => _$LicenseKeyPayloadToJson(this);

  /// Crée un payload depuis LicenseData
  factory LicenseKeyPayload.fromLicenseData(LicenseData licenseData) {
    return LicenseKeyPayload(
      userId: licenseData.userId,
      subscriptionType: licenseData.subscriptionType.name,
      issued: licenseData.issuedAt.toIso8601String(),
      expires: licenseData.expiresAt.toIso8601String(),
      device: licenseData.deviceFingerprint,
      features: licenseData.metadata['features']?.cast<String>() ?? [],
      signature: licenseData.signature,
    );
  }

  /// Convertit vers LicenseData
  LicenseData toLicenseData(String licenseKey) {
    return LicenseData(
      userId: userId,
      licenseKey: licenseKey,
      subscriptionType: SubscriptionType.values.firstWhere(
        (type) => type.name == subscriptionType,
        orElse: () => SubscriptionType.trial,
      ),
      issuedAt: DateTime.parse(issued),
      expiresAt: DateTime.parse(expires),
      deviceFingerprint: device,
      signature: signature,
      metadata: {
        'features': features,
      },
    );
  }

  /// Valide la structure du payload
  bool isValid() {
    try {
      // Vérifier que les champs obligatoires sont présents
      if (userId.isEmpty || subscriptionType.isEmpty || signature.isEmpty) {
        return false;
      }

      // Vérifier que les dates sont valides
      DateTime.parse(issued);
      DateTime.parse(expires);

      // Vérifier que le type d'abonnement est valide
      final validTypes = SubscriptionType.values.map((e) => e.name).toList();
      if (!validTypes.contains(subscriptionType)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'LicenseKeyPayload(userId: $userId, type: $subscriptionType, expires: $expires)';
  }
}

/// Utilitaires pour la gestion des clés de licence
class LicenseKeyUtils {
  /// Préfixe standard pour les clés de licence
  static const String keyPrefix = 'LOGESCO_';

  /// Version du format de clé
  static const String keyVersion = 'V1';

  /// Sépare les composants d'une clé de licence
  static const String keySeparator = '_';

  /// Encode un payload en clé de licence Base64
  static String encodePayload(LicenseKeyPayload payload) {
    final jsonString = jsonEncode(payload.toJson());
    final bytes = utf8.encode(jsonString);
    final base64String = base64Encode(bytes);

    // Format: LOGESCO_V1_<base64_payload>
    return '$keyPrefix$keyVersion$keySeparator$base64String';
  }

  /// Décode une clé de licence en payload (supporte format court et long)
  static LicenseKeyPayload? decodePayload(String licenseKey) {
    try {
      // Vérifier le format de la clé
      if (!isValidKeyFormat(licenseKey)) {
        return null;
      }

      // Format court: XXXX-XXXX-XXXX-XXXX
      // Accepter A-Z et 0-9 pour rétrocompatibilité
      if (RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(licenseKey)) {
        return _decodeShortFormat(licenseKey);
      }

      // Format long: LOGESCO_V1_<base64>
      // Extraire le payload Base64
      final parts = licenseKey.split(keySeparator);
      if (parts.length != 3) return null;

      final base64Payload = parts[2];

      // Décoder le Base64
      final bytes = base64Decode(base64Payload);
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Créer le payload
      final payload = LicenseKeyPayload.fromJson(json);

      // Valider le payload
      if (!payload.isValid()) {
        return null;
      }

      return payload;
    } catch (e) {
      return null;
    }
  }

  /// Décode une clé au format court XXXX-XXXX-XXXX-XXXX
  static LicenseKeyPayload? _decodeShortFormat(String licenseKey) {
    try {
      // Utiliser le même alphabet que le générateur (sans caractères ambigus)
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final segments = licenseKey.split('-');

      if (segments.length != 4) return null;

      // Décoder les segments
      final typeCode = _decodeSegment(segments[0], alphabet);
      final clientHash = _decodeSegment(segments[1], alphabet);
      final dateCode = _decodeSegment(segments[2], alphabet);
      final deviceHash = _decodeSegment(segments[3], alphabet);

      // Reconstruire les informations
      final type = _getTypeFromCode(typeCode);
      final expirationDate = _decodeDateFromShort(dateCode);
      final now = DateTime.now();

      // Créer un payload simplifié pour le format court
      // Le deviceHash sera vérifié lors de la validation
      return LicenseKeyPayload(
        userId: 'client_$clientHash',
        subscriptionType: type.name,
        issued: now.toIso8601String(),
        expires: expirationDate.toIso8601String(),
        device: deviceHash.toString(), // Stocker le hash pour validation
        features: const [
          'full_inventory',
          'sales',
          'reports',
          'advanced_analytics',
          'cash_register',
          'expense_management',
          'user_management',
          'role_management',
          'backup_restore',
          'multi_device_sync',
        ],
        signature: 'short_format_$licenseKey',
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une clé courte correspond à l'empreinte d'appareil actuelle
  static bool verifyShortFormatDevice(String licenseKey, String deviceFingerprint) {
    try {
      // Utiliser le même alphabet que le générateur (sans caractères ambigus)
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final segments = licenseKey.split('-');

      if (segments.length != 4) return false;

      // Décoder le hash d'appareil de la clé
      final licenseDeviceHash = _decodeSegment(segments[3], alphabet);

      // Calculer le hash de l'empreinte actuelle
      final currentDeviceHash = _hashDeviceFingerprint(deviceFingerprint);

      // Comparer les hash
      return licenseDeviceHash == currentDeviceHash;
    } catch (e) {
      return false;
    }
  }

  /// Hash l'empreinte d'appareil de manière déterministe
  static int _hashDeviceFingerprint(String deviceFingerprint) {
    // Nettoyer l'empreinte (enlever les tirets si présents)
    final cleanFingerprint = deviceFingerprint.replaceAll('-', '');

    // Utiliser le même algorithme que le générateur
    int hash = 0;
    for (int i = 0; i < cleanFingerprint.length; i++) {
      hash = ((hash << 5) - hash + cleanFingerprint.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final fullHash = hash.abs();

    // Réduire le hash pour qu'il tienne dans 4 caractères (32^4 = 1,048,576)
    const maxValue = 32 * 32 * 32 * 32; // 1,048,576
    return fullHash % maxValue;
  }

  /// Décode un segment de clé (cohérent avec l'encodage qui construit de droite à gauche)
  static int _decodeSegment(String segment, String alphabet) {
    int value = 0;
    int multiplier = 1;

    // Décoder de droite à gauche pour être cohérent avec l'encodage
    for (int i = segment.length - 1; i >= 0; i--) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) return 0; // Caractère invalide
      value += charIndex * multiplier;
      multiplier *= alphabet.length;
    }
    return value;
  }

  /// Obtient le type depuis le code
  static SubscriptionType _getTypeFromCode(int code) {
    final typeValue = code % 10;
    switch (typeValue) {
      case 1:
        return SubscriptionType.trial;
      case 2:
        return SubscriptionType.monthly;
      case 3:
        return SubscriptionType.annual;
      case 4:
        return SubscriptionType.lifetime;
      default:
        return SubscriptionType.trial;
    }
  }

  /// Décode une date depuis le format court
  static DateTime _decodeDateFromShort(int dateCode) {
    final year = 2000 + (dateCode ~/ 10000);
    final month = (dateCode % 10000) ~/ 100;
    final day = dateCode % 100;

    try {
      return DateTime(year, month, day);
    } catch (e) {
      // Date invalide, retourner une date dans le futur
      return DateTime.now().add(const Duration(days: 365));
    }
  }

  /// Vérifie si le format de la clé est valide (supporte format court et long)
  static bool isValidKeyFormat(String licenseKey) {
    if (licenseKey.isEmpty) return false;

    // Format court: XXXX-XXXX-XXXX-XXXX (16 caractères + 3 tirets)
    // Accepter A-Z et 0-9 pour rétrocompatibilité
    if (RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(licenseKey)) {
      return true;
    }

    // Format long: LOGESCO_V1_<base64> (rétrocompatibilité)
    if (!licenseKey.startsWith('$keyPrefix$keyVersion$keySeparator')) {
      return false;
    }

    // Vérifier la structure
    final parts = licenseKey.split(keySeparator);
    if (parts.length != 3) return false;

    // Vérifier que le payload Base64 est valide
    try {
      base64Decode(parts[2]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extrait les métadonnées de base d'une clé sans validation complète
  static Map<String, String>? extractKeyMetadata(String licenseKey) {
    try {
      final payload = decodePayload(licenseKey);
      if (payload == null) return null;

      return {
        'userId': payload.userId,
        'type': payload.subscriptionType,
        'issued': payload.issued,
        'expires': payload.expires,
        'version': keyVersion,
      };
    } catch (e) {
      return null;
    }
  }

  /// Génère une clé de licence complète
  static String generateLicenseKey({
    required String userId,
    required SubscriptionType subscriptionType,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required String deviceFingerprint,
    required String signature,
    List<String> features = const [],
  }) {
    final payload = LicenseKeyPayload(
      userId: userId,
      subscriptionType: subscriptionType.name,
      issued: issuedAt.toIso8601String(),
      expires: expiresAt.toIso8601String(),
      device: deviceFingerprint,
      features: features,
      signature: signature,
    );

    return encodePayload(payload);
  }

  /// Valide une clé de licence complète
  static LicenseKeyValidationResult validateLicenseKey(String licenseKey) {
    // Vérifier le format
    if (!isValidKeyFormat(licenseKey)) {
      return LicenseKeyValidationResult.invalid('Format de clé invalide');
    }

    // Décoder le payload
    final payload = decodePayload(licenseKey);
    if (payload == null) {
      return LicenseKeyValidationResult.invalid('Impossible de décoder la clé');
    }

    // Vérifier la validité du payload
    if (!payload.isValid()) {
      return LicenseKeyValidationResult.invalid('Payload de clé invalide');
    }

    // Vérifier l'expiration
    final expirationDate = DateTime.parse(payload.expires);
    if (DateTime.now().isAfter(expirationDate)) {
      return LicenseKeyValidationResult.expired('Clé expirée');
    }

    return LicenseKeyValidationResult.valid(payload);
  }
}

/// Résultat de la validation d'une clé de licence
class LicenseKeyValidationResult {
  /// Indique si la clé est valide
  final bool isValid;

  /// Payload de la clé (si valide)
  final LicenseKeyPayload? payload;

  /// Message d'erreur (si invalide)
  final String? errorMessage;

  /// Indique si la clé est expirée
  final bool isExpired;

  const LicenseKeyValidationResult._({
    required this.isValid,
    this.payload,
    this.errorMessage,
    this.isExpired = false,
  });

  /// Crée un résultat valide
  factory LicenseKeyValidationResult.valid(LicenseKeyPayload payload) {
    return LicenseKeyValidationResult._(
      isValid: true,
      payload: payload,
    );
  }

  /// Crée un résultat invalide
  factory LicenseKeyValidationResult.invalid(String message) {
    return LicenseKeyValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }

  /// Crée un résultat pour une clé expirée
  factory LicenseKeyValidationResult.expired(String message) {
    return LicenseKeyValidationResult._(
      isValid: false,
      errorMessage: message,
      isExpired: true,
    );
  }

  @override
  String toString() {
    if (isValid) {
      return 'LicenseKeyValidationResult(valid: true, payload: $payload)';
    } else {
      return 'LicenseKeyValidationResult(valid: false, error: $errorMessage)';
    }
  }
}
