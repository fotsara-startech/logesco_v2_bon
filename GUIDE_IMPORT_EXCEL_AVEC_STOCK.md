# Guide d'Import Excel avec Quantités Initiales

## 📋 Vue d'ensemble

Cette fonctionnalité permet d'importer des produits depuis un fichier Excel en incluant leurs quantités initiales. Le système créera automatiquement les mouvements de stock correspondants.

## 🚀 Fonctionnalités ajoutées

### 1. Colonne "Quantité Initiale" dans le template Excel
- Nouvelle colonne dans le fichier template
- Permet de spécifier la quantité de stock initial pour chaque produit
- Ignorée pour les services (Est Service = Oui)

### 2. Création automatique des mouvements de stock
- Génération automatique d'un mouvement "ENTRÉE" pour chaque quantité initiale
- Type de référence : "IMPORT_EXCEL"
- Notes automatiques : "Stock initial importé depuis Excel"

### 3. Interface utilisateur améliorée
- Affichage du nombre de produits avec stock initial
- Indication visuelle des quantités dans l'aperçu d'import
- Messages informatifs sur le processus

## 📊 Structure du fichier Excel

### Colonnes obligatoires
- **Référence** : Identifiant unique du produit
- **Nom** : Nom du produit
- **Prix Unitaire** : Prix de vente (nombre)

### Colonnes optionnelles
- **Description** : Description du produit
- **Prix Achat** : Prix d'achat (nombre)
- **Code Barre** : Code-barres du produit
- **Catégorie** : Catégorie du produit
- **Seuil Stock Minimum** : Seuil d'alerte stock (nombre)
- **Remise Max Autorisée** : Remise maximale en % (nombre)
- **Est Actif** : Oui/Non
- **Est Service** : Oui/Non
- **Quantité Initiale** : Quantité de stock initial (nombre)

### Exemple de fichier Excel

| Référence | Nom | Description | Prix Unitaire | Prix Achat | Code Barre | Catégorie | Seuil Stock Minimum | Remise Max Autorisée | Est Actif | Est Service | Quantité Initiale |
|-----------|-----|-------------|---------------|------------|------------|-----------|-------------------|-------------------|-----------|-------------|------------------|
| REF001 | Produit A | Description A | 2500 | 1500 | 1234567890 | Électronique | 10 | 5.0 | Oui | Non | 50 |
| REF002 | Service B | Description B | 5000 |  |  | Services | 0 | 10.0 | Oui | Oui |  |

## 🔧 Utilisation

### 1. Télécharger le template
1. Aller dans **Gestion des Produits**
2. Cliquer sur le menu **⋮** → **Import/Export Excel**
3. Cliquer sur **Template** pour télécharger le modèle

### 2. Remplir le fichier Excel
1. Ouvrir le template téléchargé
2. Remplir les informations des produits
3. **Important** : Ajouter les quantités initiales dans la colonne "Quantité Initiale"
4. Laisser vide pour les services ou produits sans stock initial
5. Sauvegarder le fichier

### 3. Importer les produits
1. Dans la page Import/Export Excel
2. Cliquer sur **Importer depuis Excel**
3. Sélectionner votre fichier Excel
4. Vérifier l'aperçu (produits avec stock initial indiqués)
5. Cliquer sur **Confirmer l'import**

### 4. Vérification
1. Les produits sont créés dans le système
2. Les mouvements de stock "ENTRÉE" sont automatiquement générés
3. Les quantités sont disponibles dans l'inventaire

## ⚠️ Points importants

### Règles de validation
- Les quantités initiales ne sont appliquées qu'aux produits physiques (Est Service = Non)
- Les quantités doivent être des nombres entiers positifs
- Les quantités nulles ou vides sont ignorées

### Gestion des erreurs
- Si un produit ne peut pas être créé, son stock initial est ignoré
- Les erreurs de création de mouvement n'empêchent pas l'import des produits
- Les logs détaillent les succès et échecs

### Permissions requises
- Accès au module Produits
- Accès au module Inventaire (pour les mouvements de stock)
- Droits d'import/export

## 🔍 Exemple de flux complet

### Fichier Excel d'exemple
```
REF001, Ordinateur Portable, PC Gaming, 150000, 120000, 1111111111, Informatique, 5, 10, Oui, Non, 25
REF002, Souris Gaming, Souris RGB, 5000, 3000, 2222222222, Informatique, 20, 15, Oui, Non, 100
REF003, Installation OS, Service installation, 10000, , , Services, 0, 0, Oui, Oui, 
```

### Résultat après import
1. **3 produits créés** dans le système
2. **2 mouvements de stock** générés :
   - REF001 : +25 unités (ENTRÉE)
   - REF002 : +100 unités (ENTRÉE)
3. **REF003** : Aucun mouvement (service)

## 🛠️ Dépannage

### Problèmes courants

#### "Aucun produit valide trouvé"
- Vérifier que les colonnes obligatoires sont remplies
- Vérifier le format des nombres (utiliser . pour les décimales)
- S'assurer que la première ligne contient les en-têtes

#### "Erreur lors de la création du stock initial"
- Vérifier que le service d'inventaire est disponible
- Vérifier les permissions d'accès à l'inventaire
- Consulter les logs pour plus de détails

#### "Quantités non appliquées"
- Vérifier que "Est Service" = "Non" pour les produits physiques
- S'assurer que les quantités sont des nombres entiers positifs
- Vérifier que la colonne "Quantité Initiale" est correctement nommée

### Logs et diagnostic
- Les opérations sont loggées dans la console
- Format : `✅ Stock initial créé pour REF001: 25`
- Format erreur : `❌ Erreur création stock initial pour REF001: [détail]`

## 📈 Avantages

1. **Gain de temps** : Import en une seule opération
2. **Cohérence** : Mouvements de stock automatiques et traçables
3. **Simplicité** : Interface utilisateur intuitive
4. **Flexibilité** : Gestion optionnelle des quantités initiales
5. **Traçabilité** : Historique complet des mouvements

## 🔄 Intégration avec les autres modules

### Module Inventaire
- Création automatique des mouvements de stock
- Mise à jour des quantités disponibles
- Respect des règles de gestion des stocks

### Module Produits
- Import standard des informations produit
- Validation des données avant création
- Gestion des doublons par référence

### Module Rapports
- Les mouvements apparaissent dans l'historique
- Traçabilité complète des stocks initiaux
- Possibilité d'export des mouvements

Cette fonctionnalité simplifie grandement la mise en place initiale d'un inventaire complet lors de l'adoption du système LOGESCO.