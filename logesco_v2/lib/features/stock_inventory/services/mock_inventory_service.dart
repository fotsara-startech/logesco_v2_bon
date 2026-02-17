import '../models/inventory_model.dart';

/// Service mock pour la gestion de l'inventaire de stock (données simulées)
class MockInventoryService {
  static final List<StockInventory> _inventories = [
    StockInventory(
      id: 1,
      nom: 'Inventaire Mensuel - Octobre 2024',
      description: 'Inventaire complet de fin de mois',
      type: InventoryType.TOTAL,
      status: InventoryStatus.EN_COURS,
      utilisateurId: 1,
      nomUtilisateur: 'Admin',
      dateCreation: DateTime.now().subtract(const Duration(days: 2)),
      dateDebut: DateTime.now().subtract(const Duration(days: 1)),
      stats: InventoryStats(
        totalItems: 150,
        countedItems: 75,
        itemsWithVariance: 5,
        totalSystemQuantity: 1250.0,
        totalCountedQuantity: 1245.0,
        totalVariance: -5.0,
        positiveVariance: 10.0,
        negativeVariance: -15.0,
      ),
    ),
    StockInventory(
      id: 2,
      nom: 'Inventaire Électronique',
      description: 'Inventaire partiel - Catégorie Électronique',
      type: InventoryType.PARTIEL,
      status: InventoryStatus.TERMINE,
      categorieId: 1,
      nomCategorie: 'Électronique',
      utilisateurId: 1,
      nomUtilisateur: 'Admin',
      dateCreation: DateTime.now().subtract(const Duration(days: 7)),
      dateDebut: DateTime.now().subtract(const Duration(days: 6)),
      dateFin: DateTime.now().subtract(const Duration(days: 5)),
      stats: InventoryStats(
        totalItems: 45,
        countedItems: 45,
        itemsWithVariance: 2,
        totalSystemQuantity: 320.0,
        totalCountedQuantity: 318.0,
        totalVariance: -2.0,
        positiveVariance: 0.0,
        negativeVariance: -2.0,
      ),
    ),
    StockInventory(
      id: 3,
      nom: 'Inventaire Vêtements',
      description: 'Inventaire partiel - Catégorie Vêtements',
      type: InventoryType.PARTIEL,
      status: InventoryStatus.BROUILLON,
      categorieId: 2,
      nomCategorie: 'Vêtements',
      utilisateurId: 2,
      nomUtilisateur: 'Manager',
      dateCreation: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  static final List<InventoryItem> _inventoryItems = [
    // Items pour l'inventaire 1
    InventoryItem(
      id: 1,
      inventaireId: 1,
      produitId: 1,
      nomProduit: 'iPhone 15 Pro',
      codeProduit: 'IPH15P',
      categorieProduit: 'Électronique',
      quantiteSysteme: 25.0,
      quantiteComptee: 23.0,
      ecart: -2.0,
      dateComptage: DateTime.now().subtract(const Duration(hours: 1)),
      utilisateurComptageId: 1,
      nomUtilisateurComptage: 'Admin',
    ),
    InventoryItem(
      id: 2,
      inventaireId: 1,
      produitId: 2,
      nomProduit: 'Samsung Galaxy S24',
      codeProduit: 'SGS24',
      categorieProduit: 'Électronique',
      quantiteSysteme: 15.0,
      quantiteComptee: 16.0,
      ecart: 1.0,
      dateComptage: DateTime.now().subtract(const Duration(minutes: 30)),
      utilisateurComptageId: 1,
      nomUtilisateurComptage: 'Admin',
    ),
    InventoryItem(
      id: 3,
      inventaireId: 1,
      produitId: 3,
      nomProduit: 'MacBook Air M3',
      codeProduit: 'MBA-M3',
      categorieProduit: 'Électronique',
      quantiteSysteme: 8.0,
    ),
    InventoryItem(
      id: 4,
      inventaireId: 1,
      produitId: 4,
      nomProduit: 'AirPods Pro',
      codeProduit: 'APP',
      categorieProduit: 'Électronique',
      quantiteSysteme: 30.0,
    ),
    // Items pour l'inventaire 2 (terminé)
    InventoryItem(
      id: 5,
      inventaireId: 2,
      produitId: 1,
      nomProduit: 'iPhone 15 Pro',
      codeProduit: 'IPH15P',
      categorieProduit: 'Électronique',
      quantiteSysteme: 25.0,
      quantiteComptee: 25.0,
      ecart: 0.0,
      dateComptage: DateTime.now().subtract(const Duration(days: 5)),
      utilisateurComptageId: 1,
      nomUtilisateurComptage: 'Admin',
    ),
  ];

  static int _nextInventoryId = 4;
  static int _nextItemId = 6;

  /// Récupérer tous les inventaires
  static Future<List<StockInventory>> getAllInventories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_inventories);
  }

