/// Générateur de clé de licence standalone
/// Utilise exactement le même algorithme que logesco_v2 attend
import 'dart:io';

enum SubscriptionType { trial, monthly, annual, lifetime }

class KeyGenerator {
  /// Génère une clé de licence liée à l'appareil
  static String generateLicenseKey({
    required String clientId,
    required SubscriptionType type,
    required DateTime expiresAt,
    required String deviceFingerprint,
  }) {
    // Alphabet sans caractères ambigus (même que logesco_license_admin)
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    print('🔑 Génération de clé avec:');
    print('   Client ID: $clientId');
    print('   Type: $type');
    print('   Expire: $expiresAt');
    print('   Empreinte: "$deviceFingerprint"');
    print('');

    // Encoder le type
    final typeCode = _getTypeCode(type);
    print('   Type code: $typeCode');

    // Encoder le client ID
    final clientHash = _hashString(clientId);
    print('   Client hash: $clientHash');

    // Encoder la date d'expiration
    final dateCode = _encodeDateToShort(expiresAt);
    print('   Date code: $dateCode');

    // Encoder l'empreinte d'appareil
    final deviceHash = _hashDeviceFingerprint(deviceFingerprint);
    print('   Device hash: $deviceHash');
    print('');

    // Générer les 4 segments
    final segment1 = _generateSegment(typeCode, alphabet, 4);
    final segment2 = _generateSegment(clientHash, alphabet, 4);
    final segment3 = _generateSegment(dateCode, alphabet, 4);
    final segment4 = _generateSegment(deviceHash, alphabet, 4);

    print('   Segments:');
    print('     1. Type: $segment1');
    print('     2. Client: $segment2');
    print('     3. Date: $segment3');
    print('     4. Appareil: $segment4');
    print('');

    // Assembler la clé
    final licenseKey = '$segment1-$segment2-$segment3-$segment4';
    print('✅ Clé générée: $licenseKey');

    return licenseKey;
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

  /// Hash l'empreinte d'appareil
  static int _hashDeviceFingerprint(String deviceFingerprint) {
    final cleanFingerprint = deviceFingerprint.replaceAll('-', '');
    return _hashString(cleanFingerprint);
  }

  /// Encode une date en format court
  static int _encodeDateToShort(DateTime date) {
    return (date.year % 100) * 10000 + date.month * 100 + date.day;
  }

  /// Génère un segment de clé
  static String _generateSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;

    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }

    return result.padLeft(length, alphabet[0]);
  }

  /// Vérifie si une clé correspond à une empreinte
  static bool verifyKey(String licenseKey, String deviceFingerprint) {
    try {
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final segments = licenseKey.split('-');

      if (segments.length != 4) return false;

      // Décoder le hash d'appareil de la clé
      int decodeSegment(String segment) {
        int value = 0;
        for (int i = 0; i < segment.length; i++) {
          value = value * alphabet.length + alphabet.indexOf(segment[i]);
        }
        return value;
      }

      final keyDeviceHash = decodeSegment(segments[3]);
      final currentDeviceHash = _hashDeviceFingerprint(deviceFingerprint);

      return keyDeviceHash == currentDeviceHash;
    } catch (e) {
      return false;
    }
  }
}

void main() {
  print('🚀 Générateur de clé de licence LOGESCO\n');

  // Paramètres
  const clientId = 'test_client';
  const type = SubscriptionType.trial;
  final expiresAt = DateTime.now().add(const Duration(days: 7));
  const deviceFingerprint = '98D6-QP3C-FVMZ-4L3P';

  // Générer la clé
  final licenseKey = KeyGenerator.generateLicenseKey(
    clientId: clientId,
    type: type,
    expiresAt: expiresAt,
    deviceFingerprint: deviceFingerprint,
  );

  print('\n🧪 Vérification:');
  final isValid = KeyGenerator.verifyKey(licenseKey, deviceFingerprint);
  print('   Clé valide pour cet appareil: $isValid');

  print('\n📋 Résumé:');
  print('   Empreinte d\'appareil: $deviceFingerprint');
  print('   Clé de licence: $licenseKey');
  print('   Type: ${type.name}');
  print('   Expire: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}');

  if (isValid) {
    print('\n✅ Cette clé devrait fonctionner dans logesco_v2!');
  } else {
    print('\n❌ Erreur dans la génération!');
  }
}
