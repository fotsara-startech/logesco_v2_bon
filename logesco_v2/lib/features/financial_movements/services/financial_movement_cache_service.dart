import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/financial_movement.dart';
import '../models/movement_category.dart';

/// Service de cache local pour les mouvements financiers
class FinancialMovementCacheService {
  static const String _boxName = 'financial_movements_cache';
  static const String _movementsKey = 'movements';
  static const String _categoriesKey = 'categories';
  static const String _statisticsKey = 'statistics';
  static const String _lastSyncKey = 'last_sync';
  static const String _movementDetailPrefix = 'movement_detail_';

  // Durée de validité du cache (en minutes)
  static const int _cacheValidityMinutes = 30;

  late final GetStorage _storage;
  bool _isInitialized = false;

  /// Initialise le service de cache
  Future<void> init() async {
    if (_isInitialized) {
      print('💾 Cache service déjà initialisé, ignoré');
      return;
    }

    await GetStorage.init(_boxName);
    _storage = GetStorage(_boxName);
    _isInitialized = true;
    print('💾 Cache service initialisé avec succès');
  }

  /// Vérifie si le cache est valide
  bool _isCacheValid(String key) {
    final lastSync = _storage.read('${key}_timestamp');
    if (lastSync == null) return false;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime).inMinutes;

