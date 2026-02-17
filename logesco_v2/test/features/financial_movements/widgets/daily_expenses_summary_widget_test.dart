// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:get/get.dart';
// import 'package:logesco_v2/features/financial_movements/widgets/daily_expenses_summary_widget.dart';
// import 'package:logesco_v2/features/financial_movements/services/movement_report_service.dart';
// import 'package:logesco_v2/core/services/auth_service.dart';

// // Mock classes
// class MockAuthService extends GetxService implements AuthService {
//   final Rx<String?> _token = Rx<String?>('mock_token');

//   @override
//   String? get token => _token.value;

//   @override
//   bool get isAuthenticated => _token.value != null;

//   @override
//   Future<void> onInit() async {
//     super.onInit();
//   }

//   @override
//   Future<String?> getToken() async => 'mock_token';

//   @override
//   Future<void> setToken(String token) async {
//     _token.value = token;
//   }

//   @override
//   Future<void> setRefreshToken(String refreshToken) async {}

//   @override
//   Future<String?> getRefreshToken() async => 'mock_refresh_token';

//   @override
//   Future<void> clearTokens() async {
//     _token.value = null;
//   }

//   @override
//   Future<void> logout() async {
//     await clearTokens();
//   }
// }

// class MockMovementReportService extends GetxService implements MovementReportService {
//   MockMovementReportService(AuthService authService);

//   @override
//   Future<MovementSummary> getSummary(DateTime startDate, DateTime endDate) async {
//     // Simuler des données de test
//     return MovementSummary(
//       totalAmount: 25000.0,
//       totalCount: 3,
//       averageAmount: 8333.33,
//       maxAmount: 15000.0,
//       minAmount: 2500.0,
//       lastMovementDate: DateTime.now(),
//     );
//   }

//   @override
//   Future<List<CategorySummary>> getCategorySummary(DateTime startDate, DateTime endDate) async {
//     return [];
//   }

//   @override
//   Future<List<DailySummary>> getDailySummary(DateTime startDate, DateTime endDate) async {
//     return [];
//   }

//   @override
//   Future<String> exportReportToPdf(MovementReportRequest request) async {
//     return '/mock/path/report.pdf';
//   }

//   @override
//   Future<String> exportReportToExcel(MovementReportRequest request) async {
//     return '/mock/path/report.xlsx';
//   }

//   @override
//   Future<MovementReport> generateCompleteReport(DateTime startDate, DateTime endDate) async {
//     final summary = await getSummary(startDate, endDate);
//     return MovementReport(
//       startDate: startDate,
//       endDate: endDate,
//       summary: summary,
//       categorySummaries: [],
//       dailySummaries: [],
//       generatedAt: DateTime.now(),
//     );
//   }

//   @override
//   Future<PeriodComparison> comparePeriods(
//     DateTime period1Start,
//     DateTime period1End,
//     DateTime period2Start,
//     DateTime period2End,
//   ) async {
//     final summary1 = await getSummary(period1Start, period1End);
//     final summary2 = await getSummary(period2Start, period2End);

//     return PeriodComparison(
//       period1Start: period1Start,
//       period1End: period1End,
//       period2Start: period2Start,
//       period2End: period2End,
//       period1Summary: summary1,
//       period2Summary: summary2,
//       period1Categories: [],
//       period2Categories: [],
//       generatedAt: DateTime.now(),
//     );
//   }
// }

// void main() {
//   group('DailyExpensesSummaryWidget Tests', () {
//     setUp(() {
//       // Initialiser GetX pour les tests
//       Get.reset();

//       // Enregistrer les services mock
//       Get.put<AuthService>(MockAuthService());
//       Get.put<MovementReportService>(
//         MockMovementReportService(Get.find<AuthService>()),
//       );
//     });

//     tearDown(() {
//       Get.reset();
//     });

//     testWidgets('should display loading state initially', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         GetMaterialApp(
//           home: Scaffold(
//             body: DailyExpensesSummaryWidget(),
//           ),
//         ),
//       );

//       // Vérifier que l'état de chargement est affiché
//       expect(find.text('Dépenses du jour'), findsOneWidget);
//       expect(find.text('Chargement...'), findsOneWidget);
//       expect(find.byType(CircularProgressIndicator), findsOneWidget);
//     });

//     testWidgets('should display summary data when loaded', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         GetMaterialApp(
//           home: Scaffold(
//             body: DailyExpensesSummaryWidget(),
//           ),
//         ),
//       );

//       // Attendre que les données se chargent
//       await tester.pumpAndSettle(Duration(seconds: 2));

//       // Vérifier que les données sont affichées
//       expect(find.text('Dépenses du jour'), findsOneWidget);
//       expect(find.text('25000.00 FCFA'), findsOneWidget);
//       expect(find.text('3 mouvements'), findsOneWidget);
//     });

