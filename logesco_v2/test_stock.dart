import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/features/sales/controllers/sales_controller.dart';
import 'lib/core/services/auth_service.dart';
import 'lib/core/bindings/initial_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les bindings
  InitialBindings().dependencies();

  // Créer le contrôleur des ventes
  final salesController = Get.put(SalesController());

  print('Test de chargement des stocks...');

  // Charger les stocks
  await salesController.loadStocks();

  // Afficher les informations de débogage
  salesController.debugPrintStocks();

  // Tester quelques produits
  for (int i = 1; i <= 5; i++) {
    final stock = salesController.getProductStock(i);
    final available = salesController.getAvailableQuantity(i);
    final raw = salesController.getRawStockQuantity(i);

    print('Produit $i:');
    print('  - Stock objet: $stock');
    print('  - Quantité brute: $raw');
    print('  - Quantité disponible: $available');
    print('');
  }
}
