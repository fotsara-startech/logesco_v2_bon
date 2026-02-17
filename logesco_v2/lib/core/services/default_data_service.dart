// import '../../../features/users/models/user_model.dart';
// import '../../../features/financial_movements/models/movement_category.dart';

// /// Service pour fournir les données par défaut de l'application
// /// Ces données sont toujours disponibles même si la BD est reset
// class DefaultDataService {
//   /// Rôles par défaut du système
//   static List<UserRole> getDefaultRoles() {
//     return [
//       // Rôle Administrateur
//       UserRole(
//         id: 1,
//         nom: 'admin',
//         displayName: 'Administrateur',
//         isAdmin: true,
//         privileges: UserPrivileges(
//           canManageUsers: true,
//           canManageProducts: true,
//           canManageSales: true,
//           canManageInventory: true,
//           canManageReports: true,
//           canManageCompanySettings: true,
//           canManageCashRegisters: true,
//           canViewReports: true,
//           canMakeSales: true,
//           canManageStock: true,
//         ),
//       ),

//       // Rôle Gérant
//       UserRole(
//         id: 2,
//         nom: 'manager',
//         displayName: 'Gérant',
//         isAdmin: false,
//         privileges: UserPrivileges(
//           canManageUsers: false,
//           canManageProducts: true,
//           canManageSales: true,
//           canManageInventory: true,
//           canManageReports: true,
//           canManageCompanySettings: false,
//           canManageCashRegisters: true,
//           canViewReports: true,
//           canMakeSales: true,
//           canManageStock: true,
//         ),
//       ),

//       // Rôle Vendeur
//       UserRole(
//         id: 3,
//         nom: 'seller',
//         displayName: 'Vendeur',
//         isAdmin: false,
//         privileges: UserPrivileges(
//           canManageUsers: false,
//           canManageProducts: false,
//           canManageSales: true,
//           canManageInventory: false,
//           canManageReports: false,
//           canManageCompanySettings: false,
//           canManageCashRegisters: false,
//           canViewReports: true,
//           canMakeSales: true,
//           canManageStock: false,
//         ),
//       ),

//       // Rôle Caissier
//       UserRole(
//         id: 4,
//         nom: 'cashier',
//         displayName: 'Caissier',
//         isAdmin: false,
//         privileges: UserPrivileges(
//           canManageUsers: false,
//           canManageProducts: false,
//           canManageSales: true,
//           canManageInventory: false,
//           canManageReports: false,
//           canManageCompanySettings: false,
//           canManageCashRegisters: false,
//           canViewReports: false,
//           canMakeSales: true,
//           canManageStock: false,
//         ),
//       ),
//     ];
//   }

//   /// Catégories de dépenses par défaut
//   static List<MovementCategory> getDefaultCategories() {
//     return [
//       MovementCategory(
//         id: 1,
//         name: 'achat_marchandises',
//         displayName: 'Achat de marchandises',
//         color: '#3B82F6', // Bleu
//         icon: 'shopping_cart',
//         isDefault: true,
//         isActive: true,
//       ),
//       MovementCategory(
//         id: 2,
//         name: 'frais_generaux',
//         displayName: 'Frais généraux',
//         color: '#6B7280', // Gris
//         icon: 'receipt_long',
//         isDefault: true,
//         isActive: true,
//       ),
//       MovementCategory(
//         id: 3,
//         name: 'salaires_personnel',
//         displayName: 'Salaires du personnel',
//         color: '#10B981', // Vert
//         icon: 'people',
//         isDefault: true,
//         isActive: true,
//       ),
//       MovementCategory(
//         id: 4,
//         name: 'maintenance_reparation',
//         displayName: 'Maintenance et réparation',
//         color: '#F59E0B', // Orange
//         icon: 'build',
//         isDefault: true,
//         isActive: true,
//       ),
//       MovementCategory(
//         id: 5,
//         name: 'transport_livraison',
//         displayName: 'Transport et livraison',
//         color: '#8B5CF6', // Violet
//         icon: 'local_shipping',
//         isDefault: true,
//         isActive: true,
//       ),
//       MovementCategory(
//         id: 6,
//         name: 'autres_depenses',
//         displayName: 'Autres dépenses',
//         color: '#EF4444', // Rouge
//         icon: 'more_horiz',
//         isDefault: true,
//         isActive: true,
//       ),
//     ];
//   }

//   /// Trouve un rôle par défaut par son nom
//   static UserRole? getDefaultRoleByName(String roleName) {
//     try {
//       return getDefaultRoles().firstWhere((role) => role.nom == roleName);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Trouve une catégorie par défaut par son nom
//   static MovementCategory? getDefaultCategoryByName(String categoryName) {
//     try {
//       return getDefaultCategories().firstWhere((cat) => cat.name == categoryName);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Vérifie si un rôle est un rôle par défaut
//   static bool isDefaultRole(String roleName) {
//     return getDefaultRoles().any((role) => role.nom == roleName);
//   }

//   /// Vérifie si une catégorie est une catégorie par défaut
//   static bool isDefaultCategory(String categoryName) {
//     return getDefaultCategories().any((cat) => cat.name == categoryName);
//   }
// }
