# Guide d'Internationalisation (i18n) - LOGESCO v2

## 📋 Vue d'ensemble

Le système d'internationalisation de LOGESCO v2 permet de traduire l'interface utilisateur en plusieurs langues (actuellement Français et Anglais).

## 🎯 Fonctionnalités

- ✅ Traduction complète de l'interface (Français/Anglais)
- ✅ Changement de langue en temps réel
- ✅ Sauvegarde de la préférence de langue
- ✅ Langue par défaut: Français
- ✅ Plus de 400 traductions disponibles

## 📁 Structure des fichiers

```
logesco_v2/lib/
├── core/
│   ├── translations/
│   │   ├── app_translations.dart      # Configuration principale
│   │   ├── fr_translations.dart       # Traductions françaises
│   │   └── en_translations.dart       # Traductions anglaises
│   ├── controllers/
│   │   └── language_controller.dart   # Contrôleur de langue
│   └── widgets/
│       └── language_selector.dart     # Widget de sélection
└── main.dart                          # Configuration GetX
```

## 🚀 Utilisation

### 1. Utiliser une traduction dans le code

```dart
// Méthode simple avec .tr
Text('dashboard_title'.tr)

// Avec paramètres (si nécessaire)
Text('validation_min_length'.trParams({'min': '5'}))

// Dans un widget
AppBar(
  title: Text('products_title'.tr),
)
```

### 2. Changer la langue

```dart
// Via le contrôleur
final languageController = Get.find<LanguageController>();
await languageController.changeLanguage('en'); // ou 'fr'

// Via AppTranslations directement
await AppTranslations.changeLanguage('en');
```

### 3. Obtenir la langue actuelle

```dart
// Code de langue (fr, en)
String currentLang = AppTranslations.currentLanguageCode;

// Locale complète
Locale currentLocale = AppTranslations.currentLocale;
```

### 4. Ajouter le sélecteur de langue dans une page

```dart
import 'package:logesco_v2/core/widgets/language_selector.dart';

// Dans votre widget
Column(
  children: [
    const LanguageSelector(),
    // Autres widgets...
  ],
)
```

## 📝 Clés de traduction disponibles

### Général
- `app_name`, `yes`, `no`, `ok`, `cancel`, `save`, `delete`, `edit`, `add`
- `search`, `filter`, `refresh`, `loading`, `saving`, `error`, `success`
- `confirm`, `close`, `back`, `next`, `total`, `date`, `status`, `actions`

### Authentification
- `auth_login_title`, `auth_username_label`, `auth_password_label`
- `auth_login_button`, `auth_logout_button`, `auth_login_success`

### Tableau de bord
- `dashboard_title`, `dashboard_welcome`, `dashboard_today_sales`
- `dashboard_total_revenue`, `dashboard_total_profit`, `dashboard_total_expenses`

### Produits
- `products_title`, `products_list`, `products_add`, `products_edit`
- `products_name`, `products_code`, `products_barcode`, `products_category`
- `products_purchase_price`, `products_sale_price`, `products_stock`

### Ventes
- `sales_title`, `sales_new`, `sales_create`, `sales_number`
- `sales_customer`, `sales_products`, `sales_total`, `sales_payment_method`

### Clients
- `customers_title`, `customers_list`, `customers_add`, `customers_name`
- `customers_phone`, `customers_balance`, `customers_debt`

### Fournisseurs
- `suppliers_title`, `suppliers_list`, `suppliers_add`, `suppliers_name`

### Inventaire
- `inventory_title`, `inventory_movements`, `inventory_current_stock`
- `inventory_low_stock_products`, `inventory_expired_products`

### Caisse
- `cash_register_title`, `cash_register_open`, `cash_register_close`
- `cash_register_balance`, `cash_register_sessions`, `cash_register_total_sales`

### Rapports
- `reports_title`, `reports_sales`, `reports_inventory`, `reports_financial`

### Paramètres entreprise
- `company_settings_title`, `company_settings_company_name`
- `company_settings_address`, `company_settings_phone`, `company_settings_logo`
- `company_settings_receipt_language`, `company_settings_save`

### Utilisateurs & Rôles
- `users_title`, `users_list`, `users_add`, `users_username`
- `roles_title`, `roles_list`, `roles_permissions`

### Factures
- `receipts_title`, `receipts_preview`, `receipts_print`
- `receipts_format_thermal`, `receipts_format_a4`, `receipts_format_a5`

### Dépenses
- `expenses_title`, `expenses_list`, `expenses_add`, `expenses_category`

### Messages de validation
- `validation_required`, `validation_invalid_email`, `validation_min_length`

### Messages d'erreur
- `error_network`, `error_server`, `error_unknown`, `error_not_found`

### Langues
- `language_french`, `language_english`, `language_app`, `language_change_success`

## 🔧 Ajouter de nouvelles traductions

### 1. Ajouter dans fr_translations.dart

```dart
const Map<String, String> frTranslations = {
  // ... traductions existantes
  'my_new_key': 'Ma nouvelle traduction',
};
```

### 2. Ajouter dans en_translations.dart

```dart
const Map<String, String> enTranslations = {
  // ... traductions existantes
  'my_new_key': 'My new translation',
};
```

### 3. Utiliser dans le code

```dart
Text('my_new_key'.tr)
```

## 📱 Exemple complet de page traduite

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('products_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'products_add'.tr,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'products_search_placeholder'.tr,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
```

## 🎨 Bonnes pratiques

1. **Toujours utiliser .tr** pour les textes affichés à l'utilisateur
2. **Ne pas traduire** les clés techniques, logs, ou données métier
3. **Grouper les traductions** par module/fonctionnalité
4. **Utiliser des clés descriptives** (ex: `products_add` au lieu de `add`)
5. **Tester** dans les deux langues avant de valider

## 🔄 Migration du code existant

Pour migrer une page existante:

1. Identifier tous les textes hardcodés
2. Trouver ou créer les clés de traduction correspondantes
3. Remplacer `Text('Mon texte')` par `Text('my_key'.tr)`
4. Tester le changement de langue

### Exemple de migration

**Avant:**
```dart
AppBar(
  title: const Text('Liste des produits'),
)
```

**Après:**
```dart
AppBar(
  title: Text('products_list'.tr),
)
```

## 🧪 Test

Pour tester le système de traduction:

1. Lancer l'application
2. Aller dans Paramètres de l'entreprise
3. Utiliser le sélecteur de langue
4. Vérifier que l'interface change de langue
5. Redémarrer l'app pour vérifier la persistance

## 📊 Statistiques

- **Langues supportées:** 2 (Français, Anglais)
- **Clés de traduction:** 400+
- **Modules couverts:** Tous les modules principaux
- **Persistance:** GetStorage

## 🚧 Prochaines étapes

Pour continuer l'internationalisation:

1. Migrer progressivement chaque page
2. Remplacer tous les textes hardcodés
3. Ajouter des traductions pour les messages dynamiques
4. Tester exhaustivement dans les deux langues
5. Documenter les nouvelles clés ajoutées

## 💡 Conseils

- Commencez par les pages les plus utilisées
- Faites des commits réguliers par module
- Testez après chaque migration de page
- Gardez les clés cohérentes entre les modules
- Documentez les clés complexes ou avec paramètres

## 📞 Support

Pour toute question sur l'internationalisation, consultez:
- Ce guide
- Les fichiers de traduction (fr_translations.dart, en_translations.dart)
- La documentation GetX: https://pub.dev/packages/get#internationalization
