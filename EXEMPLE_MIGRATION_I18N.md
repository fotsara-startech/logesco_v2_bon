# Exemple de Migration i18n - LOGESCO v2

## 📋 Guide pratique de migration

Ce document montre des exemples concrets de migration de code pour l'internationalisation.

## 🎯 Principe de base

```dart
// ❌ AVANT (texte hardcodé)
Text('Mon texte')

// ✅ APRÈS (traduit)
Text('my_key'.tr)
```

## 📝 Exemples par type de widget

### 1. AppBar

```dart
// ❌ AVANT
AppBar(
  title: const Text('Liste des produits'),
  actions: [
    IconButton(
      icon: const Icon(Icons.add),
      tooltip: 'Ajouter un produit',
      onPressed: () {},
    ),
  ],
)

// ✅ APRÈS
AppBar(
  title: Text('products_list'.tr),
  actions: [
    IconButton(
      icon: const Icon(Icons.add),
      tooltip: 'products_add'.tr,
      onPressed: () {},
    ),
  ],
)
```

### 2. Boutons

```dart
// ❌ AVANT
ElevatedButton(
  onPressed: () {},
  child: const Text('Enregistrer'),
)

TextButton(
  onPressed: () {},
  child: const Text('Annuler'),
)

// ✅ APRÈS
ElevatedButton(
  onPressed: () {},
  child: Text('save'.tr),
)

TextButton(
  onPressed: () {},
  child: Text('cancel'.tr),
)
```

### 3. TextField / TextFormField

```dart
// ❌ AVANT
TextFormField(
  decoration: const InputDecoration(
    labelText: 'Nom du produit',
    hintText: 'Entrez le nom',
    helperText: 'Requis',
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  },
)

// ✅ APRÈS
TextFormField(
  decoration: InputDecoration(
    labelText: 'products_name'.tr,
    hintText: 'products_name'.tr,
    helperText: 'required'.tr,
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'validation_required'.tr;
    }
    return null;
  },
)
```

### 4. Dialogues

```dart
// ❌ AVANT
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirmation'),
    content: const Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      ElevatedButton(
        onPressed: () {
          // Supprimer
          Navigator.pop(context);
        },
        child: const Text('Supprimer'),
      ),
    ],
  ),
)

// ✅ APRÈS
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('confirm'.tr),
    content: Text('products_delete_confirm'.tr),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('cancel'.tr),
      ),
      ElevatedButton(
        onPressed: () {
          // Supprimer
          Navigator.pop(context);
        },
        child: Text('delete'.tr),
      ),
    ],
  ),
)
```

### 5. SnackBar

```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Produit enregistré avec succès'),
    backgroundColor: Colors.green,
  ),
)

// ✅ APRÈS
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('products_save_success'.tr),
    backgroundColor: Colors.green,
  ),
)

// Ou avec GetX (recommandé)
Get.snackbar(
  'success'.tr,
  'products_save_success'.tr,
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.green,
  colorText: Colors.white,
)
```

### 6. ListTile

```dart
// ❌ AVANT
ListTile(
  leading: const Icon(Icons.inventory),
  title: const Text('Inventaire'),
  subtitle: const Text('Gérer le stock'),
  trailing: const Icon(Icons.arrow_forward),
  onTap: () {},
)

// ✅ APRÈS
ListTile(
  leading: const Icon(Icons.inventory),
  title: Text('inventory_title'.tr),
  subtitle: Text('inventory_movements'.tr),
  trailing: const Icon(Icons.arrow_forward),
  onTap: () {},
)
```

### 7. Card avec titre

```dart
// ❌ AVANT
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations du produit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Détails du produit...'),
      ],
    ),
  ),
)

// ✅ APRÈS
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'products_title'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('products_description'.tr),
      ],
    ),
  ),
)
```

### 8. DropdownButton

```dart
// ❌ AVANT
DropdownButton<String>(
  value: selectedCategory,
  hint: const Text('Sélectionner une catégorie'),
  items: const [
    DropdownMenuItem(value: 'food', child: Text('Alimentation')),
    DropdownMenuItem(value: 'drink', child: Text('Boissons')),
  ],
  onChanged: (value) {},
)

// ✅ APRÈS
DropdownButton<String>(
  value: selectedCategory,
  hint: Text('categories_title'.tr),
  items: [
    DropdownMenuItem(value: 'food', child: Text('category_food'.tr)),
    DropdownMenuItem(value: 'drink', child: Text('category_drink'.tr)),
  ],
  onChanged: (value) {},
)
```

### 9. DataTable

```dart
// ❌ AVANT
DataTable(
  columns: const [
    DataColumn(label: Text('Nom')),
    DataColumn(label: Text('Prix')),
    DataColumn(label: Text('Stock')),
    DataColumn(label: Text('Actions')),
  ],
  rows: [],
)

// ✅ APRÈS
DataTable(
  columns: [
    DataColumn(label: Text('name'.tr)),
    DataColumn(label: Text('price'.tr)),
    DataColumn(label: Text('products_stock'.tr)),
    DataColumn(label: Text('actions'.tr)),
  ],
  rows: [],
)
```

