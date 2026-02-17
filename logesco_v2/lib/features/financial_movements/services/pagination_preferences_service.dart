import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/pagination_widget.dart';

/// Service pour gérer les préférences de pagination
class PaginationPreferencesService {
  static const String _paginationTypeKey = 'financial_movements_pagination_type';
  static const String _pageSizeKey = 'financial_movements_page_size';

  /// Sauvegarde le type de pagination préféré
  static Future<void> savePaginationType(PaginationType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paginationTypeKey, type.name);
  }

  /// Récupère le type de pagination préféré
  static Future<PaginationType> getPaginationType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeString = prefs.getString(_paginationTypeKey);

    if (typeString == null) {
      return PaginationType.infinite; // Valeur par défaut
    }

    return PaginationType.values.firstWhere(
      (type) => type.name == typeString,
      orElse: () => PaginationType.infinite,
    );
  }

  /// Sauvegarde la taille de page préférée
  static Future<void> savePageSize(int pageSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageSizeKey, pageSize);
  }

  /// Récupère la taille de page préférée
  static Future<int> getPageSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pageSizeKey) ?? 20; // Valeur par défaut
  }

  /// Efface toutes les préférences de pagination
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_paginationTypeKey);
    await prefs.remove(_pageSizeKey);
  }
}
