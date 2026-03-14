import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/financial_balance.dart';
import '../../sales/models/sale.dart';
import '../../financial_movements/models/financial_movement.dart';
import 'package:intl/intl.dart';

/// Service pour la gestion de la comptabilité et des bilans financiers
class AccountingService {
  final AuthService _authService;
  final String _baseUrl = ApiConfig.baseUrl;

  AccountingService(this._authService);

  /// Formate une date pour l'API (essaie différents formats)
  String _formatDateForApi(DateTime date) {
    // Format ISO8601 (par défaut)
    final iso8601 = date.toIso8601String();

    // Format date seulement (YYYY-MM-DD)
    final dateOnly = DateFormat('yyyy-MM-dd').format(date);

    // Format avec heure de début/fin de journée
    final startOfDay = DateTime(date.year, date.month, date.day);

    print('🗓️ Formats de date testés pour ${date.day}/${date.month}/${date.year}:');
    print('  - ISO8601: $iso8601');
    print('  - Date seule: $dateOnly');
    print('  - Début de journée: ${startOfDay.toIso8601String()}');

    return dateOnly; // Commençons par tester le format date seule
  }

  /// Calcule le bilan financier pour une période donnée
  Future<FinancialBalance> calculateFinancialBalance({
    required DateTime startDate,
    required DateTime endDate,
    int? categoryId,
  }) async {
    try {
      print('🔍 Récupération des données pour la période: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}');
      if (categoryId != null) {
        print('   Filtre catégorie: $categoryId');
      }

      // Récupérer les ventes et les mouvements financiers en parallèle
      final results = await Future.wait([
        _getSalesForPeriod(startDate, endDate, categoryId: categoryId),
        _getExpensesForPeriod(startDate, endDate),
      ]);

      final sales = results[0] as List<Sale>;
      final expenses = results[1] as List<FinancialMovement>;

      print('📈 Données récupérées: ${sales.length} ventes, ${expenses.length} dépenses');

      if (sales.isEmpty && expenses.isEmpty) {
        print('ℹ️ Aucune donnée trouvée pour la période sélectionnée');
      }

      return await _calculateBalance(sales, expenses, startDate, endDate);
    } catch (e) {
      print('❌ Erreur lors du calcul du bilan: $e');
      rethrow;
    }
  }

