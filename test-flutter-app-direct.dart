// Test direct de l'application Flutter pour les dettes clients
// Ce script doit être exécuté dans le contexte Flutter

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Imports nécessaires (à adapter selon la structure du projet)
// import 'logesco_v2/lib/core/bindings/initial_bindings.dart';
// import 'logesco_v2/lib/features/accounts/services/account_api_service.dart';
// import 'logesco_v2/lib/features/reports/services/activity_report_service.dart';

void main() {
  print('🧪 Test direct de l\'application Flutter');
  print('=' * 50);
  
  // Ce test devrait être intégré dans l'application Flutter
  // pour tester directement les services
  
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String testResult = 'Test en cours...';
  
  @override
  void initState() {
    super.initState();
    // Initialiser les bindings
    // InitialBindings().dependencies();
    
    // Lancer le test après un délai pour s'assurer que tout est initialisé
    Future.delayed(Duration(seconds: 1), () {
      testCustomerDebts();
    });
  }
  
  Future<void> testCustomerDebts() async {
    try {
      setState(() {
        testResult = '🔍 Test des dettes clients en cours...';
      });
      
      print('🔍 [Flutter Test] Début du test des dettes clients');
      
      // Test 1: Vérifier l'injection de AccountApiService
      try {
        // final accountService = Get.find<AccountApiService>();
        print('✅ [Flutter Test] AccountApiService trouvé');
        
        setState(() {
          testResult += '\n✅ AccountApiService trouvé';
        });
        
        // Test 2: Appeler getComptesClients
        // final comptes = await accountService.getComptesClients(limit: 100);
        // print('✅ [Flutter Test] ${comptes.length} comptes récupérés');
        
        // setState(() {
        //   testResult += '\n✅ ${comptes.length} comptes récupérés';
        // });
        
        // Test 3: Calculer les dettes
        // double totalDettes = 0.0;
        // int clientsDebiteurs = 0;
        
        // for (final compte in comptes) {
        //   if (compte.soldeActuel > 0) {
        //     totalDettes += compte.soldeActuel;
        //     clientsDebiteurs++;
        //   }
        // }
        
        // print('✅ [Flutter Test] Dettes calculées: ${totalDettes.toStringAsFixed(2)} FCFA');
        
        // setState(() {
        //   testResult += '\n✅ Dettes: ${totalDettes.toStringAsFixed(2)} FCFA';
        //   testResult += '\n✅ Clients débiteurs: $clientsDebiteurs';
        // });
        
      } catch (e) {
        print('❌ [Flutter Test] Erreur: $e');
        setState(() {
          testResult += '\n❌ Erreur: $e';
        });
      }
      
    } catch (e) {
      print('❌ [Flutter Test] Erreur générale: $e');
      setState(() {
        testResult = '❌ Erreur générale: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Dettes Clients'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test des dettes clients Flutter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  testResult,
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: testCustomerDebts,
              child: Text('Relancer le test'),
            ),
          ],
        ),
      ),
    );
  }
}