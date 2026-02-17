/// Modèle de bilan financier simple pour analyser la rentabilité
class FinancialBalance {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue; // Total des ventes (entrées)
  final double totalCostOfGoods; // Coût des marchandises vendues
  final double grossProfit; // Marge brute (revenus - coût marchandises)
  final double totalExpenses; // Total des dépenses opérationnelles
  final double netProfit; // Bénéfice net (marge brute - dépenses)
  final double profitMargin; // Marge nette en %
  final double grossMargin; // Marge brute en %
  final int totalSales; // Nombre de ventes
  final int totalExpenseItems; // Nombre de dépenses
  final double averageSaleAmount; // Montant moyen par vente
  final double averageExpenseAmount; // Montant moyen par dépense
  final List<CategoryBalance> revenueByCategory;
  final List<CategoryBalance> expensesByCategory;
  final List<DailyBalance> dailyBalances;

  FinancialBalance({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalCostOfGoods,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.grossMargin,
    required this.totalSales,
    required this.totalExpenseItems,
    required this.averageSaleAmount,
    required this.averageExpenseAmount,
    required this.revenueByCategory,
    required this.expensesByCategory,
    required this.dailyBalances,
  });

  /// Indique si l'activité est rentable
  bool get isProfitable => netProfit > 0;

  /// Statut de rentabilité
  ProfitabilityStatus get profitabilityStatus {
    if (netProfit > totalRevenue * 0.2) return ProfitabilityStatus.excellent;
    if (netProfit > totalRevenue * 0.1) return ProfitabilityStatus.good;
    if (netProfit > 0) return ProfitabilityStatus.moderate;
    if (netProfit > -totalRevenue * 0.05) return ProfitabilityStatus.warning;
    return ProfitabilityStatus.critical;
  }

  /// Couleur associée au statut
  String get statusColor {
    switch (profitabilityStatus) {
      case ProfitabilityStatus.excellent:
        return '#10B981'; // Vert foncé
      case ProfitabilityStatus.good:
        return '#34D399'; // Vert
      case ProfitabilityStatus.moderate:
        return '#FBBF24'; // Jaune
      case ProfitabilityStatus.warning:
        return '#F59E0B'; // Orange
      case ProfitabilityStatus.critical:
        return '#EF4444'; // Rouge
    }
  }

  /// Message de statut
  String get statusMessage {
    switch (profitabilityStatus) {
      case ProfitabilityStatus.excellent:
        return 'Excellente rentabilité';
      case ProfitabilityStatus.good:
        return 'Bonne rentabilité';
      case ProfitabilityStatus.moderate:
        return 'Rentabilité modérée';
      case ProfitabilityStatus.warning:
        return 'Attention aux dépenses';
      case ProfitabilityStatus.critical:
        return 'Situation critique';
    }
  }

  /// Formatage des montants
  String get totalRevenueFormatted => '${totalRevenue.toStringAsFixed(0)} FCFA';
  String get totalCostOfGoodsFormatted => '${totalCostOfGoods.toStringAsFixed(0)} FCFA';
  String get grossProfitFormatted => '${grossProfit.toStringAsFixed(0)} FCFA';
  String get totalExpensesFormatted => '${totalExpenses.toStringAsFixed(0)} FCFA';
  String get netProfitFormatted => '${netProfit.toStringAsFixed(0)} FCFA';
  String get profitMarginFormatted => '${profitMargin.toStringAsFixed(1)}%';
  String get grossMarginFormatted => '${grossMargin.toStringAsFixed(1)}%';
  String get averageSaleAmountFormatted => '${averageSaleAmount.toStringAsFixed(0)} FCFA';
  String get averageExpenseAmountFormatted => '${averageExpenseAmount.toStringAsFixed(0)} FCFA';

  /// Période formatée
  String get periodFormatted {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }

  /// Nombre de jours dans la période
  int get periodDays => endDate.difference(startDate).inDays + 1;

  /// Bénéfice moyen par jour
  double get averageDailyProfit => netProfit / periodDays;
  String get averageDailyProfitFormatted => '${averageDailyProfit.toStringAsFixed(0)} FCFA/jour';

