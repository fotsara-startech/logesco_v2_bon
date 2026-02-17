/// Test direct du générateur de clés
/// À exécuter depuis logesco_license_admin
import 'dart:io';

// Copie de la fonction _hashString
int hashString(String input) {
  int hash = 0;
  for (int i = 0; i < input.length; i++) {
    hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return hash.abs();
}

// Copie de _hashDeviceFingerprint
int hashDeviceFingerprint(String deviceFingerprint) {
  final cleanFingerprint = deviceFingerprint.replaceAll('-', '');
  return hashString(cleanFingerprint);
}

// Copie de _generateSegment
String generateSegment(int value, String alphabet, int length) {
  String result = '';
  int remaining = value;

  for (int i = 0; i < length; i++) {
    result = alphabet[remaining % alphabet.length] + result;
    remaining = remaining ~/ alphabet.length;
  }

  return result.padLeft(length, alphabet[0]);
}

void main() {
  print('🧪 Test du générateur de clés\n');

  const deviceFingerprint = '98D6-QP3C-FVMZ-4L3P';
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  print('Empreinte d\'appareil: $deviceFingerprint');
  print('');

  // Calculer le hash
  final deviceHash = hashDeviceFingerprint(deviceFingerprint);
  print('Hash calculé: $deviceHash');

  // Générer le segment
  final segment = generateSegment(deviceHash, alphabet, 4);
  print('Segment généré: $segment');
  print('');

  print('✅ La clé générée devrait se terminer par: $segment');
  print('   Format complet: AAAC-XXXX-XXXX-$segment');
  print('');
  print('📝 Si la clé générée ne se termine pas par "$segment",');
  print('   c\'est que l\'ancien code est encore utilisé.');
}
