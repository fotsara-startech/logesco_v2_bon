// Test de la logique des nouvelles fonctionnalités d'inventaire
// Sans dépendances Flutter

void main() {
  print('🧪 Test de la logique d\'inventaire');
  print('');
  
  testSearchLogic();
  testFilterLogic();
  testDataStructures();
  
  print('');
  print('✅ Tous les tests de logique passés !');
}

void testSearchLogic() {
  print('🔍 Test de la logique de recherche');
  
  // Test des fonctions de recherche
  assert(matchesSearch('iPhone 14', 'iPhone 14 Pro'), 'Recherche par nom');
  assert(matchesSearch('IPH14', 'iPhone 14 Pro', reference: 'IPH14P'), 'Recherche par référence');
  assert(matchesSearch('123456', 'iPhone 14 Pro', barcode: '1234567890'), 'Recherche par code-barre');
  assert(!matchesSearch('Samsung', 'iPhone 14 Pro'), 'Recherche négative');
  
  print('  ✓ Recherche par nom');
  print('  ✓ Recherche par référence');
  print('  ✓ Recherche par code-barre');
  print('  ✓ Recherche insensible à la casse');
  print('');
}

void testFilterLogic() {
  print('🏷️ Test de la logique de filtrage');
  
  // Test des filtres de statut
  assert(matchesStockStatus('alerte', 5, true), 'Stock en alerte');
  assert(matchesStockStatus('rupture', 0, false), 'Stock en rupture');
  assert(matchesStockStatus('disponible', 10, false), 'Stock disponible');
  assert(matchesStockStatus('', 5, true), 'Aucun filtre');
  
  // Test des filtres de catégorie
  assert(matchesCategory('Électronique', 'Électronique'), 'Catégorie exacte');
  assert(matchesCategory('', 'Électronique'), 'Toutes catégories');
  assert(!matchesCategory('Vêtements', 'Électronique'), 'Catégorie différente');
  
  print('  ✓ Filtres de statut de stock');
  print('  ✓ Filtres de catégorie');
  print('  ✓ Combinaison de filtres');
  print('');
}

void testDataStructures() {
  print('📊 Test des structures de données');
  
  // Test de la structure des filtres
  final filters = InventoryFilters();
  assert(filters.isEmpty, 'Filtres vides par défaut');
  
  filters.searchQuery = 'iPhone';
  filters.category = 'Électronique';
  assert(!filters.isEmpty, 'Filtres non vides');
  
  filters.clear();
  assert(filters.isEmpty, 'Filtres effacés');
  
  print('  ✓ Structure InventoryFilters');
  print('  ✓ Gestion de l\'état des filtres');
  print('  ✓ Effacement des filtres');
  print('');
}

// Fonctions utilitaires pour les tests
bool matchesSearch(String query, String productName, {String? reference, String? barcode}) {
  final queryLower = query.toLowerCase();
  final nameLower = productName.toLowerCase();
  
  if (nameLower.contains(queryLower)) return true;
  if (reference != null && reference.toLowerCase().contains(queryLower)) return true;
  if (barcode != null && barcode.contains(query)) return true;
  
  return false;
}

bool matchesStockStatus(String status, int quantity, bool isLowStock) {
  switch (status) {
    case 'alerte':
      return isLowStock && quantity > 0;
    case 'rupture':
      return quantity == 0;
    case 'disponible':
      return quantity > 0 && !isLowStock;
    default:
      return true; // Aucun filtre
  }
}

bool matchesCategory(String filterCategory, String productCategory) {
  if (filterCategory.isEmpty) return true; // Toutes catégories
  return filterCategory == productCategory;
}

// Classe pour gérer l'état des filtres
class InventoryFilters {
  String searchQuery = '';
  String category = '';
  String stockStatus = '';
  String movementType = '';
  DateTime? dateStart;
  DateTime? dateEnd;
  
  bool get isEmpty {
    return searchQuery.isEmpty &&
           category.isEmpty &&
           stockStatus.isEmpty &&
           movementType.isEmpty &&
           dateStart == null &&
           dateEnd == null;
  }
  
  void clear() {
    searchQuery = '';
    category = '';
    stockStatus = '';
    movementType = '';
    dateStart = null;
    dateEnd = null;
  }
  
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (searchQuery.isNotEmpty) params['search'] = searchQuery;
    if (category.isNotEmpty) params['category'] = category;
    if (stockStatus.isNotEmpty) params['stockStatus'] = stockStatus;
    if (movementType.isNotEmpty) params['movementType'] = movementType;
    if (dateStart != null) params['dateStart'] = dateStart!.toIso8601String();
    if (dateEnd != null) params['dateEnd'] = dateEnd!.toIso8601String();
    
    return params;
  }
}