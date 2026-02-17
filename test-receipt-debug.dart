/**
 * Test de debug pour les remises sur le reçu
 */

void main() {
  print('🔍 Debug des remises sur le reçu');
  print('================================\n');

  testReceiptCalculation();
  analyzeYourCase();
  provideFix();
}

/// Test du calcul des remises
void testReceiptCalculation() {
  print('📊 Test du calcul des remises:');
  print('------------------------------');
  
  // Simulation de vos données REAKTOR 16
  final saleDetail = {
    'produitId': 32,
    'quantite': 1,
    'prixUnitaire': 1006.0,    // Prix final sur le reçu
    'prixAffiche': 1306.0,     // Prix original (devrait être là)
    'remiseAppliquee': 100.0,  // Remise unitaire (devrait être là)
    'montantLigne': 1006.0,    // Total de la ligne
  };
  
  final sale = {
    'sousTotal': 1006.0,       // Sous-total sur le reçu
    'montantRemise': 0.0,      // Remise globale (probablement 0)
    'montantTotal': 1006.0,    // Total final
  };
  
  print('📦 Données de vente simulées:');
  print('  SaleDetail:');
  print('    prixUnitaire: ${saleDetail['prixUnitaire']} FCFA');
  print('    prixAffiche: ${saleDetail['prixAffiche']} FCFA');
  print('    remiseAppliquee: ${saleDetail['remiseAppliquee']} FCFA');
  print('    montantLigne: ${saleDetail['montantLigne']} FCFA');
  print('');
  print('  Sale:');
  print('    sousTotal: ${sale['sousTotal']} FCFA');
  print('    montantRemise: ${sale['montantRemise']} FCFA');
  print('    montantTotal: ${sale['montantTotal']} FCFA');
  print('');
  
  // Calcul comme dans ReceiptItem
  final discountAmount = saleDetail['remiseAppliquee'] as double;
  final quantity = saleDetail['quantite'] as int;
  final totalDiscountAmount = discountAmount * quantity;
  
  print('📈 Calcul des remises:');
  print('  discountAmount: $discountAmount FCFA');
  print('  quantity: $quantity');
  print('  totalDiscountAmount: $totalDiscountAmount FCFA');
  print('');
  
  // Calcul comme dans Receipt.fromSale
  final totalDiscountFromItems = totalDiscountAmount;
  final saleMontantRemise = sale['montantRemise'] as double;
  final actualDiscountAmount = totalDiscountFromItems > 0 ? totalDiscountFromItems : saleMontantRemise;
  
  print('🧮 Calcul final:');
  print('  totalDiscountFromItems: $totalDiscountFromItems FCFA');
  print('  sale.montantRemise: $saleMontantRemise FCFA');
  print('  actualDiscountAmount: $actualDiscountAmount FCFA');
  print('');
  
  if (actualDiscountAmount > 0) {
    print('✅ La remise devrait s\'afficher: $actualDiscountAmount FCFA');
  } else {
    print('❌ Aucune remise ne s\'affichera (actualDiscountAmount = 0)');
  }
}

/// Analyse de votre cas spécifique
void analyzeYourCase() {
  print('🔍 Analyse de votre cas REAKTOR 16:');
  print('-----------------------------------');
  
  print('Sur votre reçu, je vois:');
  print('  - Sous-total: 1006 FCFA');
  print('  - TOTAL: 1006 FCFA');
  print('  - Pas de ligne "Remise"');
  print('');
  
  print('❌ Problèmes possibles:');
  print('  1. detail.remiseAppliquee = 0 (pas de remise enregistrée)');
  print('  2. detail.prixAffiche = detail.prixUnitaire (pas de différence)');
  print('  3. sale.montantRemise = 0 (pas de remise globale)');
  print('  4. Le calcul ne fonctionne pas correctement');
  print('');
  
  print('🔍 Ce qui devrait se passer:');
  print('  - Prix original: 1306 FCFA');
  print('  - Remise: 100 FCFA');
  print('  - Prix final: 1206 FCFA');
  print('  - Sous-total: 1306 FCFA');
  print('  - Remise: -100 FCFA');
  print('  - TOTAL: 1206 FCFA');
  print('');
  
  print('🤔 Mais sur votre reçu:');
  print('  - Sous-total: 1006 FCFA (déjà avec remise appliquée)');
  print('  - TOTAL: 1006 FCFA');
  print('  - Pas de remise visible');
}

/// Solution proposée
void provideFix() {
  print('🛠️ Solutions à essayer:');
  print('=======================');
  print('');
  
  print('1. 📊 Vérifier les données de vente:');
  print('   - Regarder les logs de debug ajoutés');
  print('   - Vérifier que remiseAppliquee > 0');
  print('   - Vérifier que prixAffiche > prixUnitaire');
  print('');
  
  print('2. 🔧 Correction temporaire:');
  print('   - Forcer l\'affichage de la remise si sous-total != total');
  print('   - Calculer la remise comme: sous-total - total');
  print('');
  
  print('3. 🎯 Solution définitive:');
  print('   - Corriger la logique de calcul des remises dans SalesController');
  print('   - S\'assurer que remiseAppliquee est correctement enregistré');
  print('   - Vérifier que prixAffiche contient le prix original');
  print('');
  
  print('4. 🚨 Test immédiat:');
  print('   - Créer une nouvelle vente avec REAKTOR 16');
  print('   - Appliquer une remise de 100 FCFA');
  print('   - Regarder les logs de debug dans la console');
  print('   - Vérifier les valeurs affichées');
}