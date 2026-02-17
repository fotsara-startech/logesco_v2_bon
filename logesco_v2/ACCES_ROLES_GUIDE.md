# 🔐 Guide d'accès à la gestion des rôles

## 🎯 Méthodes d'accès aux rôles

### **1. 📱 Depuis le menu principal (Dashboard)**
1. Ouvrir l'application LOGESCO v2
2. Dans le menu latéral (drawer), aller à la section **ADMINISTRATION**
3. Cliquer sur **"Rôles"** (icône 🛡️)

### **2. 👥 Depuis la gestion des utilisateurs**
1. Aller dans **Gestion des Utilisateurs**
2. Dans l'AppBar, cliquer sur l'icône **🛡️** (Gérer les rôles)

### **3. 💻 Navigation directe par code**
```dart
// Depuis n'importe où dans l'application
Get.toNamed(AppRoutes.roles);
// ou
Get.toNamed('/roles');
```

### **4. 🌐 URL directe**
Si vous utilisez la version web : `http://localhost/roles`

## 🛡️ Permissions requises

Pour accéder à la gestion des rôles, l'utilisateur doit avoir :
- **Rôle administrateur** OU
- **Permission `users.manage`** OU  
- **Permission `roles.manage`**

## 📋 Fonctionnalités disponibles

Une fois dans la gestion des rôles, vous pouvez :

### **📊 Vue d'ensemble**
- Voir tous les rôles existants
- Statistiques (Total, Admin, Standard)
- Recherche et filtrage

### **➕ Création de rôle**
1. Cliquer sur le bouton **"+"** (FloatingActionButton)
2. Remplir les informations de base :
   - **Nom du rôle** (ex: MANAGER, EMPLOYEE)
   - **Nom d'affichage** (ex: Gestionnaire, Employé)
3. Choisir le **type de rôle** :
   - **Administrateur** : Accès complet automatique
   - **Standard** : Sélection manuelle des privilèges
4. **Attribution des privilèges par module** (si Standard) :
   - Dashboard, Produits, Catégories, Inventaire
   - Fournisseurs, Clients, Ventes, Approvisionnement
   - Comptes, Mouvements financiers, Caisses
   - Inventaire de stock, Utilisateurs, Paramètres
   - Impression, Rapports

### **✏️ Modification de rôle**
1. Cliquer sur un rôle dans la liste
2. Sélectionner **"Modifier"** dans le menu
3. Ajuster les privilèges selon les besoins

### **👁️ Visualisation des détails**
- Cliquer sur un rôle pour voir tous ses privilèges
- Affichage organisé par module
- Privilèges sous forme de chips colorés

### **🗑️ Suppression de rôle**
- Sélectionner **"Supprimer"** dans le menu du rôle
- ⚠️ **Protection** : Impossible de supprimer un rôle utilisé par des utilisateurs

## 🎨 Interface utilisateur

### **🏠 Page principale (`/roles`)**
- Liste des rôles avec cartes informatives
- Statistiques en temps réel
- Actions rapides (Créer, Modifier, Supprimer)

### **📝 Formulaire de création/modification**
- Interface intuitive avec sections organisées
- Sélection des privilèges par chips interactifs
- Boutons de sélection/désélection en masse
- Validation en temps réel

### **🔍 Détails d'un rôle**
- Vue complète des privilèges par module
- Informations de création/modification
- Actions rapides (Modifier, Supprimer)

## 🚀 Raccourcis clavier

- **Échap** : Fermer les dialogues
- **Entrée** : Valider les formulaires
- **Tab** : Navigation entre les champs

## 📱 Responsive Design

L'interface s'adapte automatiquement :
- **Desktop** : Interface complète avec sidebar
- **Tablet** : Interface adaptée avec navigation optimisée  
- **Mobile** : Interface compacte avec navigation tactile

## 🔧 Dépannage

### **❌ "Accès refusé"**
- Vérifier que votre rôle a les permissions nécessaires
- Contacter un administrateur pour obtenir les droits

### **❌ "Page non trouvée"**
- Vérifier que les routes sont bien configurées
- Redémarrer l'application si nécessaire

### **❌ "Erreur de chargement"**
- Vérifier la connexion au serveur API
- Actualiser la page avec le bouton refresh

## 📞 Support

Pour toute question ou problème :
1. Consulter la documentation technique
2. Vérifier les logs de l'application
3. Contacter l'équipe de développement