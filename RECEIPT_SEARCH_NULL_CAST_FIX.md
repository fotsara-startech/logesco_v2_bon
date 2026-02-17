# Correction du problème de cast null dans la recherche de reçus

## Problème identifié

L'erreur `type 'Null' is not a subtype of type 'String' in type cast` se produisait lors de la recherche de reçus dans le module d'impression. Cette erreur était causée par des valeurs null dans les données de réponse de l'API qui étaient ensuite castées en String par le code généré de `json_annotation`.

## Cause racine

Dans le fichier `logesco_v2/lib/features/printing/services/printing_service.dart`, la méthode `searchReceipts` tentait de parser des données JSON qui contenaient des valeurs null pour des champs requis comme :
- `id` (null au lieu de String)
- `saleId` (parfois int, parfois null)
- `saleNumber` (null au lieu de String)
- `paymentMethod` (null au lieu de String)
- `companyInfo` (null au lieu d'objet)
- `items` (null au lieu de liste)

## Solution implémentée

### 1. Nettoyage des données avant parsing

Ajout d'une étape de nettoyage et de validation des données avant de les passer au parser JSON généré :

```dart
// Convertir et nettoyer les données pour éviter les erreurs de type
final fixedJson = Map<String, dynamic>.from(json);

// Corriger les IDs (convertir int en string si nécessaire, gérer les null)
if (fixedJson['id'] != null) {
  fixedJson['id'] = fixedJson['id'].toString();
} else {
  fixedJson['id'] = '0';
}

if (fixedJson['saleId'] != null) {
  fixedJson['saleId'] = fixedJson['saleId'].toString();
} else {
  fixedJson['saleId'] = '0';
}

// Assurer que les champs String requis ne sont pas null
fixedJson['saleNumber'] = fixedJson['saleNumber']?.toString() ?? 'N/A';
fixedJson['paymentMethod'] = fixedJson['paymentMethod']?.toString() ?? 'Comptant';
```

### 2. Validation des objets imbriqués

Ajout de validation pour `companyInfo` avec création d'un objet par défaut si null :

```dart
// Assurer que companyInfo existe avec tous les champs requis
if (fixedJson['companyInfo'] == null) {
  fixedJson['companyInfo'] = {
    'id': 0,
    'name': 'LOGESCO',
    'address': 'Adresse non définie',
    'location': '',
    'phone': '',
    'email': '',
    'nuiRccm': '',
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
} else {
  // Vérifier et corriger les champs manquants dans companyInfo
  final companyInfo = Map<String, dynamic>.from(fixedJson['companyInfo']);
  if (companyInfo['id'] == null) companyInfo['id'] = 0;
  companyInfo['name'] = companyInfo['name']?.toString() ?? 'LOGESCO';
  // ... autres champs
}
```

### 3. Validation des listes d'items

Nettoyage des items avec valeurs par défaut :

```dart
// Assurer que items existe et corriger les données des items
if (fixedJson['items'] == null) {
  fixedJson['items'] = [];
} else {
  final items = List<Map<String, dynamic>>.from(fixedJson['items']);
  for (var item in items) {
    item['productId'] = item['productId']?.toString() ?? '0';
    item['productName'] = item['productName']?.toString() ?? 'Produit';
    item['productReference'] = item['productReference']?.toString() ?? '';
    if (item['quantity'] == null) item['quantity'] = 1;
    if (item['unitPrice'] == null) item['unitPrice'] = 0.0;
    // ... autres champs
  }
}
```

### 4. Validation des champs numériques et de format

```dart
// Assurer que les champs numériques existent
if (fixedJson['subtotal'] == null) fixedJson['subtotal'] = 0.0;
if (fixedJson['discountAmount'] == null) fixedJson['discountAmount'] = 0.0;
if (fixedJson['totalAmount'] == null) fixedJson['totalAmount'] = 0.0;
if (fixedJson['paidAmount'] == null) fixedJson['paidAmount'] = 0.0;
if (fixedJson['remainingAmount'] == null) fixedJson['remainingAmount'] = 0.0;

// Assurer que les champs de date existent
if (fixedJson['saleDate'] == null) {
  fixedJson['saleDate'] = DateTime.now().toIso8601String();
}

// Assurer que les champs de format existent
if (fixedJson['format'] == null) fixedJson['format'] = 'thermal';
if (fixedJson['isReprint'] == null) fixedJson['isReprint'] = false;
if (fixedJson['reprintCount'] == null) fixedJson['reprintCount'] = 0;
```

## Fichiers modifiés

- `logesco_v2/lib/features/printing/services/printing_service.dart` : Ajout du nettoyage des données dans la méthode `searchReceipts`

## Tests

- Créé `test-simple-receipt-fix.dart` pour valider la correction
- Le test confirme que les valeurs null sont correctement converties en valeurs par défaut appropriées

## Résultat

✅ L'erreur `type 'Null' is not a subtype of type 'String'` ne devrait plus se produire lors de la recherche de reçus.

✅ Les données manquantes ou null sont maintenant remplacées par des valeurs par défaut appropriées.

✅ La recherche de reçus fonctionne même avec des données incomplètes de l'API.

## Recommandations

1. **Côté backend** : Idéalement, l'API devrait être corrigée pour ne jamais retourner de valeurs null pour les champs requis.

2. **Validation supplémentaire** : Considérer l'ajout de validation similaire dans d'autres services qui parsent des données JSON.

3. **Monitoring** : Surveiller les logs pour identifier d'autres cas similaires dans l'application.