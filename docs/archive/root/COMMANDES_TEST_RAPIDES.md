# 🚀 COMMANDES ET PROCÉDURES DE TEST RAPIDES

## 1. Compiler et exécuter l'application

```bash
# Depuis le dossier logesco_v2
cd D:\projects\Logesco_bon\logesco_app\logesco_v2

# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter pub upgrade

# Lancer en mode debug
flutter run -d windows

# Ou sur un autre device
flutter run -d <device_id>
```

---

## 2. Tester: Quantité initiale à 0

### Via Excel:
```
1. Créer un fichier Excel avec:
   - Colonne 1: Référence (ex: PRD001, PRD002, PRD003)
   - Colonne 2: Nom (ex: Produit A, Produit B, Produit C)
   - Colonne 3: Prix Unitaire (ex: 100, 200, 150)
   - Colonne 4: Catégorie (ex: Accessoires)
   
2. NE PAS créer de colonne "Quantité Initiale"

3. Ouvrir l'app → Gestion des Produits → Import/Export Excel
4. Sélectionner le fichier et importer
5. Aller dans Gestion de Stock (Inventory)
6. Vérifier que les 3 produits apparaissent avec Quantité = 0
```

---

## 3. Tester: Recherche isolée par module

### Test pratique:
```
ÉTAPE 1 - Gestion des Produits:
  1. Aller dans "Gestion des Produits"
  2. Dans la barre de recherche, taper: "iPhone"
  3. ✓ Vérifier: Liste filtrée par "iPhone"

ÉTAPE 2 - Aller dans Gestion de Stock:
  1. Naviguer vers "Gestion de Stock" (Inventory)
  2. ✓ Vérifier: Le champ de recherche est VIDE
  3. ✓ Vérifier: La liste complète des stocks s'affiche

ÉTAPE 3 - Revenir à Gestion des Produits:
  1. Naviguer vers "Gestion des Produits"
  2. ✓ Vérifier: La recherche "iPhone" est TOUJOURS active
  3. ✓ Vérifier: La liste est toujours filtrée

RÉSULTAT: ✅ Chaque module a sa propre recherche indépendante
```

---

## 4. Tester: Tri des produits

### Test du tri par Nom:
```
DANS GESTION DES PRODUITS:
  1. Aller dans "Gestion des Produits"
  2. Chercher la barre de tri (sous la barre de filtres)
  3. ✓ Vérifier: Boutons visibles "Nom | Prix | Référence"
  4. Cliquer sur le bouton "Nom"
  5. ✓ Résultat: Produits triés A→Z alphabétiquement
  6. ✓ Vérifier: Bouton "Nom" surligné en bleu
  7. ✓ Vérifier: Flèche haut (↑) à côté du bouton

TEST DE BASCULEMENT D'ORDRE:
  1. Cliquer sur la flèche (↑)
  2. ✓ Résultat: Produits triés Z→A (inverse)
  3. ✓ Vérifier: Flèche change vers le bas (↓)
  
TEST CHANGEMENT DE CRITÈRE:
  1. Cliquer sur le bouton "Prix"
  2. ✓ Résultat: Produits triés par prix croissant
  3. ✓ Vérifier: Bouton "Prix" est maintenant surligné en bleu
  4. ✓ Vérifier: Flèche revient à ↑
```

### Test du tri dans Gestion de Stock:
```
DANS GESTION DE STOCK (INVENTORY):
  1. Aller dans "Gestion de Stock"
  2. ✓ Vérifier: Barre de tri avec "Nom | Quantité | Prix | Référence"
  3. Cliquer sur "Quantité"
  4. ✓ Résultat: Stocks triés par quantité croissante
  5. Cliquer sur la flèche
  6. ✓ Résultat: Stocks triés par quantité décroissante
```

### Test du tri dans Inventaire:
```
DANS INVENTAIRE DE STOCK:
  1. Aller dans "Inventaire de Stock"
  2. ✓ Vérifier: Barre de tri avec "Nom | Date | Statut"
  3. Cliquer sur "Date"
  4. ✓ Résultat: Inventaires triés par date
```

---

## 5. Tester: Filtres persistants

