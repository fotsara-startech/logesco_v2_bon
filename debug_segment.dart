void main() {
  print('🔍 Debug du calcul de segment\n');

  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const deviceHash = 1419425586;

  print('Hash d\'appareil: $deviceHash');
  print('Alphabet: $alphabet');
  print('Longueur alphabet: ${alphabet.length}');
  print('');

  // Calculer le segment manuellement
  String generateSegment(int value, String alphabet, int length) {
    print('Calcul du segment pour $value:');
    String result = '';
    int remaining = value;

    for (int i = 0; i < length; i++) {
      final index = remaining % alphabet.length;
      final char = alphabet[index];
      result = char + result;
      print('  Étape ${i + 1}: remaining=$remaining, index=$index, char=$char, result=$result');
      remaining = remaining ~/ alphabet.length;
    }

    final padded = result.padLeft(length, alphabet[0]);
    print('  Final (padded): $padded');
    return padded;
  }

  final segment = generateSegment(deviceHash, alphabet, 4);
  print('\n✅ Segment calculé: $segment');

  // Vérifier le décodage inverse
  print('\n🔄 Vérification inverse:');
  int decodeSegment(String segment) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      final index = alphabet.indexOf(segment[i]);
      value = value * alphabet.length + index;
      print('  Char ${segment[i]} -> index $index -> value $value');
    }
    return value;
  }

  final decoded = decodeSegment(segment);
  print('  Hash décodé: $decoded');
  print('  Match: ${decoded == deviceHash}');
}
