/// Helper pour parser les doubles de manière sûre
double _parseDouble(dynamic value, {double? defaultValue}) {
  if (value == null) return defaultValue ?? 0.0;
  if (value is double) {
    return value.isNaN || value.isInfinite ? (defaultValue ?? 0.0) : value;
  }
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return defaultValue ?? 0.0;
    }
    return parsed;
  }
  return defaultValue ?? 0.0;
}

/// Modèle pour les presets de filtres sauvegardés
class FilterPreset {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? categoryId;
  final String? searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final DateTime createdAt;
  final bool isDefault;

  FilterPreset({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.searchQuery,
    this.minAmount,
    this.maxAmount,
    required this.createdAt,
    this.isDefault = false,
  });

  /// Crée un preset à partir d'un JSON
  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    return FilterPreset(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse((json['startDate'] ?? DateTime.now().toIso8601String()) as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse((json['endDate'] ?? DateTime.now().toIso8601String()) as String) : null,
      categoryId: json['categoryId'] as int?,
      searchQuery: json['searchQuery'] as String?,
      minAmount: json['minAmount'] != null ? _parseDouble(json['minAmount']) : null,
      maxAmount: json['maxAmount'] != null ? _parseDouble(json['maxAmount']) : null,
      createdAt: DateTime.parse((json['createdAt'] ?? DateTime.now().toIso8601String()) as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convertit le preset en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (categoryId != null) 'categoryId': categoryId,
      if (searchQuery != null) 'searchQuery': searchQuery,
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// Crée une copie du preset avec des modifications
  FilterPreset copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return FilterPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Vérifie si le preset a des filtres actifs
  bool get hasActiveFilters {
    return startDate != null || endDate != null || categoryId != null || (searchQuery != null && searchQuery!.isNotEmpty) || minAmount != null || maxAmount != null;
  }

  /// Obtient un résumé des filtres du preset
  String get filtersSummary {
    final filters = <String>[];

    if (startDate != null || endDate != null) {
      if (startDate != null && endDate != null) {
        filters.add('Période: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}');
      } else if (startDate != null) {
        filters.add('Depuis: ${_formatDate(startDate!)}');
      } else if (endDate != null) {
        filters.add('Jusqu\'au: ${_formatDate(endDate!)}');
      }
    }

    if (categoryId != null) {
      filters.add('Catégorie: $categoryId');
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filters.add('Recherche: "$searchQuery"');
    }

    if (minAmount != null || maxAmount != null) {
      if (minAmount != null && maxAmount != null) {
        filters.add('Montant: ${minAmount!.toStringAsFixed(0)} - ${maxAmount!.toStringAsFixed(0)} FCFA');
      } else if (minAmount != null) {
        filters.add('Min: ${minAmount!.toStringAsFixed(0)} FCFA');
      } else if (maxAmount != null) {
        filters.add('Max: ${maxAmount!.toStringAsFixed(0)} FCFA');
      }
    }

    return filters.isEmpty ? 'Aucun filtre' : filters.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  String toString() {
    return 'FilterPreset(id: $id, name: $name, hasActiveFilters: $hasActiveFilters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Presets par défaut
  static List<FilterPreset> get defaultPresets {
    final now = DateTime.now();

    return [
      FilterPreset(
        id: 'today',
        name: 'Aujourd\'hui',
        description: 'Mouvements d\'aujourd\'hui',
        startDate: DateTime(now.year, now.month, now.day),
        endDate: now,
        createdAt: now,
        isDefault: true,
      ),
      FilterPreset(
        id: 'this_week',
        name: 'Cette semaine',
        description: 'Mouvements de cette semaine',
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now,
        createdAt: now,
        isDefault: true,
      ),
      FilterPreset(
        id: 'this_month',
        name: 'Ce mois',
        description: 'Mouvements de ce mois',
        startDate: DateTime(now.year, now.month, 1),
        endDate: now,
        createdAt: now,
        isDefault: true,
      ),
      FilterPreset(
        id: 'large_amounts',
        name: 'Montants élevés',
        description: 'Mouvements supérieurs à 50 000 FCFA',
        minAmount: 50000,
        createdAt: now,
        isDefault: true,
      ),
    ];
  }
}
