/// Test avec hash réduit
void main() {
  print('🧪 Test avec hash réduit\n');

  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const deviceFingerprint = '98D6-QP3C-FVMZ-4L3P';

  // Calculer le hash complet
  String cleanFingerprint = deviceFingerprint.replaceAll('-', '');
  int hash = 0;
  for (int i = 0; i < cleanFingerprint.length; i++) {
    hash = ((hash << 5) - hash + cleanFingerprint.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  final fullHash = hash.abs();

  // Réduire le hash
  const maxValue = 32 * 32 * 32 * 32; // 1,048,576
  final reducedHash = fullHash % maxValue;

  print('Empreinte: $deviceFingerprint');
  print('Hash complet: $fullHash');
  print('Hash réduit: $reducedHash');
  print('Capacité max: $maxValue');
  print('');

  // Encodage
  String generateSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;

    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }

    return result.padLeft(length, alphabet[0]);
  }

  // Décodage
  int decodeSegment(String segment, String alphabet) {
    int value = 0;
    int multiplier = 1;

    for (int i = segment.length - 1; i >= 0; i--) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) return 0;
      value += charIndex * multiplier;
      multiplier *= alphabet.length;
    }
    return value;
  }

  // Test
  final encoded = generateSegment(reducedHash, alphabet, 4);
  print('✅ Segment encodé: $encoded');

  final decoded = decodeSegment(encoded, alphabet);
  print('✅ Hash décodé: $decoded');

  final isConsistent = (decoded == reducedHash);
  print('✅ Cohérent: $isConsistent');

  if (isConsistent) {
    print('\n🎉 SUCCÈS! L\'algorithme fonctionne maintenant!');
    print('\n📋 Pour l\'empreinte $deviceFingerprint:');
    print('   Hash réduit: $reducedHash');
    print('   Segment: $encoded');
    print('   La clé générée se terminera par: $encoded');
  } else {
    print('\n❌ ÉCHEC! Incohérence persistante.');
  }
}
