import 'dart:io';
import 'dart:convert';

/// Test simple pour vérifier la récupération des dettes clients
/// Ce script simule l'appel API que fait Flutter
void main() async {
  print('🔍 Test de récupération des dettes clients (simulation Flutter)');
  print('=' * 60);

  try {
    // Simulation de l'appel API que fait Flutter
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=100'));
    
    // Ajouter les headers comme le fait Flutter
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ Réponse reçue - Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final comptes = data['data'] as List;
      
      print('📊 ${comptes.length} comptes clients récupérés');
      
      // Analyser les dettes comme le fait le service Flutter
      double totalOutstandingDebt = 0.0;
      int customersWithDebt = 0;
      
      print('\n📋 Analyse des dettes:');
      for (final compteJson in comptes) {
        final soldeActuel = (compteJson['soldeActuel'] as num).toDouble();
        final clientName = compteJson['client']['nomComplet'] ?? 'Client inconnu';
        
        print('  - $clientName: ${soldeActuel.toStringAsFixed(2)} FCFA');
        
        // Un solde positif = dette du client (logique métier)
        if (soldeActuel > 0) {
          totalOutstandingDebt += soldeActuel;
          customersWithDebt++;
          print('    ⚠️  DETTE: ${soldeActuel.toStringAsFixed(2)} FCFA');
        } else if (soldeActuel < 0) {
          print('    ✅ CRÉDIT: ${(-soldeActuel).toStringAsFixed(2)} FCFA');
        } else {
          print('    ➖ SOLDE NUL');
        }
      }
      
      final averageDebtPerCustomer = customersWithDebt > 0 ? totalOutstandingDebt / customersWithDebt : 0.0;
      
      print('\n📈 RÉSUMÉ FINAL:');
      print('  - Total des dettes: ${totalOutstandingDebt.toStringAsFixed(0)} FCFA');
      print('  - Clients débiteurs: $customersWithDebt');
      print('  - Dette moyenne: ${averageDebtPerCustomer.toStringAsFixed(0)} FCFA');
      
      if (totalOutstandingDebt > 0) {
        print('\n✅ CORRECTION RÉUSSIE: Les dettes clients sont maintenant récupérées !');
        print('   Le problème était dans l\'URL de l\'API (port 3000 → 8080)');
      } else {
        print('\n⚠️  Aucune dette trouvée - vérifiez les données de test');
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
      print('Response: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}