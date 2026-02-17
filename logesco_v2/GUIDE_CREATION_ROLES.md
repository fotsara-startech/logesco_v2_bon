# Guide de Création des Rôles

## 🧹 Nettoyage des rôles prédéfinis (si nécessaire)

Si vous voyez des rôles prédéfinis (ADMIN, MANAGER, EMPLOYEE, CASHIER, VIEWER), vous devez d'abord les supprimer :

### Option 1 : Script automatique (recommandé)
```powershell
cd logesco_v2
./clean_predefined_roles.ps1
```

### Option 2 : Script SQL manuel
1. Ouvrez votre gestionnaire de base de données
2. Exécutez le script `clean_predefined_roles.sql`

## 📋 Première utilisation

Après le nettoyage, aucun rôle n'existe en base de données. Vous devez créer manuellement les rôles nécessaires pour votre organisation.

## 🔧 Comment créer un rôle

### 1. Accéder à la gestion des rôles
- Connectez-vous à l'application
- Allez dans **Gestion des Utilisateurs**
- Cliquez sur l'icône **Gérer les rôles** (⚙️) dans la barre d'actions

### 2. Créer un nouveau rôle
- Cliquez sur le bouton **"+"** (Nouveau rôle)
- Remplissez les informations :
  - **Nom du rôle** : Identifiant unique (ex: ADMIN, MANAGER)
  - **Nom d'affichage** : Nom lisible (ex: Administrateur, Gestionnaire)
  - **Type de rôle** : Administrateur ou Standard

### 3. Configurer les privilèges
Pour un rôle **Standard**, sélectionnez les privilèges par module :

#### Modules disponibles :
- **Utilisateurs** : Gestion des comptes utilisateurs
- **Produits** : Gestion du catalogue produits
- **Ventes** : Opérations de vente
- **Inventaire** : Gestion des stocks
- **Rapports** : Consultation et export des rapports
- **Caisses** : Gestion des caisses enregistreuses
- **Paramètres** : Configuration de l'entreprise
- **Mouvements financiers** : Gestion financière

#### Privilèges par module :
- **Lecture** : Consulter les données
- **Création** : Ajouter de nouveaux éléments
- **Modification** : Modifier les éléments existants
- **Suppression** : Supprimer des éléments
- **Privilèges spéciaux** : Actions spécifiques au module

## 🎯 Rôles recommandés

### Administrateur
- **Type** : Administrateur
- **Privilèges** : Accès complet automatique

### Gestionnaire
- **Modules** : Produits, Ventes, Inventaire, Rapports, Caisses
- **Privilèges** : Lecture, Création, Modification, Suppression

### Caissier
- **Modules** : Ventes, Caisses
- **Privilèges** : Lecture, Création (ventes)

### Gestionnaire de Stock
- **Modules** : Produits, Inventaire
- **Privilèges** : Lecture, Création, Modification, Ajustement

## ⚠️ Important

1. **Créez d'abord un rôle Administrateur** pour avoir accès complet
2. **Assignez ce rôle à votre compte** via la gestion des utilisateurs
3. **Créez ensuite les autres rôles** selon vos besoins
4. **Testez les privilèges** avant de les assigner aux utilisateurs

## 🔒 Sécurité

- Limitez le nombre d'administrateurs
- Donnez seulement les privilèges nécessaires à chaque rôle
- Révisez régulièrement les privilèges accordés
- Désactivez les comptes inutilisés

## 🆘 Dépannage

**Problème** : "Aucun rôle trouvé"
**Solution** : Créez au moins un rôle via l'interface de gestion des rôles

**Problème** : "Accès refusé"
**Solution** : Vérifiez que votre compte a les privilèges nécessaires

**Problème** : "Impossible de créer un utilisateur"
**Solution** : Assurez-vous qu'au moins un rôle existe en base de données