import 'package:json_annotation/json_annotation.dart';
import 'print_format.dart';

part 'receipt_filter.g.dart';

/// Filtres prédéfinis pour les reçus
enum ReceiptFilterPreset {
  @JsonValue('all')
  all,
  @JsonValue('today')
  today,
  @JsonValue('thisWeek')
  thisWeek,
  @JsonValue('thisMonth')
  thisMonth,
  @JsonValue('reprints')
  reprints,
  @JsonValue('cash')
  cash,
  @JsonValue('credit')
  credit,
  @JsonValue('highValue')
  highValue,
}

/// Extension pour les filtres prédéfinis
extension ReceiptFilterPresetExtension on ReceiptFilterPreset {
  String get displayName {
    switch (this) {
      case ReceiptFilterPreset.all:
        return 'Tous les reçus';
      case ReceiptFilterPreset.today:
        return 'Aujourd\'hui';
      case ReceiptFilterPreset.thisWeek:
        return 'Cette semaine';
      case ReceiptFilterPreset.thisMonth:
        return 'Ce mois';
      case ReceiptFilterPreset.reprints:
        return 'Réimpressions';
      case ReceiptFilterPreset.cash:
        return 'Paiements cash';
      case ReceiptFilterPreset.credit:
        return 'Paiements crédit';
      case ReceiptFilterPreset.highValue:
        return 'Montants élevés';
    }
  }

  String get description {
    switch (this) {
      case ReceiptFilterPreset.all:
        return 'Affiche tous les reçus disponibles';
      case ReceiptFilterPreset.today:
        return 'Reçus émis aujourd\'hui';
      case ReceiptFilterPreset.thisWeek:
        return 'Reçus de cette semaine';
      case ReceiptFilterPreset.thisMonth:
        return 'Reçus de ce mois';
      case ReceiptFilterPreset.reprints:
        return 'Reçus qui ont été réimprimés';
      case ReceiptFilterPreset.cash:
        return 'Ventes payées en espèces';
      case ReceiptFilterPreset.credit:
        return 'Ventes à crédit';
      case ReceiptFilterPreset.highValue:
        return 'Ventes de montant élevé (>100,000 FCFA)';
    }
  }

  /// Applique le filtre prédéfini
  ReceiptAdvancedFilter apply() {
    final now = DateTime.now();

    switch (this) {
      case ReceiptFilterPreset.all:
        return ReceiptAdvancedFilter.empty();

      case ReceiptFilterPreset.today:
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        return ReceiptAdvancedFilter(
          dateRange: DateRange(start: startOfDay, end: endOfDay),
        );

      case ReceiptFilterPreset.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
        return ReceiptAdvancedFilter(
          dateRange: DateRange(start: startOfWeekDay, end: endOfWeek),
        );

      case ReceiptFilterPreset.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        return ReceiptAdvancedFilter(
          dateRange: DateRange(start: startOfMonth, end: endOfMonth),
        );

      case ReceiptFilterPreset.reprints:
        return const ReceiptAdvancedFilter(
          reprintStatus: ReprintStatus.reprintsOnly,
        );

      case ReceiptFilterPreset.cash:
        return const ReceiptAdvancedFilter(
          paymentMethods: ['cash', 'especes'],
        );

      case ReceiptFilterPreset.credit:
        return const ReceiptAdvancedFilter(
          paymentMethods: ['credit'],
        );

      case ReceiptFilterPreset.highValue:
        return const ReceiptAdvancedFilter(
          amountRange: AmountRange(min: 100000),
        );
    }
  }
}

/// Statut de réimpression pour le filtrage
enum ReprintStatus {
  @JsonValue('all')
  all,
  @JsonValue('originals')
  originalsOnly,
  @JsonValue('reprints')
  reprintsOnly,
}

