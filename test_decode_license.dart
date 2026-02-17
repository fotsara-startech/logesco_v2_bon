void main() {
  // Test de décodage de la clé AAAB-T4WU-HXHM-Q5VD
  const licenseKey = 'AAAB-T4WU-HXHM-Q5VD';

  print('Clé à décoder: $licenseKey');
  print('Longueur: ${licenseKey.length}');

  // Vérifier le format
  final formatValid = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(licenseKey);
  print('Format valide: $formatValid');

  // Décoder les segments
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final segments = licenseKey.split('-');

  print('\nDécodage des segments:');
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print('Segment $i: $segment');

    // Vérifier que tous les caractères sont dans l'alphabet
    for (var char in segment.split('')) {
      if (!alphabet.contains(char)) {
        print('  ERREUR: $char n\'est pas dans l\'alphabet!');
      }
    }

    // Décoder le segment
    int value = 0;
    for (int j = 0; j < segment.length; j++) {
      final charIndex = alphabet.indexOf(segment[j]);
      if (charIndex == -1) {
        print('  ERREUR: Impossible de trouver $segment[j] dans l\'alphabet');
        break;
      }
      value = value * alphabet.length + charIndex;
    }
    print('  Valeur décodée: $value');
  }
}
