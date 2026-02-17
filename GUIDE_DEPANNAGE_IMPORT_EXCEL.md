# Guide de Dépannage - Import Excel avec Stocks

## 🚨 Problèmes identifiés

### 1. Les quantités initiales ne sont pas prises en compte

#### Causes possibles :
- ❌ Colonne "Quantité Initiale" mal nommée dans Excel
- ❌ Service d'inventaire non disponible
- ❌ Erreur dans la création des mouvements de stock
- ❌ Produits marqués comme services

#### Solutions :

##### A. Vérifier le nom de la colonne Excel
La colonne doit être nommée exactement :
- ✅ "Quantité Initiale"
- ✅ "Quantité initiale" 
- ✅ "quantité initiale"
- ✅ "quantite initiale"
- ✅ "Qte"
- ✅ "Stock Initial"

##### B. Vérifier les logs de débogage
Après l'import, vérifiez les logs dans la console :
```
📋 Mapping des colonnes:
  quantiteInitiale -> colonne 11
🔍 Ligne 1 - Référence: REF001, Quantité brute: "50"
🔍 Ligne 1 - Quantité parsée: 50
✅ Stock initial ajouté: REF001 -> 50
✅ Stock initial créé pour REF001: 50
```

##### C. Vérifier que ce ne sont pas des services
Les services (Est Service = Oui) n'ont pas de stock :
```
ℹ️ Service ignoré pour stock: REF002
```

##### D. Vérifier les permissions
L'utilisateur doit avoir accès au module Inventaire.

### 2. Les catégories ne sont pas liées aux produits

#### Causes possibles :
- ❌ Catégories n'existent pas dans le système
- ❌ Backend ne gère pas la création automatique des catégories
- ❌ Problème de liaison catégorie-produit

#### Solutions :

##### A. Créer les catégories avant l'import
1. Aller dans **Gestion des Produits** → **Catégories**
2. Créer toutes les catégories utilisées dans le fichier Excel
3. Relancer l'import

##### B. Vérifier les noms de catégories
- Utiliser exactement les mêmes noms que dans le système
- Respecter la casse (majuscules/minuscules)
- Éviter les espaces en début/fin

##### C. Vérifier les logs d'import
```
📡 Réponse import: Success=true, Data={...}
```

## 🔧 Tests de diagnostic

### Test 1: Vérifier la structure Excel
```bash
dart test-excel-stock-debug.dart
```

### Test 2: Vérifier les catégories
```bash
dart test-import-categories-debug.dart
```

## 📋 Checklist de dépannage

### Avant l'import :
- [ ] Template Excel téléchargé récemment
- [ ] Colonne "Quantité Initiale" présente et bien nommée
- [ ] Catégories créées dans le système
- [ ] Produits marqués correctement (Service/Produit)
- [ ] Quantités sont des nombres entiers positifs

### Pendant l'import :
- [ ] Aperçu affiche les stocks initiaux
- [ ] Message indique "X avec stock initial"
- [ ] Catégories visibles dans l'aperçu
- [ ] Aucune erreur dans les logs

### Après l'import :
- [ ] Produits créés dans la liste
- [ ] Stocks visibles dans l'inventaire
- [ ] Catégories assignées aux produits
- [ ] Mouvements de stock "ENTRÉE" créés

## 🛠️ Corrections avancées

### Problème : Service d'inventaire non disponible
```dart
// Dans excel_controller.dart, vérifier :
try {
  _inventoryService = InventoryService(Get.find<AuthService>());
} catch (e) {
  print('⚠️ InventoryService non disponible: $e');
}
```

### Problème : Mapping des colonnes incorrect
```dart
// Dans excel_service.dart, ajouter des logs :
print('📋 Mapping des colonnes:');
columnMap.forEach((key, value) => print('  $key -> colonne $value'));
```

### Problème : Catégories non liées
Vérifier que le backend retourne les catégories dans la réponse d'import.

## 📊 Exemple de fichier Excel correct

| Référence | Nom | Description | Prix Unitaire | Prix Achat | Code Barre | Catégorie | Seuil Stock Minimum | Remise Max Autorisée | Est Actif | Est Service | Quantité Initiale |
|-----------|-----|-------------|---------------|------------|------------|-----------|-------------------|-------------------|-----------|-------------|------------------|
| REF001 | Ordinateur | PC Gaming | 150000 | 120000 | 1111111111 | Informatique | 5 | 10 | Oui | Non | 25 |
| REF002 | Souris | Souris RGB | 5000 | 3000 | 2222222222 | Informatique | 20 | 15 | Oui | Non | 100 |
| REF003 | Installation | Service | 10000 |  |  | Services | 0 | 0 | Oui | Oui |  |

### Résultat attendu :
- ✅ 3 produits créés
- ✅ 2 mouvements de stock (REF001: +25, REF002: +100)
- ✅ Catégories "Informatique" et "Services" assignées
- ✅ REF003 sans stock (service)

## 🔍 Logs de débogage détaillés

### Logs normaux (succès) :
```
📋 Colonne quantité trouvée: "quantité initiale" -> index 11
📋 Mapping des colonnes:
  reference -> colonne 0
  nom -> colonne 1
  quantiteInitiale -> colonne 11
🔍 Ligne 1 - Référence: REF001, Quantité brute: "25"
🔍 Ligne 1 - Quantité parsée: 25
✅ Stock initial ajouté: REF001 -> 25
🔄 Import de 3 produits...
📡 Réponse import: Success=true
✅ Stock initial créé pour REF001: 25
```

### Logs d'erreur (problème) :
```
⚠️ Quantité ignorée pour REF001: null
❌ Erreur création stock initial pour REF001: [détail]
⚠️ InventoryService non disponible: [erreur]
```

## 📞 Support

Si les problèmes persistent :

1. **Vérifier les logs** dans la console de l'application
2. **Tester avec un fichier minimal** (1-2 produits)
3. **Vérifier les permissions** utilisateur
4. **Contacter le support** avec les logs d'erreur

## 🔄 Mise à jour recommandée

Pour éviter ces problèmes à l'avenir, considérer :

1. **Validation en temps réel** des catégories
2. **Création automatique** des catégories manquantes
3. **Interface d'édition** des données avant import
4. **Rapport détaillé** post-import avec résumé des opérations