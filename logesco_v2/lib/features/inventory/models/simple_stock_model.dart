// Modèle Stock simplifié pour le débogage
class SimpleStock {
  final int id;
  final int produitId;
  final int quantiteDisponible;
  final int quantiteReservee;
  final DateTime derniereMaj;

  SimpleStock({
    required this.id,
    required this.produitId,
    required this.quantiteDisponible,
    required this.quantiteReservee,
    required this.derniereMaj,
  });

  factory SimpleStock.fromJson(Map<String, dynamic> json) {


    // Extraction sécurisée de chaque champ
    int id = 0;
    try {
      id = _extractInt(json, ['id']);
      print('✓ id: $id');
    } catch (e) {
      print('❌ Erreur id: $e');
    }

    int produitId = 0;
    try {
      produitId = _extractInt(json, ['produitId', 'productId', 'product_id']);
      print('✓ produitId: $produitId');
    } catch (e) {
      print('❌ Erreur produitId: $e');
    }

    int quantiteDisponible = 0;
    try {
      quantiteDisponible = _extractInt(json, ['quantiteDisponible', 'quantite_disponible', 'availableQuantity', 'available_quantity']);
      print('✓ quantiteDisponible: $quantiteDisponible');
    } catch (e) {
      print('❌ Erreur quantiteDisponible: $e');
    }

    int quantiteReservee = 0;
    try {
      quantiteReservee = _extractInt(json, ['quantiteReservee', 'quantite_reservee', 'reservedQuantity', 'reserved_quantity']);
      print('✓ quantiteReservee: $quantiteReservee');
    } catch (e) {
      print('❌ Erreur quantiteReservee: $e');
    }

    DateTime derniereMaj = DateTime.now();
    try {
      derniereMaj = _extractDateTime(json, ['derniereMaj', 'derniere_maj', 'lastUpdate', 'last_update', 'updatedAt', 'updated_at']);
      print('✓ derniereMaj: $derniereMaj');
    } catch (e) {
      print('❌ Erreur derniereMaj: $e');
    }

    return SimpleStock(
      id: id,
      produitId: produitId,
      quantiteDisponible: quantiteDisponible,
      quantiteReservee: quantiteReservee,
      derniereMaj: derniereMaj,
    );
  }

  static int _extractInt(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final value = json[key];
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
        if (value is num) return value.toInt();
      }
    }
    return 0;
  }

  static DateTime _extractDateTime(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        try {
          return DateTime.parse(json[key] as String);
        } catch (e) {
          continue;
        }
      }
    }
    return DateTime.now();
  }

  // Conversion vers Stock normal
  dynamic toStock() {
    // Retourner un objet qui peut être utilisé comme Stock
    return {
      'id': id,
      'produitId': produitId,
      'quantiteDisponible': quantiteDisponible,
      'quantiteReservee': quantiteReservee,
      'derniereMaj': derniereMaj,
    };
  }
}
