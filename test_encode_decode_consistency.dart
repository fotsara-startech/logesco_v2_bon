/// Test de cohérence encodage/décodage
void main() {
  print('🧪 Test de cohérence encodage/décodage\n');

  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const testHash = 1419425586;

  print('Hash original: $testHash');
  print('Alphabet: $alphabet');
  print('');

  // Encodage (comme dans le générateur)
  String generateSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;

    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }

    return result.padLeft(length, alphabet[0]);
  }

  // Décodage (comme dans le validateur)
  int decodeSegment(String segment, String alphabet) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) return 0;
      value = value * alphabet.length + charIndex;
    }
    return value;
  }

  // Test
  final encoded = generateSegment(testHash, alphabet, 4);
  print('✅ Segment encodé: $encoded');

  final decoded = decodeSegment(encoded, alphabet);
  print('✅ Hash décodé: $decoded');

  final isConsistent = (decoded == testHash);
  print('✅ Cohérent: $isConsistent');

  if (isConsistent) {
    print('\n🎉 SUCCÈS! L\'encodage et le décodage sont cohérents!');
    print('   Pour l\'empreinte 98D6-QP3C-FVMZ-4L3P');
    print('   Le segment sera: $encoded');
  } else {
    print('\n❌ ÉCHEC! Incohérence détectée.');
    print('   Hash original: $testHash');
    print('   Hash décodé: $decoded');
    print('   Différence: ${testHash - decoded}');
  }
}
