import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/printing/models/receipt_model.dart';
import 'package:logesco_v2/features/printing/models/print_format.dart' as print_models;
import 'package:logesco_v2/features/printing/utils/receipt_translations.dart';
import 'package:logesco_v2/features/company_settings/models/company_profile.dart';
import 'package:logesco_v2/features/customers/models/customer.dart';

/// Preservation Property Tests - Contenu Informationnel et Calculs Préservés
///
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10**
///
/// **IMPORTANT**: Ces tests suivent la méthodologie observation-first.
/// Ils observent le comportement du code NON CORRIGÉ pour les entrées non-buggy.
///
/// **Property 2: Preservation** - Pour toutes les factures où la condition de bug n'est
/// PAS vraie (isBugCondition returns false), le template fixé SHALL produire exactement
/// le même contenu informationnel que le template original.
///
/// **RÉSULTAT ATTENDU**: Ces tests PASSENT sur le code non corrigé (ils confirment le
/// comportement de base à préserver).
///
/// Note sur la stratégie de test:
/// Comme le code source a des erreurs de compilation dans buildHeader() et buildCompanyHeader(),
/// les tests de préservation se concentrent sur les modèles de données, les calculs, et
/// les utilitaires de traduction — qui fonctionnent correctement et constituent le
/// comportement informationnel à préserver.

// ─── Helpers : constructeurs de données de test ─────────────────────────────

CompanyProfile _makeCompany({
  String name = 'Logesco SARL',
  String address = '123 Rue du Commerce',
  String? location = 'Yaoundé, Cameroun',
  String? phone = '+237 699 123 456',
  String? email = 'contact@logesco.cm',
  String? nuiRccm = 'NUI-12345/RCCM-67890',
  String? logo,
  String? slogan = 'Votre partenaire commercial',
  String language = 'fr',
}) {
  return CompanyProfile(
    name: name,
    address: address,
    location: location,
    phone: phone,
    email: email,
    nuiRccm: nuiRccm,
    logo: logo,
    slogan: slogan,
    receiptLanguage: language,
  );
}

ReceiptItem _makeItem({
  String productId = '1',
  String productName = 'Produit Test',
  String productReference = 'REF-001',
  int quantity = 2,
  double unitPrice = 5000.0,
  double totalPrice = 10000.0,
  double displayPrice = 5000.0,
  double discountAmount = 0.0,
}) {
  return ReceiptItem(
    productId: productId,
    productName: productName,
    productReference: productReference,
    quantity: quantity,
    unitPrice: unitPrice,
    totalPrice: totalPrice,
    displayPrice: displayPrice,
    discountAmount: discountAmount,
  );
}

