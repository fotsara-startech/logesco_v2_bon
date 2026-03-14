import '../utils/currency_formatter.dart';
import '../../company_settings/models/company_profile.dart';

/// Modèle pour le bilan comptable d'activités
class ActivityReport {
  final DateTime startDate;
  final DateTime endDate;
  final String companyName;
  final String reportPeriod;

  // Informations complètes de l'entreprise pour l'en-tête
  final CompanyInfo companyInfo;

  // Données de ventes
  final SalesData salesData;

  // Mouvements financiers
  final FinancialMovementsData financialMovements;

  // Dettes clients
  final CustomerDebtsData customerDebts;

  // Bénéfices
  final ProfitData profitData;

  // Résumé général
  final ActivitySummary summary;

  ActivityReport({
    required this.startDate,
    required this.endDate,
    required this.companyName,
    required this.reportPeriod,
    required this.companyInfo,
    required this.salesData,
    required this.financialMovements,
    required this.customerDebts,
    required this.profitData,
    required this.summary,
  });

  factory ActivityReport.fromJson(Map<String, dynamic> json) {
    return ActivityReport(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      companyName: json['companyName'] ?? '',
      reportPeriod: json['reportPeriod'] ?? '',
      companyInfo: CompanyInfo.fromJson(json['companyInfo'] ?? {}),
      salesData: SalesData.fromJson(json['salesData'] ?? {}),
      financialMovements: FinancialMovementsData.fromJson(json['financialMovements'] ?? {}),
      customerDebts: CustomerDebtsData.fromJson(json['customerDebts'] ?? {}),
      profitData: ProfitData.fromJson(json['profitData'] ?? {}),
      summary: ActivitySummary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'companyName': companyName,
      'reportPeriod': reportPeriod,
      'companyInfo': companyInfo.toJson(),
      'salesData': salesData.toJson(),
      'financialMovements': financialMovements.toJson(),
      'customerDebts': customerDebts.toJson(),
      'profitData': profitData.toJson(),
      'summary': summary.toJson(),
    };
  }
}

/// Données de ventes
class SalesData {
  final int totalSales;
  final double totalRevenue;
  final double averageSaleAmount;
  final List<SalesByCategory> salesByCategory;
  final List<TopProduct> topProducts;
  final List<DailySales> dailySales;

  SalesData({
    required this.totalSales,
    required this.totalRevenue,
    required this.averageSaleAmount,
    required this.salesByCategory,
    required this.topProducts,
    required this.dailySales,
  });

  String get totalRevenueFormatted => CurrencyFormatter.formatAmount(totalRevenue);
  String get averageSaleAmountFormatted => CurrencyFormatter.formatAmount(averageSaleAmount);

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      totalSales: json['totalSales'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      averageSaleAmount: (json['averageSaleAmount'] ?? 0.0).toDouble(),
      salesByCategory: (json['salesByCategory'] as List? ?? []).map((item) => SalesByCategory.fromJson(item)).toList(),
      topProducts: (json['topProducts'] as List? ?? []).map((item) => TopProduct.fromJson(item)).toList(),
      dailySales: (json['dailySales'] as List? ?? []).map((item) => DailySales.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
      'averageSaleAmount': averageSaleAmount,
      'salesByCategory': salesByCategory.map((item) => item.toJson()).toList(),
      'topProducts': topProducts.map((item) => item.toJson()).toList(),
      'dailySales': dailySales.map((item) => item.toJson()).toList(),
    };
  }
}

/// Ventes par catégorie
class SalesByCategory {
  final String categoryName;
  final double amount;
  final int count;
  final double percentage;

