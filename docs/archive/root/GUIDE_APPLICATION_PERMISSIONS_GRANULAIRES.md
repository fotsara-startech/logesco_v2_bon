# 🔐 GUIDE - APPLICATION DES PERMISSIONS GRANULAIRES

## 🎯 OBJECTIF

Appliquer les permissions granulaires (CREATE, UPDATE, DELETE) dans toutes les pages de l'application pour que les boutons d'action soient affichés/masqués selon les privilèges de l'utilisateur.

## ✅ CORRECTIONS APPLIQUÉES

### Module Produits

#### 1. Liste des Produits (`product_list_view.dart`)
- ✅ FloatingActionButton "Ajouter" protégé par `products.CREATE`
- ✅ Import de `PermissionWidget` ajouté

#### 2. Carte Produit (`product_card.dart`)
- ✅ PopupMenu filtré selon les permissions
- ✅ Option "Modifier" visible si `products.UPDATE`
- ✅ Option "Activer/Désactiver" visible si `products.UPDATE`
- ✅ Option "Supprimer" visible si `products.DELETE`
- ✅ Menu complètement masqué si aucune permission

#### 3. Détail Produit (`product_detail_view.dart`)
- ✅ FloatingActionButton "Modifier" protégé par `products.UPDATE`

### Module Catégories

#### 1. Page Catégories (`categories_page.dart`)
- ✅ Déjà implémenté avec `PermissionWidget`

## 📋 MODULES À CORRIGER

### Priorité 1 (Modules Critiques)

#### 1. **Clients** (`customers`)
```dart
// Liste des clients
floatingActionButton: PermissionWidget(
  module: 'customers',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
)

// Carte client - PopupMenu
if (canUpdate) { // Modifier }
if (canDelete) { // Supprimer }

// Détail client
floatingActionButton: PermissionWidget(
  module: 'customers',
  privilege: 'UPDATE',
  child: FloatingActionButton(...),
)
```

#### 2. **Ventes** (`sales`)
```dart
// Liste des ventes
floatingActionButton: PermissionWidget(
  module: 'sales',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
)

// Actions sur vente
if (canUpdate) { // Modifier }
if (canDelete) { // Supprimer }
if (hasPermission('sales', 'REFUND')) { // Rembourser }
```

#### 3. **Utilisateurs** (`users`)
```dart
// Liste des utilisateurs
floatingActionButton: PermissionWidget(
  module: 'users',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
)

// Actions sur utilisateur
if (canUpdate) { // Modifier }
if (canDelete) { // Supprimer }
```

#### 4. **Rôles** (`users/roles`)
```dart
// Liste des rôles
floatingActionButton: PermissionWidget(
  module: 'users',
  privilege: 'ROLES',
  child: FloatingActionButton(...),
)

// Actions sur rôle
if (hasPermission('users', 'ROLES')) { // Modifier/Supprimer }
```

### Priorité 2 (Modules Importants)

#### 5. **Fournisseurs** (`suppliers`)
```dart
floatingActionButton: PermissionWidget(
  module: 'suppliers',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
)
```

#### 6. **Commandes** (`procurement`)
```dart
floatingActionButton: PermissionWidget(
  module: 'procurement',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
)

// Action recevoir
if (hasPermission('procurement', 'RECEIVE')) { ... }
```

#### 7. **Inventaire** (`inventory`)
```dart
floatingActionButton: PermissionWidget(
  module: 'inventory',
  privilege: 'ADJUST',
  child: FloatingActionButton(...),
)
```

#### 8. **Caisses** (`cash_registers`)
```dart
// Ouvrir caisse
if (hasPermission('cash_registers', 'OPEN')) { ... }

// Fermer caisse
if (hasPermission('cash_registers', 'CLOSE')) { ... }

// Modifier caisse
if (hasPermission('cash_registers', 'UPDATE')) { ... }
```

#### 9. **Mouvements Financiers** (`financial_movements`)
```dart
floatingActionButton: PermissionWidget(
  module: 'financial_movements',
  privilege: 'CREATE',
  child: FloatingActionButton(...),
)
```

### Priorité 3 (Modules Secondaires)

