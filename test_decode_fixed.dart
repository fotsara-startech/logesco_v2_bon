// void main() {
//   print('🧪 Test du décodage corrigé\n');

//   const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
//   const segment = 'XP3U';
//   const expectedHash = 1419425586;

//   print('Segment: $segment');
//   print('Hash attendu: $expectedHash');
//   print('');

//   // Nouveau décodage (de droite à gauche)
//   int decodeSegmentFixed(String segment, String alphabet) {
//     int value = 0;
//     for (int i = segment.length - 1; i >= 0; i--) {
//       final charIndex = alphabet.indexOf(segment[i]);
//       final power = _power(alphabet.length, segment.length - 1 - i);
//       value += charIndex * power;
//       print('  ${segment[i]} (index $charIndex) * ${alphabet.length}^${segment.length - 1 - i} = $charIndex * $power = ${charIndex * power}');
//     }
//     return value;
//   }

//   int _power(int base, int exponent) {
//     int result = 1;
//     for (int i = 0; i < exponent; i++) {
//       result *= base;
//     }
//     return result;
//   }

//   final decoded = decodeSegmentFixed(segment, alphabet);
//   print('\n✅ Hash décodé: $decoded');
//   print('   Match: ${decoded == expectedHash}');

//   if (decoded == expectedHash) {
//     print('\n🎉 SUCCÈS! Le décodage est maintenant correct!');
//   } else {
//     print('\n❌ Le décodage ne correspond toujours pas.');
//   }
// }