  SalesByCategory({
    required this.categoryName,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  String get amountFormatted => CurrencyFormatter.formatAmount(amount);
  String get percentageFormatted => CurrencyFormatter.formatPercentage(percentage);

  factory SalesByCategory.fromJson(Map<String, dynamic> json) {
    return SalesByCategory(
      categoryName: json['categoryName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'amount': amount,
      'count': count,
      'percentage': percentage,
    };
  }
}

/// Produit le plus vendu
class TopProduct {
  final String productName;
  final int quantitySold;
  final double revenue;

  TopProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  String get revenueFormatted => CurrencyFormatter.formatAmount(revenue);

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: json['productName'] ?? '',
      quantitySold: json['quantitySold'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantitySold': quantitySold,
      'revenue': revenue,
    };
  }
}

/// Ventes quotidiennes
class DailySales {
  final DateTime date;
  final double amount;
  final int count;

  DailySales({
    required this.date,
    required this.amount,
    required this.count,
  });

  String get amountFormatted => CurrencyFormatter.formatAmount(amount);
  String get dateFormatted => '${date.day}/${date.month}';

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: DateTime.parse(json['date']),
      amount: (json['amount'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'count': count,
    };
  }
}

/// Données des mouvements financiers
class FinancialMovementsData {
  final double totalIncome;
  final double totalExpenses;
  final double netCashFlow;
  final List<MovementByCategory> movementsByCategory;
  final List<DailyMovement> dailyMovements;

  FinancialMovementsData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.movementsByCategory,
    required this.dailyMovements,
  });

  String get totalIncomeFormatted => CurrencyFormatter.formatAmount(totalIncome);
  String get totalExpensesFormatted => CurrencyFormatter.formatAmount(totalExpenses);
  String get netCashFlowFormatted => CurrencyFormatter.formatAmount(netCashFlow);

  factory FinancialMovementsData.fromJson(Map<String, dynamic> json) {
    return FinancialMovementsData(
      totalIncome: (json['totalIncome'] ?? 0.0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0.0).toDouble(),
      netCashFlow: (json['netCashFlow'] ?? 0.0).toDouble(),
      movementsByCategory: (json['movementsByCategory'] as List? ?? []).map((item) => MovementByCategory.fromJson(item)).toList(),
      dailyMovements: (json['dailyMovements'] as List? ?? []).map((item) => DailyMovement.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netCashFlow': netCashFlow,
      'movementsByCategory': movementsByCategory.map((item) => item.toJson()).toList(),
      'dailyMovements': dailyMovements.map((item) => item.toJson()).toList(),
    };
  }
}

/// Mouvement par catégorie
class MovementByCategory {
  final String categoryName;
  final double amount;
  final int count;
  final bool isIncome;

  MovementByCategory({
    required this.categoryName,
    required this.amount,
    required this.count,
    required this.isIncome,
  });

  String get amountFormatted => CurrencyFormatter.formatAmount(amount);
  String get typeLabel => isIncome ? 'Entrée' : 'Sortie';