  /// Récupère les catégories de produits
  Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categoriesList = (data['data'] ?? data) as List;
        return categoriesList.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('❌ Erreur API catégories: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur getProductCategories: $e');
      return [];
    }
  }

  /// Récupère les ventes pour une période
  Future<List<Sale>> _getSalesForPeriod(DateTime startDate, DateTime endDate, {int? categoryId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token non disponible');

      // Essayons différents noms de paramètres que l'API pourrait accepter
      final queryParams = <String, String>{
        'start_date': _formatDateForApi(startDate),
        'end_date': _formatDateForApi(endDate),
        'date_debut': _formatDateForApi(startDate), // Format français
        'date_fin': _formatDateForApi(endDate), // Format français
        'from': _formatDateForApi(startDate), // Format anglais alternatif
        'to': _formatDateForApi(endDate), // Format anglais alternatif
        'status': 'completed',
      };

      final uri = Uri.parse('$_baseUrl/sales').replace(queryParameters: queryParams);
      print('🔍 Requête ventes: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final salesList = (data['data'] ?? []) as List;
        print('📊 Réponse API ventes: ${salesList.length} éléments trouvés');

        // Log des dates des ventes pour vérification
        for (final sale in salesList) {
          if (sale is Map<String, dynamic>) {
            final dateVente = sale['dateVente'] ?? sale['dateCreation'];
            print('  - Vente ID ${sale['id']}: date = $dateVente');
          }
        }

        final sales = salesList.map((item) => Sale.fromJson(item as Map<String, dynamic>)).toList();

        // FILTRAGE CÔTÉ CLIENT car l'API ne filtre pas correctement
        var filteredSales = sales.where((sale) {
          // CORRECTION: Exclure les ventes annulées de la comptabilité
          if (sale.statut == 'annulee') {
            print('🗑️ Vente annulée exclue du bilan comptable: ${sale.numeroVente}');
            return false;
          }

          final saleDate = DateTime(sale.dateCreation.year, sale.dateCreation.month, sale.dateCreation.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);

          return (saleDate.isAtSameMomentAs(start) || saleDate.isAfter(start)) && (saleDate.isAtSameMomentAs(end) || saleDate.isBefore(end));
        }).toList();

        // Filtrer par catégorie si spécifié
        if (categoryId != null) {
          final filteredByCategorySales = <Sale>[];

          for (final sale in filteredSales) {
            bool hasProductInCategory = false;

            for (final detail in sale.details) {
              // Récupérer les informations complètes du produit pour obtenir la catégorie
              final productCategoryId = await _getProductCategoryId(detail.produitId);
              if (productCategoryId == categoryId) {
                hasProductInCategory = true;
                break;
              }
            }

            if (hasProductInCategory) {
              filteredByCategorySales.add(sale);
            }
          }

          filteredSales = filteredByCategorySales;
          print('🔍 Filtrage par catégorie $categoryId: ${filteredSales.length} ventes');
        }

        print('🔍 Filtrage côté client: ${sales.length} → ${filteredSales.length} ventes pour la période');

        return filteredSales;
      } else {
        print('❌ Erreur API ventes: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur lors de la récupération des ventes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur _getSalesForPeriod: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  /// Récupère les dépenses (mouvements financiers) pour une période
  Future<List<FinancialMovement>> _getExpensesForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token non disponible');

      // Essayons différents noms de paramètres que l'API pourrait accepter
      final queryParams = <String, String>{
        'start_date': _formatDateForApi(startDate),
        'end_date': _formatDateForApi(endDate),
        'date_debut': _formatDateForApi(startDate), // Format français
        'date_fin': _formatDateForApi(endDate), // Format français
        'from': _formatDateForApi(startDate), // Format anglais alternatif
        'to': _formatDateForApi(endDate), // Format anglais alternatif
      };

      final uri = Uri.parse('$_baseUrl/financial-movements').replace(queryParameters: queryParams);
      print('🔍 Requête mouvements: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final movementsList = (data['data'] ?? []) as List;
        print('📊 Réponse API mouvements: ${movementsList.length} éléments trouvés');

        // Log des dates des mouvements pour vérification
        for (final movement in movementsList) {
          if (movement is Map<String, dynamic>) {
            final dateMovement = movement['date'];
            print('  - Mouvement ID ${movement['id']}: date = $dateMovement');
          }
        }

        final movements = movementsList.map((item) => FinancialMovement.fromJson(item as Map<String, dynamic>)).toList();

        // FILTRAGE CÔTÉ CLIENT car l'API ne filtre pas correctement
        final filteredMovements = movements.where((movement) {
          final movementDate = DateTime(movement.date.year, movement.date.month, movement.date.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);

          return (movementDate.isAtSameMomentAs(start) || movementDate.isAfter(start)) && (movementDate.isAtSameMomentAs(end) || movementDate.isBefore(end));
        }).toList();

        print('🔍 Filtrage côté client: ${movements.length} → ${filteredMovements.length} mouvements pour la période');

        return filteredMovements;
      } else {
        print('❌ Erreur API mouvements: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur lors de la récupération des dépenses: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur _getExpensesForPeriod: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  /// Calcule le bilan à partir des données
  Future<FinancialBalance> _calculateBalance(
    List<Sale> sales,
    List<FinancialMovement> expenses,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Calculs de base
    final totalRevenue = sales.fold<double>(0.0, (sum, sale) => sum + sale.montantTotal);

    // Calcul du coût des marchandises vendues (COGS - Cost of Goods Sold)
    final totalCostOfGoodsSold = await _calculateCostOfGoodsSold(sales);

    // Marge brute = Revenus - Coût des marchandises vendues
    final grossProfit = totalRevenue - totalCostOfGoodsSold;

    // Dépenses opérationnelles (mouvements financiers)
    final operationalExpenses = expenses.fold<double>(0.0, (sum, expense) => sum + expense.montant);

    // Bénéfice net = Marge brute - Dépenses opérationnelles
    final netProfit = grossProfit - operationalExpenses;

    // Marge brute en pourcentage
    final grossMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;

    // Marge nette en pourcentage
    final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

    // Moyennes
    final averageSaleAmount = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;
    final averageExpenseAmount = expenses.isNotEmpty ? operationalExpenses / expenses.length : 0.0;

    // Analyse par catégorie des revenus (par défaut, une seule catégorie "Ventes")
    final revenueByCategory = [
      CategoryBalance(
        categoryId: 1,
        categoryName: 'sales',
        categoryDisplayName: 'Ventes',
        categoryColor: '#10B981',
        categoryIcon: 'shopping_cart',
        amount: totalRevenue,
        count: sales.length,
        percentage: 100.0,
      ),
    ];

    // Analyse par catégorie des dépenses
    final expensesByCategory = _groupExpensesByCategory(expenses, operationalExpenses);

    // Balance quotidienne
    final dailyBalances = _calculateDailyBalances(sales, expenses, startDate, endDate);

    return FinancialBalance(
      startDate: startDate,
      endDate: endDate,
      totalRevenue: totalRevenue,
      totalCostOfGoods: totalCostOfGoodsSold,
      grossProfit: grossProfit,
      totalExpenses: operationalExpenses,
      netProfit: netProfit,
      profitMargin: profitMargin,
      grossMargin: grossMargin,
      totalSales: sales.length,
      totalExpenseItems: expenses.length,
      averageSaleAmount: averageSaleAmount,
      averageExpenseAmount: averageExpenseAmount,
      revenueByCategory: revenueByCategory,
      expensesByCategory: expensesByCategory,
      dailyBalances: dailyBalances,
    );
  }

  /// Calcule le coût des marchandises vendues (COGS)
  Future<double> _calculateCostOfGoodsSold(List<Sale> sales) async {
    double totalCogs = 0.0;

    for (final sale in sales) {
      for (final detail in sale.details) {
        if (detail.produit != null) {
          // Récupérer le prix d'achat du produit
          final costPrice = await _getProductCostPrice(detail.produitId);
          if (costPrice != null) {
            totalCogs += costPrice * detail.quantite;
          }
        }
      }
    }

    return totalCogs;
  }

  /// Récupère le prix d'achat d'un produit
  Future<double?> _getProductCostPrice(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productData = data['data'] ?? data;
        return productData['prixAchat'] != null ? (productData['prixAchat'] as num).toDouble() : null;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du prix d\'achat pour le produit $productId: $e');
    }
    return null;
  }

  /// Récupère l'ID de catégorie d'un produit
  Future<int?> _getProductCategoryId(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productData = data['data'] ?? data;
        return productData['categorieId'] as int?;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la catégorie pour le produit $productId: $e');
    }
    return null;
  }

  /// Groupe les dépenses par catégorie
  List<CategoryBalance> _groupExpensesByCategory(List<FinancialMovement> expenses, double totalExpenses) {
    final Map<int, List<FinancialMovement>> groupedExpenses = {};

    // Grouper par catégorie
    for (final expense in expenses) {
      final categoryId = expense.categorieId;
      if (!groupedExpenses.containsKey(categoryId)) {
        groupedExpenses[categoryId] = [];
      }
      groupedExpenses[categoryId]!.add(expense);
    }

    // Créer les CategoryBalance
    return groupedExpenses.entries.map((entry) {
      final categoryId = entry.key;
      final categoryExpenses = entry.value;
      final categoryAmount = categoryExpenses.fold<double>(0.0, (sum, expense) => sum + expense.montant);
      final percentage = totalExpenses > 0 ? (categoryAmount / totalExpenses) * 100 : 0.0;

      // Utiliser les informations de la première dépense de la catégorie
      final firstExpense = categoryExpenses.first;
      final categoryName = firstExpense.categorie?.name ?? 'Catégorie $categoryId';
      final categoryDisplayName = firstExpense.categorie?.displayName ?? categoryName;
      final categoryColor = firstExpense.categorie?.color ?? '#6B7280';
      final categoryIcon = firstExpense.categorie?.icon ?? 'receipt';

      return CategoryBalance(
        categoryId: categoryId,
        categoryName: categoryName,
        categoryDisplayName: categoryDisplayName,
        categoryColor: categoryColor,
        categoryIcon: categoryIcon,
        amount: categoryAmount,
        count: categoryExpenses.length,
        percentage: percentage,
      );
    }).toList();
  }

  /// Calcule les balances quotidiennes
  List<DailyBalance> _calculateDailyBalances(
    List<Sale> sales,
    List<FinancialMovement> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    final List<DailyBalance> dailyBalances = [];
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

    DateTime date = currentDate;
    while (date.isBefore(endDateOnly) || date.isAtSameMomentAs(endDateOnly)) {
      // Ventes du jour
      final dailySales = sales.where((sale) {
        final saleDate = DateTime(sale.dateCreation.year, sale.dateCreation.month, sale.dateCreation.day);
        return saleDate.isAtSameMomentAs(date);
      }).toList();

      // Dépenses du jour
      final dailyExpenses = expenses.where((expense) {
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        return expenseDate.isAtSameMomentAs(date);
      }).toList();

      final dailyRevenue = dailySales.fold<double>(0.0, (sum, sale) => sum + sale.montantTotal);
      final dailyExpensesAmount = dailyExpenses.fold<double>(0.0, (sum, expense) => sum + expense.montant);

      // Pour simplifier, on calcule le profit quotidien comme revenus - dépenses
      // TODO: Améliorer en calculant le coût exact des marchandises vendues par jour
      final dailyProfit = dailyRevenue - dailyExpensesAmount;

      dailyBalances.add(DailyBalance(
        date: date,
        revenue: dailyRevenue,
        expenses: dailyExpensesAmount,
        profit: dailyProfit,
        salesCount: dailySales.length,
        expensesCount: dailyExpenses.length,
      ));

      date = date.add(const Duration(days: 1));
    }

    return dailyBalances;
  }

  /// Calcule les KPI pour une période
  Future<KPIIndicators> calculateKPIs({
    required DateTime startDate,
    required DateTime endDate,
    double? initialInvestment,
  }) async {
    try {
      final balance = await calculateFinancialBalance(startDate: startDate, endDate: endDate);

      // ROI (Return on Investment)
      final roi = initialInvestment != null && initialInvestment > 0 ? (balance.netProfit / initialInvestment) * 100 : 0.0;

      // Seuil de rentabilité (point mort)
      final breakEvenPoint = balance.totalExpenses;

      // Flux de trésorerie
      final cashFlow = balance.netProfit;

      // Taux de croissance (nécessiterait une période de comparaison)
      final growthRate = 0.0; // À implémenter avec des données historiques

      // Jours pour atteindre le seuil de rentabilité
      final averageDailyProfit = balance.averageDailyProfit;
      final daysToBreakEven = averageDailyProfit > 0 ? (breakEvenPoint / averageDailyProfit).ceil() : -1;

      return KPIIndicators(
        returnOnInvestment: roi,
        breakEvenPoint: breakEvenPoint,
        cashFlow: cashFlow,
        growthRate: growthRate,
        daysToBreakEven: daysToBreakEven,
      );
    } catch (e) {
      print('❌ Erreur lors du calcul des KPI: $e');
      rethrow;
    }
  }

  /// Obtient un résumé rapide de la rentabilité
  Future<Map<String, dynamic>> getQuickProfitabilitySummary() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final balance = await calculateFinancialBalance(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      return {
        'isProfitable': balance.isProfitable,
        'netProfit': balance.netProfit,
        'profitMargin': balance.profitMargin,
        'status': balance.profitabilityStatus.toString(),
        'statusMessage': balance.statusMessage,
        'statusColor': balance.statusColor,
        'totalRevenue': balance.totalRevenue,
        'totalExpenses': balance.totalExpenses,
      };
    } catch (e) {
      print('❌ Erreur lors du résumé de rentabilité: $e');
      return {
        'isProfitable': false,
        'netProfit': 0.0,
        'profitMargin': 0.0,
        'status': 'unknown',
        'statusMessage': 'Données non disponibles',
        'statusColor': '#6B7280',
        'totalRevenue': 0.0,
        'totalExpenses': 0.0,
      };
    }
  }

  /// Test pour récupérer toutes les données sans filtre
  Future<void> _testApiWithoutFilters() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      print('🧪 Test API sans filtres...');

      // Test ventes sans filtre
      final salesResponse = await http.get(
        Uri.parse('$_baseUrl/sales'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (salesResponse.statusCode == 200) {
        final salesData = json.decode(salesResponse.body);
        final allSales = (salesData['data'] ?? []) as List;
        print('📊 Total ventes dans la base: ${allSales.length}');

        // Afficher les 3 dernières ventes avec leurs dates
        final recentSales = allSales.take(3);
        for (final sale in recentSales) {
          if (sale is Map<String, dynamic>) {
            final dateVente = sale['dateVente'] ?? sale['dateCreation'];
            print('  - Vente récente ID ${sale['id']}: $dateVente');
          }
        }
      }

      // Test mouvements sans filtre
      final movementsResponse = await http.get(
        Uri.parse('$_baseUrl/financial-movements'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (movementsResponse.statusCode == 200) {
        final movementsData = json.decode(movementsResponse.body);
        final allMovements = (movementsData['data'] ?? []) as List;
        print('📊 Total mouvements dans la base: ${allMovements.length}');

        // Afficher les 3 derniers mouvements avec leurs dates
        final recentMovements = allMovements.take(3);
        for (final movement in recentMovements) {
          if (movement is Map<String, dynamic>) {
            final dateMovement = movement['date'];
            print('  - Mouvement récent ID ${movement['id']}: $dateMovement');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur test API: $e');
    }
  }
}
