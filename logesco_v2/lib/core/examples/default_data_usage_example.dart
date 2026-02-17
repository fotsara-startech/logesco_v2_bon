// import 'package:flutter/material.dart';
// import '../services/fallback_data_service.dart';
// import '../widgets/fallback_data_info_widget.dart';
// import '../../features/users/models/role_model.dart' as role_model;
// import '../../features/financial_movements/models/movement_category.dart';

// /// Exemple d'utilisation du système de données par défaut
// class DefaultDataUsageExample extends StatefulWidget {
//   const DefaultDataUsageExample({super.key});

//   @override
//   State<DefaultDataUsageExample> createState() => _DefaultDataUsageExampleState();
// }

// class _DefaultDataUsageExampleState extends State<DefaultDataUsageExample> {
//   List<role_model.UserRole> roles = [];
//   List<MovementCategory> categories = [];
//   bool isLoading = true;
//   bool usingFallback = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Charger les rôles avec fallback automatique
//       roles = await FallbackDataService.getRolesWithFallback();

//       // Charger les catégories avec fallback automatique
//       categories = await FallbackDataService.getCategoriesWithFallback();

//       // Vérifier si on utilise les données par défaut
//       usingFallback = roles.length <= 4 || categories.length <= 6;
//     } catch (e) {
//       print('Erreur lors du chargement: $e');
//       usingFallback = true;
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Exemple - Données par défaut'),
//         actions: [
//           IconButton(
//             onPressed: _loadData,
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Actualiser',
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Afficher l'info de fallback si nécessaire
//                   if (usingFallback) ...[
//                     FallbackDataInfoWidget(
//                       dataType: 'rôles et catégories',
//                       onRefresh: _loadData,
//                     ),
//                     const SizedBox(height: 16),
//                   ],

//                   // Section des rôles
//                   _buildRolesSection(),

//                   const SizedBox(height: 24),

//                   // Section des catégories
//                   _buildCategoriesSection(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildRolesSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.people, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Rôles disponibles (${roles.length})',
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ...roles.map((role) => ListTile(
//                   leading: Icon(
//                     role.isAdmin ? Icons.admin_panel_settings : Icons.person,
//                     color: role.isAdmin ? Colors.amber : Colors.blue,
//                   ),
//                   title: Text(role.displayName),
//                   subtitle: Text('ID: ${role.id} • ${role.nom}'),
//                   trailing: role.isAdmin
//                       ? const Chip(
//                           label: Text('Admin'),
//                           backgroundColor: Colors.amber,
//                         )
//                       : null,
//                 )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoriesSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.category, color: Colors.green),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Catégories de dépenses (${categories.length})',
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ...categories.map((category) => ListTile(
//                   leading: Container(
//                     width: 24,
//                     height: 24,
//                     decoration: BoxDecoration(
//                       color: _parseColor(category.color),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   title: Text(category.displayName),
//                   subtitle: Text('${category.name} • ${category.icon}'),
//                   trailing: category.isDefault
//                       ? const Chip(
//                           label: Text('Défaut'),
//                           backgroundColor: Colors.green,
//                         )
//                       : null,
//                 )),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _parseColor(String colorString) {
//     try {
//       return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
//     } catch (e) {
//       return Colors.grey;
//     }
//   }
// }
