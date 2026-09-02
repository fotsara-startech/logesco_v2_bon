# Ajout de l'export/import Excel des fiches de comptage d'inventaire

## Contexte

Dans le module d'inventaire, il est maintenant possible d'**exporter la fiche de comptage sous format Excel**, de la **remplir manuellement hors ligne**, puis de la **réimporter** pour mettre à jour automatiquement les comptages dans le système.

## Problème résolu

Auparavant, le comptage d'inventaire devait être effectué exclusivement via l'application, ce qui pouvait être contraignant dans certains scénarios :
- ❌ Comptage sur papier nécessitant une double saisie
- ❌ Impossibilité de répartir le travail sur plusieurs personnes sans accès à l'application
- ❌ Pas de sauvegarde intermédiaire des comptages hors ligne
- ❌ Difficulté pour les équipes habituées aux tableurs Excel

## Solution implémentée

### 1. Export Excel des fiches de comptage

**Fonctionnalité** : Exporter un fichier Excel contenant tous les produits de l'inventaire avec colonnes pré-remplies.

**Structure du fichier Excel généré** :

| Code | Produit | Catégorie | Stock Système | Qté Comptée | Écart | Commentaire |
|------|---------|-----------|---------------|-------------|-------|-------------|
| P001 | Produit A | Électronique | 50 | *[vide]* | =E2-D2 | *[vide]* |
| P002 | Produit B | Textile | 120 | *[vide]* | =E3-D3 | *[vide]* |

**Caractéristiques** :
- ✅ En-tête avec informations de l'inventaire (nom, type, date)
- ✅ Colonnes pré-formatées et stylisées
- ✅ Formule Excel automatique pour calculer l'écart (`=E-D`)
- ✅ Colonne "Qté Comptée" vide pour remplissage manuel
- ✅ Instructions au bas du document
- ✅ Largeurs de colonnes ajustées pour lisibilité

### 2. Import Excel avec mise à jour des comptages

**Fonctionnalité** : Réimporter le fichier Excel rempli et mettre à jour automatiquement les comptages dans le système.

**Logique d'import** :
1. Lecture du fichier Excel (formats `.xlsx` et `.xls` supportés)
2. Parcours des lignes à partir de la ligne 8 (après les en-têtes)
3. Extraction des données :
   - Code produit (colonne A)
   - Nom produit (colonne B)
   - Quantité comptée (colonne E)
   - Commentaire (colonne G)
4. **Correspondance produit** :
   - Priorité 1 : Par code produit
   - Priorité 2 : Par nom produit (si code vide)
5. Mise à jour des items d'inventaire via API
6. Affichage du résumé d'import

**Gestion des cas particuliers** :
- ✅ Ignorer les lignes avec quantité comptée vide
- ✅ Ignorer les lignes sans nom de produit (fin des données)
- ✅ Supporter les nombres entiers et décimaux
- ✅ Parser les cellules texte contenant des nombres
- ⚠️ Afficher un avertissement pour les produits non trouvés
- ⚠️ Afficher les erreurs de mise à jour

## Fichiers créés/modifiés

### Nouveaux fichiers

1. **`logesco_v2/lib/features/stock_inventory/services/inventory_excel_service.dart`**
   - Service d'export/import Excel
   - Classe `CountingSheetImport` pour les données importées
   - Méthodes :
     - `exportCountingSheet()` : Génère le fichier Excel
     - `importCountingSheet()` : Lit et parse le fichier Excel

### Fichiers modifiés

2. **`logesco_v2/lib/features/stock_inventory/controllers/stock_inventory_controller.dart`**
   - Ajout de `exportCountingSheetToExcel()`
   - Ajout de `importCountingSheetFromExcel()`
   - Intégration avec `Share` pour partager le fichier exporté

3. **`logesco_v2/lib/features/stock_inventory/views/inventory_count_view.dart`**
   - Ajout des options "Exporter Excel" et "Importer Excel" dans le menu
   - Méthodes `_exportToExcel()` et `_importFromExcel()`
   - Dialog de confirmation avant import

## Utilisation

### Workflow complet

#### 1. Exporter la fiche de comptage

```
1. Ouvrir un inventaire en mode comptage
2. Cliquer sur le menu (⋮) en haut à droite
3. Sélectionner "Exporter Excel"
4. Le fichier Excel est généré et peut être partagé
```

