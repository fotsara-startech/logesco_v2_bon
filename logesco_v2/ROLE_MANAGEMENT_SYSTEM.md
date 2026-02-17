# 🔐 Système de gestion des rôles - LOGESCO v2

## 📋 Vue d'ensemble

Le système de gestion des rôles permet de créer et gérer des rôles utilisateur avec attribution granulaire des privilèges par module.

## 🏗️ Architecture

### **Modèle de données**
```dart
UserRole {
  int? id
  String nom                    // Code du rôle (ex: ADMIN, MANAGER)
  String displayName           // Nom d'affichage (ex: Administrateur)
  bool isAdmin                 // Rôle administrateur (accès complet)
  Map<String, List<String>> privileges  // Privilèges par module
  DateTime? dateCreation
  DateTime? dateModification
}
```

### **Structure des privilèges**
```json
{
  "dashboard": ["READ", "STATS"],
  "products": ["READ", "CREATE", "UPDATE", "DELETE"],
  "sales": ["READ", "CREATE", "UPDATE", "DELETE", "REFUND"],
  "users": ["READ", "CREATE", "UPDATE", "DELETE", "ROLES"]
}
```

## 🎯 Modules et privilèges disponibles

### **Modules système**
1. **Dashboard** - Tableau de bord
   - `READ` : Consultation
   - `STATS` : Statistiques

2. **Products** - Gestion des produits
   - `READ` : Consultation
   - `CREATE` : Création
   - `UPDATE` : Modification
   - `DELETE` : Suppression

3. **Categories** - Gestion des catégories
   - `READ`, `CREATE`, `UPDATE`, `DELETE`

4. **Inventory** - Gestion de l'inventaire
   - `READ`, `CREATE`, `UPDATE`, `DELETE`, `ADJUST`

5. **Suppliers** - Gestion des fournisseurs
   - `READ`, `CREATE`, `UPDATE`, `DELETE`

6. **Customers** - Gestion des clients
   - `READ`, `CREATE`, `UPDATE`, `DELETE`

7. **Sales** - Gestion des ventes
   - `READ`, `CREATE`, `UPDATE`, `DELETE`, `REFUND`

8. **Procurement** - Approvisionnement
   - `READ`, `CREATE`, `UPDATE`, `DELETE`, `RECEIVE`

9. **Accounts** - Gestion des comptes
   - `READ`, `CREATE`, `UPDATE`, `DELETE`, `TRANSACTIONS`

10. **Financial Movements** - Mouvements financiers
    - `READ`, `CREATE`, `UPDATE`, `DELETE`, `REPORTS`

11. **Cash Registers** - Gestion des caisses
    - `READ`, `CREATE`, `UPDATE`, `DELETE`, `OPEN`, `CLOSE`

12. **Stock Inventory** - Inventaire de stock
    - `READ`, `CREATE`, `UPDATE`, `DELETE`, `COUNT`

13. **Users** - Gestion des utilisateurs
    - `READ`, `CREATE`, `UPDATE`, `DELETE`, `ROLES`

14. **Company Settings** - Paramètres entreprise
    - `READ`, `UPDATE`

15. **Printing** - Impression
    - `READ`, `PRINT`, `REPRINT`

16. **Reports** - Rapports
    - `READ`, `EXPORT`

## 🎨 Interface utilisateur

### **Page de liste des rôles** (`/roles`)
- ✅ Affichage des rôles avec statistiques
- ✅ Création, modification, suppression
- ✅ Visualisation des détails et privilèges
- ✅ Recherche et filtrage

### **Formulaire de création/modification**
- ✅ Informations de base (nom, nom d'affichage)
- ✅ Type de rôle (Admin/Standard)
- ✅ Attribution granulaire des privilèges par module
- ✅ Interface intuitive avec chips et expansion tiles
- ✅ Sélection/désélection en masse

### **Fonctionnalités avancées**
- ✅ Validation des noms uniques
- ✅ Protection contre la suppression de rôles utilisés
- ✅ Gestion des erreurs et feedback utilisateur
- ✅ Responsive design

## 🔧 API Endpoints

### **Rôles**
- `GET /api/v1/roles` - Liste des rôles
- `GET /api/v1/roles/:id` - Détails d'un rôle
- `POST /api/v1/roles` - Création d'un rôle
- `PUT /api/v1/roles/:id` - Modification d'un rôle
- `DELETE /api/v1/roles/:id` - Suppression d'un rôle

### **Format de données API**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "nom": "MANAGER",
    "displayName": "Gestionnaire",
    "isAdmin": false,
    "privileges": "{\"products\":[\"READ\",\"CREATE\"],\"sales\":[\"READ\",\"CREATE\"]}",
    "dateCreation": "2024-01-01T00:00:00Z",
    "dateModification": "2024-01-01T00:00:00Z"
  }
}
```

## 🚀 Utilisation

### **1. Accès à la gestion des rôles**
```dart
// Navigation vers la page des rôles
Get.toNamed(AppRoutes.roles);
```

### **2. Vérification des privilèges**
```dart
// Vérifier un privilège spécifique
bool canCreateProducts = role.hasPrivilege('products', 'CREATE');

// Vérifier tous les privilèges d'un module
bool hasAllProductsAccess = role.hasAllPrivileges('products');

// Obtenir les privilèges d'un module
List<String> productPrivileges = role.getModulePrivileges('products');
```

### **3. Création d'un rôle**
```dart
final newRole = UserRole(
  nom: 'CASHIER',
  displayName: 'Caissier',
  isAdmin: false,
  privileges: {
    'dashboard': ['READ'],
    'sales': ['READ', 'CREATE'],
    'cash_registers': ['READ', 'OPEN', 'CLOSE'],
  },
);

await roleController.createRole(newRole);
```

## 🔒 Sécurité

### **Contrôles d'accès**
- ✅ Middleware d'authentification sur toutes les routes
- ✅ Validation des privilèges côté serveur
- ✅ Protection contre les modifications non autorisées

### **Validation des données**
- ✅ Noms de rôles uniques
- ✅ Privilèges valides par module
- ✅ Vérification des dépendances avant suppression

## 📊 Statistiques

Le système fournit des statistiques en temps réel :
- Nombre total de rôles
- Rôles administrateurs vs standard
- Répartition des privilèges par module

## 🎯 Prochaines étapes

1. **Intégration avec le système d'authentification**
2. **Audit trail des modifications de rôles**
3. **Templates de rôles prédéfinis**
4. **Import/Export des configurations de rôles**
5. **Interface de test des privilèges**

## 📝 Notes techniques

- Les privilèges sont stockés en JSON dans la base de données
- Le système supporte l'héritage de privilèges (Admin = tous les privilèges)
- Interface responsive compatible mobile/desktop
- Gestion d'état avec GetX pour la réactivité
- Validation côté client et serveur