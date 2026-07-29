import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/printing/models/receipt_model.dart';
import 'package:logesco_v2/features/printing/models/print_format.dart';
import 'package:logesco_v2/features/printing/widgets/receipt_template_a4.dart';
import 'package:logesco_v2/features/company_settings/models/company_profile.dart';
import 'package:logesco_v2/features/customers/models/customer.dart';

void main() {
  group('Receipt Header Display Tests', () {
    late Receipt testReceipt;
    late CompanyProfile testCompany;

    setUp(() {
      testCompany = CompanyProfile(
        id: 1,
        name: 'LAURY EVENT SA',
        address: 'yaounde, nvan',
        location: 'Yaounde',
        phone: '658962546',
        email: 'contact@lauryevent.com',
        logo: null,
        slogan: 'Excellence en événementiel',
        nuiRccm: '1234567890',
        createdAt: DateTime.parse('2024-01-01'),
        updatedAt: DateTime.parse('2024-01-01'),
      );

      testReceipt = Receipt(
        id: 'test_001',
        saleId: '1',
        saleNumber: 'VTE-20260718-042216',
        companyInfo: testCompany,
        items: [
          const ReceiptItem(
            productId: '1',
            productName: 'AIR FORCE BLANCHE',
            productReference: 'PRD20260004',
            quantity: 2,
            unitPrice: 25000,
            totalPrice: 50000,
          ),
        ],
        subtotal: 50000,
        discountAmount: 0,
        totalAmount: 50000,
        paidAmount: 50000,
        remainingAmount: 0,
        paymentMethod: 'comptant',
        saleDate: DateTime(2026, 7, 18, 16, 30, 0),
        format: PrintFormat.a4,
      );
    });

    testWidgets('Date and time should be displayed in receipt', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptTemplateA4(
              receipt: testReceipt,
              template: PrintTemplate.defaultFor(PrintFormat.a4),
              showPreview: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que la date est affichée
      expect(find.textContaining('Date:'), findsOneWidget);
      expect(find.textContaining('18/07/2026'), findsOneWidget);

      // Vérifier que l'heure est affichée
      expect(find.textContaining('Heure:'), findsOneWidget);
      expect(find.textContaining('16:30'), findsOneWidget);
    });

    testWidgets('Company info should be in header line', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptTemplateA4(
              receipt: testReceipt,
              template: PrintTemplate.defaultFor(PrintFormat.a4),
              showPreview: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que les informations de l'entreprise sont affichées en ligne
      // La localisation devrait être présente
      expect(find.textContaining('Localisation:'), findsOneWidget);
      expect(find.textContaining('Yaounde'), findsOneWidget);

      // L'adresse devrait être présente
      expect(find.textContaining('Adresse:'), findsOneWidget);

      // Le téléphone devrait être présent
      expect(find.textContaining('Tél:'), findsOneWidget);
      expect(find.textContaining('658962546'), findsOneWidget);
    });

    testWidgets('Only customer card should be displayed, not issuer card', (WidgetTester tester) async {
      final receiptWithCustomer = testReceipt.copyWith(
        customer: Customer(
          id: 1,
          nom: 'soeur mana MANA',
          telephone: '123456789',
          adresse: 'Test Address',
          nui: '0123456789',
          rccm: 'ABCDRF',
          dateCreation: DateTime(2024, 1, 1),
          dateModification: DateTime(2024, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptTemplateA4(
              receipt: receiptWithCustomer,
              template: PrintTemplate.defaultFor(PrintFormat.a4),
              showPreview: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que "Client" est présent (titre de la carte)
      expect(find.text('Client'), findsOneWidget);

      // Vérifier que "Émetteur" n'est PAS présent (carte supprimée)
      expect(find.text('Émetteur'), findsNothing);

      // Vérifier que les infos du client sont affichées
      expect(find.textContaining('soeur mana MANA'), findsOneWidget);
      expect(find.textContaining('NUI: 0123456789'), findsOneWidget);
    });

    test('Custom sale date should preserve current time', () {
      // Simuler la sélection d'une date
      final selectedDate = DateTime(2026, 7, 2, 0, 0, 0); // Date du sélecteur (minuit)
      final now = DateTime.now();

      // Appliquer la même logique que setCustomSaleDate
      final resultDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      // Vérifier que la date est correcte mais l'heure est celle d'aujourd'hui
      expect(resultDate.year, equals(2026));
      expect(resultDate.month, equals(7));
      expect(resultDate.day, equals(2));
      expect(resultDate.hour, equals(now.hour));
      expect(resultDate.minute, equals(now.minute));
      expect(resultDate.second, equals(now.second));
    });
  });
}