#### 2. Remplir la fiche manuellement

```
1. Ouvrir le fichier Excel exporté
2. Remplir la colonne "Qté Comptée" (colonne E) avec les quantités physiques
3. L'écart se calcule automatiquement (colonne F)
4. Ajouter des commentaires si nécessaire (colonne G)
5. Sauvegarder le fichier
```

#### 3. Réimporter la fiche remplie

```
1. Retourner dans l'application
2. Ouvrir le même inventaire
3. Cliquer sur le menu (⋮)
4. Sélectionner "Importer Excel"
5. Confirmer l'import
6. Sélectionner le fichier Excel rempli
7. ✅ Les comptages sont automatiquement mis à jour
```

### Message de résultat d'import

```
✅ Import Excel réussi

15 comptage(s) importé(s) avec succès
2 produit(s) non trouvé(s)
```

## Avantages

### Pour les utilisateurs
- ✅ **Flexibilité** : Comptage possible hors ligne sur Excel
- ✅ **Collaboration** : Fichier partageable entre plusieurs compteurs
- ✅ **Familiarité** : Utilisation d'Excel, outil connu de tous
- ✅ **Sauvegarde** : Backup automatique des comptages dans le fichier
- ✅ **Calculs automatiques** : Écarts calculés en temps réel dans Excel

### Pour le système
- ✅ **Traçabilité** : Chaque comptage importé est horodaté et attribué à un utilisateur
- ✅ **Synchronisation** : Les comptages importés sont synchronisés vers Neon
- ✅ **Cohérence** : Correspondance automatique produits par code ou nom
- ✅ **Validation** : Vérification des données avant mise à jour

## Scénarios d'usage

### Scénario 1 : Inventaire en entrepôt sans connexion

```
1. Responsable exporte la fiche Excel avant de partir en entrepôt
2. Équipe de comptage remplit le fichier sur tablette Excel hors ligne
3. De retour au bureau, import du fichier dans l'application
4. ✅ Tous les comptages sont synchronisés en une seule opération
```

### Scénario 2 : Répartition du travail

```
1. Export de la fiche Excel complète
2. Séparation du fichier en 3 parties (catégories A, B, C)
3. Chaque équipe remplit sa partie
4. Import des 3 fichiers successivement
5. ✅ L'inventaire complet est mis à jour
```

### Scénario 3 : Validation préalable

```
1. Export de la fiche avec quantités système
2. Contrôle visuel des écarts dans Excel (filtres, tris, couleurs)
3. Correction des erreurs évidentes avant import
4. Import uniquement des comptages validés
5. ✅ Import propre sans surprises
```

## Dépendances

### Packages utilisés

```yaml
dependencies:
  excel: ^4.0.3              # Génération et parsing Excel
  file_picker: ^8.0.0+1      # Sélection de fichiers
  share_plus: ^7.2.2         # Partage de fichiers
  path_provider: ^2.1.1      # Accès au dossier Documents
```

Ces packages étaient déjà présents dans `pubspec.yaml`, aucune installation supplémentaire nécessaire.

## Structure du code

### Service Excel

```dart
class InventoryExcelService {
  // Export
  static Future<String> exportCountingSheet(
    StockInventory inventory,
    List<InventoryItem> items,
  ) async { ... }

  // Import
  static Future<List<CountingSheetImport>> importCountingSheet() async { ... }
}

class CountingSheetImport {
  final String? codeProduit;
  final String nomProduit;
  final double quantiteComptee;
  final String? commentaire;
}
```

### Controller

```dart
class StockInventoryController extends GetxController {
  // Export vers Excel
  Future<void> exportCountingSheetToExcel(int inventoryId) async { ... }

  // Import depuis Excel
  Future<void> importCountingSheetFromExcel() async {
    // 1. Importer les données depuis Excel
    final imports = await InventoryExcelService.importCountingSheet();
    
    // 2. Correspondre avec les items existants
    // 3. Mettre à jour via API
    // 4. Afficher le résumé
  }
}
```

## Limitations actuelles

### 1. Correspondance produits
- La correspondance se fait par code **ou** par nom
- Si un produit n'est pas trouvé, il est ignoré (pas d'erreur bloquante)
- Pas de correspondance fuzzy (nom doit correspondre exactement)

