import 'package:json_annotation/json_annotation.dart';

part 'print_format.g.dart';

/// Énumération des formats d'impression supportés
enum PrintFormat {
  @JsonValue('a4')
  a4,
  @JsonValue('a5')
  a5,
  @JsonValue('thermal')
  thermal,
}

/// Extension pour les propriétés des formats d'impression
extension PrintFormatExtension on PrintFormat {
  /// Nom d'affichage du format
  String get displayName {
    switch (this) {
      case PrintFormat.a4:
        return 'A4 (210 x 297 mm)';
      case PrintFormat.a5:
        return 'A5 (148 x 210 mm)';
      case PrintFormat.thermal:
        return 'Thermique (80 mm)';
    }
  }

  /// Largeur en millimètres
  double get widthMm {
    switch (this) {
      case PrintFormat.a4:
        return 210.0;
      case PrintFormat.a5:
        return 148.0;
      case PrintFormat.thermal:
        return 80.0;
    }
  }

  /// Hauteur en millimètres (variable pour thermique)
  double get heightMm {
    switch (this) {
      case PrintFormat.a4:
        return 297.0;
      case PrintFormat.a5:
        return 210.0;
      case PrintFormat.thermal:
        return 0.0; // Variable selon le contenu
    }
  }

  /// Largeur en points (72 DPI)
  double get widthPoints {
    return widthMm * 2.834645669;
  }

  /// Hauteur en points (72 DPI)
  double get heightPoints {
    return heightMm * 2.834645669;
  }

  /// Marges par défaut en millimètres
  PrintMargins get defaultMargins {
    switch (this) {
      case PrintFormat.a4:
        return const PrintMargins.all(20.0);
      case PrintFormat.a5:
        return const PrintMargins.all(15.0);
      case PrintFormat.thermal:
        return const PrintMargins.symmetric(horizontal: 8.0, vertical: 12.0);
    }
  }

  /// Taille de police par défaut
  double get defaultFontSize {
    switch (this) {
      case PrintFormat.a4:
        return 12.0;
      case PrintFormat.a5:
        return 10.0;
      case PrintFormat.thermal:
        return 8.5;
    }
  }

  /// Taille de police pour le titre
  double get titleFontSize {
    switch (this) {
      case PrintFormat.a4:
        return 18.0;
      case PrintFormat.a5:
        return 16.0;
      case PrintFormat.thermal:
        return 11.5;
    }
  }

  /// Taille de police pour les en-têtes
  double get headerFontSize {
    switch (this) {
      case PrintFormat.a4:
        return 14.0;
      case PrintFormat.a5:
        return 12.0;
      case PrintFormat.thermal:
        return 10.5;
    }
  }

  /// Indique si le format supporte les couleurs
  bool get supportsColor {
    switch (this) {
      case PrintFormat.a4:
      case PrintFormat.a5:
        return true;
      case PrintFormat.thermal:
        return false;
    }
  }

  /// Indique si le format nécessite une génération PDF
  bool get requiresPdf {
    switch (this) {
      case PrintFormat.a4:
      case PrintFormat.a5:
        return true;
      case PrintFormat.thermal:
        return false;
    }
  }
}

/// Classe pour les marges d'impression
@JsonSerializable()
class PrintMargins {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const PrintMargins({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  const PrintMargins.all(double value)
      : top = value,
        right = value,
        bottom = value,
        left = value;

  const PrintMargins.symmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  })  : top = vertical,
        right = horizontal,
        bottom = vertical,
        left = horizontal;

  const PrintMargins.only({
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
  });

  factory PrintMargins.fromJson(Map<String, dynamic> json) => _$PrintMarginsFromJson(json);
  Map<String, dynamic> toJson() => _$PrintMarginsToJson(this);

  /// Largeur totale des marges horizontales
  double get horizontal => left + right;

  /// Hauteur totale des marges verticales
  double get vertical => top + bottom;
}

/// Configuration de template pour un format d'impression
@JsonSerializable()
class PrintTemplate {
  final PrintFormat format;
  final PrintMargins margins;
  final double fontSize;
  final double titleFontSize;
  final double headerFontSize;
  final bool showLogo;
  final bool showBorder;
  final Map<String, dynamic> customSettings;

  const PrintTemplate({
    required this.format,
    required this.margins,
    required this.fontSize,
    required this.titleFontSize,
    required this.headerFontSize,
    this.showLogo = true,
    this.showBorder = false,
    this.customSettings = const {},
  });

  factory PrintTemplate.fromJson(Map<String, dynamic> json) => _$PrintTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$PrintTemplateToJson(this);

  /// Crée un template par défaut pour un format donné
  factory PrintTemplate.defaultFor(PrintFormat format) {
    return PrintTemplate(
      format: format,
      margins: format.defaultMargins,
      fontSize: format.defaultFontSize,
      titleFontSize: format.titleFontSize,
      headerFontSize: format.headerFontSize,
      showLogo: format != PrintFormat.thermal,
      showBorder: format == PrintFormat.a4,
    );
  }

  /// Crée une copie avec des modifications
  PrintTemplate copyWith({
    PrintFormat? format,
    PrintMargins? margins,
    double? fontSize,
    double? titleFontSize,
    double? headerFontSize,
    bool? showLogo,
    bool? showBorder,
    Map<String, dynamic>? customSettings,
  }) {
    return PrintTemplate(
      format: format ?? this.format,
      margins: margins ?? this.margins,
      fontSize: fontSize ?? this.fontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      headerFontSize: headerFontSize ?? this.headerFontSize,
      showLogo: showLogo ?? this.showLogo,
      showBorder: showBorder ?? this.showBorder,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Largeur disponible pour le contenu
  double get contentWidth => format.widthMm - margins.horizontal;

  /// Hauteur disponible pour le contenu (si applicable)
  double get contentHeight => format.heightMm > 0 ? format.heightMm - margins.vertical : 0;
}