### 10. Scaffold avec Drawer

```dart
// ❌ AVANT
Drawer(
  child: ListView(
    children: [
      const DrawerHeader(
        child: Text('Menu'),
      ),
      ListTile(
        leading: const Icon(Icons.dashboard),
        title: const Text('Tableau de bord'),
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.inventory),
        title: const Text('Produits'),
        onTap: () {},
      ),
    ],
  ),
)

// ✅ APRÈS
Drawer(
  child: ListView(
    children: [
      DrawerHeader(
        child: Text('app_name'.tr),
      ),
      ListTile(
        leading: const Icon(Icons.dashboard),
        title: Text('dashboard_title'.tr),
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.inventory),
        title: Text('products_title'.tr),
        onTap: () {},
      ),
    ],
  ),
)
```

## 🔍 Cas spéciaux

### 1. Texte avec variables

```dart
// Si vous avez besoin de variables dans le texte
// Ajoutez dans les traductions:
// 'products_count': 'Nombre de produits: @count'

// Utilisation:
Text('products_count'.trParams({'count': '25'}))
```

### 2. Pluralisation

```dart
// Pour l'instant, gérer manuellement:
Text(count == 1 ? 'product_singular'.tr : 'product_plural'.tr)

// Ou:
Text('$count ${'products_title'.tr}')
```

### 3. Texte conditionnel

```dart
// ❌ AVANT
Text(isActive ? 'Actif' : 'Inactif')

// ✅ APRÈS
Text(isActive ? 'users_active'.tr : 'users_inactive'.tr)
```

### 4. Texte formaté

```dart
// ❌ AVANT
Text('Total: ${formatCurrency(total)} FCFA')

// ✅ APRÈS
Text('${'total'.tr}: ${formatCurrency(total)} FCFA')
```

## 📋 Checklist de migration d'une page

Pour migrer une page complète:

- [ ] **1. Importer GetX**
  ```dart
  import 'package:get/get.dart';
  ```

- [ ] **2. AppBar**
  - [ ] Titre
  - [ ] Actions (tooltips)

- [ ] **3. Boutons**
  - [ ] Labels des boutons
  - [ ] Tooltips

- [ ] **4. Formulaires**
  - [ ] Labels des champs
  - [ ] Hints
  - [ ] Messages de validation

- [ ] **5. Textes statiques**
  - [ ] Titres de sections
  - [ ] Descriptions
  - [ ] Messages d'aide

- [ ] **6. Dialogues**
  - [ ] Titres
  - [ ] Messages
  - [ ] Boutons

- [ ] **7. Messages**
  - [ ] SnackBars
  - [ ] Toasts
  - [ ] Alertes

- [ ] **8. Listes**
  - [ ] En-têtes de colonnes
  - [ ] Labels

- [ ] **9. Test**
  - [ ] Tester en français
  - [ ] Tester en anglais
  - [ ] Vérifier la cohérence

## 🎯 Exemple complet: Page de produits

### Avant (hardcodé)

```dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un produit',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher',
              hintText: 'Nom ou code du produit',
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Filtrer'),
          ),
        ],
      ),
    );
  }
}
```

### Après (traduit)

```dart
import 'package:get/get.dart';  // ← Ajout de l'import

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('products_list'.tr),  // ← Traduit
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'products_add'.tr,  // ← Traduit
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'search'.tr,  // ← Traduit
              hintText: 'products_search_placeholder'.tr,  // ← Traduit
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('filter'.tr),  // ← Traduit
          ),
        ],
      ),
    );
  }
}
```

## 💡 Astuces

### 1. Rechercher les textes hardcodés

```bash
# Dans VS Code, rechercher:
Text('
Text("

# Ou utiliser grep:
grep -r "Text('" lib/
```

### 2. Vérifier les clés disponibles

Ouvrir `fr_translations.dart` ou `en_translations.dart` et chercher la clé appropriée.

### 3. Tester rapidement

```dart
// Ajouter temporairement dans votre page:
FloatingActionButton(
  onPressed: () async {
    final lang = AppTranslations.currentLanguageCode;
    await AppTranslations.changeLanguage(lang == 'fr' ? 'en' : 'fr');
  },
  child: const Icon(Icons.language),
)
```

### 4. Ordre de migration

1. Commencer par les pages les plus utilisées
2. Migrer une page à la fois
3. Tester après chaque migration
4. Commit régulièrement

## 🎓 Ressources

- **Liste complète des clés:** Voir `fr_translations.dart` et `en_translations.dart`
- **Guide complet:** Voir `GUIDE_INTERNATIONALISATION.md`
- **Tests:** Voir `TEST_INTERNATIONALISATION.md`

---

**Conseil:** Gardez ce document ouvert pendant la migration pour référence rapide!
