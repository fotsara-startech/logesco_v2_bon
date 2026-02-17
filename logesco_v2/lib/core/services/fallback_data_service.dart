// import 'package:get/get.dart';
// import 'default_data_service.dart';
// import '../../features/users/models/user_model.dart';
// import '../../features/financial_movements/models/movement_category.dart';
// import '../../features/users/services/user_service.dart';

// /// Service de fallback qui fournit les données par défaut
// /// quand la base de données est vide ou inaccessible
// class FallbackDataService {
//   /// Obtient les rôles avec fallback sur les données par défaut
//   static Future<List<UserRole>> getRolesWithFallback() async {
//     try {
//       // Essayer de récupérer depuis l'API
//       if (Get.isRegistered<UserService>()) {
//         final userService = Get.find<UserService>();
//         final apiRoles = await userService.getAllRoles();

//         if (apiRoles.isNotEmpty) {
//           print('✅ Rôles récupérés depuis l\'API: ${apiRoles.length}');
//           return apiRoles;
//         }
//       }
//     } catch (e) {
//       print('⚠️ Erreur API pour les rôles, utilisation du fallback: $e');
//     }

//     // Fallback sur les données par défaut
//     final defaultRoles = DefaultDataService.getDefaultRoles();
//     print('🔄 Utilisation des rôles par défaut: ${defaultRoles.length}');
//     return defaultRoles;
//   }

//   /// Obtient les catégories avec fallback sur les données par défaut
//   static Future<List<MovementCategory>> getCategoriesWithFallback() async {
//     try {
//       // Essayer de récupérer depuis l'API
//       // Note: Vous devrez adapter selon votre service de catégories
//       // final apiCategories = await categoryService.getAllCategories();
//       // if (apiCategories.isNotEmpty) {
//       //   return apiCategories;
//       // }
//     } catch (e) {
//       print('⚠️ Erreur API pour les catégories, utilisation du fallback: $e');
//     }

//     // Fallback sur les données par défaut
//     final defaultCategories = DefaultDataService.getDefaultCategories();
//     print('🔄 Utilisation des catégories par défaut: ${defaultCategories.length}');
//     return defaultCategories;
//   }

//   /// Obtient un rôle spécifique avec fallback
//   static Future<UserRole?> getRoleWithFallback(String roleName) async {
//     try {
//       // Essayer depuis l'API d'abord
//       final roles = await getRolesWithFallback();
//       return roles.firstWhereOrNull((role) => role.nom == roleName);
//     } catch (e) {
//       print('⚠️ Erreur lors de la récupération du rôle $roleName: $e');
//       return DefaultDataService.getDefaultRoleByName(roleName);
//     }
//   }

//   /// Obtient une catégorie spécifique avec fallback
//   static Future<MovementCategory?> getCategoryWithFallback(String categoryName) async {
//     try {
//       // Essayer depuis l'API d'abord
//       final categories = await getCategoriesWithFallback();
//       return categories.firstWhereOrNull((cat) => cat.name == categoryName);
//     } catch (e) {
//       print('⚠️ Erreur lors de la récupération de la catégorie $categoryName: $e');
//       return DefaultDataService.getDefaultCategoryByName(categoryName);
//     }
//   }

//   /// Initialise les données par défaut si nécessaire
//   static Future<void> ensureDefaultDataExists() async {
//     print('🔄 Vérification des données par défaut...');

//     // Vérifier et initialiser les rôles
//     await _ensureDefaultRoles();

//     // Vérifier et initialiser les catégories
//     await _ensureDefaultCategories();

//     print('✅ Vérification des données par défaut terminée');
//   }

//   static Future<void> _ensureDefaultRoles() async {
//     try {
//       final roles = await getRolesWithFallback();
//       if (roles.length < 4) {
//         // Moins de 4 rôles = données manquantes
//         print('⚠️ Rôles manquants détectés, utilisation du fallback');
//         // Ici vous pourriez déclencher une synchronisation ou un avertissement
//       }
//     } catch (e) {
//       print('❌ Erreur lors de la vérification des rôles: $e');
//     }
//   }

//   static Future<void> _ensureDefaultCategories() async {
//     try {
//       final categories = await getCategoriesWithFallback();
//       if (categories.length < 6) {
//         // Moins de 6 catégories = données manquantes
//         print('⚠️ Catégories manquantes détectées, utilisation du fallback');
//         // Ici vous pourriez déclencher une synchronisation ou un avertissement
//       }
//     } catch (e) {
//       print('❌ Erreur lors de la vérification des catégories: $e');
//     }
//   }
// }
