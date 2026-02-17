import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';

/// Service dédié aux rapports et analyses des mouvements financiers
class MovementReportService {
  final AuthService _authService;
  static const String _endpoint = '/financial-movements';

  MovementReportService(this._authService);

  /// Récupère un résumé des mouvements pour une période donnée
  Future<MovementSummary> getSummary(DateTime startDate, DateTime endDate) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/summary').replace(queryParameters: queryParams);

      print('🔄 Récupération du résumé depuis: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API résumé: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final summary = MovementSummary.fromJson(jsonData['data']);
        print('✅ Résumé récupéré avec succès');
        return summary;
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du résumé');
      }
    } catch (e) {
      print('💥 Erreur récupération résumé: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les statistiques par catégorie pour une période donnée
  Future<List<CategorySummary>> getCategorySummary(DateTime startDate, DateTime endDate) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/category-summary').replace(queryParameters: queryParams);

      print('🔄 Récupération du résumé par catégorie depuis: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API résumé catégories: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final summaries = <CategorySummary>[];
        final dataList = jsonData['data'] as List;

        for (final item in dataList) {
          try {
            final summary = CategorySummary.fromJson(item as Map<String, dynamic>);
            summaries.add(summary);
          } catch (e) {
            print('⚠️ Erreur parsing résumé catégorie, ignoré: $e');
          }
        }

        print('✅ ${summaries.length} résumés par catégorie récupérés avec succès');
        return summaries;
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du résumé par catégorie');
      }
    } catch (e) {
      print('💥 Erreur récupération résumé catégories: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les statistiques quotidiennes pour une période donnée
  Future<List<DailySummary>> getDailySummary(DateTime startDate, DateTime endDate) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/daily-summary').replace(queryParameters: queryParams);

      print('🔄 Récupération du résumé quotidien depuis: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API résumé quotidien: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final summaries = <DailySummary>[];
        final dataList = jsonData['data'] as List;

        for (final item in dataList) {
          try {
            final summary = DailySummary.fromJson(item as Map<String, dynamic>);
            summaries.add(summary);
          } catch (e) {
            print('⚠️ Erreur parsing résumé quotidien, ignoré: $e');
          }
        }

        print('✅ ${summaries.length} résumés quotidiens récupérés avec succès');
        return summaries;
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du résumé quotidien');
      }
    } catch (e) {
      print('💥 Erreur récupération résumé quotidien: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Exporte un rapport au format PDF
  Future<String> exportReportToPdf(MovementReportRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      print('🔄 Export PDF du rapport: ${request.title}');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_endpoint/export/pdf'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 60));

      print('📡 Réponse export PDF: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final downloadUrl = jsonData['data']['downloadUrl'] as String;

        // Télécharger le fichier PDF
        final pdfResponse = await http.get(Uri.parse(downloadUrl));

        if (pdfResponse.statusCode == 200) {
          // Sauvegarder le fichier localement
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'rapport_mouvements_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '${directory.path}/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(pdfResponse.bodyBytes);

          print('✅ Rapport PDF exporté avec succès: $filePath');
          return filePath;
        } else {
          throw Exception('Erreur lors du téléchargement du PDF');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'export PDF');
      }
    } catch (e) {
      print('💥 Erreur export PDF: $e');
      throw Exception('Erreur d\'export: $e');
    }
  }

  /// Exporte un rapport au format Excel
  Future<String> exportReportToExcel(MovementReportRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      print('🔄 Export Excel du rapport: ${request.title}');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_endpoint/export/excel'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 60));

      print('📡 Réponse export Excel: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final downloadUrl = jsonData['data']['downloadUrl'] as String;

        // Télécharger le fichier Excel
        final excelResponse = await http.get(Uri.parse(downloadUrl));

        if (excelResponse.statusCode == 200) {
          // Sauvegarder le fichier localement
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'rapport_mouvements_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final filePath = '${directory.path}/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(excelResponse.bodyBytes);

          print('✅ Rapport Excel exporté avec succès: $filePath');
          return filePath;
        } else {
          throw Exception('Erreur lors du téléchargement du fichier Excel');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'export Excel');
      }
    } catch (e) {
      print('💥 Erreur export Excel: $e');
      throw Exception('Erreur d\'export: $e');
    }
  }

  /// Génère un rapport complet avec toutes les données
  Future<MovementReport> generateCompleteReport(DateTime startDate, DateTime endDate) async {
    try {
      print('🔄 Génération du rapport complet du ${startDate.toIso8601String()} au ${endDate.toIso8601String()}');

      // Récupérer toutes les données en parallèle
      final futures = await Future.wait([
        getSummary(startDate, endDate),
        getCategorySummary(startDate, endDate),
        getDailySummary(startDate, endDate),
      ]);

      final summary = futures[0] as MovementSummary;
      final categorySummaries = futures[1] as List<CategorySummary>;
      final dailySummaries = futures[2] as List<DailySummary>;

      final report = MovementReport(
        startDate: startDate,
        endDate: endDate,
        summary: summary,
        categorySummaries: categorySummaries,
        dailySummaries: dailySummaries,
        generatedAt: DateTime.now(),
      );

      print('✅ Rapport complet généré avec succès');
      return report;
    } catch (e) {
      print('💥 Erreur génération rapport complet: $e');
      throw Exception('Erreur de génération: $e');
    }
  }

  /// Compare les mouvements financiers entre deux périodes
  Future<PeriodComparison> comparePeriods(
    DateTime period1Start,
    DateTime period1End,
    DateTime period2Start,
    DateTime period2End,
  ) async {
    try {
      print('🔄 Comparaison entre périodes:');
      print('   Période 1: ${period1Start.toIso8601String()} - ${period1End.toIso8601String()}');
      print('   Période 2: ${period2Start.toIso8601String()} - ${period2End.toIso8601String()}');

      // Récupérer les données des deux périodes en parallèle
      final futures = await Future.wait([
        getSummary(period1Start, period1End),
        getCategorySummary(period1Start, period1End),
        getSummary(period2Start, period2End),
        getCategorySummary(period2Start, period2End),
      ]);

      final period1Summary = futures[0] as MovementSummary;
      final period1Categories = futures[1] as List<CategorySummary>;
      final period2Summary = futures[2] as MovementSummary;
      final period2Categories = futures[3] as List<CategorySummary>;

      final comparison = PeriodComparison(
        period1Start: period1Start,
        period1End: period1End,
        period2Start: period2Start,
        period2End: period2End,
        period1Summary: period1Summary,
        period2Summary: period2Summary,
        period1Categories: period1Categories,
        period2Categories: period2Categories,
        generatedAt: DateTime.now(),
      );

      print('✅ Comparaison entre périodes générée avec succès');
      return comparison;
    } catch (e) {
      print('💥 Erreur comparaison périodes: $e');
      throw Exception('Erreur de comparaison: $e');
    }
  }
}

/// Modèle pour les résumés de mouvements financiers
class MovementSummary {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final double maxAmount;
  final double minAmount;
  final DateTime? lastMovementDate;

  MovementSummary({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    required this.maxAmount,
    required this.minAmount,
    this.lastMovementDate,
  });

  factory MovementSummary.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
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

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return MovementSummary(
      totalAmount: parseDouble(json['totalAmount']),
      totalCount: parseInt(json['totalCount']),
      averageAmount: parseDouble(json['averageAmount']),
      maxAmount: parseDouble(json['maxAmount']),
      minAmount: parseDouble(json['minAmount']),
      lastMovementDate: parseDate(json['lastMovementDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'averageAmount': averageAmount,
      'maxAmount': maxAmount,
      'minAmount': minAmount,
      if (lastMovementDate != null) 'lastMovementDate': lastMovementDate!.toIso8601String(),
    };
  }

  /// Formate le montant total avec la devise
  String get totalAmountFormatted => '${totalAmount.toStringAsFixed(2)} FCFA';

  /// Formate le montant moyen avec la devise
  String get averageAmountFormatted => '${averageAmount.toStringAsFixed(2)} FCFA';
}

/// Modèle pour les résumés par catégorie
class CategorySummary {
  final int categoryId;
  final String categoryName;
  final String categoryDisplayName;
  final String categoryColor;
  final String categoryIcon;
  final double amount;
  final int count;
  final double percentage;

  CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDisplayName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
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

    return CategorySummary(
      categoryId: parseInt(json['categoryId']),
      categoryName: json['categoryName']?.toString() ?? '',
      categoryDisplayName: json['categoryDisplayName']?.toString() ?? '',
      categoryColor: json['categoryColor']?.toString() ?? '#000000',
      categoryIcon: json['categoryIcon']?.toString() ?? 'category',
      amount: parseDouble(json['amount']),
      count: parseInt(json['count']),
      percentage: parseDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryDisplayName': categoryDisplayName,
      'categoryColor': categoryColor,
      'categoryIcon': categoryIcon,
      'amount': amount,
      'count': count,
      'percentage': percentage,
    };
  }

  /// Formate le montant avec la devise
  String get amountFormatted => '${amount.toStringAsFixed(2)} FCFA';

  /// Formate le pourcentage
  String get percentageFormatted => '${percentage.toStringAsFixed(1)}%';
}

/// Modèle pour les résumés quotidiens
class DailySummary {
  final DateTime date;
  final double amount;
  final int count;

  DailySummary({
    required this.date,
    required this.amount,
    required this.count,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
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

    DateTime parseDate(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return DailySummary(
      date: parseDate(json['date']),
      amount: parseDouble(json['amount']),
      count: parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'count': count,
    };
  }

  /// Formate le montant avec la devise
  String get amountFormatted => '${amount.toStringAsFixed(2)} FCFA';

  /// Formate la date
  String get dateFormatted => '${date.day}/${date.month}/${date.year}';
}

/// Modèle pour les demandes de rapport
class MovementReportRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final List<int>? categoryIds;
  final bool includeDetails;
  final String format; // 'pdf' ou 'excel'

  MovementReportRequest({
    required this.startDate,
    required this.endDate,
    required this.title,
    this.categoryIds,
    this.includeDetails = true,
    this.format = 'pdf',
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'title': title,
      if (categoryIds != null) 'categoryIds': categoryIds,
      'includeDetails': includeDetails,
      'format': format,
    };
  }
}

/// Modèle pour un rapport complet
class MovementReport {
  final DateTime startDate;
  final DateTime endDate;
  final MovementSummary summary;
  final List<CategorySummary> categorySummaries;
  final List<DailySummary> dailySummaries;
  final DateTime generatedAt;

  MovementReport({
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.categorySummaries,
    required this.dailySummaries,
    required this.generatedAt,
  });

  /// Période du rapport formatée
  String get periodFormatted {
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  /// Nombre de jours dans la période
  int get dayCount {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Moyenne quotidienne
  double get dailyAverage {
    return summary.totalAmount / dayCount;
  }

  /// Moyenne quotidienne formatée
  String get dailyAverageFormatted {
    return '${dailyAverage.toStringAsFixed(2)} FCFA';
  }
}

/// Modèle pour la comparaison entre deux périodes
class PeriodComparison {
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;
  final MovementSummary period1Summary;
  final MovementSummary period2Summary;
  final List<CategorySummary> period1Categories;
  final List<CategorySummary> period2Categories;
  final DateTime generatedAt;

  PeriodComparison({
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
    required this.period1Summary,
    required this.period2Summary,
    required this.period1Categories,
    required this.period2Categories,
    required this.generatedAt,
  });

  /// Période 1 formatée
  String get period1Formatted {
    return '${period1Start.day}/${period1Start.month}/${period1Start.year} - ${period1End.day}/${period1End.month}/${period1End.year}';
  }

  /// Période 2 formatée
  String get period2Formatted {
    return '${period2Start.day}/${period2Start.month}/${period2Start.year} - ${period2End.day}/${period2End.month}/${period2End.year}';
  }

  /// Différence de montant total entre les périodes
  double get totalAmountDifference {
    return period1Summary.totalAmount - period2Summary.totalAmount;
  }

  /// Pourcentage de variation du montant total
  double get totalAmountVariationPercent {
    if (period2Summary.totalAmount == 0) return 0;
    return ((period1Summary.totalAmount - period2Summary.totalAmount) / period2Summary.totalAmount) * 100;
  }

  /// Différence du nombre de mouvements
  int get countDifference {
    return period1Summary.totalCount - period2Summary.totalCount;
  }

  /// Pourcentage de variation du nombre de mouvements
  double get countVariationPercent {
    if (period2Summary.totalCount == 0) return 0;
    return ((period1Summary.totalCount - period2Summary.totalCount) / period2Summary.totalCount) * 100;
  }

  /// Différence de montant moyen
  double get averageAmountDifference {
    return period1Summary.averageAmount - period2Summary.averageAmount;
  }

  /// Pourcentage de variation du montant moyen
  double get averageAmountVariationPercent {
    if (period2Summary.averageAmount == 0) return 0;
    return ((period1Summary.averageAmount - period2Summary.averageAmount) / period2Summary.averageAmount) * 100;
  }

  /// Comparaisons par catégorie
  List<CategoryComparison> get categoryComparisons {
    final comparisons = <CategoryComparison>[];

    // Créer une map des catégories de la période 2 pour faciliter la recherche
    final period2Map = <int, CategorySummary>{};
    for (final cat in period2Categories) {
      period2Map[cat.categoryId] = cat;
    }

    // Comparer chaque catégorie de la période 1
    for (final cat1 in period1Categories) {
      final cat2 = period2Map[cat1.categoryId];
      comparisons.add(CategoryComparison(
        categoryId: cat1.categoryId,
        categoryName: cat1.categoryName,
        categoryDisplayName: cat1.categoryDisplayName,
        categoryColor: cat1.categoryColor,
        categoryIcon: cat1.categoryIcon,
        period1Amount: cat1.amount,
        period2Amount: cat2?.amount ?? 0,
        period1Count: cat1.count,
        period2Count: cat2?.count ?? 0,
        period1Percentage: cat1.percentage,
        period2Percentage: cat2?.percentage ?? 0,
      ));

      // Retirer de la map pour éviter les doublons
      period2Map.remove(cat1.categoryId);
    }

    // Ajouter les catégories qui n'existent que dans la période 2
    for (final cat2 in period2Map.values) {
      comparisons.add(CategoryComparison(
        categoryId: cat2.categoryId,
        categoryName: cat2.categoryName,
        categoryDisplayName: cat2.categoryDisplayName,
        categoryColor: cat2.categoryColor,
        categoryIcon: cat2.categoryIcon,
        period1Amount: 0,
        period2Amount: cat2.amount,
        period1Count: 0,
        period2Count: cat2.count,
        period1Percentage: 0,
        period2Percentage: cat2.percentage,
      ));
    }

    return comparisons;
  }

  /// Indique si la période 1 a plus de dépenses que la période 2
  bool get hasIncreasedExpenses => totalAmountDifference > 0;

  /// Indique si la période 1 a moins de dépenses que la période 2
  bool get hasDecreasedExpenses => totalAmountDifference < 0;

  /// Indique si les dépenses sont stables (différence < 5%)
  bool get hasStableExpenses => totalAmountVariationPercent.abs() < 5;

  /// Résumé textuel de la comparaison
  String get comparisonSummary {
    if (hasStableExpenses) {
      return 'Dépenses stables entre les deux périodes';
    } else if (hasIncreasedExpenses) {
      return 'Augmentation de ${totalAmountVariationPercent.toStringAsFixed(1)}% des dépenses';
    } else {
      return 'Diminution de ${totalAmountVariationPercent.abs().toStringAsFixed(1)}% des dépenses';
    }
  }
}

/// Modèle pour la comparaison d'une catégorie entre deux périodes
class CategoryComparison {
  final int categoryId;
  final String categoryName;
  final String categoryDisplayName;
  final String categoryColor;
  final String categoryIcon;
  final double period1Amount;
  final double period2Amount;
  final int period1Count;
  final int period2Count;
  final double period1Percentage;
  final double period2Percentage;

  CategoryComparison({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDisplayName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.period1Amount,
    required this.period2Amount,
    required this.period1Count,
    required this.period2Count,
    required this.period1Percentage,
    required this.period2Percentage,
  });

  /// Différence de montant entre les périodes
  double get amountDifference => period1Amount - period2Amount;

  /// Pourcentage de variation du montant
  double get amountVariationPercent {
    if (period2Amount == 0) return period1Amount > 0 ? 100 : 0;
    return ((period1Amount - period2Amount) / period2Amount) * 100;
  }

  /// Différence du nombre de mouvements
  int get countDifference => period1Count - period2Count;

  /// Pourcentage de variation du nombre de mouvements
  double get countVariationPercent {
    if (period2Count == 0) return period1Count > 0 ? 100 : 0;
    return ((period1Count - period2Count) / period2Count) * 100;
  }

  /// Différence de pourcentage de répartition
  double get percentageDifference => period1Percentage - period2Percentage;

  /// Indique si cette catégorie a augmenté
  bool get hasIncreased => amountDifference > 0;

  /// Indique si cette catégorie a diminué
  bool get hasDecreased => amountDifference < 0;

  /// Indique si cette catégorie est stable (différence < 5%)
  bool get isStable => amountVariationPercent.abs() < 5;

  /// Montant période 1 formaté
  String get period1AmountFormatted => '${period1Amount.toStringAsFixed(2)} FCFA';

  /// Montant période 2 formaté
  String get period2AmountFormatted => '${period2Amount.toStringAsFixed(2)} FCFA';

  /// Différence de montant formatée
  String get amountDifferenceFormatted {
    final sign = amountDifference >= 0 ? '+' : '';
    return '$sign${amountDifference.toStringAsFixed(2)} FCFA';
  }

  /// Variation en pourcentage formatée
  String get variationPercentFormatted {
    final sign = amountVariationPercent >= 0 ? '+' : '';
    return '$sign${amountVariationPercent.toStringAsFixed(1)}%';
  }
}
