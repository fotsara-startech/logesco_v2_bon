/// Diagnostic complet pour les clés du client
/// Clé appareil: G6LD-4MV4-JU4L-SC4Y
/// Clé licence: AAAB-H2MG-H8LE-7VEY
/// Clé universelle: AAAB-H2MG-H8LE-8ST9

void main() {
  // Alphabet utilisé par le GÉNÉRATEUR (logesco_license_admin)
  const alphabetGenerator = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans O,0,I,1,l

  // Alphabet utilisé dans test_real_key.dart (MAUVAIS alphabet)
  const alphabetOld = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; // avec tous les caractères

  print('=== DIAGNOSTIC CLÉS CLIENT ===\n');
  print('Clé appareil (device fingerprint): G6LD-4MV4-JU4L-SC4Y');
  print('Clé licence: AAAB-H2MG-H8LE-7VEY');
  print('Clé universelle: AAAB-H2MG-H8LE-8ST9\n');

  // ---- Fonction de décodage (utilisée dans license_key.dart - de droite à gauche) ----
  int decodeSegmentRTL(String segment, String alphabet) {
    int value = 0;
    int multiplier = 1;
    for (int i = segment.length - 1; i >= 0; i--) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) return -1;
      value += charIndex * multiplier;
      multiplier *= alphabet.length;
    }
    return value;
  }

  // ---- Fonction de décodage (utilisée dans license_generator_service.dart - de gauche à droite) ----
  int decodeSegmentLTR(String segment, String alphabet) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      value = value * alphabet.length + alphabet.indexOf(segment[i]);
    }
    return value;
  }

  // ---- Fonction d'encodage (utilisée dans license_generator_service.dart) ----
  String encodeSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;
    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }
    return result.padLeft(length, alphabet[0]);
  }

  // ---- Hash de l'empreinte d'appareil ----
  int hashDeviceFingerprint(String fingerprint) {
    final clean = fingerprint.replaceAll('-', '').toUpperCase();
    int hash = 0;
    for (int i = 0; i < clean.length; i++) {
      hash = ((hash << 5) - hash + clean.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final fullHash = hash.abs();
    const maxValue = 32 * 32 * 32 * 32; // 1,048,576
    return fullHash % maxValue;
  }

  // ============================================================
  print('--- 1. ANALYSE DE LA CLÉ UNIVERSELLE ---');
  const universalKey = 'AAAB-H2MG-H8LE-8ST9';
  final uSegments = universalKey.split('-');

  final uDeviceHashRTL = decodeSegmentRTL(uSegments[3], alphabetGenerator);
  final uDeviceHashLTR = decodeSegmentLTR(uSegments[3], alphabetGenerator);

  print('Segment appareil de la clé universelle: ${uSegments[3]}');
  print('Hash décodé (RTL - méthode license_key.dart): $uDeviceHashRTL');
  print('Hash décodé (LTR - méthode license_generator): $uDeviceHashLTR');
  print('Valeur magique attendue: 999999');
  print('RTL == 999999: ${uDeviceHashRTL == 999999}');
  print('LTR == 999999: ${uDeviceHashLTR == 999999}');

  // Quel segment encode 999999 ?
  final expectedUniversalSegment = encodeSegment(999999, alphabetGenerator, 4);
  print('Segment attendu pour 999999: $expectedUniversalSegment');
  print('Segment dans la clé: ${uSegments[3]}');
  print('Match: ${uSegments[3] == expectedUniversalSegment}\n');

  // ============================================================
  print('--- 2. ANALYSE DE LA CLÉ NORMALE ---');
  const licenseKey = 'AAAB-H2MG-H8LE-7VEY';
  const deviceFingerprint = 'G6LD-4MV4-JU4L-SC4Y';

  final lSegments = licenseKey.split('-');
  final lDeviceHashRTL = decodeSegmentRTL(lSegments[3], alphabetGenerator);
  final lDeviceHashLTR = decodeSegmentLTR(lSegments[3], alphabetGenerator);

  print('Segment appareil de la clé licence: ${lSegments[3]}');
  print('Hash décodé (RTL): $lDeviceHashRTL');
  print('Hash décodé (LTR): $lDeviceHashLTR');

  // Hash de l'empreinte de l'appareil du client
  final clientDeviceHash = hashDeviceFingerprint(deviceFingerprint);
  print('\nEmpreinte appareil client: $deviceFingerprint');
  print('Hash calculé de l\'empreinte: $clientDeviceHash');

  final expectedSegment = encodeSegment(clientDeviceHash, alphabetGenerator, 4);
  print('Segment attendu pour cet appareil: $expectedSegment');
  print('Segment dans la clé: ${lSegments[3]}');
  print('RTL match: ${lDeviceHashRTL == clientDeviceHash}');
  print('LTR match: ${lDeviceHashLTR == clientDeviceHash}\n');

  // ============================================================
  print('--- 3. DIAGNOSTIC DU PROBLÈME ---');

  // Vérifier si le générateur et le validateur utilisent le même sens de décodage
  // Générateur: _generateSegment encode de droite à gauche
  // license_key.dart: _decodeSegment décode de droite à gauche (RTL) ✓
  // license_generator_service.dart: _decodeSegment décode de gauche à droite (LTR) ✗

  print('Le générateur encode: de droite à gauche (result = alphabet[remaining % len] + result)');
  print('license_key.dart décode: de droite à gauche (RTL) ✓');
  print('license_generator_service.dart décode: de gauche à droite (LTR) ✗\n');

  // Vérifier si la clé a été générée avec le bon hash
  // Le générateur utilise: _hashDeviceFingerprint qui fait % maxValue
  // Mais le hash brut peut dépasser maxValue

  print('--- 4. VÉRIFICATION HASH BRUT ---');
  final cleanFP = deviceFingerprint.replaceAll('-', '').toUpperCase();
  int rawHash = 0;
  for (int i = 0; i < cleanFP.length; i++) {
    rawHash = ((rawHash << 5) - rawHash + cleanFP.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  final rawHashAbs = rawHash.abs();
  const maxValue = 32 * 32 * 32 * 32;
  final reducedHash = rawHashAbs % maxValue;

  print('Empreinte nettoyée: $cleanFP');
  print('Hash brut: $rawHashAbs');
  print('Hash réduit (% $maxValue): $reducedHash');
  print('Segment encodé: ${encodeSegment(reducedHash, alphabetGenerator, 4)}');

  // ============================================================
  print('\n--- 5. CONCLUSION ---');

  // Vérifier si la clé universelle fonctionne avec RTL
  if (uDeviceHashRTL == 999999) {
    print('✅ Clé universelle: VALIDE avec décodage RTL');
  } else if (uDeviceHashLTR == 999999) {
    print('⚠️  Clé universelle: valide avec LTR mais PAS avec RTL (incohérence!)');
  } else {
    print('❌ Clé universelle: INVALIDE avec les deux méthodes');
    print('   Le segment ${uSegments[3]} ne décode pas à 999999');
    print('   Segment correct pour 999999: $expectedUniversalSegment');
  }
}
