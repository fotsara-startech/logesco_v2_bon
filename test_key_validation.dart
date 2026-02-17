/// Test de validation de clé avec empreinte d'appareil
void main() {
  print('🧪 Test de validation de clé avec empreinte d\'appareil\n');

  // Simulation des données
  const licenseKey = 'AAAC-DM43-HXLJ-XP3U';
  const deviceFingerprint = 'K7M9-P3Q8-R2N5-W4X6'; // Exemple

  print('Clé de licence: $licenseKey');
  print('Empreinte d\'appareil: $deviceFingerprint');
  print('');

  // Extraire le 4ème segment de la clé (hash de l'appareil)
  final keySegments = licenseKey.split('-');
  final keyDeviceSegment = keySegments[3]; // XP3U

  print('Segment appareil dans la clé: $keyDeviceSegment');

  // Décoder le segment
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  int decodeSegment(String segment) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) {
        print('ERREUR: Caractère ${segment[i]} non trouvé dans l\'alphabet');
        return -1;
      }
      value = value * alphabet.length + charIndex;
    }
    return value;
  }

  final keyDeviceHash = decodeSegment(keyDeviceSegment);
  print('Hash appareil décodé de la clé: $keyDeviceHash');
  print('');

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

  // Comparer
  if (keyDeviceHash == currentDeviceHash) {
    print('✅ SUCCÈS: La clé correspond à cet appareil!');
  } else {
    print('❌ ÉCHEC: La clé ne correspond PAS à cet appareil');
    print('   La clé a été générée pour un autre appareil');
  }

  print('\n📝 Note: Pour que la clé fonctionne, elle doit être générée');
  print('   avec l\'empreinte EXACTE de l\'appareil cible.');
}
