import '../../features/inventory/models/stock_model.dart';

class TestDataService {
  static List<Stock> getTestStocks() {
    return [
      Stock(
        id: 1,
        produitId: 1,
        quantiteDisponible: 50,
        quantiteReservee: 5,
        derniereMaj: DateTime.now().subtract(const Duration(hours: 2)),
        stockFaible: false,
        produit: Product(
          id: 1,
          reference: 'REF001',
          nom: 'iPhone 15 Pro',
          seuilStockMinimum: 10,
          estActif: true,
        ),
      ),
      Stock(
        id: 2,
        produitId: 2,
        quantiteDisponible: 25,
        quantiteReservee: 0,
        derniereMaj: DateTime.now().subtract(const Duration(hours: 1)),
        stockFaible: false,
        produit: Product(
          id: 2,
          reference: 'REF002',
          nom: 'Samsung Galaxy S24',
          seuilStockMinimum: 15,
          estActif: true,
        ),
      ),
      Stock(
        id: 3,
        produitId: 3,
        quantiteDisponible: 100,
        quantiteReservee: 10,
        derniereMaj: DateTime.now().subtract(const Duration(minutes: 30)),
        stockFaible: false,
        produit: Product(
          id: 3,
          reference: 'REF003',
          nom: 'MacBook Air M3',
          seuilStockMinimum: 5,
          estActif: true,
        ),
      ),
      Stock(
        id: 4,
        produitId: 4,
        quantiteDisponible: 0,
        quantiteReservee: 0,
        derniereMaj: DateTime.now().subtract(const Duration(days: 1)),
        stockFaible: true,
        produit: Product(
          id: 4,
          reference: 'REF004',
          nom: 'iPad Pro 12.9"',
          seuilStockMinimum: 8,
          estActif: true,
        ),
      ),
      Stock(
        id: 5,
        produitId: 5,
        quantiteDisponible: 75,
        quantiteReservee: 2,
        derniereMaj: DateTime.now().subtract(const Duration(minutes: 15)),
        stockFaible: false,
        produit: Product(
          id: 5,
          reference: 'REF005',
          nom: 'AirPods Pro 2',
          seuilStockMinimum: 20,
          estActif: true,
        ),
      ),
      Stock(
        id: 6,
        produitId: 6,
        quantiteDisponible: 200,
        quantiteReservee: 15,
        derniereMaj: DateTime.now().subtract(const Duration(hours: 3)),
        stockFaible: false,
        produit: Product(
          id: 6,
          reference: 'REF006',
          nom: 'Câble USB-C',
          seuilStockMinimum: 50,
          estActif: true,
        ),
      ),
      Stock(
        id: 7,
        produitId: 7,
        quantiteDisponible: 3,
        quantiteReservee: 1,
        derniereMaj: DateTime.now().subtract(const Duration(hours: 4)),
        stockFaible: true,
        produit: Product(
          id: 7,
          reference: 'REF007',
          nom: 'Apple Watch Ultra 2',
          seuilStockMinimum: 5,
          estActif: true,
        ),
      ),
      Stock(
        id: 8,
        produitId: 8,
        quantiteDisponible: 150,
        quantiteReservee: 20,
        derniereMaj: DateTime.now().subtract(const Duration(minutes: 45)),
        stockFaible: false,
        produit: Product(
          id: 8,
          reference: 'REF008',
          nom: 'Chargeur MagSafe',
          seuilStockMinimum: 25,
          estActif: true,
        ),
      ),
      Stock(
        id: 9,
        produitId: 9,
        quantiteDisponible: 30,
        quantiteReservee: 5,
        derniereMaj: DateTime.now().subtract(const Duration(hours: 1)),
        stockFaible: false,
        produit: Product(
          id: 9,
          reference: 'REF009',
          nom: 'Sony WH-1000XM5',
          seuilStockMinimum: 12,
          estActif: true,
        ),
      ),
      Stock(
        id: 10,
        produitId: 10,
        quantiteDisponible: 85,
        quantiteReservee: 8,
        derniereMaj: DateTime.now().subtract(const Duration(minutes: 20)),
        stockFaible: false,
        produit: Product(
          id: 10,
          reference: 'REF010',
          nom: 'Dell XPS 13',
          seuilStockMinimum: 6,
          estActif: true,
        ),
      ),
    ];
  }

  static Stock? getTestStockByProductId(int productId) {
    final stocks = getTestStocks();
    try {
      return stocks.firstWhere((stock) => stock.produitId == productId);
    } catch (e) {
      return null;
    }
  }
}