  /// Récupérer un inventaire par ID
  static Future<StockInventory> getInventoryById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final inventory = _inventories.firstWhere(
      (i) => i.id == id,
      orElse: () => throw Exception('Inventaire non trouvé'),
    );
    return inventory;
  }

  /// Créer un nouvel inventaire
  static Future<StockInventory> createInventory(StockInventory inventory) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Vérifier si le nom existe déjà
    if (_inventories.any((i) => i.nom == inventory.nom)) {
      throw Exception('Un inventaire avec ce nom existe déjà');
    }

    final newInventory = inventory.copyWith(
      id: _nextInventoryId++,
      dateCreation: DateTime.now(),
    );

    _inventories.add(newInventory);

    // Générer automatiquement les items pour l'inventaire
    await _generateInventoryItems(newInventory);

    return newInventory;
  }

  /// Générer automatiquement les items d'inventaire
  static Future<void> _generateInventoryItems(StockInventory inventory) async {
    // Simulation de produits selon le type d'inventaire
    final mockProducts = [
      {'id': 1, 'nom': 'iPhone 15 Pro', 'code': 'IPH15P', 'categorie': 'Électronique', 'stock': 25.0},
      {'id': 2, 'nom': 'Samsung Galaxy S24', 'code': 'SGS24', 'categorie': 'Électronique', 'stock': 15.0},
      {'id': 3, 'nom': 'MacBook Air M3', 'code': 'MBA-M3', 'categorie': 'Électronique', 'stock': 8.0},
      {'id': 4, 'nom': 'AirPods Pro', 'code': 'APP', 'categorie': 'Électronique', 'stock': 30.0},
      {'id': 5, 'nom': 'T-shirt Homme', 'code': 'TSH-H', 'categorie': 'Vêtements', 'stock': 50.0},
      {'id': 6, 'nom': 'Jean Femme', 'code': 'JF', 'categorie': 'Vêtements', 'stock': 35.0},
      {'id': 7, 'nom': 'Chaussures Sport', 'code': 'CHS', 'categorie': 'Vêtements', 'stock': 20.0},
    ];

    List<Map<String, dynamic>> productsToInclude;

    if (inventory.type == InventoryType.TOTAL) {
      productsToInclude = mockProducts;
    } else {
      // Inventaire partiel - filtrer par catégorie
      final categoryName = inventory.nomCategorie ?? 'Électronique';
      productsToInclude = mockProducts.where((p) => p['categorie'] == categoryName).toList();
    }

    for (final product in productsToInclude) {
      final item = InventoryItem(
        id: _nextItemId++,
        inventaireId: inventory.id!,
        produitId: product['id'],
        nomProduit: product['nom'],
        codeProduit: product['code'],
        categorieProduit: product['categorie'],
        quantiteSysteme: product['stock'],
      );
      _inventoryItems.add(item);
    }
  }

  /// Démarrer un inventaire
  static Future<StockInventory> startInventory(int id, int userId, String userName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _inventories.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw Exception('Inventaire non trouvé');
    }

    final inventory = _inventories[index];

    if (inventory.status != InventoryStatus.BROUILLON) {
      throw Exception('Seuls les inventaires en brouillon peuvent être démarrés');
    }

    final updatedInventory = inventory.copyWith(
      status: InventoryStatus.EN_COURS,
      dateDebut: DateTime.now(),
    );

    _inventories[index] = updatedInventory;
    return updatedInventory;
  }

  /// Récupérer les items d'un inventaire
  static Future<List<InventoryItem>> getInventoryItems(int inventoryId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return _inventoryItems.where((item) => item.inventaireId == inventoryId).toList();
  }

  /// Mettre à jour un item d'inventaire (comptage)
  static Future<InventoryItem> updateInventoryItem(int itemId, double quantiteComptee, int userId, String userName, {String? commentaire}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _inventoryItems.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw Exception('Article d\'inventaire non trouvé');
    }

    final item = _inventoryItems[index];
    final ecart = quantiteComptee - item.quantiteSysteme;

    final updatedItem = item.copyWith(
      quantiteComptee: quantiteComptee,
      ecart: ecart,
      commentaire: commentaire,
      dateComptage: DateTime.now(),
      utilisateurComptageId: userId,
      nomUtilisateurComptage: userName,
    );

    _inventoryItems[index] = updatedItem;

    // Mettre à jour les statistiques de l'inventaire
    await _updateInventoryStats(item.inventaireId);

    return updatedItem;
  }

  /// Mettre à jour les statistiques d'un inventaire
  static Future<void> _updateInventoryStats(int inventoryId) async {
    final items = _inventoryItems.where((item) => item.inventaireId == inventoryId).toList();

    final totalItems = items.length;
    final countedItems = items.where((item) => item.isCounted).length;
    final itemsWithVariance = items.where((item) => item.hasVariance).length;

    final totalSystemQuantity = items.fold<double>(0.0, (sum, item) => sum + item.quantiteSysteme);
    final totalCountedQuantity = items.fold<double>(0.0, (sum, item) => sum + (item.quantiteComptee ?? 0.0));
    final totalVariance = totalCountedQuantity - totalSystemQuantity;

    final positiveVariance = items.where((item) => item.isPositiveVariance).fold<double>(0.0, (sum, item) => sum + item.calculatedEcart);
    final negativeVariance = items.where((item) => item.isNegativeVariance).fold<double>(0.0, (sum, item) => sum + item.calculatedEcart);

    final stats = InventoryStats(
      totalItems: totalItems,
      countedItems: countedItems,
      itemsWithVariance: itemsWithVariance,
      totalSystemQuantity: totalSystemQuantity,
      totalCountedQuantity: totalCountedQuantity,
      totalVariance: totalVariance,
      positiveVariance: positiveVariance,
      negativeVariance: negativeVariance,
    );

    // Mettre à jour l'inventaire avec les nouvelles stats
    final inventoryIndex = _inventories.indexWhere((inv) => inv.id == inventoryId);
    if (inventoryIndex != -1) {
      _inventories[inventoryIndex] = _inventories[inventoryIndex].copyWith(stats: stats);
    }
  }

  /// Finaliser un inventaire
  static Future<StockInventory> finalizeInventory(int id, int userId, String userName) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final index = _inventories.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw Exception('Inventaire non trouvé');
    }

    final inventory = _inventories[index];

    if (inventory.status != InventoryStatus.EN_COURS) {
      throw Exception('Seuls les inventaires en cours peuvent être finalisés');
    }

    // Vérifier que tous les items sont comptés
    final items = _inventoryItems.where((item) => item.inventaireId == id).toList();
    final unCountedItems = items.where((item) => !item.isCounted).toList();

    if (unCountedItems.isNotEmpty) {
      throw Exception('Tous les articles doivent être comptés avant la finalisation');
    }

    final updatedInventory = inventory.copyWith(
      status: InventoryStatus.TERMINE,
      dateFin: DateTime.now(),
    );

    _inventories[index] = updatedInventory;

    // Simulation de l'application des écarts au stock
    // Dans un vrai système, cela mettrait à jour les quantités en stock

    return updatedInventory;
  }

  /// Clôturer un inventaire (équilibrer le stock)
  static Future<StockInventory> closeInventory(int id, int userId, String userName) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _inventories.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw Exception('Inventaire non trouvé');
    }

    final inventory = _inventories[index];

    if (inventory.status != InventoryStatus.TERMINE) {
      throw Exception('Seuls les inventaires terminés peuvent être clôturés');
    }

    final updatedInventory = inventory.copyWith(
      status: InventoryStatus.CLOTURE,
    );

    _inventories[index] = updatedInventory;

    // Simulation de l'équilibrage du stock
    // Dans un vrai système, cela créerait les mouvements de stock nécessaires

    return updatedInventory;
  }

  /// Supprimer un inventaire
  static Future<void> deleteInventory(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _inventories.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw Exception('Inventaire non trouvé');
    }

    final inventory = _inventories[index];

    if (inventory.status == InventoryStatus.EN_COURS) {
      throw Exception('Impossible de supprimer un inventaire en cours');
    }

    _inventories.removeAt(index);

    // Supprimer aussi les items associés
    _inventoryItems.removeWhere((item) => item.inventaireId == id);
  }

  /// Obtenir des statistiques sur les inventaires
  static Future<Map<String, dynamic>> getInventoryStats() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final totalInventories = _inventories.length;
    final draftInventories = _inventories.where((i) => i.status == InventoryStatus.BROUILLON).length;
    final inProgressInventories = _inventories.where((i) => i.status == InventoryStatus.EN_COURS).length;
    final completedInventories = _inventories.where((i) => i.status == InventoryStatus.TERMINE).length;
    final closedInventories = _inventories.where((i) => i.status == InventoryStatus.CLOTURE).length;

    return {
      'total': totalInventories,
      'draft': draftInventories,
      'inProgress': inProgressInventories,
      'completed': completedInventories,
      'closed': closedInventories,
      'lastCreated': _inventories.isNotEmpty ? _inventories.map((i) => i.dateCreation).reduce((a, b) => a.isAfter(b) ? a : b) : null,
    };
  }

  /// Rechercher des inventaires
  static Future<List<StockInventory>> searchInventories(String query, {InventoryStatus? status, InventoryType? type}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = _inventories.where((inventory) {
      final matchesQuery = query.isEmpty || inventory.nom.toLowerCase().contains(query.toLowerCase()) || inventory.description.toLowerCase().contains(query.toLowerCase());

      final matchesStatus = status == null || inventory.status == status;
      final matchesType = type == null || inventory.type == type;

      return matchesQuery && matchesStatus && matchesType;
    }).toList();

    // Trier par date de création (plus récent en premier)
    filtered.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));

    return filtered;
  }

  /// Récupérer les catégories disponibles
  static Future<List<Map<String, dynamic>>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return [
      {'id': 1, 'nom': 'Électronique'},
      {'id': 2, 'nom': 'Vêtements'},
      {'id': 3, 'nom': 'Alimentation'},
      {'id': 4, 'nom': 'Maison & Jardin'},
      {'id': 5, 'nom': 'Sport & Loisirs'},
      {'id': 6, 'nom': 'Beauté & Santé'},
      {'id': 7, 'nom': 'Automobile'},
      {'id': 8, 'nom': 'Livres & Médias'},
      {'id': 9, 'nom': 'Jouets & Enfants'},
    ];
  }

  /// Imprimer une feuille de comptage
  static Future<String> printCountingSheet(int inventoryId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final inventory = _inventories.firstWhere(
      (i) => i.id == inventoryId,
      orElse: () => throw Exception('Inventaire non trouvé'),
    );

    // Simulation de la génération d'une URL d'impression
    final printUrl = 'https://logesco.com/print/inventory/${inventory.id}/counting-sheet.pdf';

    return printUrl;
  }

  /// Méthodes de compatibilité avec les signatures simplifiées

  /// Démarrer un inventaire (version simplifiée)
  static Future<StockInventory> startInventorySimple(int id) async {
    return startInventory(id, 1, 'Utilisateur');
  }

  /// Terminer un inventaire (version simplifiée)
  static Future<StockInventory> finishInventory(int inventoryId) async {
    return finalizeInventory(inventoryId, 1, 'Utilisateur');
  }

  /// Clôturer un inventaire (version simplifiée)
  static Future<StockInventory> closeInventorySimple(int inventoryId) async {
    return closeInventory(inventoryId, 1, 'Utilisateur');
  }

  /// Mettre à jour un article d'inventaire (version simplifiée)
  static Future<InventoryItem> updateInventoryItemSimple(int itemId, double quantiteComptee, String? commentaire) async {
    return updateInventoryItem(itemId, quantiteComptee, 1, 'Utilisateur', commentaire: commentaire);
  }

  /// Mettre à jour un inventaire
  static Future<StockInventory> updateInventory(int id, StockInventory inventory) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final index = _inventories.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw Exception('Inventaire non trouvé');
    }

    // Vérifier si le nom existe déjà (sauf pour l'inventaire actuel)
    if (_inventories.any((i) => i.nom == inventory.nom && i.id != id)) {
      throw Exception('Un inventaire avec ce nom existe déjà');
    }

    final updatedInventory = inventory.copyWith(
      id: id,
      dateCreation: _inventories[index].dateCreation,
    );

    _inventories[index] = updatedInventory;
    return updatedInventory;
  }
}