//     testWidgets('should display compact version correctly', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         GetMaterialApp(
//           home: Scaffold(
//             body: CompactDailyExpensesSummary(),
//           ),
//         ),
//       );

//       // Vérifier que la version compacte est affichée
//       expect(find.text('Dépenses du jour'), findsOneWidget);

//       // La version compacte ne devrait pas afficher les détails étendus
//       await tester.pumpAndSettle(Duration(seconds: 2));
//       expect(find.text('Moy:'), findsNothing);
//     });

//     testWidgets('should display detailed version correctly', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         GetMaterialApp(
//           home: Scaffold(
//             body: DetailedDailyExpensesSummary(),
//           ),
//         ),
//       );

//       // Attendre que les données se chargent
//       await tester.pumpAndSettle(Duration(seconds: 2));

//       // Vérifier que la version détaillée affiche plus d'informations
//       expect(find.text('Dépenses du jour'), findsOneWidget);
//       expect(find.text('25000.00 FCFA'), findsOneWidget);
//       expect(find.textContaining('Moy:'), findsOneWidget);
//     });

//     testWidgets('should handle tap events', (WidgetTester tester) async {
//       bool tapped = false;

//       await tester.pumpWidget(
//         GetMaterialApp(
//           home: Scaffold(
//             body: DailyExpensesSummaryWidget(
//               onTap: () => tapped = true,
//             ),
//           ),
//         ),
//       );

//       // Taper sur le widget
//       await tester.tap(find.byType(DailyExpensesSummaryWidget));
//       await tester.pumpAndSettle();

//       // Vérifier que le callback a été appelé
//       expect(tapped, isTrue);
//     });

//     testWidgets('should display no data state when no expenses', (WidgetTester tester) async {
//       // Remplacer le service par un qui retourne des données vides
//       Get.delete<MovementReportService>();
//       Get.put<MovementReportService>(
//         _MockEmptyMovementReportService(Get.find<AuthService>()),
//       );

//       await tester.pumpWidget(
//         GetMaterialApp(
//           home: Scaffold(
//             body: DailyExpensesSummaryWidget(),
//           ),
//         ),
//       );

//       // Attendre que les données se chargent
//       await tester.pumpAndSettle(Duration(seconds: 2));

//       // Vérifier l'état "aucune donnée"
//       expect(find.text('Aucune dépense aujourd\'hui'), findsOneWidget);
//       expect(find.text('0 FCFA • 0 mouvement'), findsOneWidget);
//     });
//   });
// }

// class _MockEmptyMovementReportService extends GetxService implements MovementReportService {
//   _MockEmptyMovementReportService(AuthService authService);

//   @override
//   Future<MovementSummary> getSummary(DateTime startDate, DateTime endDate) async {
//     return MovementSummary(
//       totalAmount: 0.0,
//       totalCount: 0,
//       averageAmount: 0.0,
//       maxAmount: 0.0,
//       minAmount: 0.0,
//       lastMovementDate: null,
//     );
//   }

//   @override
//   Future<List<CategorySummary>> getCategorySummary(DateTime startDate, DateTime endDate) async {
//     return [];
//   }

//   @override
//   Future<List<DailySummary>> getDailySummary(DateTime startDate, DateTime endDate) async {
//     return [];
//   }

//   @override
//   Future<String> exportReportToPdf(MovementReportRequest request) async {
//     return '/mock/path/report.pdf';
//   }

//   @override
//   Future<String> exportReportToExcel(MovementReportRequest request) async {
//     return '/mock/path/report.xlsx';
//   }

//   @override
//   Future<MovementReport> generateCompleteReport(DateTime startDate, DateTime endDate) async {
//     final summary = await getSummary(startDate, endDate);
//     return MovementReport(
//       startDate: startDate,
//       endDate: endDate,
//       summary: summary,
//       categorySummaries: [],
//       dailySummaries: [],
//       generatedAt: DateTime.now(),
//     );
//   }

//   @override
//   Future<PeriodComparison> comparePeriods(
//     DateTime period1Start,
//     DateTime period1End,
//     DateTime period2Start,
//     DateTime period2End,
//   ) async {
//     final summary1 = await getSummary(period1Start, period1End);
//     final summary2 = await getSummary(period2Start, period2End);

//     return PeriodComparison(
//       period1Start: period1Start,
//       period1End: period1End,
//       period2Start: period2Start,
//       period2End: period2End,
//       period1Summary: summary1,
//       period2Summary: summary2,
//       period1Categories: [],
//       period2Categories: [],
//       generatedAt: DateTime.now(),
//     );
//   }
// }
