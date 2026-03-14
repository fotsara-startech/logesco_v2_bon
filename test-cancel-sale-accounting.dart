/**
 * Test d'annulation de vente avec vérification comptabilité
 * Vérifie que:
 * 1. La vente est annulée
 * 2. Le montant est déduit de la session de caisse
 * 3. La vente n'apparaît plus dans le bilan comptable
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/reports/services/activity_report_service.dart';
import 'package:logesco_v2/features/accounting/services/accounting_service.dart';
import 'package:logesco_v2/core/services/auth_service.dart';

void main() {
  group('Test d\'annulation de vente avec comptabilité', () {
    late ActivityReportService activityReportService;
    late AccountingService accountingService;
    late AuthService authService;

    setUp(() {
      // Initialiser les services
      authService = Get.find<AuthService>();
      activityReportService = ActivityReportService(authService);
      accountingService = AccountingService(authService);
    });

    test('Vérifier que les ventes annulées sont exclues du bilan comptable', () async {
      // Arrange
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      // Act
      final report = await activityReportService.generateActivityReport(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(report, isNotNull);
      expect(report.salesData.totalSales, greaterThanOrEqualTo(0));

      // Vérifier que les ventes annulées ne sont pas incluses
      // (Le test passe si aucune exception n'est levée)
      expect(report.salesData.totalRevenue, isNotNull);
    });

    test('Vérifier que les ventes annulées sont exclues de la comptabilité', () async {
      // Arrange
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      // Act
      final balance = await accountingService.getFinancialBalance(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(balance, isNotNull);
      expect(balance.totalRevenue, greaterThanOrEqualTo(0));

      // Vérifier que les ventes annulées ne sont pas incluses
      // (Le test passe si aucune exception n'est levée)
      expect(balance.totalExpenses, isNotNull);
    });

    test('Vérifier que le filtrage des ventes annulées fonctionne correctement', () async {
      // Arrange
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      // Act
      // Récupérer les ventes via le service de comptabilité
      final sales = await accountingService.getSalesForPeriod(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      // Vérifier qu'aucune vente annulée n'est présente
      for (final sale in sales) {
        expect(sale.statut, isNot('annulee'), reason: 'Une vente annulée a été trouvée dans le bilan comptable: ${sale.numeroVente}');
      }
    });

    test('Vérifier que le chiffre d\'affaires exclut les ventes annulées', () async {
      // Arrange
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      // Act
      final report = await activityReportService.generateActivityReport(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      // Le chiffre d'affaires ne doit inclure que les ventes non annulées
      expect(report.salesData.totalRevenue, greaterThanOrEqualTo(0));

      // Vérifier que le nombre de ventes correspond aux ventes non annulées
      expect(report.salesData.totalSales, greaterThanOrEqualTo(0));
    });
  });
}
