void main() {
  // Test de génération de segment
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String generateSegment(int value, String alphabet, int length) {
    String result = '';
    int remaining = value;

    for (int i = 0; i < length; i++) {
      result = alphabet[remaining % alphabet.length] + result;
      remaining = remaining ~/ alphabet.length;
    }

    return result.padLeft(length, alphabet[0]);
  }

  // Test avec différentes valeurs
  print('Test 1: ${generateSegment(12345, alphabet, 4)}');
  print('Test 2: ${generateSegment(67890, alphabet, 4)}');
  print('Test 3: ${generateSegment(111111, alphabet, 4)}');

  // Vérifier que tous les caractères sont dans l'alphabet
  final test = generateSegment(12345, alphabet, 4);
  for (var char in test.split('')) {
    if (!alphabet.contains(char)) {
      print('ERREUR: $char n\'est pas dans l\'alphabet!');
    }
  }
}
