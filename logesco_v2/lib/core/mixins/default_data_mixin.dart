// import '../services/fallback_data_service.dart';
// import '../../features/users/models/user_model.dart';
// import '../../features/financial_movements/models/movement_category.dart';

// /// Mixin pour faciliter l'accès aux données par défaut dans les contrôleurs
// mixin DefaultDataMixin {
//   /// Obtient les rôles avec fallback automatique
//   Future<List<UserRole>> getRoles() async {
//     return await FallbackDataService.getRolesWithFallback();
//   }

//   /// Obtient les catégories avec fallback automatique
//   Future<List<MovementCategory>> getCategories() async {
//     return await FallbackDataService.getCategoriesWithFallback();
//   }

//   /// Obtient un rôle spécifique
//   Future<UserRole?> getRole(String roleName) async {
//     return await FallbackDataService.getRoleWithFallback(roleName);
//   }

//   /// Obtient une catégorie spécifique
//   Future<MovementCategory?> getCategory(String categoryName) async {
//     return await FallbackDataService.getCategoryWithFallback(categoryName);
//   }

//   /// Obtient le rôle administrateur par défaut
//   Future<UserRole> getAdminRole() async {
//     final role = await getRole('admin');
//     if (role == null) {
//       throw Exception('Rôle administrateur non trouvé');
//     }
//     return role;
//   }

//   /// Obtient le rôle utilisateur par défaut
//   Future<UserRole> getDefaultUserRole() async {
//     final role = await getRole('seller');
//     if (role == null) {
//       throw Exception('Rôle utilisateur par défaut non trouvé');
//     }
//     return role;
//   }

//   /// Obtient la catégorie "Autres dépenses" par défaut
//   Future<MovementCategory> getDefaultExpenseCategory() async {
//     final category = await getCategory('autres_depenses');
//     if (category == null) {
//       throw Exception('Catégorie par défaut non trouvée');
//     }
//     return category;
//   }
// }
