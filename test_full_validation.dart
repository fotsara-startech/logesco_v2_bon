/// Test complet de validation
void main() {
  print('🧪 Test complet de validation\n');

  const licenseKey = 'AAAC-ZLAD-HXLJ-XP3U';
  const deviceFingerprint = '98D6-QP3C-FVMZ-4L3P';

  print('Clé: $licenseKey');
  print('Empreinte: $deviceFingerprint');
  print('');

  // Vérifier le format
  final formatValid = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(licenseKey);
  print('✓ Format valide: $formatValid');

  // Extraire les segments
  final keySegments = licenseKey.split('-');
  final deviceSegment = keySegments[3];

  // Décoder le segment d'appareil de la clé
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  int decodeSegment(String segment) {
    int value = 0;
    for (int i = 0; i < segment.length; i++) {
      value = value * alphabet.length + alphabet.indexOf(segment[i]);
    }
    return value;
  }

  final keyDeviceHash = decodeSegment(deviceSegment);
  print('✓ Hash dans la clé: $keyDeviceHash');

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
  print('✓ Hash de l\'empreinte: $currentDeviceHash');
  print('');

  if (keyDeviceHash == currentDeviceHash) {
    print('✅ SUCCÈS: La clé correspond à l\'appareil!');
    print('');
    print('Si la clé est rejetée dans l\'application, le problème');
    print('est dans une autre validation (date, unicité, etc.)');
  } else {
    print('❌ ÉCHEC: Les hash ne correspondent pas');
    print('   Clé: $keyDeviceHash');
    print('   Appareil: $currentDeviceHash');
  }
}
