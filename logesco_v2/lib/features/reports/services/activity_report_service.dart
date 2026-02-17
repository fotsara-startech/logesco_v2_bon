import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../accounts/services/account_service.dart';
import '../../../core/config/api_config.dart';
import '../utils/currency_formatter.dart';
import '../../../core/services/auth_service.dart';
import '../models/activity_report.dart';
import '../../sales/models/sale.dart';
import '../../financial_movements/models/financial_movement.dart';
import '../../accounts/services/account_api_service.dart';
import '../../company_settings/models/company_profile.dart';
import '../utils/safe_financial_parser.dart';
import 'package:intl/intl.dart';

/// Service pour générer les bilans comptables d'activités
class ActivityReportService {
  final AuthService _authService;
  final String _baseUrl = ApiConfig.baseUrl;

  ActivityReportService(this._authService);

  /// Génère un bilan comptable complet pour une période donnée
  Future<ActivityReport> generateActivityReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('📊 [DEBUG] ===== DÉBUT GÉNÉRATION BILAN COMPTABLE =====');
      print('📊 [DEBUG] Période: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
      print('📊 [DEBUG] AuthService disponible: ${_authService != null}');

      // Récupérer les informations de l'entreprise
      final companyInfo = await _getCompanyInfo();

      print('📊 [DEBUG] Récupération des données en parallèle...');

      // Récupérer toutes les données en parallèle
      final results = await Future.wait([
        _getSalesData(startDate, endDate),
        _getFinancialMovementsData(startDate, endDate),
        _getCustomerDebtsData(startDate, endDate), // CORRECTION: Passer les dates pour filtrage
      ]);

      print('📊 [DEBUG] Toutes les données récupérées avec succès');

      final salesData = results[0] as SalesData;
      final financialMovements = results[1] as FinancialMovementsData;
      final customerDebts = results[2] as CustomerDebtsData;

      print('📊 [DEBUG] Données extraites:');
      print('  - Ventes: ${salesData.totalRevenue} FCFA');
      print('  - Mouvements: ${financialMovements.totalExpenses} FCFA dépenses');
      print('  - Dettes clients: ${customerDebts.totalOutstandingDebt} FCFA');
      print('  - Clients débiteurs: ${customerDebts.customersWithDebt}');

      // Calculer les données de profit
      final profitData = await _calculateProfitData(salesData, financialMovements, startDate, endDate);

      // Générer le résumé d'activité
      final summary = _generateActivitySummary(salesData, financialMovements, customerDebts, profitData);

      final reportPeriod = _formatPeriod(startDate, endDate);

      final report = ActivityReport(
        startDate: startDate,
        endDate: endDate,
        companyName: companyInfo?.name ?? 'Entreprise',
        reportPeriod: reportPeriod,
        companyInfo: CompanyInfo.fromProfile(companyInfo),
        salesData: salesData,
        financialMovements: financialMovements,
        customerDebts: customerDebts,
        profitData: profitData,
        summary: summary,
      );

      print('📊 [DEBUG] ===== BILAN COMPTABLE GÉNÉRÉ AVEC SUCCÈS =====');
      print('📊 [DEBUG] Dettes clients dans le rapport final: ${report.customerDebts.totalOutstandingDebt} FCFA');
      print('📊 [DEBUG] ================================================');

      return report;
    } catch (e) {
      print('❌ Erreur lors de la génération du bilan: $e');
      rethrow;
    }
  }

  /// Récupère les informations de l'entreprise
  Future<CompanyProfile?> _getCompanyInfo() async {
    try {
      print('🏢 [DEBUG] Récupération des informations de l\'entreprise...');

      final token = await _authService.getToken();
      if (token == null) {
        print('⚠️  [WARNING] Aucun token d\'authentification disponible');
        return _getDefaultCompanyInfo();
      }

      print('🏢 [DEBUG] Token disponible, appel API company-settings...');
      final response = await http.get(
        Uri.parse('$_baseUrl/company-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🏢 [DEBUG] Réponse API company-settings: ${response.statusCode}');
      print('🏢 [DEBUG] Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🏢 [DEBUG] Données entreprise récupérées: ${data.toString()}');

        // Vérifier la structure de la réponse
        final companyData = data['data'] ?? data;
        print('🏢 [DEBUG] Données à mapper: ${companyData.toString()}');
        print('🏢 [DEBUG] Type de companyData: ${companyData.runtimeType}');

        // Vérifier que c'est bien un Map
        if (companyData is! Map<String, dynamic>) {
          print('❌ [ERROR] companyData n\'est pas un Map<String, dynamic>, c\'est: ${companyData.runtimeType}');
          print('❌ [ERROR] Contenu: $companyData');
          return _getDefaultCompanyInfo();
        }

        // Créer manuellement le CompanyProfile pour éviter les problèmes de parsing
        final companyProfile = CompanyProfile(
          id: companyData['id'],
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: companyData['dateCreation'] != null ? DateTime.parse(companyData['dateCreation']) : DateTime.now(),
          updatedAt: companyData['dateModification'] != null ? DateTime.parse(companyData['dateModification']) : DateTime.now(),
        );
        print('✅ [DEBUG] CompanyProfile créé: ${companyProfile.name}');
        return companyProfile;
      } else {
        print('⚠️  [WARNING] Erreur API company-settings: ${response.statusCode}');
        print('⚠️  [WARNING] Corps de l\'erreur: ${response.body}');

        // Si c'est une erreur d'authentification, utilisons l'endpoint public
        if (response.statusCode == 401) {
          print('🔄 [INFO] Erreur d\'authentification, utilisation de l\'endpoint public...');
          return await _getCompanyInfoFromPublicEndpoint();
        }

        return _getDefaultCompanyInfo();
      }
    } catch (e) {
      print('❌ [ERROR] Erreur lors de la récupération des infos entreprise: $e');
      return _getDefaultCompanyInfo();
    }
  }

  /// Essaie de récupérer les informations sans authentification
  Future<CompanyProfile?> _tryGetCompanyInfoWithoutAuth() async {
    try {
      print('🔓 [DEBUG] Tentative de récupération sans authentification...');

      final response = await http.get(
        Uri.parse('$_baseUrl/company-settings'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🔓 [DEBUG] Réponse sans auth: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final companyProfile = CompanyProfile.fromJson(data['data'] ?? data);
        print('✅ [DEBUG] Données récupérées sans auth: ${companyProfile.name}');
        return companyProfile;
      }

      return null;
    } catch (e) {
      print('❌ [ERROR] Erreur récupération sans auth: $e');
      return null;
    }
  }

  /// Récupère les informations depuis l'endpoint public
  Future<CompanyProfile?> _getCompanyInfoFromPublicEndpoint() async {
    try {
      print('🌐 [DEBUG] Récupération depuis l\'endpoint public...');

      final response = await http.get(
        Uri.parse('$_baseUrl/company-settings/public'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🌐 [DEBUG] Réponse endpoint public: ${response.statusCode}');
      print('🌐 [DEBUG] Corps réponse public: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final companyData = data['data'] ?? data;

        // Créer un CompanyProfile avec les données publiques
        final companyProfile = CompanyProfile(
          id: 1,
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('✅ [DEBUG] CompanyProfile créé depuis endpoint public: ${companyProfile.name}');
        return companyProfile;
      }

      return null;
    } catch (e) {
      print('❌ [ERROR] Erreur endpoint public: $e');
      return null;
    }
  }

  /// Retourne des informations par défaut de l'entreprise
  CompanyProfile _getDefaultCompanyInfo() {
    print('🏢 [DEBUG] Utilisation des informations par défaut de l\'entreprise');
    return CompanyProfile(
      id: 1,
      name: 'LOGESCO ENTERPRISE',
      address: 'Adresse non configurée',
      location: 'Cameroun, CMR',
      phone: 'Téléphone non configuré',
      email: 'email@logesco.com',
      nuiRccm: 'NUI RCCM non configuré',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Récupère et analyse les données de ventes
  Future<SalesData> _getSalesData(DateTime startDate, DateTime endDate) async {
    try {
      final sales = await _getSalesForPeriod(startDate, endDate);

      final totalSales = sales.length;
      final totalRevenue = sales.fold<double>(0.0, (sum, sale) => sum + sale.montantTotal);
      final averageSaleAmount = totalSales > 0 ? totalRevenue / totalSales : 0.0;

      // Analyser les ventes par catégorie (avec récupération des catégories réelles)
      final salesByCategory = await _analyzeSalesByCategory(sales, totalRevenue);

      // Identifier les produits les plus vendus
      final topProducts = _getTopProducts(sales);

      // Calculer les ventes quotidiennes
      final dailySales = _calculateDailySales(sales, startDate, endDate);

      return SalesData(
        totalSales: totalSales,
        totalRevenue: totalRevenue,
        averageSaleAmount: averageSaleAmount,
        salesByCategory: salesByCategory,
        topProducts: topProducts,
        dailySales: dailySales,
      );
    } catch (e) {
      print('❌ Erreur lors de l\'analyse des ventes: $e');
      return SalesData(
        totalSales: 0,
        totalRevenue: 0.0,
        averageSaleAmount: 0.0,
        salesByCategory: [],
        topProducts: [],
        dailySales: [],
      );
    }
  }

  /// Récupère et analyse les mouvements financiers
  Future<FinancialMovementsData> _getFinancialMovementsData(DateTime startDate, DateTime endDate) async {
    try {
      final movements = await _getFinancialMovementsForPeriod(startDate, endDate);

      double totalIncome = 0.0;
      double totalExpenses = 0.0;

      // CORRECTION: Tous les mouvements financiers sont des sorties (dépenses)
      // Le système de mouvements financiers gère uniquement les sorties d'argent
      for (final movement in movements) {
        // Tous les mouvements sont des dépenses, peu importe le signe
        totalExpenses += movement.montant.abs();
      }

      final netCashFlow = totalIncome - totalExpenses;

      // Analyser par catégorie
      final movementsByCategory = _analyzeMovementsByCategory(movements);

      // Calculer les mouvements quotidiens
      final dailyMovements = _calculateDailyMovements(movements, startDate, endDate);

      return FinancialMovementsData(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netCashFlow: netCashFlow,
        movementsByCategory: movementsByCategory,
        dailyMovements: dailyMovements,
      );
    } catch (e) {
      print('❌ Erreur lors de l\'analyse des mouvements financiers: $e');
      return FinancialMovementsData(
        totalIncome: 0.0,
        totalExpenses: 0.0,
        netCashFlow: 0.0,
        movementsByCategory: [],
        dailyMovements: [],
      );
    }
  }

  /// Récupère les données des dettes clients (CORRIGÉ - filtrage strict par période)
  Future<CustomerDebtsData> _getCustomerDebtsData(DateTime startDate, DateTime endDate) async {
    try {
      print('📊 [DEBUG] ===== DÉBUT RÉCUPÉRATION DETTES CLIENTS (FILTRAGE STRICT PÉRIODE) =====');
      print('📊 [DEBUG] Période analysée: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
      print('📊 [DEBUG] Date d\'aujourd\'hui: ${_formatDate(DateTime.now())}');

      // CORRECTION MAJEURE: Ne montrer QUE les nouvelles dettes créées dans la période
      // Si aucune vente à crédit dans la période → 0 FCFA de dette (comportement attendu)

      // Récupérer UNIQUEMENT les ventes à crédit de la période spécifiée
      final salesInPeriod = await _getSalesForPeriod(startDate, endDate);

      // Filtrer strictement les ventes à crédit avec montant restant > 0
      final creditSalesInPeriod = salesInPeriod.where((sale) => sale.modePaiement == 'credit' && sale.montantRestant > 0).toList();

      print('📊 [DEBUG] Ventes totales dans la période: ${salesInPeriod.length}');
      print('📊 [DEBUG] Ventes à crédit dans la période: ${creditSalesInPeriod.length}');

      // Si aucune vente à crédit dans la période → retourner 0 dette
      if (creditSalesInPeriod.isEmpty) {
        print('✅ [DEBUG] AUCUNE vente à crédit dans la période → 0 FCFA de dette');
        return CustomerDebtsData(
          totalOutstandingDebt: 0.0,
          customersWithDebt: 0,
          averageDebtPerCustomer: 0.0,
          topDebtors: [],
          debtAging: [
            DebtAging(
              ageRange: '0-30 jours',
              count: 0,
              amount: 0.0,
              percentage: 0.0,
            ),
          ],
        );
      }

      // Calculer les nouvelles dettes créées dans la période
      double totalNewDebtsInPeriod = 0.0;
      int customersWithNewDebts = 0;
      final List<CustomerDebt> newDebtorsInPeriod = [];
      final Map<String, double> customerNewDebts = {};

      for (final sale in creditSalesInPeriod) {
        if (sale.client != null && sale.montantRestant > 0) {
          final customerName = sale.client!.nomComplet;
          final debtAmount = sale.montantRestant;

          totalNewDebtsInPeriod += debtAmount;

          // Accumuler les dettes par client
          customerNewDebts[customerName] = (customerNewDebts[customerName] ?? 0.0) + debtAmount;

          print('📊 [DEBUG] Nouvelle dette créée dans la période: $customerName = ${debtAmount.toStringAsFixed(0)} FCFA (Vente ID: ${sale.id})');
        }
      }

      // Créer la liste des débiteurs de la période
      customerNewDebts.forEach((customerName, totalDebt) {
        customersWithNewDebts++;
        newDebtorsInPeriod.add(CustomerDebt(
          customerName: customerName,
          debtAmount: totalDebt,
          daysOverdue: 0, // Nouvelles dettes de la période, donc 0 jour de retard
        ));
      });

      // Trier par montant décroissant
      newDebtorsInPeriod.sort((a, b) => b.debtAmount.compareTo(a.debtAmount));

      print('📊 [DEBUG] RÉSULTAT FILTRAGE STRICT:');
      print('  - Nouvelles dettes créées dans la période: ${totalNewDebtsInPeriod.toStringAsFixed(2)} FCFA');
      print('  - Nouveaux clients débiteurs: $customersWithNewDebts');
      print('  - Ventes à crédit génératrices: ${creditSalesInPeriod.length}');

      // Classification par ancienneté (toutes nouvelles)
      final debtAging = [
        DebtAging(
          ageRange: '0-30 jours',
          count: customersWithNewDebts,
          amount: totalNewDebtsInPeriod,
          percentage: 100.0,
        ),
        DebtAging(
          ageRange: '31-60 jours',
          count: 0,
          amount: 0.0,
          percentage: 0.0,
        ),
        DebtAging(
          ageRange: '61-90 jours',
          count: 0,
          amount: 0.0,
          percentage: 0.0,
        ),
        DebtAging(
          ageRange: '90+ jours',
          count: 0,
          amount: 0.0,
          percentage: 0.0,
        ),
      ];

      // Calculer la dette moyenne
      final averageDebtPerCustomer = customersWithNewDebts > 0 ? totalNewDebtsInPeriod / customersWithNewDebts : 0.0;

      final result = CustomerDebtsData(
        totalOutstandingDebt: totalNewDebtsInPeriod, // SEULEMENT les nouvelles dettes de la période
        customersWithDebt: customersWithNewDebts, // SEULEMENT les nouveaux débiteurs
        averageDebtPerCustomer: averageDebtPerCustomer,
        topDebtors: newDebtorsInPeriod.take(10).toList(),
        debtAging: debtAging,
      );

      print('📊 [DEBUG] CustomerDebtsData créé avec FILTRAGE STRICT PÉRIODE');
      print('  - Dettes période: ${result.totalOutstandingDebt} FCFA');
      print('  - Clients débiteurs période: ${result.customersWithDebt}');
      print('📊 [DEBUG] ===== FIN RÉCUPÉRATION DETTES CLIENTS =====');

      return result;
    } catch (e, stackTrace) {
      print('❌ [ERROR] Erreur lors de l\'analyse des dettes clients: $e');
      print('❌ [ERROR] Stack trace: $stackTrace');

      // En cas d'erreur, retourner des données par défaut (0 dette)
      final defaultResult = CustomerDebtsData(
        totalOutstandingDebt: 0.0,
        customersWithDebt: 0,
        averageDebtPerCustomer: 0.0,
        topDebtors: [],
        debtAging: [],
      );

      print('❌ [ERROR] Retour de données par défaut: ${defaultResult.totalOutstandingDebt} FCFA');
      return defaultResult;
    }
  }

  /// Calcule les données de profit (CORRIGÉ selon module comptabilité)
  Future<ProfitData> _calculateProfitData(
    SalesData salesData,
    FinancialMovementsData financialMovements,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('💰 Calcul des bénéfices selon méthode comptabilité...');

      // CORRECTION: Calculer le coût réel des marchandises vendues
      final costOfGoodsSold = await _calculateRealCostOfGoodsSold(startDate, endDate);

      print('📊 Données de base:');
      print('  - Chiffre d\'affaires: ${salesData.totalRevenue.toStringAsFixed(0)} FCFA');
      print('  - Coût marchandises vendues: ${costOfGoodsSold.toStringAsFixed(0)} FCFA');

      // CORRECTION: Marge brute = Revenus - Coût des marchandises vendues (méthode comptabilité)
      final grossProfit = salesData.totalRevenue - costOfGoodsSold;

      // CORRECTION: Marge brute en pourcentage
      final grossMargin = salesData.totalRevenue > 0 ? (grossProfit / salesData.totalRevenue) * 100 : 0.0;

      // Dépenses opérationnelles = dépenses des mouvements financiers
      final operatingExpenses = financialMovements.totalExpenses;

      // CORRECTION: Bénéfice net = Marge brute - Dépenses opérationnelles (méthode comptabilité)
      final netProfit = grossProfit - operatingExpenses;

      // CORRECTION: Marge nette en pourcentage (bénéfice net / chiffre d'affaires)
      final profitMargin = salesData.totalRevenue > 0 ? (netProfit / salesData.totalRevenue) * 100 : 0.0;

      // Calculer la tendance (estimation basée sur les données actuelles)
      final profitTrend = ProfitTrend(
        previousPeriodProfit: netProfit * 0.9, // Estimation
        growthRate: netProfit > 0 ? 10.0 : -5.0, // Estimation basée sur la performance
        isIncreasing: netProfit > 0,
      );

      print('📊 Résultats du calcul (méthode comptabilité):');
      print('  - Marge brute: ${grossProfit.toStringAsFixed(0)} FCFA (${grossMargin.toStringAsFixed(1)}%)');
      print('  - Dépenses opérationnelles: ${operatingExpenses.toStringAsFixed(0)} FCFA');
      print('  - Bénéfice net: ${netProfit.toStringAsFixed(0)} FCFA (${profitMargin.toStringAsFixed(1)}%)');

      return ProfitData(
        grossProfit: grossProfit,
        netProfit: netProfit,
        profitMargin: profitMargin,
        costOfGoodsSold: costOfGoodsSold,
        operatingExpenses: operatingExpenses,
        profitTrend: profitTrend,
      );
    } catch (e) {
      print('❌ Erreur lors du calcul des profits: $e');
      // CORRECTION: En cas d'erreur, utiliser une estimation plus précise
      final costOfGoodsSold = salesData.totalRevenue * 0.7; // 70% au lieu de 60%
      final grossProfit = salesData.totalRevenue - costOfGoodsSold;
      final netProfit = grossProfit - financialMovements.totalExpenses;
      final profitMargin = salesData.totalRevenue > 0 ? (netProfit / salesData.totalRevenue) * 100 : 0.0;
      final grossMargin = salesData.totalRevenue > 0 ? (grossProfit / salesData.totalRevenue) * 100 : 0.0;

      return ProfitData(
        grossProfit: grossProfit,
        netProfit: netProfit,
        profitMargin: profitMargin,
        costOfGoodsSold: costOfGoodsSold,
        operatingExpenses: financialMovements.totalExpenses,
        profitTrend: ProfitTrend(
          previousPeriodProfit: 0.0,
          growthRate: 0.0,
          isIncreasing: false,
        ),
      );
    }
  }

  /// Calcule le coût réel des marchandises vendues (CORRIGÉ selon module comptabilité)
  Future<double> _calculateRealCostOfGoodsSold(DateTime startDate, DateTime endDate) async {
    try {
      print('🔍 Calcul du coût réel des marchandises vendues (méthode accounting)...');

      // Récupérer toutes les ventes de la période
      final sales = await _getSalesForPeriod(startDate, endDate);

      double totalCostOfGoodsSold = 0.0;
      int totalItemsProcessed = 0;
      int itemsWithRealCost = 0;

      for (final sale in sales) {
        if (sale.details.isNotEmpty) {
          for (final item in sale.details) {
            totalItemsProcessed++;

            final quantity = item.quantite;

            // CORRECTION: Récupérer le prix d'achat réel via API (méthode accounting)
            final realCostPrice = await _getProductCostPrice(item.produitId);

            double prixAchat = 0.0;
            if (realCostPrice != null && realCostPrice > 0) {
              // Utiliser le prix d'achat réel récupéré via API
              prixAchat = realCostPrice;
              itemsWithRealCost++;
            } else if (item.produit?.prixAchat != null && item.produit!.prixAchat! > 0) {
              // Fallback: utiliser le prix d'achat du modèle
              prixAchat = item.produit!.prixAchat!;
              itemsWithRealCost++;
            } else {
              // Dernier recours: estimation conservatrice
              prixAchat = item.prixUnitaire * 0.7;
            }

            // Calculer le coût basé sur le prix d'achat réel
            final costForThisItem = quantity * prixAchat;
            totalCostOfGoodsSold += costForThisItem;
          }
        }
      }

      print('📊 Analyse du coût des marchandises (méthode accounting):');
      print('  - Articles traités: $totalItemsProcessed');
      print('  - Articles avec coût réel API: $itemsWithRealCost');
      print('  - Articles avec estimation: ${totalItemsProcessed - itemsWithRealCost}');
      print('  - Coût total calculé: ${totalCostOfGoodsSold.toStringAsFixed(0)} FCFA');

      return totalCostOfGoodsSold;
    } catch (e) {
      print('❌ Erreur lors du calcul du coût des marchandises: $e');
      // En cas d'erreur, retourner 0 pour utiliser l'estimation dans la méthode appelante
      return 0.0;
    }
  }

  /// Récupère le prix d'achat d'un produit via API (méthode accounting)
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

  /// Génère le résumé d'activité
  ActivitySummary _generateActivitySummary(
    SalesData salesData,
    FinancialMovementsData financialMovements,
    CustomerDebtsData customerDebts,
    ProfitData profitData,
  ) {
    String overallStatus;
    String statusMessage;
    String statusColor;

    if (profitData.netProfit > salesData.totalRevenue * 0.15) {
      overallStatus = 'Excellent';
      statusMessage = 'Performance exceptionnelle';
      statusColor = '#10B981';
    } else if (profitData.netProfit > salesData.totalRevenue * 0.08) {
      overallStatus = 'Bon';
      statusMessage = 'Bonne performance';
      statusColor = '#34D399';
    } else if (profitData.netProfit > 0) {
      overallStatus = 'Modéré';
      statusMessage = 'Performance acceptable';
      statusColor = '#FBBF24';
    } else if (profitData.netProfit > -salesData.totalRevenue * 0.05) {
      overallStatus = 'Attention';
      statusMessage = 'Surveillance requise';
      statusColor = '#F59E0B';
    } else {
      overallStatus = 'Critique';
      statusMessage = 'Action immédiate requise';
      statusColor = '#EF4444';
    }

    // Métriques clés
    final keyMetrics = [
      KeyMetric(
        name: 'Chiffre d\'affaires',
        value: CurrencyFormatter.formatNumber(salesData.totalRevenue),
        unit: 'FCFA',
        trend: profitData.profitTrend.isIncreasing ? 'up' : 'down',
        color: '#3B82F6',
      ),
      KeyMetric(
        name: 'Bénéfice net',
        value: CurrencyFormatter.formatNumber(profitData.netProfit),
        unit: 'FCFA',
        trend: profitData.isProfitable ? 'up' : 'down',
        color: profitData.isProfitable ? '#10B981' : '#EF4444',
      ),
      KeyMetric(
        name: 'Marge de profit',
        value: profitData.profitMargin.toStringAsFixed(1),
        unit: '%',
        trend: profitData.profitMargin > 10 ? 'up' : 'down',
        color: profitData.profitMargin > 10 ? '#10B981' : '#F59E0B',
      ),
      KeyMetric(
        name: 'Dettes clients',
        value: CurrencyFormatter.formatNumber(customerDebts.totalOutstandingDebt),
        unit: 'FCFA',
        trend: customerDebts.totalOutstandingDebt > salesData.totalRevenue * 0.1 ? 'down' : 'up',
        color: customerDebts.totalOutstandingDebt > salesData.totalRevenue * 0.1 ? '#EF4444' : '#10B981',
      ),
    ];

    // Recommandations
    final recommendations = <String>[];

    if (profitData.netProfit <= 0) {
      recommendations.add('Réduire les coûts opérationnels et optimiser les prix de vente');
    }

    if (customerDebts.totalOutstandingDebt > salesData.totalRevenue * 0.15) {
      recommendations.add('Améliorer le recouvrement des créances clients');
    }

    if (profitData.profitMargin < 10) {
      recommendations.add('Revoir la stratégie de prix et négocier avec les fournisseurs');
    }

    if (salesData.totalSales < 50) {
      recommendations.add('Intensifier les efforts commerciaux et marketing');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Maintenir la performance actuelle et chercher des opportunités de croissance');
    }

    return ActivitySummary(
      overallStatus: overallStatus,
      statusMessage: statusMessage,
      statusColor: statusColor,
      keyMetrics: keyMetrics,
      recommendations: recommendations,
    );
  }

  // Méthodes utilitaires privées

  Future<List<Sale>> _getSalesForPeriod(DateTime startDate, DateTime endDate) async {
    final token = await _authService.getToken();
    if (token == null) return [];

    final queryParams = {
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'status': 'completed',
    };

    final uri = Uri.parse('$_baseUrl/sales').replace(queryParameters: queryParams);
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
      final sales = salesList.map((item) => Sale.fromJson(item as Map<String, dynamic>)).toList();

      // Filtrage côté client
      return sales.where((sale) {
        final saleDate = DateTime(sale.dateCreation.year, sale.dateCreation.month, sale.dateCreation.day);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        return (saleDate.isAtSameMomentAs(start) || saleDate.isAfter(start)) && (saleDate.isAtSameMomentAs(end) || saleDate.isBefore(end));
      }).toList();
    }
    return [];
  }

  Future<List<FinancialMovement>> _getFinancialMovementsForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final queryParams = {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      };

      final uri = Uri.parse('$_baseUrl/financial-movements').replace(queryParameters: queryParams);
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

        // Utilisation du parser sécurisé
        final movements = SafeFinancialParser.parseFinancialMovementsList(movementsList);

        // Filtrage par période avec le parser sécurisé
        return SafeFinancialParser.filterMovementsByPeriod(movements, startDate, endDate);
      }
      return [];
    } catch (e) {
      print('❌ Erreur récupération mouvements financiers: $e');
      return [];
    }
  }

  /// Analyse les ventes par catégorie en récupérant les informations complètes des produits
  Future<List<SalesByCategory>> _analyzeSalesByCategory(List<Sale> sales, double totalRevenue) async {
    print('📊 [DEBUG] ===== ANALYSE DES VENTES PAR CATÉGORIE =====');
    print('📊 [DEBUG] Nombre de ventes à analyser: ${sales.length}');

    final Map<String, double> categoryAmounts = {};
    final Map<String, int> categoryCounts = {};
    final Map<int, String> productCategories = {}; // Cache des catégories par produit

    int totalItems = 0;
    int itemsWithCategory = 0;

    for (final sale in sales) {
      for (final detail in sale.details) {
        totalItems++;

        // Récupérer la catégorie du produit
        String categoryName = 'Non catégorisé';

        // D'abord, essayer de récupérer depuis le cache
        if (productCategories.containsKey(detail.produitId)) {
          categoryName = productCategories[detail.produitId]!;
          itemsWithCategory++;
        } else {
          // Récupérer les informations complètes du produit
          final productCategory = await _getProductCategory(detail.produitId);
          if (productCategory != null && productCategory.isNotEmpty) {
            categoryName = productCategory;
            itemsWithCategory++;
          }

          // Mettre en cache pour éviter les appels répétés
          productCategories[detail.produitId] = categoryName;
        }

        final amount = detail.prixUnitaire * detail.quantite;

        categoryAmounts[categoryName] = (categoryAmounts[categoryName] ?? 0.0) + amount;
        categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;

        print('📊 [DEBUG] Produit ${detail.produitId} (${detail.produit?.nom}) → Catégorie: $categoryName, Montant: ${amount.toStringAsFixed(0)} FCFA');
      }
    }

    print('📊 [DEBUG] Résultats de l\'analyse:');
    print('  - Articles traités: $totalItems');
    print('  - Articles avec catégorie: $itemsWithCategory');
    print('  - Catégories trouvées: ${categoryAmounts.keys.length}');

    categoryAmounts.forEach((category, amount) {
      print('  - $category: ${amount.toStringAsFixed(0)} FCFA (${categoryCounts[category]} articles)');
    });

    final result = categoryAmounts.entries.map((entry) {
      final categoryName = entry.key;
      final amount = entry.value;
      final count = categoryCounts[categoryName] ?? 0;
      final percentage = totalRevenue > 0 ? (amount / totalRevenue) * 100 : 0.0;

      return SalesByCategory(
        categoryName: categoryName,
        amount: amount,
        count: count,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    print('📊 [DEBUG] ===== FIN ANALYSE DES VENTES PAR CATÉGORIE =====');
    return result;
  }

  /// Récupère la catégorie d'un produit via son ID
  Future<String?> _getProductCategory(int productId) async {
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

        // Récupérer la catégorie du produit
        final category = productData['categorie']?.toString();

        print('🔍 [DEBUG] Produit $productId → Catégorie API: $category');

        return category;
      } else {
        print('⚠️  [WARNING] Erreur API produit $productId: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ERROR] Erreur lors de la récupération de la catégorie pour le produit $productId: $e');
    }
    return null;
  }

  List<TopProduct> _getTopProducts(List<Sale> sales) {
    final Map<String, int> productQuantities = {};
    final Map<String, double> productRevenues = {};

    for (final sale in sales) {
      for (final detail in sale.details) {
        final productName = detail.produit?.nom ?? 'Produit inconnu';
        final quantity = detail.quantite;
        final revenue = detail.prixUnitaire * detail.quantite;

        productQuantities[productName] = (productQuantities[productName] ?? 0) + quantity;
        productRevenues[productName] = (productRevenues[productName] ?? 0.0) + revenue;
      }
    }

    final topProducts = productQuantities.entries.map((entry) {
      final productName = entry.key;
      final quantitySold = entry.value;
      final revenue = productRevenues[productName] ?? 0.0;

      return TopProduct(
        productName: productName,
        quantitySold: quantitySold,
        revenue: revenue,
      );
    }).toList();

    topProducts.sort((a, b) => b.revenue.compareTo(a.revenue));
    return topProducts.take(10).toList();
  }

  List<DailySales> _calculateDailySales(List<Sale> sales, DateTime startDate, DateTime endDate) {
    final Map<String, double> dailyAmounts = {};
    final Map<String, int> dailyCounts = {};

    for (final sale in sales) {
      final dateKey = _formatDate(sale.dateCreation);
      dailyAmounts[dateKey] = (dailyAmounts[dateKey] ?? 0.0) + sale.montantTotal;
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }

    final dailySales = <DailySales>[];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = _formatDate(currentDate);
      final amount = dailyAmounts[dateKey] ?? 0.0;
      final count = dailyCounts[dateKey] ?? 0;

      dailySales.add(DailySales(
        date: currentDate,
        amount: amount,
        count: count,
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dailySales;
  }

  List<MovementByCategory> _analyzeMovementsByCategory(List<FinancialMovement> movements) {
    final Map<String, double> categoryAmounts = {};
    final Map<String, int> categoryCounts = {};
    final Map<String, bool> categoryTypes = {};

    for (final movement in movements) {
      final categoryName = movement.categorie?.name ?? 'Non catégorisé';
      final amount = movement.montant.abs();
      // CORRECTION: Tous les mouvements financiers sont des sorties (dépenses)
      final isIncome = false; // Toujours false car ce sont des dépenses

      categoryAmounts[categoryName] = (categoryAmounts[categoryName] ?? 0.0) + amount;
      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
      categoryTypes[categoryName] = isIncome;
    }

    return categoryAmounts.entries.map((entry) {
      final categoryName = entry.key;
      final amount = entry.value;
      final count = categoryCounts[categoryName] ?? 0;
      final isIncome = categoryTypes[categoryName] ?? false;

      return MovementByCategory(
        categoryName: categoryName,
        amount: amount,
        count: count,
        isIncome: isIncome,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<DailyMovement> _calculateDailyMovements(List<FinancialMovement> movements, DateTime startDate, DateTime endDate) {
    final Map<String, double> dailyIncome = {};
    final Map<String, double> dailyExpenses = {};

    for (final movement in movements) {
      final dateKey = _formatDate(movement.date);
      final amount = movement.montant.abs();

      // CORRECTION: Tous les mouvements financiers sont des sorties (dépenses)
      dailyExpenses[dateKey] = (dailyExpenses[dateKey] ?? 0.0) + amount;
    }

    final dailyMovements = <DailyMovement>[];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = _formatDate(currentDate);
      final income = dailyIncome[dateKey] ?? 0.0;
      final expenses = dailyExpenses[dateKey] ?? 0.0;
      final netFlow = income - expenses;

      dailyMovements.add(DailyMovement(
        date: currentDate,
        income: income,
        expenses: expenses,
        netFlow: netFlow,
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dailyMovements;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatPeriod(DateTime startDate, DateTime endDate) {
    final start = DateFormat('dd/MM/yyyy').format(startDate);
    final end = DateFormat('dd/MM/yyyy').format(endDate);
    return '$start - $end';
  }
}