### 2. Format Excel
- Le fichier doit respecter la structure exportée (lignes de données à partir de la ligne 8)
- Modifier l'ordre des colonnes peut casser l'import
- Les formules Excel dans la colonne "Écart" ne sont pas importées (calculées côté serveur)

### 3. Validation
- Pas de validation des quantités négatives
- Pas de limite sur les quantités importées
- Commentaires tronqués si trop longs (selon limite base de données)

## Améliorations futures possibles

### Court terme
- ✨ Support du format CSV en plus d'Excel
- ✨ Prévisualisation des données avant import
- ✨ Rapport d'erreurs détaillé en PDF

### Moyen terme
- ✨ Import partiel (sélection de produits à importer)
- ✨ Correspondance fuzzy pour les noms de produits
- ✨ Validation des quantités (seuils d'alerte sur écarts importants)

### Long terme
- ✨ Templates Excel personnalisables
- ✨ Import multi-fichiers simultané
- ✨ Historique des imports avec possibilité de rollback

## Tests recommandés

### Test 1 : Export basique
```
1. Créer un inventaire avec 10 produits
2. Exporter en Excel
3. Vérifier : 10 lignes de données, formules écarts, format correct
```

### Test 2 : Import complet
```
1. Exporter inventaire de 20 produits
2. Remplir toutes les quantités comptées
3. Importer
4. Vérifier : 20 comptages importés, écarts calculés, sync vers Neon
```

### Test 3 : Import partiel
```
1. Exporter inventaire de 30 produits
2. Remplir seulement 15 quantités
3. Importer
4. Vérifier : 15 importés, 15 restants inchangés
```

### Test 4 : Produits non trouvés
```
1. Exporter inventaire
2. Modifier manuellement des codes produits dans Excel
3. Importer
4. Vérifier : Message d'avertissement, comptages valides importés
```

### Test 5 : Formats numériques
```
1. Exporter inventaire
2. Tester différents formats : entiers, décimaux, texte
3. Importer
4. Vérifier : Parsing correct de tous les formats
```

## Notes techniques

### Génération Excel

- Utilise le package `excel` avec API déclarative
- Format `.xlsx` (Office Open XML)
- Support des styles (couleurs, gras, alignement)
- Formules Excel natives pour calculs d'écarts

### Parsing Excel

- Support `.xlsx` et `.xls`
- Lecture binaire du fichier via `file_picker`
- Extraction robuste avec gestion d'erreurs
- Support des types de cellules : `IntCellValue`, `DoubleCellValue`, `TextCellValue`

### Synchronisation

- Les comptages importés déclenchent la synchronisation automatique
- Chaque mise à jour d'item est enregistrée dans `sync_queue`
- Synchronisation vers Neon lors du prochain cycle (30s ou manuel)

## Exemple de fichier Excel généré

```
╔══════════════════════════════════════════════════════════════╗
║           FICHE DE COMPTAGE D'INVENTAIRE                     ║
╠══════════════════════════════════════════════════════════════╣
║ Inventaire: Inventaire Annuel 2024                          ║
║ Type: Inventaire Total                                       ║
║ Date: 2024-01-15                                             ║
╠═══════╦══════════════╦═══════════╦═════════════╦════════════╣
║ Code  ║ Produit      ║ Catégorie ║ Stock Sys.  ║ Qté Comptée║
╠═══════╬══════════════╬═══════════╬═════════════╬════════════╣
║ P001  ║ Laptop HP    ║ Info      ║ 15          ║            ║
║ P002  ║ Souris USB   ║ Info      ║ 200         ║            ║
║ P003  ║ Clavier      ║ Info      ║ 150         ║            ║
╚═══════╩══════════════╩═══════════╩═════════════╩════════════╝

INSTRUCTIONS:
1. Remplir la colonne "Qté Comptée" avec les quantités physiques
2. L'écart sera calculé automatiquement
3. Ajouter un commentaire si nécessaire
4. Sauvegarder et réimporter le fichier
```

## Conclusion

Cette fonctionnalité apporte une **flexibilité majeure** au module d'inventaire en permettant :
- ✅ Comptage hors ligne via Excel
- ✅ Collaboration facilitée entre équipes
- ✅ Import automatisé des données
- ✅ Synchronisation complète avec le backend

Le workflow **Export → Remplir → Import** est simple, intuitif et répond aux besoins réels des utilisateurs en situation de comptage physique.
