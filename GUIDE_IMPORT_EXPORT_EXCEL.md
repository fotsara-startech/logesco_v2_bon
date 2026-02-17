# Guide d'Import/Export Excel des Produits

## 📋 Vue d'ensemble

Cette fonctionnalité permet aux utilisateurs d'importer et d'exporter leurs produits via des fichiers Excel, facilitant ainsi la migration de données et la gestion en lot.

## 🚀 Fonctionnalités

### Export des Produits
- **Export complet** : Exporte tous les produits de l'entreprise
- **Format Excel** : Fichier .xlsx avec formatage professionnel
- **Partage facile** : Possibilité de partager directement le fichier
- **Colonnes incluses** :
  - Référence
  - Nom
  - Description
  - Prix Unitaire
  - Prix d'Achat
  - Code Barre
  - Catégorie
  - Seuil Stock Minimum
  - Remise Max Autorisée
  - Est Actif (Oui/Non)
  - Est Service (Oui/Non)

### Import des Produits
- **Import par fichier Excel** : Support des formats .xlsx et .xls
- **Template fourni** : Modèle Excel avec exemples
- **Aperçu avant import** : Validation des données avant insertion
- **Gestion des erreurs** : Ignore les lignes invalides
- **Import en lot** : Traitement optimisé pour de gros volumes

## 📱 Interface Utilisateur

### Accès à la fonctionnalité
1. Aller dans **Gestion des Produits**
2. Cliquer sur le menu **⋮** (trois points)
3. Sélectionner **Import/Export Excel**

### Page d'Import/Export
- **Section Export** : Bouton pour exporter tous les produits
- **Section Import** : Bouton pour importer + bouton Template
- **Instructions** : Guide d'utilisation intégré

## 🔧 Utilisation

### Pour Exporter
1. Cliquer sur **"Exporter tous les produits"**
2. Attendre la génération du fichier
3. Choisir de partager ou sauvegarder le fichier

### Pour Importer
1. **Télécharger le template** (recommandé pour la première fois)
2. Remplir le fichier Excel avec vos données
3. Cliquer sur **"Importer depuis Excel"**
4. Sélectionner votre fichier
5. **Vérifier l'aperçu** des produits à importer
6. Cliquer sur **"Confirmer l'import"**

## 📊 Format du Fichier Excel

### Colonnes Obligatoires
- **Référence** : Identifiant unique du produit
- **Nom** : Nom du produit
- **Prix Unitaire** : Prix de vente (nombre décimal)

### Colonnes Optionnelles
- **Description** : Description détaillée
- **Prix Achat** : Prix d'achat (nombre décimal)
- **Code Barre** : Code-barres du produit
- **Catégorie** : Catégorie du produit
- **Seuil Stock Minimum** : Nombre entier
- **Remise Max Autorisée** : Pourcentage (nombre décimal)
- **Est Actif** : "Oui" ou "Non"
- **Est Service** : "Oui" ou "Non"

### Exemple de Données
```
Référence | Nom           | Prix Unitaire | Prix Achat | Catégorie    | Est Actif
REF001    | Produit Test  | 25.99        | 15.50      | Électronique | Oui
REF002    | Service Test  | 50.00        |            | Services     | Oui
```

## ⚠️ Règles et Limitations

### Règles d'Import
- Les références doivent être uniques
- Les prix doivent être des nombres positifs
- Les lignes incomplètes sont ignorées
- Les doublons sont rejetés

### Gestion des Erreurs
- **Référence existante** : Le produit est ignoré
- **Données invalides** : La ligne est ignorée
- **Champs manquants** : La ligne est ignorée

## 🔒 Permissions Requises

- **Export** : Permission `READ` sur le module `products`
- **Import** : Permission `CREATE` sur le module `products`

## 🛠️ Implémentation Technique

### Frontend (Flutter)
- **ExcelService** : Gestion des fichiers Excel
- **ExcelController** : Logique métier
- **ExcelImportExportPage** : Interface utilisateur

### Backend (Node.js)
- **GET /api/v1/products/all** : Export de tous les produits
- **POST /api/v1/products/import** : Import en lot

### Dépendances Ajoutées
```yaml
dependencies:
  excel: ^4.0.3          # Manipulation des fichiers Excel
  file_picker: ^8.0.0+1  # Sélection de fichiers
```

## 📝 Exemple d'Utilisation

### Scénario : Migration depuis un autre système
1. **Préparer les données** dans le format Excel requis
2. **Télécharger le template** pour référence
3. **Remplir le fichier** avec vos produits existants
4. **Importer le fichier** via l'interface
5. **Vérifier l'aperçu** et corriger si nécessaire
6. **Confirmer l'import** pour créer les produits

### Scénario : Sauvegarde des produits
1. **Exporter tous les produits** vers Excel
2. **Sauvegarder le fichier** comme backup
3. **Partager avec l'équipe** si nécessaire

## 🐛 Dépannage

### Problèmes Courants
- **"Aucun produit valide trouvé"** : Vérifier le format des colonnes
- **"Référence déjà existante"** : Utiliser des références uniques
- **"Erreur de format"** : Utiliser des nombres pour les prix

### Solutions
- Utiliser le template fourni
- Vérifier les types de données
- S'assurer que les références sont uniques
- Contrôler que les prix sont des nombres

## 🔄 Mises à Jour Futures

### Améliorations Prévues
- Support de plus de formats (CSV, ODS)
- Import incrémental (mise à jour des produits existants)
- Validation avancée des données
- Historique des imports/exports
- Planification automatique des exports

---

Cette fonctionnalité simplifie grandement la gestion des produits en permettant l'import/export en masse, idéale pour les migrations de données et la gestion efficace des catalogues produits.