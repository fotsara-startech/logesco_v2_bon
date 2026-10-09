import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/customers/models/customer.dart';
import 'package:logesco_v2/features/company_settings/models/company_profile.dart';
import 'package:logesco_v2/features/sales/controllers/sales_controller.dart';
import 'package:logesco_v2/features/sales/models/sale.dart';
import 'package:logesco_v2/features/sales/widgets/finalize_sale_dialog.dart';

/// Faux contrôleur de vente : seules les parties lues/écrites par le dialogue
/// de paiement sont réelles (le vrai contrôleur exige tout le backend).
class _FakeSales extends GetxController implements SalesController {
  final Rx<Customer?> client = Rx<Customer?>(null);
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool tva = false.obs;
  final RxBool creating = false.obs;
  final Rx<CompanyProfile?> profile = Rx<CompanyProfile?>(null);

  // ce que le dialogue a envoyé au moment de valider
  double? sentAmountPaid;
  bool? sentResteVersSolde;
  String? sentMode;
  int createCalls = 0;

  @override
  Customer? get selectedCustomer => client.value;
  @override
  List<CartItem> get cartItems => items;
  @override
  double get cartSubtotal => items.fold(0.0, (s, i) => s + i.totalPrice);
  @override
  bool get tvaEnabled => tva.value;
  @override
  double get tvaRate => 0.0;
  @override
  double get tvaAmount => 0.0;
  @override
  double get cartTotalTTC => cartSubtotal;
  @override
  CompanyProfile? get companyProfile => profile.value; // lecture observable, comme le vrai contrôleur
  @override
  bool get isCreating => creating.value;

  @override
  void setAmountPaid(double amount) => sentAmountPaid = amount;
  @override
  void setResteVersSolde(bool value) => sentResteVersSolde = value;
  @override
  void setPaymentMode(String m) => sentMode = m;
  @override
  void setDiscount(double d) {}
  @override
  Future<bool> createSale() async {
    createCalls++;
    return false; // on s'arrête avant l'impression du reçu
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Customer _client(double solde) => Customer(
      id: 1,
      nom: 'HUBERT',
      prenom: 'MEDIGA',
      solde: solde,
      dateCreation: DateTime(2026),
      dateModification: DateTime(2026),
    );

CartItem _item(double prix) => CartItem(productId: 1, productName: 'P', productReference: 'R', quantity: 1, unitPrice: prix, originalPrice: prix);

Future<_FakeSales> _open(WidgetTester tester, {required double solde, required double vente, bool withClient = true, Size size = const Size(1000, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  Get.testMode = true;
  final fake = _FakeSales();
  if (withClient) fake.client.value = _client(solde);
  fake.items.add(_item(vente));
  Get.put<SalesController>(fake);

  await tester.pumpWidget(GetMaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => Get.dialog(const FinalizeSaleDialog(), barrierDismissible: false),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return fake;
}

String _amountField(WidgetTester tester) => tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text;

void main() {
  tearDown(() => Get.reset());

  testWidgets('client avec avance : l\'espèce proposée = vente − avance, l\'avance est affichée', (tester) async {
    await _open(tester, solde: 30000, vente: 50000);
    expect(find.text("Utiliser l'avance du client"), findsOneWidget);
    expect(find.text('Avance disponible : 30000 FCFA'), findsOneWidget);
    expect(_amountField(tester), '20000');
    expect(find.text('Avance utilisée'), findsOneWidget);
    expect(find.text('Reste à encaisser'), findsOneWidget);
  });

  testWidgets('décocher l\'avance : le client doit payer la vente en espèces', (tester) async {
    final fake = await _open(tester, solde: 30000, vente: 50000);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(_amountField(tester), '50000');
    expect(find.text('Avance utilisée'), findsNothing);

    // payer moins que la vente sans l'avance : refusé
    await tester.enterText(find.byType(TextFormField), '20000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sans l\'avance, le client doit payer au moins 50000 FCFA'), findsOneWidget);
    expect(fake.createCalls, 0);
  });

  testWidgets('avance qui couvre tout : aucun espèce, la vente part en comptant', (tester) async {
    final fake = await _open(tester, solde: 80000, vente: 50000);
    expect(_amountField(tester), '0');
    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    expect(fake.createCalls, 1);
    expect(fake.sentAmountPaid, 0);
    expect(fake.sentMode, 'comptant');
    expect(fake.sentResteVersSolde, false);
  });

  testWidgets('pas de monnaie : l\'excédent peut être ajouté au solde du client', (tester) async {
    final fake = await _open(tester, solde: 0, vente: 50000);
    expect(find.text('Rendre la monnaie'), findsNothing); // pas d'excédent au départ

    await tester.enterText(find.byType(TextFormField), '60000');
    await tester.pumpAndSettle();
    expect(find.text('Excédent de 10000 FCFA'), findsOneWidget);
    expect(find.text('sales_change_to_return'.tr), findsOneWidget);

    await tester.tap(find.text('Ajouter au solde du client'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouté au solde du client'), findsOneWidget);
    expect(find.textContaining('Nouveau solde du client : 10000 FCFA'), findsOneWidget);

    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    expect(fake.sentAmountPaid, 60000);
    expect(fake.sentResteVersSolde, true);
    expect(fake.sentMode, 'comptant');
  });

  testWidgets('sans client : la monnaie est rendue, aucun choix proposé', (tester) async {
    final fake = await _open(tester, solde: 0, vente: 50000, withClient: false);
    await tester.enterText(find.byType(TextFormField), '60000');
    await tester.pumpAndSettle();
    expect(find.text('Ajouter au solde du client'), findsNothing);
    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    expect(fake.sentResteVersSolde, false);
  });

  testWidgets('excédent supprimé : le choix "ajouter au solde" est réinitialisé', (tester) async {
    final fake = await _open(tester, solde: 0, vente: 50000);
    await tester.enterText(find.byType(TextFormField), '60000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter au solde du client'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '50000'); // plus d'excédent
    await tester.pumpAndSettle();
    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    expect(fake.sentResteVersSolde, false);
  });

  testWidgets('aucun débordement d\'affichage : grand écran et mobile, avec avance', (tester) async {
    await _open(tester, solde: 30000, vente: 50000, size: const Size(1000, 800));
    expect(tester.takeException(), isNull);
    Get.back();
    await tester.pumpAndSettle();
    await _open(tester, solde: 30000, vente: 50000, size: const Size(400, 800));
    expect(tester.takeException(), isNull);
  });
}
