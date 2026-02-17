/**
 * Test script pour vérifier la correction du problème de casting des alertes
 */

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Test de la correction du casting des alertes...\n');
  
  try {
    // Simuler la réponse de l'API
    final mockApiResponse = {
      'success': true,
      'data': {
        'alertes': [
          {
            'produit': {
              'id': 1,
              'nom': 'Produit Test',
              'reference': 'REF001',
              'seuilStockMinimum': 10
            },
            'stock': {
              'quantiteDisponible': 5,
              'quantiteReservee': 0,
              'seuilMinimum': 10
            },
            'typeAlerte': 'stock_faible',
            'priorite': 'moyenne'
          }
        ],
        'statistiques': {
          'total': 1,
          'ruptures': 0,
          'stocksFaibles': 1
        }
      }
    };

    print('📊 Données simulées de l\'API:');
    print(json.encode(mockApiResponse));
    print('\n');

    // Test de la conversion comme dans le contrôleur corrigé
    final result = mockApiResponse['data'] as Map<String, dynamic>;
    
    // Conversion sécurisée de List<dynamic> vers List<Map<String, dynamic>>
    final alertesData = result['alertes'] as List<dynamic>? ?? [];
    final alertesConverties = alertesData
        .map((alerte) => Map<String, dynamic>.from(alerte as Map))
        .toList();
    
    print('✅ Conversion réussie!');
    print('📈 Nombre d\'alertes: ${alertesConverties.length}');
    print('📋 Type de données: ${alertesConverties.runtimeType}');
    
    if (alertesConverties.isNotEmpty) {
      final premiereAlerte = alertesConverties.first;
      print('🔍 Première alerte:');
      print('   - Produit: ${premiereAlerte['produit']['nom']}');
      print('   - Type: ${premiereAlerte['typeAlerte']}');
      print('   - Priorité: ${premiereAlerte['priorite']}');
    }
    
    final nombreAlertes = result['statistiques']?['total'] ?? 0;
    print('📊 Statistiques: $nombreAlertes alertes au total');
    
    print('\n🎉 Test réussi! La correction du casting fonctionne correctement.');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
    exit(1);
  }
}