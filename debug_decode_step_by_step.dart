/// Debug du décodage étape par étape
void main() {
  print('🔍 Debug du décodage de droite à gauche\n');

  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const segment = 'XP3U';
  const expectedHash = 1419425586;

  print('Segment: $segment');
  print('Hash attendu: $expectedHash');
  print('');

  // Décodage de droite à gauche
  print('📝 Décodage de droite à gauche:');
  int value = 0;
  int multiplier = 1;

  for (int i = segment.length - 1; i >= 0; i--) {
    final char = segment[i];
    final charIndex = alphabet.indexOf(char);
    final contribution = charIndex * multiplier;
    value += contribution;
    print('  Position ${segment.length - 1 - i}: char=$char, index=$charIndex, multiplier=$multiplier, contribution=$contribution, total=$value');
    multiplier *= alphabet.length;
  }

  print('');
  print('✅ Hash décodé: $value');
  print('✅ Hash attendu: $expectedHash');
  print('✅ Match: ${value == expectedHash}');

  if (value == expectedHash) {
    print('\n🎉 SUCCÈS! Le décodage fonctionne!');
  } else {
    print('\n❌ Le décodage ne fonctionne toujours pas.');
    print('   Différence: ${expectedHash - value}');

    // Vérifier si c'est un problème de débordement
    if (value > expectedHash) {
      print('   Le hash décodé est plus grand - possible débordement');
    } else {
      print('   Le hash décodé est plus petit - algorithme incorrect');
    }
  }
}
