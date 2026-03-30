// #!/usr/bin/env dart

// /// Test de vérification de l'algorithme de génération de clés
// /// Cet outil teste que l'algorithme dans logesco_license_admin
// /// correspond à celui dans logesco_v2

// import 'dart:convert';

// void main() {
//   print('🔐 Test de Génération de Clés LOGESCO');
//   print('=====================================\n');

//   // Test avec la clé de l'appareil du client
//   final deviceFingerprint = 'P9ZD-GFQD-AWL4-L5MR';
  
//   print('📱 Empreinte d\'appareil: $deviceFingerprint');
//   print('');

//   // Calculer le hash
//   final hash = _hashDeviceFingerprint(deviceFingerprint);
//   print('🔢 Hash calculé: $hash');

//   // Générer le segment
//   const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
//   final segment = _generateSegment(hash, alphabet, 4);
//   print('📝 Segment généré: $segment');
//   print('');

//   // Vérifier la cohérence
//   print('✅ Vérification:');
//   print('   - Si le segment est "L5MR", l\'algorithme est CORRECT');
//   print('   - Si le segment est différent, il y a un problème');
//   print('');

//   // Tester le décodage
//   print('🔍 Test de décodage:');
//   final decodedHash = _decodeSegment(segment, alphabet);
//   print('   Segment: $segment');
//   print('   Hash décodé: $decodedHash');
//   print('   Hash original: $hash');
//   print('   Match: ${decodedHash == hash ? '✅ OUI' : '❌ NON'}');
// }

// /// Hash l'empreinte d'appareil de manière déterministe
// /// Cet algorithme DOIT correspondre à celui dans logesco_v2
// static int _hashDeviceFingerprint(String deviceFingerprint) {
//   // Nettoyer l'empreinte (enlever les tirets si présents)
//   final cleanFingerprint = deviceFingerprint.replaceAll('-', '');

//   print('   Empreinte nettoyée: $cleanFingerprint');

//   // Utiliser le MÊME algorithme que logesco_v2
//   int hash = 0;
//   for (int i = 0; i < cleanFingerprint.length; i++) {
//     hash = ((hash << 5) - hash + cleanFingerprint.codeUnitAt(i)) & 0xFFFFFFFF;
//   }

//   // Réduire le hash pour qu'il tienne dans 4 caractères (32^4 = 1,048,576)
//   const maxValue = 32 * 32 * 32 * 32; // 1,048,576
//   return hash.abs() % maxValue;
// }

// /// Génère un segment de clé
// static String _generateSegment(int value, String alphabet, int length) {
//   String result = '';
//   int remaining = value;

//   // Générer de droite à gauche
//   for (int i = 0; i < length; i++) {
//     result = alphabet[remaining % alphabet.length] + result;
//     remaining = remaining ~/ alphabet.length;
//   }

//   return result.padLeft(length, alphabet[0]);
// }

// /// Décode un segment de clé
// static int _decodeSegment(String segment, String alphabet) {
//   int value = 0;
//   for (int i = 0; i < segment.length; i++) {
//     value = value * alphabet.length + alphabet.indexOf(segment[i]);
//   }
//   return value;
// }
