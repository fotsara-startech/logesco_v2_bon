void main() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  int decodeSegment(String segment) {
    int value = 0;
    int multiplier = 1;
    for (int i = segment.length - 1; i >= 0; i--) {
      final charIndex = alphabet.indexOf(segment[i]);
      if (charIndex == -1) return -1;
      value += charIndex * multiplier;
      multiplier *= alphabet.length;
    }
    return value;
  }

  DateTime decodeDateFromShort(int dateCode) {
    final year = 2000 + (dateCode ~/ 10000);
    final month = (dateCode % 10000) ~/ 100;
    final day = dateCode % 100;
    return DateTime(year, month, day);
  }

  // Clé normale: AAAB-H2MG-H8LE-7VEY
  print('=== Clé normale: AAAB-H2MG-H8LE-7VEY ===');
  final dateCode1 = decodeSegment('H8LE');
  print('Segment date: H8LE -> $dateCode1');
  final date1 = decodeDateFromShort(dateCode1);
  print('Date expiration: $date1');
  print('Expirée: ${DateTime.now().isAfter(date1)}');
  print('');

  // Clé universelle: AAAB-H2MG-H8LE-8ST9
  print('=== Clé universelle: AAAB-H2MG-H8LE-8ST9 ===');
  final dateCode2 = decodeSegment('H8LE');
  print('Segment date: H8LE -> $dateCode2');
  final date2 = decodeDateFromShort(dateCode2);
  print('Date expiration: $date2');
  print('Expirée: ${DateTime.now().isAfter(date2)}');
  print('');

  // Type d'abonnement
  final typeCode1 = decodeSegment('AAAB');
  print('Type code (AAAB): $typeCode1 -> typeValue: ${typeCode1 % 10}');
  // 1=trial, 2=monthly, 3=annual, 4=lifetime
  final types = {1: 'trial', 2: 'monthly', 3: 'annual', 4: 'lifetime'};
  print('Type: ${types[typeCode1 % 10] ?? 'inconnu'}');
}
