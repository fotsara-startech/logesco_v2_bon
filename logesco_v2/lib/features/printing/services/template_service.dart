import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/print_format.dart';
import '../models/receipt_model.dart';
import '../widgets/receipt_template_factory.dart';

/// Service pour la gestion des templates de reçu
class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  // Cache des templates par défaut
  final Map<PrintFormat, PrintTemplate> _defaultTemplates = {};

  // Templates personnalisés par utilisateur/entreprise
  final Map<String, Map<PrintFormat, PrintTemplate>> _customTemplates = {};

  /// Initialise le service avec les templates par défaut
  void initialize() {
    _loadDefaultTemplates();
  }

  /// Charge les templates par défaut pour tous les formats
  void _loadDefaultTemplates() {
    for (final format in PrintFormat.values) {
      _defaultTemplates[format] = PrintTemplate.defaultFor(format);
    }
  }

  /// Obtient le template par défaut pour un format
  PrintTemplate getDefaultTemplate(PrintFormat format) {
    return _defaultTemplates[format] ?? PrintTemplate.defaultFor(format);
  }

  /// Obtient le template personnalisé ou par défaut pour un format
  PrintTemplate getTemplate({
    required PrintFormat format,
    String? companyId,
  }) {
    if (companyId != null && _customTemplates.containsKey(companyId)) {
      final companyTemplates = _customTemplates[companyId]!;
      if (companyTemplates.containsKey(format)) {
        return companyTemplates[format]!;
      }
    }

    return getDefaultTemplate(format);
  }

  /// Sauvegarde un template personnalisé
  void saveCustomTemplate({
    required PrintFormat format,
    required PrintTemplate template,
    required String companyId,
  }) {
    if (!_customTemplates.containsKey(companyId)) {
      _customTemplates[companyId] = {};
    }

    _customTemplates[companyId]![format] = template;

    // TODO: Sauvegarder en base de données ou stockage local
    _saveToStorage(companyId, format, template);
  }

  /// Supprime un template personnalisé
  void removeCustomTemplate({
    required PrintFormat format,
    required String companyId,
  }) {
    if (_customTemplates.containsKey(companyId)) {
      _customTemplates[companyId]!.remove(format);

      if (_customTemplates[companyId]!.isEmpty) {
        _customTemplates.remove(companyId);
      }
    }

    // TODO: Supprimer du stockage
    _removeFromStorage(companyId, format);
  }

  /// Réinitialise un template aux valeurs par défaut
  void resetToDefault({
    required PrintFormat format,
    required String companyId,
  }) {
    removeCustomTemplate(format: format, companyId: companyId);
  }

  /// Obtient tous les templates disponibles pour une entreprise
  Map<PrintFormat, PrintTemplate> getAllTemplates({String? companyId}) {
    final templates = <PrintFormat, PrintTemplate>{};

    for (final format in PrintFormat.values) {
      templates[format] = getTemplate(format: format, companyId: companyId);
    }

    return templates;
  }

  /// Valide un template
  bool validateTemplate(PrintTemplate template) {
    try {
      // Vérifications de base
      if (template.fontSize <= 0 || template.fontSize > 72) return false;
      if (template.titleFontSize <= 0 || template.titleFontSize > 72) return false;
      if (template.headerFontSize <= 0 || template.headerFontSize > 72) return false;

      // Vérifications des marges
      if (template.margins.top < 0 || template.margins.top > 50) return false;
      if (template.margins.bottom < 0 || template.margins.bottom > 50) return false;
      if (template.margins.left < 0 || template.margins.left > 50) return false;
      if (template.margins.right < 0 || template.margins.right > 50) return false;

      // Vérifications spécifiques au format
      switch (template.format) {
        case PrintFormat.thermal:
          // Pour le thermique, les marges doivent être plus petites
          if (template.margins.horizontal > 10) return false;
          break;
        case PrintFormat.a4:
        case PrintFormat.a5:
          // Pas de restrictions particulières
          break;
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la validation du template: $e');
      return false;
    }
  }

  /// Crée un template personnalisé basé sur un template existant
  PrintTemplate createCustomTemplate({
    required PrintTemplate baseTemplate,
    double? fontSize,
    double? titleFontSize,
    double? headerFontSize,
    PrintMargins? margins,
    bool? showLogo,
    bool? showBorder,
    Map<String, dynamic>? customSettings,
  }) {
    final newTemplate = baseTemplate.copyWith(
      fontSize: fontSize,
      titleFontSize: titleFontSize,
      headerFontSize: headerFontSize,
      margins: margins,
      showLogo: showLogo,
      showBorder: showBorder,
      customSettings: customSettings,
    );

    if (!validateTemplate(newTemplate)) {
      throw ArgumentError('Template invalide');
    }

    return newTemplate;
  }

  /// Obtient les paramètres recommandés pour un format
  Map<String, dynamic> getRecommendedSettings(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return {
          'fontSize': 12.0,
          'titleFontSize': 18.0,
          'headerFontSize': 14.0,
          'margins': const EdgeInsets.all(20.0),
          'showLogo': true,
          'showBorder': true,
        };

      case PrintFormat.a5:
        return {
          'fontSize': 10.0,
          'titleFontSize': 16.0,
          'headerFontSize': 12.0,
          'margins': const EdgeInsets.all(15.0),
          'showLogo': true,
          'showBorder': false,
        };

      case PrintFormat.thermal:
        return {
          'fontSize': 8.5,
          'titleFontSize': 11.5,
          'headerFontSize': 10.5,
          'margins': const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          'showLogo': false,
          'showBorder': false,
        };
    }
  }

  /// Exporte un template vers JSON
  Map<String, dynamic> exportTemplate(PrintTemplate template) {
    return template.toJson();
  }

  /// Importe un template depuis JSON
  PrintTemplate importTemplate(Map<String, dynamic> json) {
    try {
      final template = PrintTemplate.fromJson(json);

      if (!validateTemplate(template)) {
        throw ArgumentError('Template importé invalide');
      }

      return template;
    } catch (e) {
      throw ArgumentError('Erreur lors de l\'importation du template: $e');
    }
  }

  /// Sauvegarde dans le stockage local (à implémenter)
  Future<void> _saveToStorage(String companyId, PrintFormat format, PrintTemplate template) async {
    // TODO: Implémenter la sauvegarde en base de données ou SharedPreferences
    debugPrint('Sauvegarde template $format pour entreprise $companyId');
  }

  /// Supprime du stockage local (à implémenter)
  Future<void> _removeFromStorage(String companyId, PrintFormat format) async {
    // TODO: Implémenter la suppression du stockage
    debugPrint('Suppression template $format pour entreprise $companyId');
  }

  /// Charge les templates personnalisés depuis le stockage (à implémenter)
  Future<void> loadCustomTemplates(String companyId) async {
    // TODO: Implémenter le chargement depuis la base de données
    debugPrint('Chargement templates personnalisés pour entreprise $companyId');
  }

  /// Obtient les statistiques d'utilisation des templates
  Map<String, dynamic> getUsageStats() {
    return {
      'defaultTemplatesCount': _defaultTemplates.length,
      'customTemplatesCount': _customTemplates.values.map((templates) => templates.length).fold(0, (sum, count) => sum + count),
      'companiesWithCustomTemplates': _customTemplates.length,
    };
  }

  /// Nettoie le cache des templates
  void clearCache() {
    _customTemplates.clear();
    _loadDefaultTemplates();
  }
}
