import '../../../features/financial_movements/models/financial_movement.dart';
import '../../../features/financial_movements/models/movement_category.dart';

/// Utilitaire pour parser les mouvements financiers de manière sécurisée
class SafeFinancialParser {
  
  /// Parse un mouvement financier avec gestion d'erreur robuste
  static FinancialMovement? parseFinancialMovement(Map<String, dynamic> json) {
    try {
      // Validation des champs obligatoires
      if (!_hasRequiredFields(json)) {
        print('⚠️ Champs obligatoires manquants dans le mouvement financier');
        return null;
      }

      return FinancialMovement(
        id: _parseInt(json['id']) ?? 0,
        reference: _parseString(json['reference']) ?? '',
        montant: _parseDouble(json['montant']) ?? 0.0,
        categorieId: _parseInt(json['categorieId']) ?? 0,
        description: _parseString(json['description']) ?? '',
        date: _parseDateTime(json['date']) ?? DateTime.now(),
        utilisateurId: _parseInt(json['utilisateurId']) ?? 0,
        dateCreation: _parseDateTime(json['dateCreation']) ?? DateTime.now(),
        dateModification: _parseDateTime(json['dateModification']) ?? DateTime.now(),
        notes: _parseString(json['notes']),
        categorie: _parseMovementCategory(json['categorie']),
        utilisateurNom: _parseString(json['utilisateurNom']),
      );
    } catch (e) {
      print('❌ Erreur lors du parsing du mouvement financier: $e');
      print('📋 JSON problématique: $json');
      return null;
    }
  }

  /// Vérifie si les champs obligatoires sont présents
  static bool _hasRequiredFields(Map<String, dynamic> json) {
    final requiredFields = ['id', 'montant', 'categorieId', 'description', 'date'];
    
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        print('⚠️ Champ obligatoire manquant: $field');
        return false;
      }
    }
    
    return true;
  }

  /// Parse un entier de manière sécurisée
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    
    print('⚠️ Impossible de parser en int: $value (${value.runtimeType})');
    return null;
  }

  /// Parse un double de manière sécurisée
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    
    print('⚠️ Impossible de parser en double: $value (${value.runtimeType})');
    return null;
  }

  /// Parse une chaîne de manière sécurisée
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    
    if (value is String) return value;
    
    // Convertit les autres types en string
    return value.toString();
  }

  /// Parse une date de manière sécurisée
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Impossible de parser la date: $value');
        return null;
      }
    }
    
    print('⚠️ Type de date non supporté: $value (${value.runtimeType})');
    return null;
  }

  /// Parse une catégorie de mouvement de manière sécurisée
  static MovementCategory? _parseMovementCategory(dynamic value) {
    if (value == null) return null;
    
    if (value is! Map<String, dynamic>) {
      print('⚠️ Catégorie n\'est pas un Map: $value (${value.runtimeType})');
      return null;
    }
    
    try {
      return MovementCategory.fromJson(value);
    } catch (e) {
      print('⚠️ Erreur parsing catégorie: $e');
      return null;
    }
  }

  /// Parse une liste de mouvements financiers de manière sécurisée
  static List<FinancialMovement> parseFinancialMovementsList(List<dynamic> jsonList) {
    final movements = <FinancialMovement>[];
    
    for (int i = 0; i < jsonList.length; i++) {
      final item = jsonList[i];
      
      if (item is! Map<String, dynamic>) {
        print('⚠️ Élément $i n\'est pas un Map: $item (${item.runtimeType})');
        continue;
      }
      
      final movement = parseFinancialMovement(item);
      if (movement != null) {
        movements.add(movement);
      } else {
        print('⚠️ Mouvement $i ignoré à cause d\'erreurs de parsing');
      }
    }
    
    print('✅ ${movements.length}/${jsonList.length} mouvements financiers parsés avec succès');
    return movements;
  }

  /// Valide qu'un mouvement financier est cohérent
  static bool validateFinancialMovement(FinancialMovement movement) {
    // Vérifications de base
    if (movement.id <= 0) {
      print('⚠️ ID de mouvement invalide: ${movement.id}');
      return false;
    }
    
    if (movement.description.trim().isEmpty) {
      print('⚠️ Description de mouvement vide');
      return false;
    }
    
    if (movement.montant == 0.0) {
      print('⚠️ Montant de mouvement nul');
      return false;
    }
    
    // Vérification de la date
    final now = DateTime.now();
    final futureLimit = now.add(const Duration(days: 1));
    
    if (movement.date.isAfter(futureLimit)) {
      print('⚠️ Date de mouvement dans le futur: ${movement.date}');
      return false;
    }
    
    return true;
  }

  /// Filtre les mouvements par période de manière sécurisée
  static List<FinancialMovement> filterMovementsByPeriod(
    List<FinancialMovement> movements,
    DateTime startDate,
    DateTime endDate,
  ) {
    final filteredMovements = <FinancialMovement>[];
    
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    for (final movement in movements) {
      try {
        final movementDate = DateTime(
          movement.date.year,
          movement.date.month,
          movement.date.day,
        );
        
        if ((movementDate.isAtSameMomentAs(start) || movementDate.isAfter(start)) &&
            (movementDate.isAtSameMomentAs(end) || movementDate.isBefore(end))) {
          filteredMovements.add(movement);
        }
      } catch (e) {
        print('⚠️ Erreur lors du filtrage du mouvement ${movement.id}: $e');
      }
    }
    
    print('🔍 ${filteredMovements.length}/${movements.length} mouvements dans la période');
    return filteredMovements;
  }
}