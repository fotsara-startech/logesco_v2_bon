import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/features/sales/controllers/sales_controller.dart';
import 'lib/core/bindings/initial_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les bindings
  InitialBindings().dependencies();

  // Créer le contrôleur des ventes
  final salesController = Get.put(SalesController());

  print('=== TEST D\'AFFICHAGE DES STOCKS ===');

  // Attendre l'initialisation
  await Future.delayed(const Duration(seconds: 2));

  // Afficher les informations de débogage
  salesController.debugPrintStocks();

  // Tester les méthodes de calcul pour quelques produits
  print('\n=== TEST DES CALCULS ===');
  for (int i = 1; i <= 10; i++) {
    final stock = salesController.getProductStock(i);
    final rawQuantity = salesController.getRawStockQuantity(i);
    final availableQuantity = salesController.getAvailableQuantity(i);

    if (stock != null) {
      print('Produit $i:');
      print('  - Stock brut: $rawQuantity');
      print('  - Quantité disponible: $availableQuantity');
      print('  - Quantité réservée: ${stock.quantiteReservee}');
      print('');
    }
  }

  // Tester l'ajout au panier
  print('=== TEST AJOUT AU PANIER ===');

  // Simuler l'ajout d'un produit au panier
  // Note: Nous aurions besoin d'un objet Product réel pour cela
  print('Test d\'ajout au panier nécessite des objets Product complets');

  print('\n✅ Test terminé');
}
