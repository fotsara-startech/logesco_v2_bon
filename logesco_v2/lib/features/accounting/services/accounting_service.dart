import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/financial_balance.dart';
import '../../sales/models/sale.dart';
import '../../financial_movements/models/financial_movement.dart';
import '../../boutiques/controllers/boutique_controller.dart';
import 'package:intl/intl.dart';

/// Service pour la gestion de la comptabilite et des bilans financiers
class AccountingService {
  final AuthService _authService;
  final String _baseUrl = AppConfig.currentBaseUrl;

  AccountingService(this._authService);

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Calcule le bilan financier pour une periode donnee
  Future<FinancialBalance> calculateFinancialBalance({
    required DateTime startDate,
    required DateTime endDate,
    int? categoryId,
    int? boutiqueId,
  }) async {
    final effectiveBoutiqueId = boutiqueId ?? BoutiqueController.getActiveBoutiqueId();
    final results = await Future.wait([
      _getSalesForPeriod(startDate, endDate, categoryId: categoryId, boutiqueId: effectiveBoutiqueId),
      _getExpensesForPeriod(startDate, endDate, boutiqueId: effectiveBoutiqueId),
    ]);
    final sales = results[0] as List<Sale>;
    final expenses = results[1] as List<FinancialMovement>;
    return _calculateBalance(sales, expenses, startDate, endDate);
  }