Receipt _makeReceipt({
  String saleNumber = 'V-2024-001',
  CompanyProfile? company,
  List<ReceiptItem>? items,
  double subtotal = 10000.0,
  double discountAmount = 0.0,
  double tvaRate = 0.0,
  double tvaAmount = 0.0,
  double totalAmount = 10000.0,
  double paidAmount = 10000.0,
  double remainingAmount = 0.0,
  String paymentMethod = 'Espèces',
  DateTime? saleDate,
  Customer? customer,
  print_models.PrintFormat format = print_models.PrintFormat.a4,
  String language = 'fr',
  bool isReprint = false,
  int reprintCount = 0,
  DateTime? lastReprintDate,
  String? reprintBy,
  bool isProforma = false,
}) {
  return Receipt(
    id: 'test-receipt-001',
    saleId: 'sale-001',
    saleNumber: saleNumber,
    companyInfo: company ?? _makeCompany(),
    items: items ?? [_makeItem()],
    subtotal: subtotal,
    discountAmount: discountAmount,
    tvaRate: tvaRate,
    tvaAmount: tvaAmount,
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    remainingAmount: remainingAmount,
    paymentMethod: paymentMethod,
    saleDate: saleDate ?? DateTime(2024, 6, 15, 14, 30),
    customer: customer,
    format: format,
    language: language,
    isReprint: isReprint,
    reprintCount: reprintCount,
    lastReprintDate: lastReprintDate,
    reprintBy: reprintBy,
    isProforma: isProforma,
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── 3.1 Logo affiché correctement pour les factures avec logo valide ────────
  group('3.1 - Logo display for invoices with valid logo', () {
    test('Property: Receipt with valid logo path preserves logo field', () {
      const logoPath = 'company_logo.png';
      final company = _makeCompany(logo: logoPath);
      final receipt = _makeReceipt(company: company);

      // Observation: le logo est stocké et accessible depuis companyInfo
      expect(receipt.companyInfo.logo, equals(logoPath));
      expect(receipt.companyInfo.logo!.isNotEmpty, isTrue);
    });

    test('Property: Receipt without logo has null/empty logo field', () {
      final company = _makeCompany(logo: null);
      final receipt = _makeReceipt(company: company);

      // Observation: absence de logo est correctement représentée
      final hasLogo = receipt.companyInfo.logo != null && receipt.companyInfo.logo!.isNotEmpty;
      expect(hasLogo, isFalse);
    });

    test('Property: Multiple receipts with various logo states preserve their logo state', () {
      // Générer différentes combinaisons de logos (simulation PBT)
      final testCases = [
        (logo: 'logo1.png', hasLogo: true),
        (logo: 'path/to/logo.jpg', hasLogo: true),
        (logo: null as String?, hasLogo: false),
        (logo: '', hasLogo: false),
      ];

      for (final tc in testCases) {
        final company = _makeCompany(logo: tc.logo);
        final receipt = _makeReceipt(company: company);
        final actualHasLogo = receipt.companyInfo.logo != null && receipt.companyInfo.logo!.isNotEmpty;
        expect(actualHasLogo, equals(tc.hasLogo), reason: 'Logo "${tc.logo}" should have hasLogo=${tc.hasLogo}');
      }
    });
  });

  // ── 3.2 Informations entreprise complètes et exactes ──────────────────────
  group('3.2 - Company information is complete and exact', () {
    test('Property: All company fields are preserved in receipt', () {
      final company = _makeCompany(
        name: 'SARL Dupont & Fils',
        address: '12 Avenue des Affaires',
        location: 'Douala, Littoral',
        phone: '+237 677 000 111',
        email: 'dupont@example.cm',
        nuiRccm: 'NUI-99887/RCCM-11223',
      );
      final receipt = _makeReceipt(company: company);

      expect(receipt.companyInfo.name, equals('SARL Dupont & Fils'));
      expect(receipt.companyInfo.address, equals('12 Avenue des Affaires'));
      expect(receipt.companyInfo.location, equals('Douala, Littoral'));
      expect(receipt.companyInfo.phone, equals('+237 677 000 111'));
      expect(receipt.companyInfo.email, equals('dupont@example.cm'));
      expect(receipt.companyInfo.nuiRccm, equals('NUI-99887/RCCM-11223'));
    });

    test('Property: Company with partial info preserves only provided fields', () {
      final company = _makeCompany(
        name: 'Mini Shop',
        address: 'Centre-ville',
        location: null,
        phone: null,
        email: null,
        nuiRccm: null,
      );
      final receipt = _makeReceipt(company: company);

      expect(receipt.companyInfo.name, equals('Mini Shop'));
      expect(receipt.companyInfo.address, equals('Centre-ville'));
      expect(receipt.companyInfo.location, isNull);
      expect(receipt.companyInfo.phone, isNull);
      expect(receipt.companyInfo.email, isNull);
      expect(receipt.companyInfo.nuiRccm, isNull);
    });

    test('Property: Company name is never empty in valid receipts', () {
      // Simuler plusieurs noms d'entreprise (génération PBT-style)
      final names = [
        'Logesco SARL',
        'Trading Co',
        'EURL ABC',
        'Boutique Centrale',
        'Supermarché Express',
      ];
      for (final name in names) {
        final company = _makeCompany(name: name);
        final receipt = _makeReceipt(company: company);
        expect(receipt.companyInfo.name, isNotEmpty, reason: 'Company name "$name" should not be empty in receipt');
        expect(receipt.companyInfo.name, equals(name));
      }
    });
  });

  // ── 3.3 Informations de vente précises ────────────────────────────────────
  group('3.3 - Sale information is accurate', () {
    test('Property: Sale number, date, and payment method are preserved', () {
      final saleDate = DateTime(2024, 3, 20, 9, 45);
      final receipt = _makeReceipt(
        saleNumber: 'V-2024-567',
        paymentMethod: 'Carte Bancaire',
        saleDate: saleDate,
      );

      expect(receipt.saleNumber, equals('V-2024-567'));
      expect(receipt.paymentMethod, equals('Carte Bancaire'));
      expect(receipt.saleDate, equals(saleDate));
      expect(receipt.saleDate.day, equals(20));
      expect(receipt.saleDate.month, equals(3));
      expect(receipt.saleDate.year, equals(2024));
      expect(receipt.saleDate.hour, equals(9));
      expect(receipt.saleDate.minute, equals(45));
    });

    test('Property: Customer info is preserved when customer is set', () {
      final customer = Customer(
        id: 1,
        nom: 'Jean-Pierre Mbarga',
        telephone: '+237 691 234 567',
        email: 'jp.mbarga@email.cm',
        adresse: 'Quartier Bastos, Yaoundé',
        nui: 'NUI-CUST-001',
        rccm: 'RCCM-CUST-001',
        dateCreation: DateTime(2023, 1, 1),
        dateModification: DateTime(2023, 1, 1),
      );
      final receipt = _makeReceipt(customer: customer);

      expect(receipt.customer, isNotNull);
      expect(receipt.customer!.nom, equals('Jean-Pierre Mbarga'));
      expect(receipt.customer!.telephone, equals('+237 691 234 567'));
      expect(receipt.customer!.nui, equals('NUI-CUST-001'));
      expect(receipt.customer!.rccm, equals('RCCM-CUST-001'));
    });

    test('Property: Receipt with no customer has null customer field', () {
      final receipt = _makeReceipt(customer: null);
      expect(receipt.customer, isNull);
    });

    test('Property: Multiple sale numbers are each preserved exactly', () {
      final saleNumbers = [
        'V-2024-001',
        'V-2024-999',
        'PROFORMA-001',
        'V-2023-5678',
      ];
      for (final saleNumber in saleNumbers) {
        final receipt = _makeReceipt(saleNumber: saleNumber);
        expect(receipt.saleNumber, equals(saleNumber));
      }
    });
  });

  // ── 3.4 Articles listés avec toutes leurs propriétés ──────────────────────
  group('3.4 - All sale items listed with their properties', () {
    test('Property: Each item preserves name, reference, quantity, unit price, total', () {
      final item = _makeItem(
        productName: 'Huile de Palme 1L',
        productReference: 'HP-001',
        quantity: 5,
        unitPrice: 1500.0,
        totalPrice: 7500.0,
      );
      final receipt = _makeReceipt(items: [item]);

      expect(receipt.items.length, equals(1));
      final retrievedItem = receipt.items.first;
      expect(retrievedItem.productName, equals('Huile de Palme 1L'));
      expect(retrievedItem.productReference, equals('HP-001'));
      expect(retrievedItem.quantity, equals(5));
      expect(retrievedItem.unitPrice, equals(1500.0));
      expect(retrievedItem.totalPrice, equals(7500.0));
    });

    test('Property: Item formatted prices use FCFA suffix', () {
      final item = _makeItem(unitPrice: 2500.0, totalPrice: 5000.0);
      expect(item.formattedUnitPrice, contains('FCFA'));
      expect(item.formattedTotalPrice, contains('FCFA'));
      expect(item.formattedUnitPrice, contains('2500'));
      expect(item.formattedTotalPrice, contains('5000'));
    });

    test('Property: All items in a multi-item receipt are preserved in order', () {
      final items = [
        _makeItem(productId: '1', productName: 'Article A', quantity: 1, unitPrice: 1000, totalPrice: 1000),
        _makeItem(productId: '2', productName: 'Article B', quantity: 3, unitPrice: 2000, totalPrice: 6000),
        _makeItem(productId: '3', productName: 'Article C', quantity: 2, unitPrice: 500, totalPrice: 1000),
      ];
      final receipt = _makeReceipt(items: items);

      expect(receipt.items.length, equals(3));
      expect(receipt.items[0].productName, equals('Article A'));
      expect(receipt.items[1].productName, equals('Article B'));
      expect(receipt.items[2].productName, equals('Article C'));
      expect(receipt.items[1].quantity, equals(3));
      expect(receipt.items[2].unitPrice, equals(500.0));
    });

    test('Property: Items with discount preserve discount information', () {
      final item = _makeItem(
        unitPrice: 3000.0,
        displayPrice: 3500.0,
        discountAmount: 500.0,
        totalPrice: 6000.0, // 2 * 3000
        quantity: 2,
      );
      expect(item.hasDiscount, isTrue);
      expect(item.discountAmount, equals(500.0));
      expect(item.totalDiscountAmount, equals(1000.0)); // 500 * 2
      expect(item.displayPrice, equals(3500.0));
    });

    test('Property: Item without reference preserves empty reference field', () {
      final item = _makeItem(productReference: '');
      expect(item.productReference, isEmpty);
    });

    // PBT-style: vérifier toutes les listes de taille variable (1 à 10 articles)
    test('Property: Receipt items count is preserved for any list size (1 to 10)', () {
      for (int count = 1; count <= 10; count++) {
        final items = List.generate(
          count,
          (i) => _makeItem(
            productId: '$i',
            productName: 'Produit $i',
            quantity: i + 1,
            unitPrice: (i + 1) * 100.0,
            totalPrice: (i + 1) * (i + 1) * 100.0,
          ),
        );
        final receipt = _makeReceipt(items: items);
        expect(receipt.items.length, equals(count), reason: 'Receipt with $count items should preserve item count');
        for (int j = 0; j < count; j++) {
          expect(receipt.items[j].productName, equals('Produit $j'));
        }
      }
    });
  });

  // ── 3.5 Calculs de totaux exacts ──────────────────────────────────────────
  group('3.5 - All totals calculations are exact', () {
    test('Property: Subtotal, total, paid, remaining are preserved exactly', () {
      final receipt = _makeReceipt(
        subtotal: 20000.0,
        discountAmount: 2000.0,
        tvaRate: 19.25,
        tvaAmount: 3468.75,
        totalAmount: 21468.75,
        paidAmount: 25000.0,
        remainingAmount: 0.0,
      );

      expect(receipt.subtotal, equals(20000.0));
      expect(receipt.discountAmount, equals(2000.0));
      expect(receipt.tvaRate, equals(19.25));
      expect(receipt.tvaAmount, equals(3468.75));
      expect(receipt.totalAmount, equals(21468.75));
      expect(receipt.paidAmount, equals(25000.0));
      expect(receipt.remainingAmount, equals(0.0));
    });

    test('Property: isFullyPaid is true when remainingAmount <= 0', () {
      final paidReceipt = _makeReceipt(
        totalAmount: 10000.0,
        paidAmount: 10000.0,
        remainingAmount: 0.0,
      );
      expect(paidReceipt.isFullyPaid, isTrue);
    });

    test('Property: isFullyPaid is false when remainingAmount > 0', () {
      final unpaidReceipt = _makeReceipt(
        totalAmount: 10000.0,
        paidAmount: 5000.0,
        remainingAmount: 5000.0,
      );
      expect(unpaidReceipt.isFullyPaid, isFalse);
    });

    test('Property: Change (monnaie rendue) is computable from paidAmount - totalAmount', () {
      final receipt = _makeReceipt(
        totalAmount: 7500.0,
        paidAmount: 10000.0,
        remainingAmount: 0.0,
      );
      final change = receipt.paidAmount - receipt.totalAmount;
      expect(change, equals(2500.0));
    });

    // PBT-style: vérifier la cohérence des totaux pour plusieurs combinaisons
    test('Property: Total amounts are numerically consistent across multiple receipts', () {
      final testCases = [
        (subtotal: 5000.0, discount: 0.0, tva: 0.0, total: 5000.0),
        (subtotal: 10000.0, discount: 1000.0, tva: 0.0, total: 9000.0),
        (subtotal: 10000.0, discount: 0.0, tva: 1925.0, total: 11925.0),
        (subtotal: 15000.0, discount: 500.0, tva: 2785.6, total: 17285.6),
      ];

      for (final tc in testCases) {
        final receipt = _makeReceipt(
          subtotal: tc.subtotal,
          discountAmount: tc.discount,
          tvaAmount: tc.tva,
          totalAmount: tc.total,
          paidAmount: tc.total,
        );
        expect(receipt.subtotal, equals(tc.subtotal));
        expect(receipt.discountAmount, equals(tc.discount));
        expect(receipt.tvaAmount, equals(tc.tva));
        expect(receipt.totalAmount, equals(tc.total));
      }
    });

    test('Property: Item formattedUnitPrice and formattedTotalPrice are exact', () {
      final item = _makeItem(unitPrice: 3750.0, totalPrice: 11250.0, quantity: 3);
      expect(item.formattedUnitPrice, equals('3750 FCFA'));
      expect(item.formattedTotalPrice, equals('11250 FCFA'));
    });

    test('Property: totalDiscountAmount = discountAmount * quantity for each item', () {
      // PBT-style: plusieurs quantités et remises
      final testCases = [
        (qty: 1, disc: 100.0, expected: 100.0),
        (qty: 3, disc: 200.0, expected: 600.0),
        (qty: 5, disc: 50.0, expected: 250.0),
        (qty: 10, disc: 0.0, expected: 0.0),
      ];
      for (final tc in testCases) {
        final item = _makeItem(
          quantity: tc.qty,
          discountAmount: tc.disc,
          totalPrice: tc.qty * 1000.0,
        );
        expect(item.totalDiscountAmount, equals(tc.expected), reason: 'qty=${tc.qty}, disc=${tc.disc} → expected ${tc.expected}');
      }
    });
  });

  // ── 3.6 Mise en page A5 adaptée et lisible ────────────────────────────────
  group('3.6 - A5 format layout is adapted and readable', () {
    test('Property: A5 format receipt preserves all content in format A5', () {
      final receipt = _makeReceipt(format: print_models.PrintFormat.a5);
      expect(receipt.format, equals(print_models.PrintFormat.a5));
      // All content fields are intact regardless of format
      expect(receipt.companyInfo.name, isNotEmpty);
      expect(receipt.saleNumber, isNotEmpty);
      expect(receipt.items, isNotEmpty);
    });

    test('Property: A5 PrintTemplate has smaller fontSize than A4', () {
      final a4Template = print_models.PrintTemplate.defaultFor(print_models.PrintFormat.a4);
      final a5Template = print_models.PrintTemplate.defaultFor(print_models.PrintFormat.a5);

      expect(a5Template.fontSize, lessThan(a4Template.fontSize), reason: 'A5 font size should be smaller than A4 to fit the compact format');
    });

    test('Property: A5 format dimensions are smaller than A4', () {
      expect(print_models.PrintFormat.a5.widthMm, lessThan(print_models.PrintFormat.a4.widthMm));
      expect(print_models.PrintFormat.a5.heightMm, lessThan(print_models.PrintFormat.a4.heightMm));
    });

    test('Property: A5 receipt preserves same items count and values as A4', () {
      final items = [
        _makeItem(productName: 'Produit A', quantity: 2, unitPrice: 3000.0, totalPrice: 6000.0),
        _makeItem(productName: 'Produit B', quantity: 1, unitPrice: 1500.0, totalPrice: 1500.0),
      ];
      final a4Receipt = _makeReceipt(items: items, format: print_models.PrintFormat.a4);
      final a5Receipt = _makeReceipt(items: items, format: print_models.PrintFormat.a5);

      expect(a5Receipt.items.length, equals(a4Receipt.items.length));
      for (int i = 0; i < items.length; i++) {
        expect(a5Receipt.items[i].productName, equals(a4Receipt.items[i].productName));
        expect(a5Receipt.items[i].quantity, equals(a4Receipt.items[i].quantity));
        expect(a5Receipt.items[i].totalPrice, equals(a4Receipt.items[i].totalPrice));
      }
    });
  });

  // ── 3.7 Indicateur de réimpression affiché ────────────────────────────────
  group('3.7 - Reprint indicator is displayed', () {
    test('Property: Reprint receipt has isReprint=true and non-empty indicator', () {
      final reprintDate = DateTime(2024, 7, 10, 16, 0);
      final receipt = _makeReceipt(
        isReprint: true,
        reprintCount: 2,
        lastReprintDate: reprintDate,
        reprintBy: 'Alice Martin',
      );

      expect(receipt.isReprint, isTrue);
      expect(receipt.reprintCount, equals(2));
      expect(receipt.lastReprintDate, isNotNull);
      expect(receipt.lastReprintDate, equals(reprintDate));
      expect(receipt.reprintBy, equals('Alice Martin'));
    });

    test('Property: reprintIndicator text is non-empty for reprint receipts', () {
      final receipt = _makeReceipt(isReprint: true, reprintCount: 1);
      expect(receipt.reprintIndicator, isNotEmpty);
      expect(receipt.reprintIndicator, contains('COPIE'));
    });

    test('Property: reprintIndicator is empty for original receipts', () {
      final receipt = _makeReceipt(isReprint: false);
      expect(receipt.reprintIndicator, isEmpty);
    });

    test('Property: Multiple reprint copies increment counter correctly', () {
      for (int count = 1; count <= 5; count++) {
        final receipt = _makeReceipt(isReprint: true, reprintCount: count);
        expect(receipt.reprintIndicator, isNotEmpty);
        if (count > 1) {
          expect(receipt.reprintIndicator, contains('($count)'));
        }
      }
    });
  });

  // ── 3.8 Label "Facture Proforma" pour les proformas ───────────────────────
  group('3.8 - Proforma invoice shows correct label', () {
    test('Property: Proforma receipt has isProforma=true', () {
      final receipt = _makeReceipt(isProforma: true);
      expect(receipt.isProforma, isTrue);
    });

    test('Property: Normal receipt has isProforma=false', () {
      final receipt = _makeReceipt(isProforma: false);
      expect(receipt.isProforma, isFalse);
    });

    test('Property: Translation key "proformaInvoice" returns correct label in FR', () {
      final label = ReceiptTranslations.get('proformaInvoice', language: 'fr');
      expect(label, contains('PROFORMA'));
    });

    test('Property: Translation key "proformaInvoice" returns correct label in EN', () {
      final label = ReceiptTranslations.get('proformaInvoice', language: 'en');
      expect(label, contains('PROFORMA'));
    });

    test('Property: Translation key "proformaInvoice" returns correct label in ES', () {
      final label = ReceiptTranslations.get('proformaInvoice', language: 'es');
      expect(label, contains('PROFORMA'));
    });

    test('Property: Proforma label differs from invoice label in all languages', () {
      for (final lang in ['fr', 'en', 'es']) {
        final invoiceLabel = ReceiptTranslations.get('invoice', language: lang);
        final proformaLabel = ReceiptTranslations.get('proformaInvoice', language: lang);
        expect(proformaLabel, isNot(equals(invoiceLabel)), reason: 'In language $lang, proforma label should differ from invoice label');
        expect(proformaLabel.length, greaterThan(invoiceLabel.length), reason: 'Proforma label should be longer than invoice label (contains more words)');
      }
    });
  });

  // ── 3.9 Pied de page correct ──────────────────────────────────────────────
  group('3.9 - Footer content is correct', () {
    test('Property: Thank-you message is translated correctly in FR', () {
      final msg = ReceiptTranslations.get('thankYou', language: 'fr');
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('merci'));
    });

    test('Property: Thank-you message is translated correctly in EN', () {
      final msg = ReceiptTranslations.get('thankYou', language: 'en');
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('thank'));
    });

    test('Property: Thank-you message is translated correctly in ES', () {
      final msg = ReceiptTranslations.get('thankYou', language: 'es');
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('graci'));
    });

    test('Property: Company slogan is preserved in receipt footer data', () {
      final company = _makeCompany(slogan: 'La qualité avant tout');
      final receipt = _makeReceipt(company: company);
      expect(receipt.companyInfo.slogan, equals('La qualité avant tout'));
      expect(receipt.companyInfo.slogan!.isNotEmpty, isTrue);
    });

    test('Property: Receipt without slogan has null/empty slogan field', () {
      final company = _makeCompany(slogan: null);
      final receipt = _makeReceipt(company: company);
      final hasSlogan = receipt.companyInfo.slogan != null && receipt.companyInfo.slogan!.isNotEmpty;
      expect(hasSlogan, isFalse);
    });

    test('Property: Reprint footer data contains date and user info', () {
      final reprintDate = DateTime(2024, 8, 1, 10, 30);
      final receipt = _makeReceipt(
        isReprint: true,
        reprintCount: 1,
        lastReprintDate: reprintDate,
        reprintBy: 'Marc Dupont',
      );
      expect(receipt.lastReprintDate, equals(reprintDate));
      expect(receipt.reprintBy, equals('Marc Dupont'));
      // Verify "reprintedOn" and "by" translations exist
      expect(ReceiptTranslations.get('reprintedOn', language: 'fr'), isNotEmpty);
      expect(ReceiptTranslations.get('by', language: 'fr'), isNotEmpty);
    });
  });

  // ── 3.10 Traductions fonctionnent selon la langue ─────────────────────────
  group('3.10 - Translations work according to the selected language', () {
    test('Property: All supported languages return non-empty translations for invoice key', () {
      for (final lang in ['fr', 'en', 'es']) {
        final result = ReceiptTranslations.get('invoice', language: lang);
        expect(result, isNotEmpty, reason: 'Translation for "invoice" in "$lang" should not be empty');
      }
    });

    test('Property: FR, EN, ES give different translations for "invoice"', () {
      final fr = ReceiptTranslations.get('invoice', language: 'fr');
      final en = ReceiptTranslations.get('invoice', language: 'en');
      final es = ReceiptTranslations.get('invoice', language: 'es');

      expect(fr, equals('FACTURE'));
      expect(en, equals('INVOICE'));
      expect(es, equals('FACTURA'));

      // All three are different
      expect(fr, isNot(equals(en)));
      expect(fr, isNot(equals(es)));
      expect(en, isNot(equals(es)));
    });

    test('Property: All translation keys return non-empty values for all 3 languages', () {
      // These are all the keys used in buildSaleInfo, buildItemsList, buildTotals, buildFooter
      final keys = [
        'invoice',
        'proformaInvoice',
        'reprint',
        'saleNumber',
        'date',
        'customer',
        'paymentMethod',
        'article',
        'quantity',
        'unitPrice',
        'total',
        'reference',
        'subtotal',
        'discount',
        'totalAmount',
        'paid',
        'change',
        'remaining',
        'thankYou',
        'reprintedOn',
        'by',
        'phone',
        'email',
        'nuiRccm',
      ];
      // Keys whose translation may legitimately match the key name in some languages
      const identicalAllowed = {'by', 'email', 'date', 'total'};

      for (final lang in ['fr', 'en', 'es']) {
        for (final key in keys) {
          final result = ReceiptTranslations.get(key, language: lang);
          expect(result, isNotEmpty, reason: 'Translation for key "$key" in language "$lang" should not be empty');
          if (!identicalAllowed.contains(key)) {
            expect(result, isNot(equals(key)), reason: 'Translation for "$key" in "$lang" should be translated, not the raw key');
          }
        }
      }
    });

    test('Property: Unsupported language falls back to French', () {
      final result = ReceiptTranslations.get('invoice', language: 'de');
      // Falls back to FR default
      expect(result, isNotEmpty);
      expect(result, equals(ReceiptTranslations.get('invoice', language: 'fr')));
    });

    test('Property: Receipt language is preserved through the receipt model', () {
      for (final lang in ['fr', 'en', 'es']) {
        final company = _makeCompany(language: lang);
        final receipt = _makeReceipt(company: company, language: lang);
        expect(receipt.language, equals(lang));
        expect(receipt.companyInfo.receiptLanguage, equals(lang));
      }
    });

    test('Property: isLanguageSupported returns true only for fr, en, es', () {
      expect(ReceiptTranslations.isLanguageSupported('fr'), isTrue);
      expect(ReceiptTranslations.isLanguageSupported('en'), isTrue);
      expect(ReceiptTranslations.isLanguageSupported('es'), isTrue);
      expect(ReceiptTranslations.isLanguageSupported('de'), isFalse);
      expect(ReceiptTranslations.isLanguageSupported('ar'), isFalse);
      expect(ReceiptTranslations.isLanguageSupported(''), isFalse);
    });

    test('Property: getSupportedLanguages returns exactly [fr, en, es]', () {
      final langs = ReceiptTranslations.getSupportedLanguages();
      expect(langs, containsAll(['fr', 'en', 'es']));
      expect(langs.length, equals(3));
    });

    // PBT-style: toutes les clés × toutes les langues produisent des traductions distinctes
    test('Property: FR translations differ from EN for key non-identical terms', () {
      // These keys are language-specific (not abbreviations shared across languages)
      final distinctKeys = [
        'invoice',
        'proformaInvoice',
        'reprint',
        'customer',
        'paymentMethod',
        'subtotal',
        'paid',
        'change',
        'remaining',
        'thankYou',
      ];
      for (final key in distinctKeys) {
        final fr = ReceiptTranslations.get(key, language: 'fr');
        final en = ReceiptTranslations.get(key, language: 'en');
        expect(fr, isNot(equals(en)), reason: 'Key "$key": FR "$fr" and EN "$en" should be different translations');
      }
    });
  });

  // ── Summary: Preservation across copyWith and copyForReprint ──────────────
  group('Preservation through receipt copies', () {
    test('Property: copyWith preserves all unmodified fields', () {
      final original = _makeReceipt(
        saleNumber: 'V-001',
        totalAmount: 10000.0,
        language: 'en',
      );
      final copy = original.copyWith(paymentMethod: 'Virement');

      expect(copy.saleNumber, equals(original.saleNumber));
      expect(copy.totalAmount, equals(original.totalAmount));
      expect(copy.language, equals(original.language));
      expect(copy.companyInfo.name, equals(original.companyInfo.name));
      expect(copy.items.length, equals(original.items.length));
      expect(copy.paymentMethod, equals('Virement')); // Only this changed
    });

    test('Property: copyForReprint marks receipt as reprint with incremented count', () {
      final original = _makeReceipt(isReprint: false, reprintCount: 0);
      final reprint = original.copyForReprint(reprintBy: 'Manager Bob');

      expect(reprint.isReprint, isTrue);
      expect(reprint.reprintCount, equals(1));
      expect(reprint.reprintBy, equals('Manager Bob'));
      expect(reprint.lastReprintDate, isNotNull);

      // All content fields preserved
      expect(reprint.saleNumber, equals(original.saleNumber));
      expect(reprint.companyInfo.name, equals(original.companyInfo.name));
      expect(reprint.items.length, equals(original.items.length));
      expect(reprint.totalAmount, equals(original.totalAmount));
      expect(reprint.language, equals(original.language));
    });
  });
}