/// Extension pour le statut de réimpression
extension ReprintStatusExtension on ReprintStatus {
  String get displayName {
    switch (this) {
      case ReprintStatus.all:
        return 'Tous';
      case ReprintStatus.originalsOnly:
        return 'Originaux seulement';
      case ReprintStatus.reprintsOnly:
        return 'Réimpressions seulement';
    }
  }
}

/// Plage de dates pour le filtrage
@JsonSerializable()
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) => _$DateRangeFromJson(json);
  Map<String, dynamic> toJson() => _$DateRangeToJson(this);

  /// Crée une plage pour aujourd'hui
  factory DateRange.today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return DateRange(start: startOfDay, end: endOfDay);
  }

  /// Crée une plage pour cette semaine
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
    return DateRange(start: startOfWeekDay, end: endOfWeek);
  }

  /// Crée une plage pour ce mois
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return DateRange(start: startOfMonth, end: endOfMonth);
  }

  /// Crée une plage pour les X derniers jours
  factory DateRange.lastDays(int days) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    final startDate = endOfDay.subtract(Duration(days: days));
    return DateRange(start: startDate, end: endOfDay);
  }

  /// Vérifie si une date est dans la plage
  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }

  /// Durée de la plage
  Duration get duration => end.difference(start);

  /// Nombre de jours dans la plage
  int get days => duration.inDays;
}

/// Plage de montants pour le filtrage
@JsonSerializable()
class AmountRange {
  final double? min;
  final double? max;

  const AmountRange({
    this.min,
    this.max,
  });

  factory AmountRange.fromJson(Map<String, dynamic> json) => _$AmountRangeFromJson(json);
  Map<String, dynamic> toJson() => _$AmountRangeToJson(this);

  /// Crée une plage pour les montants élevés
  factory AmountRange.highValue() {
    return const AmountRange(min: 100000);
  }

  /// Crée une plage pour les montants moyens
  factory AmountRange.mediumValue() {
    return const AmountRange(min: 10000, max: 100000);
  }

  /// Crée une plage pour les petits montants
  factory AmountRange.lowValue() {
    return const AmountRange(max: 10000);
  }

  /// Vérifie si un montant est dans la plage
  bool contains(double amount) {
    if (min != null && amount < min!) return false;
    if (max != null && amount > max!) return false;
    return true;
  }

  /// Vérifie si la plage est définie
  bool get isDefined => min != null || max != null;
}

/// Filtre avancé pour les reçus
@JsonSerializable()
class ReceiptAdvancedFilter {
  final DateRange? dateRange;
  final AmountRange? amountRange;
  final List<String>? paymentMethods;
  final List<PrintFormat>? printFormats;
  final ReprintStatus? reprintStatus;
  final String? customerNamePattern;
  final String? saleNumberPattern;
  final bool? hasCustomer;
  final int? minReprintCount;
  final int? maxReprintCount;

  const ReceiptAdvancedFilter({
    this.dateRange,
    this.amountRange,
    this.paymentMethods,
    this.printFormats,
    this.reprintStatus,
    this.customerNamePattern,
    this.saleNumberPattern,
    this.hasCustomer,
    this.minReprintCount,
    this.maxReprintCount,
  });

  factory ReceiptAdvancedFilter.fromJson(Map<String, dynamic> json) => _$ReceiptAdvancedFilterFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptAdvancedFilterToJson(this);

  /// Crée un filtre vide
  factory ReceiptAdvancedFilter.empty() {
    return const ReceiptAdvancedFilter();
  }

