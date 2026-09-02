# Référence Rapide i18n - LOGESCO v2

## 🚀 Quick Start

```dart
// 1. Importer GetX
import 'package:get/get.dart';

// 2. Utiliser une traduction
Text('products_title'.tr)

// 3. Changer la langue
await AppTranslations.changeLanguage('en');
```

## 📝 Syntaxe de base

| Action | Code |
|--------|------|
| Traduction simple | `'key'.tr` |
| Avec paramètres | `'key'.trParams({'param': 'value'})` |
| Pluriel | `'key'.trPlural('keys', count)` |
| Langue actuelle | `AppTranslations.currentLanguageCode` |
| Changer langue | `AppTranslations.changeLanguage('en')` |

## 🔑 Clés les plus utilisées

### Actions
```dart
'save'.tr          // Enregistrer / Save
'cancel'.tr        // Annuler / Cancel
'delete'.tr        // Supprimer / Delete
'edit'.tr          // Modifier / Edit
'add'.tr           // Ajouter / Add
'search'.tr        // Rechercher / Search
'filter'.tr        // Filtrer / Filter
'refresh'.tr       // Actualiser / Refresh
'close'.tr         // Fermer / Close
'back'.tr          // Retour / Back
'confirm'.tr       // Confirmer / Confirm
```

### États
```dart
'loading'.tr       // Chargement... / Loading...
'saving'.tr        // Enregistrement... / Saving...
'error'.tr         // Erreur / Error
'success'.tr       // Succès / Success
'warning'.tr       // Attention / Warning
```

### Général
```dart
'yes'.tr           // Oui / Yes
'no'.tr            // Non / No
'ok'.tr            // OK / OK
'total'.tr         // Total / Total
'date'.tr          // Date / Date
'status'.tr        // Statut / Status
'actions'.tr       // Actions / Actions
'details'.tr       // Détails / Details
```

### Modules principaux
```dart
'dashboard_title'.tr           // Tableau de bord / Dashboard
'products_title'.tr            // Produits / Products
'sales_title'.tr               // Ventes / Sales
'customers_title'.tr           // Clients / Customers
'suppliers_title'.tr           // Fournisseurs / Suppliers
'inventory_title'.tr           // Inventaire / Inventory
'cash_register_title'.tr       // Caisse / Cash Register
'reports_title'.tr             // Rapports / Reports
'company_settings_title'.tr    // Paramètres / Settings
```

### Formulaires
```dart
'products_name'.tr             // Nom du produit / Product Name
'products_code'.tr             // Code / Code
'products_price'.tr            // Prix / Price
'products_stock'.tr            // Stock / Stock
'customers_name'.tr            // Nom du client / Customer Name
'customers_phone'.tr           // Téléphone / Phone
```

### Messages
```dart
'products_save_success'.tr     // Produit enregistré / Product saved
'products_delete_confirm'.tr   // Confirmer suppression / Confirm delete
'validation_required'.tr       // Champ requis / Field required
'error_network'.tr             // Erreur réseau / Network error
```

## 🎯 Patterns courants

### AppBar
```dart
AppBar(
  title: Text('products_title'.tr),
  actions: [
    IconButton(
      icon: Icon(Icons.add),
      tooltip: 'products_add'.tr,
      onPressed: () {},
    ),
  ],
)
```

### Bouton
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('save'.tr),
)
```

### TextField
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'products_name'.tr,
    hintText: 'products_search_placeholder'.tr,
  ),
)
```

### Validation
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'validation_required'.tr;
  }
  return null;
}
```

### Dialog
```dart
AlertDialog(
  title: Text('confirm'.tr),
  content: Text('products_delete_confirm'.tr),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('cancel'.tr),
    ),
    ElevatedButton(
      onPressed: () {},
      child: Text('delete'.tr),
    ),
  ],
)
```

### SnackBar (GetX)
```dart
Get.snackbar(
  'success'.tr,
  'products_save_success'.tr,
  snackPosition: SnackPosition.BOTTOM,
)
```

## 🔧 Contrôle de la langue

### Obtenir la langue
```dart
String lang = AppTranslations.currentLanguageCode;  // 'fr' ou 'en'
Locale locale = AppTranslations.currentLocale;      // Locale('fr', 'FR')
```

### Changer la langue
```dart
// Méthode 1: Via AppTranslations
await AppTranslations.changeLanguage('en');

