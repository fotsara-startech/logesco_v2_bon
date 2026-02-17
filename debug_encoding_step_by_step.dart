/// Debug de l'encodage étape par étape
void main() {
  print('🔍 Debug de l\'encodage étape par étape\n');

  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const testHash = 1419425586;

  print('Hash: $testHash');
  print('Alphabet: $alphabet (longueur: ${alphabet.length})');
  print('');

  // Encodage étape par étape
  print('📝 Encodage:');
  String result = '';
  int remaining = testHash;

  for (int i = 0; i < 4; i++) {
    final index = remaining % alphabet.length;
    final char = alphabet[index];
    result = char + result; // Ajouter à gauche
    print('  Étape ${i + 1}: remaining=$remaining, index=$index, char=$char, result="$result"');
    remaining = remaining ~/ alphabet.length;
  }

  final encoded = result.padLeft(4, alphabet[0]);
  print('  Final: "$encoded"');
  print('');

  // Décodage étape par étape
  print('📝 Décodage de "$encoded":');
  int value = 0;

  for (int i = 0; i < encoded.length; i++) {
    final char = encoded[i];
    final charIndex = alphabet.indexOf(char);
    final oldValue = value;
    value = value * alphabet.length + charIndex;
    print('  Étape ${i + 1}: char=$char, index=$charIndex, oldValue=$oldValue, newValue=$value');
  }

  print('');
  print('✅ Hash original: $testHash');
  print('✅ Hash décodé: $value');
  print('✅ Match: ${value == testHash}');

  if (value != testHash) {
    print('\n🔍 Le problème est que l\'encodage ajoute les caractères à GAUCHE');
    print('   mais le décodage lit de GAUCHE à DROITE.');
    print('   Il faut inverser l\'ordre de lecture dans le décodage.');
  }
}