#### 10. **Paramètres Entreprise** (`company_settings`)
```dart
// Bouton Enregistrer
PermissionWidget(
  module: 'company_settings',
  privilege: 'UPDATE',
  child: ElevatedButton(...),
)
```

#### 11. **Rapports** (`reports`)
```dart
// Bouton Exporter
PermissionWidget(
  module: 'reports',
  privilege: 'EXPORT',
  child: IconButton(...),
)
```

## 🛠️ PATTERN À SUIVRE

### 1. FloatingActionButton (Création)

**Avant:**
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => controller.create(),
  child: const Icon(Icons.add),
),
```

**Après:**
```dart
floatingActionButton: PermissionWidget(
  module: 'MODULE_NAME',
  privilege: 'CREATE',
  child: FloatingActionButton(
    onPressed: () => controller.create(),
    child: const Icon(Icons.add),
  ),
),
```

### 2. FloatingActionButton (Modification)

**Avant:**
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => controller.edit(),
  child: const Icon(Icons.edit),
),
```

**Après:**
```dart
floatingActionButton: PermissionWidget(
  module: 'MODULE_NAME',
  privilege: 'UPDATE',
  child: FloatingActionButton(
    onPressed: () => controller.edit(),
    child: const Icon(Icons.edit),
  ),
),
```

### 3. PopupMenuButton (Actions Multiples)

**Avant:**
```dart
PopupMenuButton<String>(
  itemBuilder: (context) => [
    PopupMenuItem(value: 'edit', child: Text('Modifier')),
    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
  ],
)
```

**Après:**
```dart
Widget _buildActionsMenu(BuildContext context) {
  final permissionService = Get.find<PermissionService>();
  final canUpdate = permissionService.hasPermission('MODULE_NAME', 'UPDATE');
  final canDelete = permissionService.hasPermission('MODULE_NAME', 'DELETE');

  if (!canUpdate && !canDelete) {
    return const SizedBox.shrink();
  }

  final items = <PopupMenuEntry<String>>[];

  if (canUpdate) {
    items.add(PopupMenuItem(value: 'edit', child: Text('Modifier')));
  }

  if (canDelete) {
    items.add(PopupMenuItem(value: 'delete', child: Text('Supprimer')));
  }

  return PopupMenuButton<String>(
    itemBuilder: (context) => items,
    onSelected: (value) { /* ... */ },
  );
}
```

### 4. Boutons Inline

**Avant:**
```dart
ElevatedButton(
  onPressed: () => controller.save(),
  child: Text('Enregistrer'),
)
```

**Après:**
```dart
PermissionWidget(
  module: 'MODULE_NAME',
  privilege: 'UPDATE',
  child: ElevatedButton(
    onPressed: () => controller.save(),
    child: Text('Enregistrer'),
  ),
)
```

### 5. IconButton dans AppBar

**Avant:**
```dart
actions: [
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => controller.delete(),
  ),
]
```

**Après:**
```dart
actions: [
  PermissionWidget(
    module: 'MODULE_NAME',
    privilege: 'DELETE',
    child: IconButton(
      icon: Icon(Icons.delete),
      onPressed: () => controller.delete(),
    ),
  ),
]
```

## 📝 CHECKLIST PAR MODULE

### Pour Chaque Module:

- [ ] Importer `PermissionWidget`
```dart
import '../../../core/widgets/permission_widget.dart';
```

- [ ] Protéger FloatingActionButton de création
```dart
PermissionWidget(module: 'X', privilege: 'CREATE', ...)
```

- [ ] Protéger FloatingActionButton de modification
```dart
PermissionWidget(module: 'X', privilege: 'UPDATE', ...)
```

- [ ] Filtrer PopupMenu selon permissions
```dart
final canUpdate = permissionService.hasPermission('X', 'UPDATE');
final canDelete = permissionService.hasPermission('X', 'DELETE');
```

- [ ] Protéger boutons d'action spécifiques
```dart
PermissionWidget(module: 'X', privilege: 'SPECIFIC', ...)
```

- [ ] Tester avec différents rôles
  - [ ] Admin (tout visible)
  - [ ] Manager (certaines actions)
  - [ ] Vendeur (actions limitées)

