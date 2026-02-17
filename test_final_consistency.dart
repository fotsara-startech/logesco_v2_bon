/// Test final de cohérence
void main() {
  print('🧪 Test final de cohérence encodage/décodage\n');

  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const testHash = 1419425586;

  print('Hash original: $testHash');
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

  // Décodage corrigé (de droite à gauche)
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
  final encoded = generateSegment(testHash, alphabet, 4);
  print('✅ Segment encodé: $encoded');

  final decoded = decodeSegment(encoded, alphabet);
  print('✅ Hash décodé: $decoded');

  final isConsistent = (decoded == testHash);
  print('✅ Cohérent: $isConsistent');

  if (isConsistent) {
    print('\n🎉 SUCCÈS! L\'algorithme est maintenant cohérent!');
    print('\n📋 Pour l\'empreinte 98D6-QP3C-FVMZ-4L3P:');
    print('   Hash: $testHash');
    print('   Segment: $encoded');
    print('   La clé générée se terminera par: $encoded');
  } else {
    print('\n❌ ÉCHEC! Incohérence persistante.');
  }
}
