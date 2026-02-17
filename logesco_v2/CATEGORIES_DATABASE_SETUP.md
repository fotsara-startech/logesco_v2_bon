# Configuration Base de Données - Catégories

## 🗄️ Création de la table categories

### Étape 1: Exécuter la migration

1. **Ouvrir un terminal** dans le dossier `logesco_v2/database`
2. **Exécuter le script de migration** :
   ```bash
   run_categories_migration.bat
   ```

### Étape 2: Vérifier la création

Le script va :
- ✅ Créer la table `categories` avec les colonnes :
  - `id` (clé primaire auto-incrémentée)
  - `nom` (varchar 100, unique)
  - `description` (text, optionnel)
  - `dateCreation` (datetime, auto)
  - `dateModification` (datetime, auto avec trigger)
- ✅ Insérer 5 catégories par défaut
- ✅ Créer les index pour les performances
- ✅ Créer un trigger pour la mise à jour automatique

### Étape 3: Démarrer le backend

1. **S'assurer que le serveur backend est démarré** sur `http://localhost:3002`
2. **Vérifier que l'endpoint `/api/v1/categories` existe**

## 🔧 Configuration côté Flutter

### Modifications apportées :
- ✅ `CategoryBinding` utilise maintenant `CategoryService` (API réelle)
- ✅ `CategoryController` connecté au vrai service
- ✅ Service mock désactivé

### Structure de la table :
```sql
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    dateCreation DATETIME DEFAULT CURRENT_TIMESTAMP,
    dateModification DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 🧪 Test de l'intégration

### 1. Vérifier la base de données
```bash
sqlite3 logesco.db "SELECT * FROM categories;"
```

### 2. Tester l'API backend
```bash
curl http://localhost:3002/api/v1/categories
```

### 3. Tester l'application Flutter
1. Redémarrer l'application Flutter
2. Naviguer vers les catégories depuis le dashboard
3. Vérifier que les données de la base s'affichent
4. Tester l'ajout d'une nouvelle catégorie

## 📊 Données par défaut

Les catégories suivantes seront créées automatiquement :
1. **Smartphones** - Téléphones intelligents et accessoires mobiles
2. **Ordinateurs** - PC, laptops et composants informatiques  
3. **Accessoires** - Câbles, chargeurs et autres accessoires électroniques
4. **Écrans** - Moniteurs et écrans pour ordinateurs
5. **Audio** - Casques, écouteurs et équipements audio

## 🚨 Dépannage

### Erreur "ApiService not found"
- Vérifier que `InitialBindings` est activé dans `main.dart`
- S'assurer que le backend est démarré

### Erreur de connexion réseau
- Vérifier l'URL du backend : `http://localhost:3002/api/v1`
- Tester l'endpoint avec curl ou Postman

### Base de données non trouvée
- Exécuter le script de migration
- Vérifier que `logesco.db` existe dans le dossier database