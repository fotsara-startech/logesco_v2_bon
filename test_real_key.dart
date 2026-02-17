/// Test avec les vraies données
void main() {
  print('🧪 Test avec les données réelles\n');

  const licenseKey = 'AAAC-FBSF-HXLJ-XP3U';
  const deviceFingerprint = '98D6-QP3C-FVMZ-4L3P';

  print('Clé de licence: $licenseKey');
  print('Empreinte d\'appareil: $deviceFingerprint');
  print('');

  // Extraire les segments
  final keySegments = licenseKey.split('-');
  final deviceSegments = deviceFingerprint.split('-');

  print('Segments de la clé:');
  print('  1. Type: ${keySegments[0]}');
  print('  2. Client: ${keySegments[1]}');
  print('  3. Date: ${keySegments[2]}');
  print('  4. Appareil: ${keySegments[3]}');
  print('');

  // Décoder le hash d'appareil de la clé
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  int decodeSegment(String segment) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) {
        print('ERREUR: Caractère ${segment[i]} non trouvé');
        return -1;
      }
      value = value * alphabet.length + charIndex;
    }
    return value;
  }

  final keyDeviceHash = decodeSegment(keySegments[3]);
  print('Hash appareil dans la clé: $keyDeviceHash');

  // Calculer le hash de l'empreinte actuelle
  int hashDeviceFingerprint(String fingerprint) {
    final clean = fingerprint.replaceAll('-', '');
    int hash = 0;
    for (int i = 0; i < clean.length; i++) {
      hash = ((hash << 5) - hash + clean.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.abs();
  }

  final currentDeviceHash = hashDeviceFingerprint(deviceFingerprint);
  print('Hash de l\'empreinte actuelle: $currentDeviceHash');
  print('');

  // Générer le segment attendu
  String generateSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;
    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }
    return result.padLeft(length, alphabet[0]);
  }

  final expectedSegment = generateSegment(currentDeviceHash, alphabet, 4);
  print('Segment attendu pour cet appareil: $expectedSegment');
  print('Segment dans la clé: ${keySegments[3]}');
  print('');

  if (keyDeviceHash == currentDeviceHash) {
    print('✅ SUCCÈS: La clé correspond!');
  } else {
    print('❌ ÉCHEC: La clé ne correspond pas');
    print('');
    print('🔧 Solution:');
    print('   Génère une nouvelle clé avec:');
    print('   deviceFingerprint: "$deviceFingerprint"');
    print('');
    print('   La clé devrait se terminer par: $expectedSegment');
    print('   Format complet: AAAC-XXXX-XXXX-$expectedSegment');
  }
}
