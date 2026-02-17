import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Test des nouvelles fonctionnalités de recherche et filtrage pour l'inventaire

void main() {
  runApp(const InventorySearchTestApp());
}

class InventorySearchTestApp extends StatelessWidget {
  const InventorySearchTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Test Recherche Inventaire',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InventorySearchTestPage(),
    );
  }
}

class InventorySearchTestPage extends StatelessWidget {
  const InventorySearchTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Recherche & Filtres Inventaire'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelles fonctionnalités ajoutées à l\'inventaire:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            FeatureCard(
              title: '🔍 Barre de recherche',
              description: 'Recherche par nom de produit, référence ou code-barre',
              features: [
                'Recherche en temps réel avec debounce',
                'Recherche par référence exacte',
                'Recherche par code-barre',
                'Effacement rapide des critères',
              ],
            ),
            
            SizedBox(height: 16),
            
            FeatureCard(
              title: '🏷️ Filtres par catégorie',
              description: 'Filtrage des produits par catégorie',
              features: [
                'Sélection de catégorie via dialog',
                'Affichage des filtres actifs',
                'Effacement rapide des filtres',
              ],
            ),
            
            SizedBox(height: 16),
            
            FeatureCard(
              title: '⚠️ Filtres par statut de stock',
              description: 'Filtrage par état du stock',
              features: [
                'Stocks en alerte',
                'Stocks en rupture',
                'Stocks disponibles',
                'Tous les stocks',
              ],
            ),
            
            SizedBox(height: 16),
            
            FeatureCard(
              title: '📊 Filtres avancés pour mouvements',
              description: 'Filtrage des mouvements de stock',
              features: [
                'Filtrage par type (achat, vente, ajustement, retour)',
                'Filtrage par période avec sélecteur de dates',
                'Périodes rapides (aujourd\'hui, 7 jours, 30 jours, ce mois)',
                'Combinaison de plusieurs filtres',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> features;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}