    return difference < _cacheValidityMinutes;
  }

  /// Sauvegarde les mouvements financiers en cache
  Future<void> cacheMovements(List<FinancialMovement> movements, {String? cacheKey}) async {
    try {
      final key = cacheKey ?? _movementsKey;
      final movementsJson = movements.map((m) => m.toJson()).toList();

      await _storage.write(key, json.encode(movementsJson));
      await _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);

      print('💾 ${movements.length} mouvements mis en cache avec la clé: $key');
    } catch (e) {
      print('⚠️ Erreur lors de la mise en cache des mouvements: $e');
    }
  }

  /// Récupère les mouvements financiers depuis le cache
  List<FinancialMovement>? getCachedMovements({String? cacheKey}) {
    try {
      final key = cacheKey ?? _movementsKey;

      if (!_isCacheValid(key)) {
        print('⏰ Cache expiré pour la clé: $key');
        return null;
      }

      final cachedData = _storage.read(key);
      if (cachedData == null) return null;

      final List<dynamic> movementsJson = json.decode(cachedData);
      final movements = movementsJson.map((json) => FinancialMovement.fromJson(json as Map<String, dynamic>)).toList();

      print('📦 ${movements.length} mouvements récupérés du cache avec la clé: $key');
      return movements;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des mouvements en cache: $e');
      return null;
    }
  }

  /// Sauvegarde les catégories en cache
  Future<void> cacheCategories(List<MovementCategory> categories) async {
    try {
      final categoriesJson = categories.map((c) => c.toJson()).toList();

      await _storage.write(_categoriesKey, json.encode(categoriesJson));
      await _storage.write('${_categoriesKey}_timestamp', DateTime.now().millisecondsSinceEpoch);

      print('💾 ${categories.length} catégories mises en cache');
    } catch (e) {
      print('⚠️ Erreur lors de la mise en cache des catégories: $e');
    }
  }

  /// Récupère les catégories depuis le cache
  List<MovementCategory>? getCachedCategories() {
    try {
      if (!_isCacheValid(_categoriesKey)) {
        print('⏰ Cache des catégories expiré');
        return null;
      }

      final cachedData = _storage.read(_categoriesKey);
      if (cachedData == null) return null;

      final List<dynamic> categoriesJson = json.decode(cachedData);
      final categories = categoriesJson.map((json) => MovementCategory.fromJson(json as Map<String, dynamic>)).toList();

      print('📦 ${categories.length} catégories récupérées du cache');
      return categories;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des catégories en cache: $e');
      return null;
    }
  }

  /// Sauvegarde les statistiques en cache
  Future<void> cacheStatistics(Map<String, dynamic> statistics, {String? period}) async {
    try {
      final key = period != null ? '${_statisticsKey}_$period' : _statisticsKey;

      await _storage.write(key, json.encode(statistics));
      await _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);

      print('💾 Statistiques mises en cache avec la clé: $key');
    } catch (e) {
      print('⚠️ Erreur lors de la mise en cache des statistiques: $e');
    }
  }

  /// Récupère les statistiques depuis le cache
  Map<String, dynamic>? getCachedStatistics({String? period}) {
    try {
      final key = period != null ? '${_statisticsKey}_$period' : _statisticsKey;

      if (!_isCacheValid(key)) {
        print('⏰ Cache des statistiques expiré pour la clé: $key');
        return null;
      }

      final cachedData = _storage.read(key);
      if (cachedData == null) return null;

      final statistics = json.decode(cachedData) as Map<String, dynamic>;

      print('📦 Statistiques récupérées du cache avec la clé: $key');
      return statistics;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des statistiques en cache: $e');
      return null;
    }
  }

  /// Sauvegarde un mouvement individuel en cache
  Future<void> cacheMovementDetail(FinancialMovement movement) async {
    try {
      final key = '$_movementDetailPrefix${movement.id}';

      await _storage.write(key, json.encode(movement.toJson()));
      await _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);

      print('💾 Détail du mouvement ${movement.id} mis en cache');
    } catch (e) {
      print('⚠️ Erreur lors de la mise en cache du détail du mouvement: $e');
    }
  }

  /// Récupère un mouvement individuel depuis le cache
  FinancialMovement? getCachedMovementDetail(int movementId) {
    try {
      final key = '$_movementDetailPrefix$movementId';

      if (!_isCacheValid(key)) {
        print('⏰ Cache du mouvement $movementId expiré');
        return null;
      }

      final cachedData = _storage.read(key);
      if (cachedData == null) return null;

      final movementJson = json.decode(cachedData) as Map<String, dynamic>;
      final movement = FinancialMovement.fromJson(movementJson);

      print('📦 Détail du mouvement $movementId récupéré du cache');
      return movement;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération du détail du mouvement en cache: $e');
      return null;
    }
  }

  /// Génère une clé de cache basée sur les filtres
  String generateCacheKey({
    int? page,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    String? search,
    double? minAmount,
    double? maxAmount,
  }) {
    final keyParts = <String>[];

    if (page != null) keyParts.add('page_$page');
    if (limit != null) keyParts.add('limit_$limit');
    if (startDate != null) keyParts.add('start_${startDate.millisecondsSinceEpoch}');
    if (endDate != null) keyParts.add('end_${endDate.millisecondsSinceEpoch}');
    if (categoryId != null) keyParts.add('cat_$categoryId');
    if (search != null && search.isNotEmpty) keyParts.add('search_${search.hashCode}');
    if (minAmount != null) keyParts.add('min_${minAmount.toStringAsFixed(2)}');
    if (maxAmount != null) keyParts.add('max_${maxAmount.toStringAsFixed(2)}');

    return keyParts.isEmpty ? _movementsKey : '${_movementsKey}_${keyParts.join('_')}';
  }

  /// Invalide le cache d'un mouvement spécifique
  Future<void> invalidateMovementCache(int movementId) async {
    try {
      final key = '$_movementDetailPrefix$movementId';
      await _storage.remove(key);
      await _storage.remove('${key}_timestamp');

      print('🗑️ Cache du mouvement $movementId invalidé');
    } catch (e) {
      print('⚠️ Erreur lors de l\'invalidation du cache du mouvement: $e');
    }
  }

  /// Invalide tout le cache des mouvements
  Future<void> invalidateMovementsCache() async {
    try {
      // Récupère toutes les clés du storage
      final keys = _storage.getKeys();

      // Supprime toutes les clés liées aux mouvements
      for (final key in keys) {
        if (key.toString().startsWith(_movementsKey) || key.toString().startsWith(_movementDetailPrefix)) {
          await _storage.remove(key);
        }
      }

      print('🗑️ Cache des mouvements entièrement invalidé');
    } catch (e) {
      print('⚠️ Erreur lors de l\'invalidation du cache des mouvements: $e');
    }
  }

  /// Invalide le cache des catégories
  Future<void> invalidateCategoriesCache() async {
    try {
      await _storage.remove(_categoriesKey);
      await _storage.remove('${_categoriesKey}_timestamp');

      print('🗑️ Cache des catégories invalidé');
    } catch (e) {
      print('⚠️ Erreur lors de l\'invalidation du cache des catégories: $e');
    }
  }

  /// Invalide le cache des statistiques
  Future<void> invalidateStatisticsCache() async {
    try {
      final keys = _storage.getKeys();

      // Supprime toutes les clés liées aux statistiques
      for (final key in keys) {
        if (key.toString().startsWith(_statisticsKey)) {
          await _storage.remove(key);
        }
      }

      print('🗑️ Cache des statistiques invalidé');
    } catch (e) {
      print('⚠️ Erreur lors de l\'invalidation du cache des statistiques: $e');
    }
  }

  /// Nettoie tout le cache
  Future<void> clearAllCache() async {
    try {
      await _storage.erase();
      print('🗑️ Tout le cache des mouvements financiers a été nettoyé');
    } catch (e) {
      print('⚠️ Erreur lors du nettoyage du cache: $e');
    }
  }

  /// Obtient la taille du cache en octets (approximative)
  int getCacheSize() {
    try {
      final keys = _storage.getKeys();
      int totalSize = 0;

      for (final key in keys) {
        final value = _storage.read(key);
        if (value != null) {
          totalSize += value.toString().length * 2; // Approximation UTF-16
        }
      }

      return totalSize;
    } catch (e) {
      print('⚠️ Erreur lors du calcul de la taille du cache: $e');
      return 0;
    }
  }

  /// Obtient des informations sur le cache
  Map<String, dynamic> getCacheInfo() {
    try {
      final keys = _storage.getKeys();
      final info = <String, dynamic>{
        'totalKeys': keys.length,
        'sizeBytes': getCacheSize(),
        'lastSync': _storage.read(_lastSyncKey),
        'categories': {
          'cached': _storage.hasData(_categoriesKey),
          'valid': _isCacheValid(_categoriesKey),
        },
        'movements': {
          'keysCount': keys.where((k) => k.toString().startsWith(_movementsKey)).length,
        },
        'statistics': {
          'keysCount': keys.where((k) => k.toString().startsWith(_statisticsKey)).length,
        },
      };

      return info;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des informations du cache: $e');
      return {};
    }
  }
}