  /// Recupere les categories de produits
  Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token non disponible');
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['data'] ?? data) as List;
        return list.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Recupere les ventes pour une periode
  Future<List<Sale>> _getSalesForPeriod(
    DateTime startDate,
    DateTime endDate, {
    int? categoryId,
    int? boutiqueId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token non disponible');

      final queryParams = <String, String>{
        'start_date': _formatDateForApi(startDate),
        'end_date': _formatDateForApi(endDate),
        'date_debut': _formatDateForApi(startDate),
        'date_fin': _formatDateForApi(endDate),
        'from': _formatDateForApi(startDate),
        'to': _formatDateForApi(endDate),
        'status': 'completed',
      };
      if (boutiqueId != null) queryParams['boutiqueId'] = boutiqueId.toString();

      final uri = Uri.parse('$_baseUrl/sales').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final salesList = (data['data'] ?? []) as List;
        final sales = salesList.map((item) => Sale.fromJson(item as Map<String, dynamic>)).toList();

        // Filtrage cote client
        var filtered = sales.where((sale) {
          if (sale.statut == 'annulee') return false;
          final saleDate = DateTime(sale.dateCreation.year, sale.dateCreation.month, sale.dateCreation.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          return !saleDate.isBefore(start) && !saleDate.isAfter(end);
        }).toList();

        if (categoryId != null) {
          final byCat = <Sale>[];
          for (final sale in filtered) {
            for (final detail in sale.details) {
              final catId = await _getProductCategoryId(detail.produitId);
              if (catId == categoryId) {
                byCat.add(sale);
                break;
              }
            }
          }
          filtered = byCat;
        }

        return filtered;
      }
      throw Exception('Erreur API ventes: ${response.statusCode}');
    } catch (e) {
      return [];
    }
  }

  /// Recupere les depenses pour une periode
  Future<List<FinancialMovement>> _getExpensesForPeriod(
    DateTime startDate,
    DateTime endDate, {
    int? boutiqueId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token non disponible');

      final queryParams = <String, String>{
        'start_date': _formatDateForApi(startDate),
        'end_date': _formatDateForApi(endDate),
        'date_debut': _formatDateForApi(startDate),
        'date_fin': _formatDateForApi(endDate),
        'from': _formatDateForApi(startDate),
        'to': _formatDateForApi(endDate),
      };
      if (boutiqueId != null) queryParams['boutiqueId'] = boutiqueId.toString();

      final uri = Uri.parse('$_baseUrl/financial-movements').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['data'] ?? []) as List;
        final movements = list.map((item) => FinancialMovement.fromJson(item as Map<String, dynamic>)).toList();

        return movements.where((m) {
          final d = DateTime(m.date.year, m.date.month, m.date.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          return !d.isBefore(start) && !d.isAfter(end);
        }).toList();
      }
      throw Exception('Erreur API mouvements: ${response.statusCode}');
    } catch (e) {
      return [];
    }
  }

  /// Calcule le bilan a partir des donnees
  Future<FinancialBalance> _calculateBalance(
    List<Sale> sales,
    List<FinancialMovement> expenses,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final totalRevenue = sales.fold<double>(0.0, (sum, s) => sum + s.montantTotal);
    final totalCostOfGoodsSold = await _calculateCostOfGoodsSold(sales);
    final grossProfit = totalRevenue - totalCostOfGoodsSold;
    final operationalExpenses = expenses.fold<double>(0.0, (sum, e) => sum + e.montant);
    final netProfit = grossProfit - operationalExpenses;
    final grossMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;
    final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;
    final averageSaleAmount = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;
    final averageExpenseAmount = expenses.isNotEmpty ? operationalExpenses / expenses.length : 0.0;

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
      expensesByCategory: _groupExpensesByCategory(expenses, operationalExpenses),
      dailyBalances: _calculateDailyBalances(sales, expenses, startDate, endDate),
    );
  }

  /// Cache des CUMP par produitId pour éviter les appels répétés
  final Map<int, double?> _cumpCache = {};

  Future<double> _calculateCostOfGoodsSold(List<Sale> sales) async {
    // Vider le cache à chaque nouveau calcul de bilan
    _cumpCache.clear();

    double total = 0.0;
    for (final sale in sales) {
      for (final detail in sale.details) {
        final cost = await _getProductCump(detail.produitId);
        if (cost != null) total += cost * detail.quantite;
      }
    }
    return total;
  }

  /// Récupère le CUMP d'un produit depuis le champ `cump` de la table produits.
  /// Fallback sur prixAchat si cump non disponible.
  Future<double?> _getProductCump(int productId) async {
    if (_cumpCache.containsKey(productId)) return _cumpCache[productId];

    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final p = data['data'] ?? data;
        // Utiliser le CUMP en priorité, sinon prixAchat
        final cump = p['cump'] != null ? (p['cump'] as num).toDouble() : null;
        final prixAchat = p['prixAchat'] != null ? (p['prixAchat'] as num).toDouble() : null;
        final result = cump ?? prixAchat;
        _cumpCache[productId] = result;
        return result;
      }
    } catch (_) {}
    _cumpCache[productId] = null;
    return null;
  }

  Future<int?> _getProductCategoryId(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final p = data['data'] ?? data;
        return p['categorieId'] as int?;
      }
    } catch (_) {}
    return null;
  }

  List<CategoryBalance> _groupExpensesByCategory(List<FinancialMovement> expenses, double totalExpenses) {
    final grouped = <int, List<FinancialMovement>>{};
    for (final e in expenses) {
      grouped.putIfAbsent(e.categorieId, () => []).add(e);
    }
    return grouped.entries.map((entry) {
      final amount = entry.value.fold<double>(0.0, (s, e) => s + e.montant);
      final first = entry.value.first;
      return CategoryBalance(
        categoryId: entry.key,
        categoryName: first.categorie?.name ?? 'Categorie ${entry.key}',
        categoryDisplayName: first.categorie?.displayName ?? first.categorie?.name ?? 'Categorie ${entry.key}',
        categoryColor: first.categorie?.color ?? '#6B7280',
        categoryIcon: first.categorie?.icon ?? 'receipt',
        amount: amount,
        count: entry.value.length,
        percentage: totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0,
      );
    }).toList();
  }

  List<DailyBalance> _calculateDailyBalances(
    List<Sale> sales,
    List<FinancialMovement> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    final balances = <DailyBalance>[];
    var date = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!date.isAfter(end)) {
      final dailySales = sales.where((s) {
        final d = DateTime(s.dateCreation.year, s.dateCreation.month, s.dateCreation.day);
        return d.isAtSameMomentAs(date);
      }).toList();
      final dailyExp = expenses.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return d.isAtSameMomentAs(date);
      }).toList();

      final rev = dailySales.fold<double>(0.0, (s, sale) => s + sale.montantTotal);
      final exp = dailyExp.fold<double>(0.0, (s, e) => s + e.montant);

      balances.add(DailyBalance(
        date: date,
        revenue: rev,
        expenses: exp,
        profit: rev - exp,
        salesCount: dailySales.length,
        expensesCount: dailyExp.length,
      ));
      date = date.add(const Duration(days: 1));
    }
    return balances;
  }

  /// Calcule les KPI pour une periode
  Future<KPIIndicators> calculateKPIs({
    required DateTime startDate,
    required DateTime endDate,
    double? initialInvestment,
  }) async {
    final boutiqueId = BoutiqueController.getActiveBoutiqueId();
    final balance = await calculateFinancialBalance(
      startDate: startDate,
      endDate: endDate,
      boutiqueId: boutiqueId,
    );
    final roi = initialInvestment != null && initialInvestment > 0 ? (balance.netProfit / initialInvestment) * 100 : 0.0;
    final breakEvenPoint = balance.totalExpenses;
    final averageDailyProfit = balance.averageDailyProfit;
    final daysToBreakEven = averageDailyProfit > 0 ? (breakEvenPoint / averageDailyProfit).ceil() : -1;

    return KPIIndicators(
      returnOnInvestment: roi,
      breakEvenPoint: breakEvenPoint,
      cashFlow: balance.netProfit,
      growthRate: 0.0,
      daysToBreakEven: daysToBreakEven,
    );
  }

  /// Resume rapide de rentabilite du mois en cours
  Future<Map<String, dynamic>> getQuickProfitabilitySummary() async {
    try {
      final now = DateTime.now();
      final boutiqueId = BoutiqueController.getActiveBoutiqueId();
      final balance = await calculateFinancialBalance(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        boutiqueId: boutiqueId,
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
      return {
        'isProfitable': false,
        'netProfit': 0.0,
        'profitMargin': 0.0,
        'status': 'unknown',
        'statusMessage': 'Donnees non disponibles',
        'statusColor': '#6B7280',
        'totalRevenue': 0.0,
        'totalExpenses': 0.0,
      };
    }
  }
}