  /// Crée une copie avec des modifications
  ReceiptAdvancedFilter copyWith({
    DateRange? dateRange,
    AmountRange? amountRange,
    List<String>? paymentMethods,
    List<PrintFormat>? printFormats,
    ReprintStatus? reprintStatus,
    String? customerNamePattern,
    String? saleNumberPattern,
    bool? hasCustomer,
    int? minReprintCount,
    int? maxReprintCount,
  }) {
    return ReceiptAdvancedFilter(
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      printFormats: printFormats ?? this.printFormats,
      reprintStatus: reprintStatus ?? this.reprintStatus,
      customerNamePattern: customerNamePattern ?? this.customerNamePattern,
      saleNumberPattern: saleNumberPattern ?? this.saleNumberPattern,
      hasCustomer: hasCustomer ?? this.hasCustomer,
      minReprintCount: minReprintCount ?? this.minReprintCount,
      maxReprintCount: maxReprintCount ?? this.maxReprintCount,
    );
  }

  /// Efface tous les filtres
  ReceiptAdvancedFilter clear() {
    return ReceiptAdvancedFilter.empty();
  }

  /// Vérifie si des filtres sont définis
  bool get hasFilters {
    return dateRange != null ||
        amountRange?.isDefined == true ||
        paymentMethods?.isNotEmpty == true ||
        printFormats?.isNotEmpty == true ||
        reprintStatus != null ||
        customerNamePattern?.isNotEmpty == true ||
        saleNumberPattern?.isNotEmpty == true ||
        hasCustomer != null ||
        minReprintCount != null ||
        maxReprintCount != null;
  }

  /// Nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (dateRange != null) count++;
    if (amountRange?.isDefined == true) count++;
    if (paymentMethods?.isNotEmpty == true) count++;
    if (printFormats?.isNotEmpty == true) count++;
    if (reprintStatus != null) count++;
    if (customerNamePattern?.isNotEmpty == true) count++;
    if (saleNumberPattern?.isNotEmpty == true) count++;
    if (hasCustomer != null) count++;
    if (minReprintCount != null) count++;
    if (maxReprintCount != null) count++;
    return count;
  }

  /// Convertit en paramètres de requête
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (dateRange != null) {
      params['startDate'] = dateRange!.start.toIso8601String();
      params['endDate'] = dateRange!.end.toIso8601String();
    }

    if (amountRange?.isDefined == true) {
      if (amountRange!.min != null) params['minAmount'] = amountRange!.min.toString();
      if (amountRange!.max != null) params['maxAmount'] = amountRange!.max.toString();
    }

    if (paymentMethods?.isNotEmpty == true) {
      params['paymentMethods'] = paymentMethods!.join(',');
    }

    if (printFormats?.isNotEmpty == true) {
      params['printFormats'] = printFormats!.map((f) => f.name).join(',');
    }

    if (reprintStatus != null) {
      params['reprintStatus'] = reprintStatus!.name;
    }

    if (customerNamePattern?.isNotEmpty == true) {
      params['customerNamePattern'] = customerNamePattern;
    }

    if (saleNumberPattern?.isNotEmpty == true) {
      params['saleNumberPattern'] = saleNumberPattern;
    }

    if (hasCustomer != null) {
      params['hasCustomer'] = hasCustomer.toString();
    }

    if (minReprintCount != null) {
      params['minReprintCount'] = minReprintCount.toString();
    }

    if (maxReprintCount != null) {
      params['maxReprintCount'] = maxReprintCount.toString();
    }

    return params;
  }
}

/// Configuration de filtre sauvegardée
@JsonSerializable()
class SavedReceiptFilter {
  final String id;
  final String name;
  final String? description;
  final ReceiptAdvancedFilter filter;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDefault;

  const SavedReceiptFilter({
    required this.id,
    required this.name,
    this.description,
    required this.filter,
    required this.createdAt,
    this.updatedAt,
    this.isDefault = false,
  });

  factory SavedReceiptFilter.fromJson(Map<String, dynamic> json) => _$SavedReceiptFilterFromJson(json);
  Map<String, dynamic> toJson() => _$SavedReceiptFilterToJson(this);

  /// Crée une copie avec des modifications
  SavedReceiptFilter copyWith({
    String? id,
    String? name,
    String? description,
    ReceiptAdvancedFilter? filter,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return SavedReceiptFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      filter: filter ?? this.filter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
