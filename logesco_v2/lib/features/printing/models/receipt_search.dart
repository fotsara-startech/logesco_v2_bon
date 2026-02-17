import 'package:json_annotation/json_annotation.dart';
import 'receipt_model.dart';

part 'receipt_search.g.dart';

/// Critères de recherche pour les reçus
@JsonSerializable()
class ReceiptSearchCriteria {
  final String? saleId;
  final String? saleNumber;
  final String? customerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentMethod;
  final double? minAmount;
  final double? maxAmount;
  final bool? isReprint;
  final String? reprintBy;

  const ReceiptSearchCriteria({
    this.saleId,
    this.saleNumber,
    this.customerName,
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.minAmount,
    this.maxAmount,
    this.isReprint,
    this.reprintBy,
  });

  factory ReceiptSearchCriteria.fromJson(Map<String, dynamic> json) => _$ReceiptSearchCriteriaFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptSearchCriteriaToJson(this);

  /// Crée des critères vides
  factory ReceiptSearchCriteria.empty() {
    return const ReceiptSearchCriteria();
  }

  /// Crée une copie avec des modifications
  ReceiptSearchCriteria copyWith({
    String? saleId,
    String? saleNumber,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    double? minAmount,
    double? maxAmount,
    bool? isReprint,
    String? reprintBy,
  }) {
    return ReceiptSearchCriteria(
      saleId: saleId ?? this.saleId,
      saleNumber: saleNumber ?? this.saleNumber,
      customerName: customerName ?? this.customerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      isReprint: isReprint ?? this.isReprint,
      reprintBy: reprintBy ?? this.reprintBy,
    );
  }

  /// Efface tous les critères
  ReceiptSearchCriteria clear() {
    return ReceiptSearchCriteria.empty();
  }

  /// Vérifie si des critères sont définis
  bool get hasFilters {
    return saleId?.isNotEmpty == true ||
        saleNumber?.isNotEmpty == true ||
        customerName?.isNotEmpty == true ||
        startDate != null ||
        endDate != null ||
        paymentMethod?.isNotEmpty == true ||
        minAmount != null ||
        maxAmount != null ||
        isReprint != null ||
        reprintBy?.isNotEmpty == true;
  }

  /// Nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (saleId?.isNotEmpty == true) count++;
    if (saleNumber?.isNotEmpty == true) count++;
    if (customerName?.isNotEmpty == true) count++;
    if (startDate != null) count++;
    if (endDate != null) count++;
    if (paymentMethod?.isNotEmpty == true) count++;
    if (minAmount != null) count++;
    if (maxAmount != null) count++;
    if (isReprint != null) count++;
    if (reprintBy?.isNotEmpty == true) count++;
    return count;
  }

  /// Convertit en paramètres de requête
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (saleId?.isNotEmpty == true) params['saleId'] = saleId;
    if (saleNumber?.isNotEmpty == true) params['saleNumber'] = saleNumber;
    if (customerName?.isNotEmpty == true) params['customerName'] = customerName;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (paymentMethod?.isNotEmpty == true) params['paymentMethod'] = paymentMethod;
    if (minAmount != null) params['minAmount'] = minAmount.toString();
    if (maxAmount != null) params['maxAmount'] = maxAmount.toString();
    if (isReprint != null) params['isReprint'] = isReprint.toString();
    if (reprintBy?.isNotEmpty == true) params['reprintBy'] = reprintBy;

    return params;
  }
}

/// Options de tri pour les reçus
enum ReceiptSortField {
  @JsonValue('saleDate')
  saleDate,
  @JsonValue('saleNumber')
  saleNumber,
  @JsonValue('totalAmount')
  totalAmount,
  @JsonValue('customerName')
  customerName,
  @JsonValue('paymentMethod')
  paymentMethod,
}

/// Direction du tri
enum SortDirection {
  @JsonValue('asc')
  ascending,
  @JsonValue('desc')
  descending,
}

/// Extension pour les champs de tri
extension ReceiptSortFieldExtension on ReceiptSortField {
  String get displayName {
    switch (this) {
      case ReceiptSortField.saleDate:
        return 'Date de vente';
      case ReceiptSortField.saleNumber:
        return 'Numéro de vente';
      case ReceiptSortField.totalAmount:
        return 'Montant total';
      case ReceiptSortField.customerName:
        return 'Nom du client';
      case ReceiptSortField.paymentMethod:
        return 'Mode de paiement';
    }
  }
}

/// Extension pour la direction du tri
extension SortDirectionExtension on SortDirection {
  String get displayName {
    switch (this) {
      case SortDirection.ascending:
        return 'Croissant';
      case SortDirection.descending:
        return 'Décroissant';
    }
  }
}

