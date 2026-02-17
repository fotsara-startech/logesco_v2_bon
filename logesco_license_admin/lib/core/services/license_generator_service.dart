import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../../models/license.dart';

/// Service de génération de licences LOGESCO selon les spécifications V1
/// Format: LOGESCO_V1_<payload_base64>
class LicenseGeneratorService {
  /// Toutes les fonctionnalités disponibles (identiques pour tous les types)
  static const List<String> allFeatures = [
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
  ];

  /// Génère une clé de licence courte (16 caractères au format XXXX-XXXX-XXXX-XXXX)
  /// La clé est liée à l'empreinte de l'appareil pour empêcher le partage
  static String generateLicenseKey({
    required String clientId,
    required SubscriptionType type,
    required DateTime expiresAt,
    required String deviceFingerprint,
  }) {
    // Alphabet sans caractères ambigus (O, 0, I, 1, l)
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    // DEBUG: Afficher les paramètres reçus
    print('📝 [LicenseGenerator] Paramètres reçus:');
    print('   deviceFingerprint: "$deviceFingerprint"');
    print('   Longueur: ${deviceFingerprint.length}');

    // Encoder le type (1 caractère)
    final typeCode = _getTypeCode(type);

    // Encoder le client ID (hash sur 4 caractères)
    final clientHash = _hashString(clientId);

    // Encoder la date d'expiration (format court)
    final dateCode = _encodeDateToShort(expiresAt);

    // Encoder l'empreinte d'appareil (hash sur 4 caractères)
    // IMPORTANT: Le deviceFingerprint doit être au format court XXXX-XXXX-XXXX-XXXX
    final deviceHash = _hashDeviceFingerprint(deviceFingerprint);

    print('   deviceHash calculé: $deviceHash');

    // Générer les 4 segments
    final segment1 = _generateSegment(typeCode, alphabet, 4);
    final segment2 = _generateSegment(clientHash, alphabet, 4);
    final segment3 = _generateSegment(dateCode, alphabet, 4);
    final segment4 = _generateSegment(deviceHash, alphabet, 4);

    print('   Segment appareil: $segment4');

    // Assembler la clé au format XXXX-XXXX-XXXX-XXXX
    return '$segment1-$segment2-$segment3-$segment4';
  }

  /// Hash l'empreinte d'appareil de manière déterministe
  /// Accepte le format court XXXX-XXXX-XXXX-XXXX ou long
  static int _hashDeviceFingerprint(String deviceFingerprint) {
    // Nettoyer l'empreinte (enlever les tirets si présents)
    final cleanFingerprint = deviceFingerprint.replaceAll('-', '');

    // Utiliser un hash déterministe
    final fullHash = _hashString(cleanFingerprint);

    // Réduire le hash pour qu'il tienne dans 4 caractères (32^4 = 1,048,576)
    // Utiliser modulo pour garantir que ça tient
    const maxValue = 32 * 32 * 32 * 32; // 1,048,576
    return fullHash % maxValue;
  }

