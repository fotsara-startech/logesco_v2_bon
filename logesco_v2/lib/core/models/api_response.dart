import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// Réponse de base de l'API
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final List<ApiError>? errors;
  final String timestamp;
  final Pagination? pagination;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    required this.timestamp,
    this.pagination,
  });

  /// Getter pour compatibilité avec l'ancien code
  bool get isSuccess => success;

  /// Getter pour le code d'erreur (compatibilité)
  String? get errorCode => errors?.isNotEmpty == true ? errors!.first.field : null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => _$ApiResponseToJson(this, toJsonT);

  /// Crée une réponse de succès
  factory ApiResponse.success(
    T? data, {
    String? message,
    Pagination? pagination,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      timestamp: DateTime.now().toIso8601String(),
      pagination: pagination,
    );
  }

  /// Crée une réponse d'erreur
  factory ApiResponse.error({
    String? message,
    List<ApiError>? errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}

/// Réponse paginée
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  final List<T> data;
  final Pagination pagination;
  final String? message;

  PaginatedResponse({
    required this.data,
    required this.pagination,
    this.message,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => _$PaginatedResponseToJson(this, toJsonT);
}

/// Informations de pagination
@JsonSerializable()
class Pagination {
  @JsonKey(defaultValue: 1)
  final int page;
  @JsonKey(defaultValue: 20)
  final int limit;
  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(name: 'pages', defaultValue: 0)
  final int totalPages;
  @JsonKey(defaultValue: false)
  final bool hasNext;
  @JsonKey(defaultValue: false)
  final bool hasPrev;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.hasNext = false,
    this.hasPrev = false,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    // Parsing sécurisé pour éviter les erreurs de cast
    try {
      return _$PaginationFromJson(json);
    } catch (e) {
      print('⚠️ Erreur parsing Pagination, utilisation des valeurs par défaut: $e');
      return Pagination(
        page: _parseInt(json['page'], 1),
        limit: _parseInt(json['limit'], 20),
        total: _parseInt(json['total'], 0),
        totalPages: _parseInt(json['pages'], 0),
        hasNext: json['hasNext'] as bool? ?? false,
        hasPrev: json['hasPrev'] as bool? ?? false,
      );
    }
  }

  /// Helper pour parser les entiers de manière sûre
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}

/// Erreur de l'API
@JsonSerializable()
class ApiError {
  final String field;
  final String message;
  final dynamic value;

  ApiError({
    required this.field,
    required this.message,
    this.value,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
