import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/features/company_settings/views/company_settings_page.dart';
import 'lib/core/services/auth_service.dart';

/// Test simple pour les paramètres d'entreprise
void main() {
  runApp(const TestCompanySettingsApp());
}

class TestCompanySettingsApp extends StatelessWidget {
  const TestCompanySettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Test Paramètres Entreprise',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
      initialBinding: TestBinding(),
    );
  }
}

class TestBinding extends Bindings {
  @override
  void dependencies() {
    // Service d'authentification pour les tests
    Get.put<AuthService>(AuthService(), permanent: true);
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Paramètres Entreprise'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Test des Paramètres d\'Entreprise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cliquez sur le bouton pour tester le module',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const CompanySettingsPage());
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ouvrir Paramètres Entreprise'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fonctionnalités testables :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Formulaire de saisie avec validation'),
                    const Text('✅ Gestion des erreurs de validation'),
                    const Text('✅ Détection des modifications non sauvegardées'),
                    const Text('✅ Interface responsive'),
                    const Text('✅ Gestion des permissions'),
                    const SizedBox(height: 12),
                    const Text(
                      'Note : L\'API backend n\'est pas démarrée, '
                      'donc les appels réseau échoueront avec des messages d\'erreur appropriés.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