  /// Obtient le code du type de licence
  static int _getTypeCode(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 1;
      case SubscriptionType.monthly:
        return 2;
      case SubscriptionType.annual:
        return 3;
      case SubscriptionType.lifetime:
        return 4;
    }
  }

  /// Hash une chaîne en entier
  static int _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.abs();
  }

  /// Encode une date en format court
  static int _encodeDateToShort(DateTime date) {
    // Encoder année (2 derniers chiffres) + mois + jour
    return (date.year % 100) * 10000 + date.month * 100 + date.day;
  }

  /// Génère un segment de clé (encodage de gauche à droite)
  static String _generateSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;

    // Générer de droite à gauche pour que le décodage soit cohérent
    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }

    return result.padLeft(length, alphabet[0]);
  }

  /// Calcule la date d'expiration selon le type d'abonnement
  static DateTime calculateExpirationDate(SubscriptionType type, [DateTime? from]) {
    final startDate = from ?? DateTime.now();

    switch (type) {
      case SubscriptionType.trial:
        return startDate.add(const Duration(days: 7));
      case SubscriptionType.monthly:
        return startDate.add(const Duration(days: 30));
      case SubscriptionType.annual:
        return startDate.add(const Duration(days: 365));
      case SubscriptionType.lifetime:
        return DateTime.utc(2099, 12, 31, 23, 59, 59, 999);
    }
  }

  /// Génère une signature RSA-SHA256
  /// NOTE: Cette implémentation utilise une signature simplifiée pour le développement.
  /// En production, vous devez implémenter une vraie signature RSA avec votre clé privée.
  ///
  /// Pour générer une vraie signature RSA en production:
  /// 1. Générez une paire de clés RSA 2048 bits avec OpenSSL
  /// 2. Intégrez la clé privée de manière sécurisée
  /// 3. Utilisez pointycastle RSASigner avec votre clé privée
  /// 4. Intégrez la clé publique dans l'application LOGESCO
  static String _generateRsaSignature(String data) {
    try {
      // Pour le développement, on génère une signature basée sur SHA-256
      // IMPORTANT: En production, remplacer par une vraie signature RSA-SHA256
      final dataBytes = utf8.encode(data);
      final hash = SHA256Digest().process(Uint8List.fromList(dataBytes));

      // Simuler une signature RSA (256 bytes pour RSA 2048)
      // En production, utiliser une vraie clé privée RSA
      final signatureData = Uint8List(256);
      for (int i = 0; i < hash.length && i < signatureData.length; i++) {
        signatureData[i] = hash[i];
      }
      // Remplir le reste avec un pattern dérivé du hash
      for (int i = hash.length; i < signatureData.length; i++) {
        signatureData[i] = hash[i % hash.length];
      }

      return base64Encode(signatureData);
    } catch (e) {
      // Fallback: signature de développement
      final dataBytes = utf8.encode('DEV_SIGNATURE_$data');
      final hash = SHA256Digest().process(Uint8List.fromList(dataBytes));
      return base64Encode(hash);
    }
  }

  /// Génère une empreinte d'appareil temporaire
  static String generateTempDeviceFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString();
    final bytes = utf8.encode('TEMP_$random');
    final hash = SHA256Digest().process(Uint8List.fromList(bytes));
    return base64Encode(hash).substring(0, 32).toUpperCase();
  }

  /// Valide le format d'une clé de licence (format court XXXX-XXXX-XXXX-XXXX)
  static bool isValidKeyFormat(String key) {
    // Format court: XXXX-XXXX-XXXX-XXXX (16 caractères + 3 tirets)
    return RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$').hasMatch(key);
  }

  /// Décode une clé de licence pour inspection
  static Map<String, dynamic>? decodeLicenseKey(String licenseKey) {
    try {
      if (!isValidKeyFormat(licenseKey)) return null;

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

      return {
        'type': type.name,
        'clientHash': clientHash,
        'expirationDate': expirationDate.toIso8601String(),
        'deviceHash': deviceHash,
        'deviceHashValue': deviceHash, // Valeur numérique pour validation
      };
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une clé de licence correspond à une empreinte d'appareil
  static bool verifyDeviceFingerprint(String licenseKey, String deviceFingerprint) {
    try {
      final decoded = decodeLicenseKey(licenseKey);
      if (decoded == null) return false;

      final expectedDeviceHash = _hashDeviceFingerprint(deviceFingerprint);
      final actualDeviceHash = decoded['deviceHashValue'] as int;

      return expectedDeviceHash == actualDeviceHash;
    } catch (e) {
      return false;
    }
  }

  /// Décode un segment de clé
  static int _decodeSegment(String segment, String alphabet) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      value = value * alphabet.length + alphabet.indexOf(segment[i]);
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

  /// Obtient la durée en jours pour un type d'abonnement
  static int getDurationInDays(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 7;
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.annual:
        return 365;
      case SubscriptionType.lifetime:
        return 36500; // ~100 ans
    }
  }

  /// Obtient le label descriptif d'un type d'abonnement
  static String getTypeDescription(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 'Période d\'essai gratuite - Accès complet pendant 7 jours';
      case SubscriptionType.monthly:
        return 'Abonnement mensuel - Accès complet pendant 30 jours';
      case SubscriptionType.annual:
        return 'Abonnement annuel - Accès complet pendant 365 jours';
      case SubscriptionType.lifetime:
        return 'Licence permanente - Accès complet à vie';
    }
  }
}