  /// Crée un bilan depuis JSON
  factory FinancialBalance.fromJson(Map<String, dynamic> json) {
    return FinancialBalance(
      startDate: DateTime.parse((json['startDate'] ?? DateTime.now().toIso8601String()) as String),
      endDate: DateTime.parse((json['endDate'] ?? DateTime.now().toIso8601String()) as String),
      totalRevenue: ((json['totalRevenue'] ?? 0.0) as num).toDouble(),
      totalCostOfGoods: ((json['totalCostOfGoods'] ?? 0.0) as num).toDouble(),
      grossProfit: ((json['grossProfit'] ?? 0.0) as num).toDouble(),
      totalExpenses: ((json['totalExpenses'] ?? 0.0) as num).toDouble(),
      netProfit: ((json['netProfit'] ?? 0.0) as num).toDouble(),
      profitMargin: ((json['profitMargin'] ?? 0.0) as num).toDouble(),
      grossMargin: ((json['grossMargin'] ?? 0.0) as num).toDouble(),
      totalSales: (json['totalSales'] ?? 0) as int,
      totalExpenseItems: (json['totalExpenseItems'] ?? 0) as int,
      averageSaleAmount: ((json['averageSaleAmount'] ?? 0.0) as num).toDouble(),
      averageExpenseAmount: ((json['averageExpenseAmount'] ?? 0.0) as num).toDouble(),
      revenueByCategory: ((json['revenueByCategory'] ?? []) as List).map((item) => CategoryBalance.fromJson((item ?? {}) as Map<String, dynamic>)).toList(),
      expensesByCategory: ((json['expensesByCategory'] ?? []) as List).map((item) => CategoryBalance.fromJson((item ?? {}) as Map<String, dynamic>)).toList(),
      dailyBalances: ((json['dailyBalances'] ?? []) as List).map((item) => DailyBalance.fromJson((item ?? {}) as Map<String, dynamic>)).toList(),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalCostOfGoods': totalCostOfGoods,
      'grossProfit': grossProfit,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'profitMargin': profitMargin,
      'grossMargin': grossMargin,
      'totalSales': totalSales,
      'totalExpenseItems': totalExpenseItems,
      'averageSaleAmount': averageSaleAmount,
      'averageExpenseAmount': averageExpenseAmount,
      'revenueByCategory': revenueByCategory.map((item) => item.toJson()).toList(),
      'expensesByCategory': expensesByCategory.map((item) => item.toJson()).toList(),
      'dailyBalances': dailyBalances.map((item) => item.toJson()).toList(),
    };
  }
}

/// Balance par catégorie
class CategoryBalance {
  final int categoryId;
  final String categoryName;
  final String categoryDisplayName;
  final String categoryColor;
  final String categoryIcon;
  final double amount;
  final int count;
  final double percentage;

  CategoryBalance({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDisplayName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  String get amountFormatted => '${amount.toStringAsFixed(0)} FCFA';
  String get percentageFormatted => '${percentage.toStringAsFixed(1)}%';

  factory CategoryBalance.fromJson(Map<String, dynamic> json) {
    return CategoryBalance(
      categoryId: (json['categoryId'] ?? 0) as int,
      categoryName: (json['categoryName'] ?? '') as String,
      categoryDisplayName: (json['categoryDisplayName'] ?? '') as String,
      categoryColor: (json['categoryColor'] ?? '#6B7280') as String,
      categoryIcon: (json['categoryIcon'] ?? 'category') as String,
      amount: ((json['amount'] ?? 0.0) as num).toDouble(),
      count: (json['count'] ?? 0) as int,
      percentage: ((json['percentage'] ?? 0.0) as num).toDouble(),
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
}

/// Balance quotidienne
class DailyBalance {
  final DateTime date;
  final double revenue;
  final double expenses;
  final double profit;
  final int salesCount;
  final int expensesCount;

  DailyBalance({
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.salesCount,
    required this.expensesCount,
  });

  bool get isProfitable => profit > 0;
  String get revenueFormatted => '${revenue.toStringAsFixed(0)} FCFA';
  String get expensesFormatted => '${expenses.toStringAsFixed(0)} FCFA';
  String get profitFormatted => '${profit.toStringAsFixed(0)} FCFA';
  String get dateFormatted => '${date.day}/${date.month}';

  factory DailyBalance.fromJson(Map<String, dynamic> json) {
    return DailyBalance(
      date: DateTime.parse((json['date'] ?? DateTime.now().toIso8601String()) as String),
      revenue: ((json['revenue'] ?? 0.0) as num).toDouble(),
      expenses: ((json['expenses'] ?? 0.0) as num).toDouble(),
      profit: ((json['profit'] ?? 0.0) as num).toDouble(),
      salesCount: (json['salesCount'] ?? 0) as int,
      expensesCount: (json['expensesCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'revenue': revenue,
      'expenses': expenses,
      'profit': profit,
      'salesCount': salesCount,
      'expensesCount': expensesCount,
    };
  }
}

/// Statut de rentabilité
enum ProfitabilityStatus {
  excellent, // > 20% de marge
  good, // 10-20% de marge
  moderate, // 0-10% de marge
  warning, // Légèrement négatif
  critical // Fortement négatif
}

/// Indicateurs clés de performance
class KPIIndicators {
  final double returnOnInvestment; // ROI
  final double breakEvenPoint; // Seuil de rentabilité
  final double cashFlow; // Flux de trésorerie
  final double growthRate; // Taux de croissance
  final int daysToBreakEven; // Jours pour atteindre le seuil

  KPIIndicators({
    required this.returnOnInvestment,
    required this.breakEvenPoint,
    required this.cashFlow,
    required this.growthRate,
    required this.daysToBreakEven,
  });

  String get roiFormatted => '${returnOnInvestment.toStringAsFixed(1)}%';
  String get breakEvenPointFormatted => '${breakEvenPoint.toStringAsFixed(0)} FCFA';
  String get cashFlowFormatted => '${cashFlow.toStringAsFixed(0)} FCFA';
  String get growthRateFormatted => '${growthRate.toStringAsFixed(1)}%';
}