// Méthode 2: Via LanguageController
final controller = Get.find<LanguageController>();
await controller.changeLanguage('en');
```

### Vérifier la langue
```dart
if (AppTranslations.currentLanguageCode == 'fr') {
  // Code spécifique au français
}
```

## 📦 Widget de sélection

```dart
import 'package:logesco_v2/core/widgets/language_selector.dart';

// Dans votre page
const LanguageSelector()
```

## 🎨 Ajouter une traduction

### 1. Dans fr_translations.dart
```dart
const Map<String, String> frTranslations = {
  // ... autres traductions
  'my_new_key': 'Ma nouvelle traduction',
};
```

### 2. Dans en_translations.dart
```dart
const Map<String, String> enTranslations = {
  // ... autres traductions
  'my_new_key': 'My new translation',
};
```

### 3. Utiliser
```dart
Text('my_new_key'.tr)
```

## 🔍 Recherche de clés

### Par module

| Module | Préfixe | Exemple |
|--------|---------|---------|
| Dashboard | `dashboard_` | `dashboard_title` |
| Produits | `products_` | `products_name` |
| Ventes | `sales_` | `sales_total` |
| Clients | `customers_` | `customers_name` |
| Fournisseurs | `suppliers_` | `suppliers_name` |
| Inventaire | `inventory_` | `inventory_stock` |
| Caisse | `cash_register_` | `cash_register_balance` |
| Rapports | `reports_` | `reports_sales` |
| Paramètres | `company_settings_` | `company_settings_name` |
| Utilisateurs | `users_` | `users_username` |
| Rôles | `roles_` | `roles_name` |
| Factures | `receipts_` | `receipts_print` |
| Dépenses | `expenses_` | `expenses_amount` |
| Validation | `validation_` | `validation_required` |
| Erreurs | `error_` | `error_network` |
| Auth | `auth_` | `auth_login` |

### Par type

| Type | Préfixe | Exemple |
|------|---------|---------|
| Titre | `_title` | `products_title` |
| Liste | `_list` | `products_list` |
| Ajouter | `_add` | `products_add` |
| Modifier | `_edit` | `products_edit` |
| Supprimer | `_delete` | `products_delete` |
| Enregistrer | `_save` | `products_save` |
| Rechercher | `_search` | `products_search_placeholder` |
| Succès | `_success` | `products_save_success` |
| Confirmer | `_confirm` | `products_delete_confirm` |

## 🧪 Test rapide

```dart
// Ajouter un FAB pour tester
FloatingActionButton(
  onPressed: () async {
    final lang = AppTranslations.currentLanguageCode;
    await AppTranslations.changeLanguage(
      lang == 'fr' ? 'en' : 'fr'
    );
  },
  child: Icon(Icons.language),
)
```

## 📊 Statistiques

- **Langues:** 2 (FR, EN)
- **Clés:** 400+
- **Modules:** 19
- **Fichiers:** 3

## 🔗 Liens rapides

- **Guide complet:** `GUIDE_INTERNATIONALISATION.md`
- **Exemples:** `EXEMPLE_MIGRATION_I18N.md`
- **Tests:** `TEST_INTERNATIONALISATION.md`
- **Implémentation:** `IMPLEMENTATION_INTERNATIONALISATION.md`

## 💡 Tips

1. **Toujours importer GetX:** `import 'package:get/get.dart';`
2. **Utiliser .tr pour tout texte utilisateur**
3. **Tester dans les deux langues**
4. **Garder les clés cohérentes**
5. **Documenter les nouvelles clés**

## ⚠️ À éviter

```dart
// ❌ Ne PAS faire
Text('Mon texte hardcodé')
const Text('Texte constant')

// ✅ Faire
Text('my_key'.tr)
```

## 🎯 Checklist migration

- [ ] Import GetX ajouté
- [ ] AppBar traduit
- [ ] Boutons traduits
- [ ] Formulaires traduits
- [ ] Messages traduits
- [ ] Dialogues traduits
- [ ] Testé en FR
- [ ] Testé en EN

---

**Gardez cette référence à portée de main pendant le développement!**