## 🧪 TESTS À EFFECTUER

### Test 1: Rôle Admin
```
1. Se connecter avec admin
2. Naviguer dans chaque module
3. ✅ Tous les boutons doivent être visibles
4. ✅ Toutes les actions doivent être disponibles
```

### Test 2: Rôle Vendeur (Lecture Seule)
```
1. Créer un rôle avec uniquement READ
2. Se connecter avec ce rôle
3. ✅ FloatingActionButton masqué
4. ✅ PopupMenu masqué ou vide
5. ✅ Boutons d'action masqués
```

### Test 3: Rôle Vendeur (Lecture + Création)
```
1. Créer un rôle avec READ + CREATE
2. Se connecter avec ce rôle
3. ✅ FloatingActionButton "Ajouter" visible
4. ✅ Options "Modifier/Supprimer" masquées
```

### Test 4: Rôle Manager (Toutes Actions Sauf Suppression)
```
1. Créer un rôle avec READ + CREATE + UPDATE
2. Se connecter avec ce rôle
3. ✅ FloatingActionButton "Ajouter" visible
4. ✅ Option "Modifier" visible
5. ✅ Option "Supprimer" masquée
```

## 🎯 MAPPING DES PRIVILÈGES

### Privilèges Standards
- **READ**: Voir la liste et les détails
- **CREATE**: Créer de nouveaux enregistrements
- **UPDATE**: Modifier des enregistrements existants
- **DELETE**: Supprimer des enregistrements

### Privilèges Spécifiques

#### Ventes
- **REFUND**: Rembourser une vente

#### Approvisionnement
- **RECEIVE**: Recevoir une commande

#### Inventaire
- **ADJUST**: Ajuster le stock
- **COUNT**: Faire un comptage

#### Caisses
- **OPEN**: Ouvrir une caisse
- **CLOSE**: Fermer une caisse

#### Rapports
- **EXPORT**: Exporter des rapports

#### Utilisateurs
- **ROLES**: Gérer les rôles

#### Impression
- **PRINT**: Imprimer
- **REPRINT**: Réimprimer

## 💡 BONNES PRATIQUES

### 1. Toujours Vérifier les Permissions Côté Backend
Les vérifications frontend sont pour l'UX, pas la sécurité. Le backend doit aussi vérifier.

### 2. Utiliser des Noms de Privilèges Cohérents
- CREATE, UPDATE, DELETE (pas Add, Edit, Remove)
- Majuscules pour les privilèges
- Minuscules pour les modules

### 3. Grouper les Vérifications
```dart
// ✅ Bon
final permissionService = Get.find<PermissionService>();
final canUpdate = permissionService.hasPermission('products', 'UPDATE');
final canDelete = permissionService.hasPermission('products', 'DELETE');

// ❌ Mauvais (répétitif)
if (Get.find<PermissionService>().hasPermission('products', 'UPDATE')) { ... }
if (Get.find<PermissionService>().hasPermission('products', 'DELETE')) { ... }
```

### 4. Masquer Complètement les Éléments Sans Permission
```dart
// ✅ Bon
if (!canUpdate && !canDelete) {
  return const SizedBox.shrink();
}

// ❌ Mauvais (menu vide visible)
return PopupMenuButton(itemBuilder: (context) => []);
```

### 5. Logs pour Débogage
```dart
print('🔐 [ProductCard] canUpdate: $canUpdate, canDelete: $canDelete');
```

## 🎉 RÉSULTAT ATTENDU

Après application complète:
- ✅ Chaque bouton d'action vérifie les permissions
- ✅ Les utilisateurs voient uniquement ce qu'ils peuvent faire
- ✅ Expérience utilisateur cohérente
- ✅ Sécurité renforcée (frontend + backend)
- ✅ Maintenance simplifiée (pattern uniforme)

## 📞 SUPPORT

En cas de doute sur un privilège:
1. Consulter `ModulePrivileges.availablePrivileges` dans `role_model.dart`
2. Vérifier les privilèges existants pour le module
3. Ajouter de nouveaux privilèges si nécessaire