### Test d'effacement de filtres:
```
ÉTAPE 1 - Appliquer des filtres:
  1. Aller dans "Gestion des Produits"
  2. Recherche: "Test"
  3. Sélectionner Catégorie: "Accessoires"
  4. ✓ Vérifier: Barre "Filtres actifs" visible avec 2 filtres

ÉTAPE 2 - Effacer les filtres:
  1. Cliquer sur "Effacer tout"
  2. ✓ Vérifier: Barre de filtres disparaît
  3. ✓ Vérifier: Liste complète réapparaît

ÉTAPE 3 - Vérifier que l'effacement persiste:
  1. Naviguer vers "Gestion de Stock"
  2. Revenir à "Gestion des Produits"
  3. ✓ Vérifier: Les filtres sont TOUJOURS vides
  4. ✓ Vérifier: La liste complète s'affiche
```

### Test d'effacement individuel:
```
  1. Aller dans "Gestion des Produits"
  2. Appliquer 2-3 filtres (recherche + catégorie)
  3. Cliquer sur le "X" de la recherche (le premier filtre)
  4. ✓ Vérifier: Seul le filtre de recherche est supprimé
  5. ✓ Vérifier: Catégorie reste active
  6. Cliquer sur "X" de la catégorie
  7. ✓ Vérifier: Tous les filtres sont maintenant supprimés
```

---

## 6. Compilation et vérification des erreurs

### Vérifier qu'il n'y a pas d'erreurs de compilation:
```powershell
cd D:\projects\Logesco_bon\logesco_app\logesco_v2

# Analyser le code
flutter analyze

# Vérifier que le résultat contient:
# "XX issues found" (pas d'ERREURS critiques, seulement des infos/avertissements)
```

### Construire un APK (Android) ou un executable (Windows):
```bash
# Pour Windows
flutter build windows --release

# Pour Android
flutter build apk --release

# Pour iOS (sur Mac)
flutter build ios --release
```

---

## 7. Points de vérification clés (Checklist)

### ✅ Quantité initiale
- [ ] Produit créé sans quantité apparaît avec qté = 0
- [ ] Produit créé avec quantité X conserve qté = X
- [ ] Import Excel sans colonne quantité fonctionne

### ✅ Recherche isolée
- [ ] Recherche dans Produits ne s'affiche pas dans Stock
- [ ] Recherche dans Stock ne s'affiche pas dans Inventaire
- [ ] Chaque module peut faire sa propre recherche

### ✅ Tri des produits
- [ ] Barre de tri visible dans chaque module
- [ ] Tri par chaque critère fonctionne
- [ ] Basculer ordre (ASC/DESC) fonctionne
- [ ] Critères différents pour chaque module (Produits vs Stock vs Inventaire)

### ✅ Filtres persistants
- [ ] Effacer un filtre le supprime immédiatement
- [ ] Naviguer vers autre module puis revenir = filtres restent effacés
- [ ] Pas de "ghosting" (filtres qui reviennent)
- [ ] Fonction "Effacer tout" fonctionne

---

## 8. Logs pour débogage (si problèmes)

### Vérifier les logs de la recherche:
```dart
// Les contrôleurs affichent des logs comme:
// 🔍 RECHERCHE: "iPhone"
// 🔍 DONNÉES REÇUES: 5 produits
// 🔍 LISTE ASSIGNÉE: 5 produits

// Si vous voyez: "⚠️ Quantité ignorée pour ..." 
// = un produit n'a pas eu de stock créé
```

### Vérifier l'isolation des recherches:
```
- ProductController.searchQuery doit être vide après onClose()
- InventoryGetxController.searchQuery doit être vide après onClose()
- StockInventoryController.searchQuery doit être vide après onClose()
```

---

## 9. Aider au débogage

Si vous rencontrez des problèmes:

1. **Toujours commencer par**: `flutter clean` + `flutter pub get`
2. **Vérifier les logs**: Chercher 🔍, ✅, ❌ dans la console
3. **Analyser le code**: `flutter analyze` pour erreurs syntaxe
4. **Voir les fichiers modifiés**:
   - `CORRECTIONS_APPORTEES_PRODUITS_RECHERCHE_TRI.md`
   - `GUIDE_VALIDATION_CORRECTIONS.md`

---

## ✅ Résumé en une minute

```
1. flutter clean && flutter pub get
2. flutter run -d windows
3. Tester: Produit sans qté initiale → apparaît avec 0
4. Tester: Recherche Produits vs Stocks = indépendantes
5. Tester: Barre de tri visible et fonctionnelle
6. Tester: Effacer filtres = disparaissent complètement
7. flutter analyze = pas d'erreurs critiques
8. ✅ DONE!
```

---

**Bonne chance avec les tests! 🚀**
