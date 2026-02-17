import 'dart:convert';

void main() {
  // Simuler différents formats JSON problématiques

  print('=== TEST DE PARSING JSON ===');

  // Test 1: JSON avec des valeurs null
  final json1 = '''
  {
    "data": [
      {
        "id": 1,
        "produitId": null,
        "quantiteDisponible": 25,
        "quantiteReservee": 0
      }
    ]
  }
  ''';

  print('\n1. Test avec produitId null:');
  testJsonParsing(json1);

  // Test 2: JSON avec des champs manquants
  final json2 = '''
  {
    "data": [
      {
        "id": 1,
        "quantiteDisponible": 25
      }
    ]
  }
  ''';

  print('\n2. Test avec champs manquants:');
  testJsonParsing(json2);

  // Test 3: JSON avec des types incorrects
  final json3 = '''
  {
    "data": [
      {
        "id": "1",
        "produitId": "2",
        "quantiteDisponible": "25",
        "quantiteReservee": "0"
      }
    ]
  }
  ''';

  print('\n3. Test avec types string:');
  testJsonParsing(json3);

  // Test 4: JSON avec des noms de champs différents
  final json4 = '''
  {
    "data": [
      {
        "id": 1,
        "product_id": 2,
        "available_quantity": 25,
        "reserved_quantity": 0
      }
    ]
  }
  ''';

  print('\n4. Test avec noms de champs différents:');
  testJsonParsing(json4);
}

void testJsonParsing(String jsonString) {
  try {
    final jsonData = json.decode(jsonString);
    print('✓ JSON décodé avec succès');
    print('  Structure: ${jsonData.keys}');

    if (jsonData['data'] != null) {
      final dataList = jsonData['data'] as List;
      print('  Nombre d\'éléments: ${dataList.length}');

      for (int i = 0; i < dataList.length; i++) {
        final item = dataList[i];
        print('  Élément $i: $item');
        print('    Type: ${item.runtimeType}');

        if (item is Map<String, dynamic>) {
          print('    Champs: ${item.keys.toList()}');

          // Test d'extraction sécurisée
          final id = safeExtractInt(item, ['id']);
          final produitId = safeExtractInt(item, ['produitId', 'product_id']);
          final quantiteDisponible = safeExtractInt(item, ['quantiteDisponible', 'available_quantity']);
          final quantiteReservee = safeExtractInt(item, ['quantiteReservee', 'reserved_quantity']);

          print('    Extraits: id=$id, produitId=$produitId, dispo=$quantiteDisponible, reservé=$quantiteReservee');
        }
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

int safeExtractInt(Map<String, dynamic> json, List<String> keys) {
  for (String key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      final value = json[key];
      try {
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
        if (value is num) return value.toInt();
      } catch (e) {
        print('⚠️ Erreur conversion $key: $value -> $e');
        continue;
      }
    }
  }
  return 0;
}
