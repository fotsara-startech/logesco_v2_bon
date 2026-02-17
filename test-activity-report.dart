import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logesco_v2/lib/features/reports/models/activity_report.dart';
import 'logesco_v2/lib/features/reports/services/activity_report_service.dart';
import 'logesco_v2/lib/features/reports/services/pdf_export_service.dart';
import 'logesco_v2/lib/core/services/auth_service.dart';

/// Script de test pour le module de bilan comptable
void main() async {
  print('🧪 Test du module de bilan comptable d\'activités');
  
  // Test de création d'un rapport factice
  final report = _createMockReport();
  
  print('✅ Rapport créé avec succès');
  print('📊 Période: ${report.reportPeriod}');
  print('💰 Chiffre d\'affaires: ${report.salesData.totalRevenueFormatted}');
  print('📈 Bénéfice net: ${report.profitData.netProfitFormatted}');
  print('👥 Clients débiteurs: ${report.customerDebts.customersWithDebt}');
  print('🎯 Statut: ${report.summary.overallStatus}');
  
  // Test de sérialisation JSON
  try {
    final json = report.toJson();
    final reportFromJson = ActivityReport.fromJson(json);
    print('✅ Sérialisation JSON réussie');
    print('📋 Nombre de recommandations: ${reportFromJson.summary.recommendations.length}');
  } catch (e) {
    print('❌ Erreur de sérialisation: $e');
  }
  
  print('🎉 Tests terminés avec succès !');
}

/// Crée un rapport factice pour les tests
ActivityReport _createMockReport() {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month, now.day);
  
  // Données de ventes factices
  final salesData = SalesData(
    totalSales: 45,
    totalRevenue: 2500000.0,
    averageSaleAmount: 55555.0,
    salesByCategory: [
      SalesByCategory(
        categoryName: 'Électronique',
        amount: 1500000.0,
        count: 25,
        percentage: 60.0,
      ),
      SalesByCategory(
        categoryName: 'Vêtements',
        amount: 750000.0,
        count: 15,
        percentage: 30.0,
      ),
      SalesByCategory(
        categoryName: 'Accessoires',
        amount: 250000.0,
        count: 5,
        percentage: 10.0,
      ),
    ],
    topProducts: [
      TopProduct(
        productName: 'Smartphone Samsung',
        quantitySold: 12,
        revenue: 600000.0,
      ),
      TopProduct(
        productName: 'Ordinateur portable',
        quantitySold: 8,
        revenue: 800000.0,
      ),
      TopProduct(
        productName: 'Écouteurs Bluetooth',
        quantitySold: 25,
        revenue: 125000.0,
      ),
    ],
    dailySales: [
      DailySales(date: startDate, amount: 150000.0, count: 3),
      DailySales(date: startDate.add(const Duration(days: 1)), amount: 200000.0, count: 4),
      DailySales(date: startDate.add(const Duration(days: 2)), amount: 180000.0, count: 2),
    ],
  );
  
  // Mouvements financiers factices
  final financialMovements = FinancialMovementsData(
    totalIncome: 100000.0,
    totalExpenses: 300000.0,
    netCashFlow: -200000.0,
    movementsByCategory: [
      MovementByCategory(
        categoryName: 'Loyer',
        amount: 150000.0,
        count: 1,
        isIncome: false,
      ),
      MovementByCategory(
        categoryName: 'Salaires',
        amount: 100000.0,
        count: 3,
        isIncome: false,
      ),
      MovementByCategory(
        categoryName: 'Vente d\'équipement',
        amount: 100000.0,
        count: 1,
        isIncome: true,
      ),
    ],
    dailyMovements: [
      DailyMovement(
        date: startDate,
        income: 50000.0,
        expenses: 100000.0,
        netFlow: -50000.0,
      ),
      DailyMovement(
        date: startDate.add(const Duration(days: 1)),
        income: 25000.0,
        expenses: 150000.0,
        netFlow: -125000.0,
      ),
    ],
  );
  
  // Dettes clients factices
  final customerDebts = CustomerDebtsData(
    totalOutstandingDebt: 450000.0,
    customersWithDebt: 8,
    averageDebtPerCustomer: 56250.0,
    topDebtors: [
      CustomerDebt(
        customerName: 'Entreprise ABC',
        debtAmount: 150000.0,
        daysOverdue: 45,
      ),
      CustomerDebt(
        customerName: 'Client XYZ',
        debtAmount: 100000.0,
        daysOverdue: 30,
      ),
      CustomerDebt(
        customerName: 'Société DEF',
        debtAmount: 75000.0,
        daysOverdue: 15,
      ),
    ],
    debtAging: [
      DebtAging(ageRange: '0-30 jours', amount: 200000.0, count: 4, percentage: 44.4),
      DebtAging(ageRange: '31-60 jours', amount: 200000.0, count: 3, percentage: 44.4),
      DebtAging(ageRange: '61-90 jours', amount: 50000.0, count: 1, percentage: 11.1),
    ],
  );
  
  // Données de profit factices
  final profitData = ProfitData(
    grossProfit: 1000000.0,
    netProfit: 700000.0,
    profitMargin: 28.0,
    costOfGoodsSold: 1500000.0,
    operatingExpenses: 300000.0,
    profitTrend: ProfitTrend(
      previousPeriodProfit: 600000.0,
      growthRate: 16.7,
      isIncreasing: true,
    ),
  );
  
  // Résumé d'activité factice
  final summary = ActivitySummary(
    overallStatus: 'Bon',
    statusMessage: 'Performance satisfaisante avec une croissance positive',
    statusColor: '#34D399',
    keyMetrics: [
      KeyMetric(
        name: 'Chiffre d\'affaires',
        value: '2,500,000',
        unit: 'FCFA',
        trend: 'up',
        color: '#3B82F6',
      ),
      KeyMetric(
        name: 'Bénéfice net',
        value: '700,000',
        unit: 'FCFA',
        trend: 'up',
        color: '#10B981',
      ),
      KeyMetric(
        name: 'Marge de profit',
        value: '28.0',
        unit: '%',
        trend: 'up',
        color: '#F59E0B',
      ),
      KeyMetric(
        name: 'Dettes clients',
        value: '450,000',
        unit: 'FCFA',
        trend: 'down',
        color: '#EF4444',
      ),
    ],
    recommendations: [
      'Améliorer le recouvrement des créances clients pour réduire les dettes',
      'Optimiser les coûts opérationnels pour augmenter la marge bénéficiaire',
      'Diversifier l\'offre produits pour réduire la dépendance aux catégories principales',
      'Mettre en place un suivi quotidien des ventes pour maintenir la croissance',
    ],
  );
  
  // Informations de l'entreprise factices
  final companyInfo = CompanyInfo(
    name: 'LOGESCO ENTERPRISE TEST',
    address: '123 Rue de la Technologie, Douala',
    location: 'Douala, Cameroun',
    phone: '+237 6XX XX XX XX',
    email: 'contact@logesco-test.com',
    nuiRccm: 'RC/DLA/2024/B/1234',
  );

  return ActivityReport(
    startDate: startDate,
    endDate: endDate,
    companyName: 'LOGESCO SARL',
    reportPeriod: '01/12/2024 - 11/12/2024',
    companyInfo: companyInfo,
    salesData: salesData,
    financialMovements: financialMovements,
    customerDebts: customerDebts,
    profitData: profitData,
    summary: summary,
  );
}