  factory MovementByCategory.fromJson(Map<String, dynamic> json) {
    return MovementByCategory(
      categoryName: json['categoryName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
      isIncome: json['isIncome'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'amount': amount,
      'count': count,
      'isIncome': isIncome,
    };
  }
}

/// Mouvement quotidien
class DailyMovement {
  final DateTime date;
  final double income;
  final double expenses;
  final double netFlow;

  DailyMovement({
    required this.date,
    required this.income,
    required this.expenses,
    required this.netFlow,
  });

  String get incomeFormatted => CurrencyFormatter.formatAmount(income);
  String get expensesFormatted => CurrencyFormatter.formatAmount(expenses);
  String get netFlowFormatted => CurrencyFormatter.formatAmount(netFlow);
  String get dateFormatted => '${date.day}/${date.month}';

  factory DailyMovement.fromJson(Map<String, dynamic> json) {
    return DailyMovement(
      date: DateTime.parse(json['date']),
      income: (json['income'] ?? 0.0).toDouble(),
      expenses: (json['expenses'] ?? 0.0).toDouble(),
      netFlow: (json['netFlow'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'income': income,
      'expenses': expenses,
      'netFlow': netFlow,
    };
  }
}

/// Données des dettes clients
class CustomerDebtsData {
  final double totalOutstandingDebt;
  final int customersWithDebt;
  final double averageDebtPerCustomer;
  final List<CustomerDebt> topDebtors;
  final List<DebtAging> debtAging;

  CustomerDebtsData({
    required this.totalOutstandingDebt,
    required this.customersWithDebt,
    required this.averageDebtPerCustomer,
    required this.topDebtors,
    required this.debtAging,
  });

  String get totalOutstandingDebtFormatted => CurrencyFormatter.formatAmount(totalOutstandingDebt);
  String get averageDebtPerCustomerFormatted => CurrencyFormatter.formatAmount(averageDebtPerCustomer);

  factory CustomerDebtsData.fromJson(Map<String, dynamic> json) {
    return CustomerDebtsData(
      totalOutstandingDebt: (json['totalOutstandingDebt'] ?? 0.0).toDouble(),
      customersWithDebt: json['customersWithDebt'] ?? 0,
      averageDebtPerCustomer: (json['averageDebtPerCustomer'] ?? 0.0).toDouble(),
      topDebtors: (json['topDebtors'] as List? ?? []).map((item) => CustomerDebt.fromJson(item)).toList(),
      debtAging: (json['debtAging'] as List? ?? []).map((item) => DebtAging.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOutstandingDebt': totalOutstandingDebt,
      'customersWithDebt': customersWithDebt,
      'averageDebtPerCustomer': averageDebtPerCustomer,
      'topDebtors': topDebtors.map((item) => item.toJson()).toList(),
      'debtAging': debtAging.map((item) => item.toJson()).toList(),
    };
  }
}

/// Dette client
class CustomerDebt {
  final String customerName;
  final double debtAmount;
  final int daysOverdue;

  CustomerDebt({
    required this.customerName,
    required this.debtAmount,
    required this.daysOverdue,
  });

  String get debtAmountFormatted => CurrencyFormatter.formatAmount(debtAmount);

  factory CustomerDebt.fromJson(Map<String, dynamic> json) {
    return CustomerDebt(
      customerName: json['customerName'] ?? '',
      debtAmount: (json['debtAmount'] ?? 0.0).toDouble(),
      daysOverdue: json['daysOverdue'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'debtAmount': debtAmount,
      'daysOverdue': daysOverdue,
    };
  }
}

/// Ancienneté des dettes
class DebtAging {
  final String ageRange;
  final double amount;
  final int count;
  final double percentage;

  DebtAging({
    required this.ageRange,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  String get amountFormatted => CurrencyFormatter.formatAmount(amount);
  String get percentageFormatted => CurrencyFormatter.formatPercentage(percentage);

  factory DebtAging.fromJson(Map<String, dynamic> json) {
    return DebtAging(
      ageRange: json['ageRange'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ageRange': ageRange,
      'amount': amount,
      'count': count,
      'percentage': percentage,
    };
  }
}

/// Données de bénéfices
class ProfitData {
  final double grossProfit;
  final double netProfit;
  final double profitMargin;
  final double costOfGoodsSold;
  final double operatingExpenses;
  final ProfitTrend profitTrend;

  ProfitData({
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.costOfGoodsSold,
    required this.operatingExpenses,
    required this.profitTrend,
  });

  String get grossProfitFormatted => CurrencyFormatter.formatAmount(grossProfit);
  String get netProfitFormatted => CurrencyFormatter.formatAmount(netProfit);
  String get profitMarginFormatted => CurrencyFormatter.formatPercentage(profitMargin);
  String get costOfGoodsSoldFormatted => CurrencyFormatter.formatAmount(costOfGoodsSold);
  String get operatingExpensesFormatted => CurrencyFormatter.formatAmount(operatingExpenses);

  bool get isProfitable => netProfit > 0;

  factory ProfitData.fromJson(Map<String, dynamic> json) {
    return ProfitData(
      grossProfit: (json['grossProfit'] ?? 0.0).toDouble(),
      netProfit: (json['netProfit'] ?? 0.0).toDouble(),
      profitMargin: (json['profitMargin'] ?? 0.0).toDouble(),
      costOfGoodsSold: (json['costOfGoodsSold'] ?? 0.0).toDouble(),
      operatingExpenses: (json['operatingExpenses'] ?? 0.0).toDouble(),
      profitTrend: ProfitTrend.fromJson(json['profitTrend'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grossProfit': grossProfit,
      'netProfit': netProfit,
      'profitMargin': profitMargin,
      'costOfGoodsSold': costOfGoodsSold,
      'operatingExpenses': operatingExpenses,
      'profitTrend': profitTrend.toJson(),
    };
  }
}

/// Tendance des bénéfices
class ProfitTrend {
  final double previousPeriodProfit;
  final double growthRate;
  final bool isIncreasing;

  ProfitTrend({
    required this.previousPeriodProfit,
    required this.growthRate,
    required this.isIncreasing,
  });

  String get previousPeriodProfitFormatted => CurrencyFormatter.formatAmount(previousPeriodProfit);
  String get growthRateFormatted => CurrencyFormatter.formatPercentage(growthRate);

  factory ProfitTrend.fromJson(Map<String, dynamic> json) {
    return ProfitTrend(
      previousPeriodProfit: (json['previousPeriodProfit'] ?? 0.0).toDouble(),
      growthRate: (json['growthRate'] ?? 0.0).toDouble(),
      isIncreasing: json['isIncreasing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'previousPeriodProfit': previousPeriodProfit,
      'growthRate': growthRate,
      'isIncreasing': isIncreasing,
    };
  }
}

/// Résumé d'activité
class ActivitySummary {
  final String overallStatus;
  final String statusMessage;
  final String statusColor;
  final List<KeyMetric> keyMetrics;
  final List<String> recommendations;

  ActivitySummary({
    required this.overallStatus,
    required this.statusMessage,
    required this.statusColor,
    required this.keyMetrics,
    required this.recommendations,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      overallStatus: json['overallStatus'] ?? '',
      statusMessage: json['statusMessage'] ?? '',
      statusColor: json['statusColor'] ?? '#6B7280',
      keyMetrics: (json['keyMetrics'] as List? ?? []).map((item) => KeyMetric.fromJson(item)).toList(),
      recommendations: (json['recommendations'] as List? ?? []).map((item) => item.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallStatus': overallStatus,
      'statusMessage': statusMessage,
      'statusColor': statusColor,
      'keyMetrics': keyMetrics.map((item) => item.toJson()).toList(),
      'recommendations': recommendations,
    };
  }
}

/// Métrique clé
class KeyMetric {
  final String name;
  final String value;
  final String unit;
  final String trend;
  final String color;

  KeyMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.trend,
    required this.color,
  });

  factory KeyMetric.fromJson(Map<String, dynamic> json) {
    return KeyMetric(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      unit: json['unit'] ?? '',
      trend: json['trend'] ?? '',
      color: json['color'] ?? '#6B7280',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'trend': trend,
      'color': color,
    };
  }
}

/// Informations complètes de l'entreprise pour l'en-tête du bilan
class CompanyInfo {
  final String name;
  final String address;
  final String location;
  final String phone;
  final String email;
  final String nuiRccm;
  final String logoPath;

  CompanyInfo({
    required this.name,
    required this.address,
    required this.location,
    required this.phone,
    required this.email,
    required this.nuiRccm,
    this.logoPath = '',
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      nuiRccm: json['nuiRccm'] ?? '',
      logoPath: json['logoPath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'phone': phone,
      'email': email,
      'nuiRccm': nuiRccm,
      'logoPath': logoPath,
    };
  }

  /// Crée CompanyInfo à partir d'un CompanyProfile
  factory CompanyInfo.fromProfile(CompanyProfile? profile) {
    if (profile == null) {
      return CompanyInfo.defaultInfo();
    }

    return CompanyInfo(
      name: profile.name,
      address: profile.address,
      location: profile.location ?? '',
      phone: profile.phone ?? '',
      email: profile.email ?? '',
      nuiRccm: profile.nuiRccm ?? '',
      logoPath: profile.logo ?? '',
    );
  }

  /// Informations par défaut
  factory CompanyInfo.defaultInfo() {
    return CompanyInfo(
      name: 'LOGESCO ENTERPRISE',
      address: 'Adresse non configurée',
      location: 'Cameroun, CMR',
      phone: 'Téléphone non configuré',
      email: 'email@logesco.com',
      nuiRccm: 'NUI RCCM non configuré',
      logoPath: '',
    );
  }
}
