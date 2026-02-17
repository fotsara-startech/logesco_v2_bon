# 🔧 CORRECTIONS À APPLIQUER - TOUS LES MODULES

## 📋 MODULES À CORRIGER

### 1. CLIENTS ✅ À FAIRE
- `customer_list_view.dart` - FloatingActionButton CREATE
- `customer_detail_view.dart` - FloatingActionButton UPDATE
- Carte client - PopupMenu UPDATE/DELETE

### 2. CATÉGORIES ✅ À FAIRE
- `categories_page.dart` - Vérifier si déjà fait
- PopupMenu UPDATE/DELETE

### 3. MOUVEMENTS FINANCIERS ✅ À FAIRE
- `financial_movements_page.dart` - FloatingActionButton CREATE
- Carte mouvement - PopupMenu UPDATE/DELETE

### 4. COMPTABILITÉ ✅ À FAIRE
- Widget dashboard - Vérifier permission READ

### 5. VENTES ⚠️ PRIORITAIRE
- `sales_list_view.dart` - FloatingActionButton CREATE
- Carte vente - PopupMenu UPDATE/DELETE/REFUND

### 6. FOURNISSEURS
- `suppliers_list_view.dart` - FloatingActionButton CREATE
- Carte fournisseur - PopupMenu UPDATE/DELETE

### 7. INVENTAIRE
- `inventory_page.dart` - FloatingActionButton ADJUST
- Actions - Permission ADJUST

### 8. CAISSES
- `cash_registers_page.dart` - FloatingActionButton CREATE
- Actions OPEN/CLOSE - Permissions spécifiques

### 9. UTILISATEURS
- `users_page.dart` - FloatingActionButton CREATE
- Carte utilisateur - PopupMenu UPDATE/DELETE

### 10. RÔLES
- `roles_page.dart` - FloatingActionButton ROLES
- Carte rôle - PopupMenu ROLES

## 🎯 PATTERN À APPLIQUER

### FloatingActionButton
```dart
floatingActionButton: PermissionWidget(
  module: 'MODULE_NAME',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
),
```

### PopupMenuButton
```dart
Widget _buildActionsMenu(BuildContext context) {
  final permissionService = Get.find<PermissionService>();
  final canUpdate = permissionService.hasPermission('MODULE_NAME', 'UPDATE');
  final canDelete = permissionService.hasPermission('MODULE_NAME', 'DELETE');

  if (!canUpdate && !canDelete) {
    return const SizedBox.shrink();
  }

  final items = <PopupMenuEntry<String>>[];
  if (canUpdate) items.add(...);
  if (canDelete) items.add(...);

  return PopupMenuButton<String>(
    itemBuilder: (context) => items,
    onSelected: (value) { ... },
  );
}
```

### Import Requis
```dart
import '../../../core/widgets/permission_widget.dart';
import '../../../core/services/permission_service.dart';
```

## 📝 ORDRE DE PRIORITÉ

1. **Clients** - Testé, problèmes identifiés
2. **Catégories** - Testé, problèmes identifiés
3. **Mouvements Financiers** - Testé, problèmes identifiés
4. **Comptabilité** - Widget dashboard à corriger
5. **Ventes** - Module critique
6. **Autres modules** - Selon besoin
