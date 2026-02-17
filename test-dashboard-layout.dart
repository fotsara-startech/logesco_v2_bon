// import 'package:flutter/material.dart';

// void main() {
//   print('🧪 Test de la mise en page du dashboard...');

//   // Simuler les dimensions d'écran typiques
//   final screenSizes = [
//     {'name': 'Mobile Portrait', 'width': 375.0, 'height': 812.0},
//     {'name': 'Mobile Landscape', 'width': 812.0, 'height': 375.0},
//     {'name': 'Tablet Portrait', 'width': 768.0, 'height': 1024.0},
//     {'name': 'Tablet Landscape', 'width': 1024.0, 'height': 768.0},
//     {'name': 'Desktop', 'width': 1440.0, 'height': 900.0},
//   ];

//   print('\n📱 Test des dimensions d\'écran:');

//   for (final size in screenSizes) {
//     final width = size['width'] as double;
//     final height = size['height'] as double;

//     print('\n${size['name']} (${width.toInt()}x${height.toInt()}):');

//     // Calculer l'espace disponible pour le contenu
//     final appBarHeight = 56.0;
//     final statusBarHeight = 24.0;
//     final padding = 40.0; // 20px de chaque côté
//     final availableHeight = height - appBarHeight - statusBarHeight - padding;
//     final availableWidth = width - padding;

//     print('  - Espace disponible: ${availableWidth.toInt()}x${availableHeight.toInt()}');

//     // Calculer l'espace nécessaire pour le dashboard
//     final headerHeight = 120.0;
//     final quickActionsHeight = 100.0 + 16.0; // hauteur + titre
//     final statsGridHeight = (availableWidth / 4 / 1.4) + 16.0; // ratio 1.4 + titre
//     final chartRowHeight = 300.0;
//     final salesStatsHeight = (availableWidth / 3 / 1.4) + 16.0;
//     final spacings = 24.0 * 5; // 5 espacements de 24px

//     final totalContentHeight = headerHeight + quickActionsHeight + statsGridHeight + chartRowHeight + salesStatsHeight + spacings;

//     print('  - Contenu nécessaire: ${totalContentHeight.toInt()}px');

//     if (totalContentHeight <= availableHeight) {
//       print('  ✅ Layout OK - Pas de débordement');
//     } else {
//       final overflow = totalContentHeight - availableHeight;
//       print('  ⚠️  Débordement potentiel: ${overflow.toInt()}px');

//       if (overflow <= 50) {
//         print('     → Débordement mineur, scroll acceptable');
//       } else {
//         print('     → Débordement important, ajustements nécessaires');
//       }
//     }
//   }

//   print('\n🎯 Recommandations de mise en page:');
//   print('  - Hauteur des actions rapides: 100px (réduite de 120px)');
//   print('  - Ratio des cartes stats: 1.4 (augmenté de 1.2)');
//   print('  - Espacements: 24px (réduits de 32px)');
//   print('  - Padding des cartes: 16px (réduit de 20px)');
//   print('  - Taille des icônes: 24px (réduite de 28px)');

//   print('\n✅ Optimisations appliquées pour éviter les débordements !');
// }