/// Options de tri pour les reçus
@JsonSerializable()
class ReceiptSortOptions {
  final ReceiptSortField field;
  final SortDirection direction;

  const ReceiptSortOptions({
    required this.field,
    required this.direction,
  });

  factory ReceiptSortOptions.fromJson(Map<String, dynamic> json) => _$ReceiptSortOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptSortOptionsToJson(this);

  /// Tri par défaut (date décroissante)
  factory ReceiptSortOptions.defaultSort() {
    return const ReceiptSortOptions(
      field: ReceiptSortField.saleDate,
      direction: SortDirection.descending,
    );
  }

  /// Crée une copie avec des modifications
  ReceiptSortOptions copyWith({
    ReceiptSortField? field,
    SortDirection? direction,
  }) {
    return ReceiptSortOptions(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }

  /// Inverse la direction du tri
  ReceiptSortOptions toggleDirection() {
    return copyWith(
      direction: direction == SortDirection.ascending ? SortDirection.descending : SortDirection.ascending,
    );
  }

  /// Convertit en paramètres de requête
  Map<String, String> toQueryParams() {
    return {
      'sortBy': field.name,
      'sortDirection': direction.name,
    };
  }
}

/// Options de pagination pour les reçus
@JsonSerializable()
class ReceiptPaginationOptions {
  final int page;
  final int limit;
  final int? offset;

  const ReceiptPaginationOptions({
    required this.page,
    required this.limit,
    this.offset,
  });

  factory ReceiptPaginationOptions.fromJson(Map<String, dynamic> json) => _$ReceiptPaginationOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptPaginationOptionsToJson(this);

  /// Pagination par défaut
  factory ReceiptPaginationOptions.defaultPagination() {
    return const ReceiptPaginationOptions(
      page: 1,
      limit: 20,
    );
  }

  /// Crée une copie avec des modifications
  ReceiptPaginationOptions copyWith({
    int? page,
    int? limit,
    int? offset,
  }) {
    return ReceiptPaginationOptions(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Page suivante
  ReceiptPaginationOptions nextPage() {
    return copyWith(page: page + 1);
  }

  /// Page précédente
  ReceiptPaginationOptions previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  /// Calcule l'offset
  int get calculatedOffset => offset ?? (page - 1) * limit;

  /// Convertit en paramètres de requête
  Map<String, String> toQueryParams() {
    return {
      'page': page.toString(),
      'limit': limit.toString(),
      'offset': calculatedOffset.toString(),
    };
  }
}

/// Requête complète de recherche de reçus
@JsonSerializable()
class ReceiptSearchRequest {
  final ReceiptSearchCriteria criteria;
  final ReceiptSortOptions sortOptions;
  final ReceiptPaginationOptions paginationOptions;

  const ReceiptSearchRequest({
    required this.criteria,
    required this.sortOptions,
    required this.paginationOptions,
  });

  factory ReceiptSearchRequest.fromJson(Map<String, dynamic> json) => _$ReceiptSearchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptSearchRequestToJson(this);

  /// Requête par défaut
  factory ReceiptSearchRequest.defaultRequest() {
    return ReceiptSearchRequest(
      criteria: ReceiptSearchCriteria.empty(),
      sortOptions: ReceiptSortOptions.defaultSort(),
      paginationOptions: ReceiptPaginationOptions.defaultPagination(),
    );
  }

  /// Crée une copie avec des modifications
  ReceiptSearchRequest copyWith({
    ReceiptSearchCriteria? criteria,
    ReceiptSortOptions? sortOptions,
    ReceiptPaginationOptions? paginationOptions,
  }) {
    return ReceiptSearchRequest(
      criteria: criteria ?? this.criteria,
      sortOptions: sortOptions ?? this.sortOptions,
      paginationOptions: paginationOptions ?? this.paginationOptions,
    );
  }

  /// Convertit en paramètres de requête
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    params.addAll(criteria.toQueryParams());
    params.addAll(sortOptions.toQueryParams());
    params.addAll(paginationOptions.toQueryParams());
    return params;
  }
}

/// Réponse de recherche de reçus
@JsonSerializable()
class ReceiptSearchResponse {
  final List<Receipt> receipts;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const ReceiptSearchResponse({
    required this.receipts,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory ReceiptSearchResponse.fromJson(Map<String, dynamic> json) => _$ReceiptSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptSearchResponseToJson(this);

  /// Crée une réponse vide
  factory ReceiptSearchResponse.empty() {
    return const ReceiptSearchResponse(
      receipts: [],
      totalCount: 0,
      currentPage: 1,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  /// Vérifie si la réponse est vide
  bool get isEmpty => receipts.isEmpty;

  /// Vérifie si la réponse contient des données
  bool get isNotEmpty => receipts.isNotEmpty;
}
