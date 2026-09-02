# Guide de test - Permissions Fournisseurs et Approvisionnement

## Vue d'ensemble

Ce guide permet de tester les contrôles de permissions nouvellement implémentés pour les modules Fournisseurs et Approvisionnement.

## Permissions implémentées

### Module Fournisseurs (`suppliers`)
- **READ** : Voir la liste des fournisseurs
- **CREATE** : Créer de nouveaux fournisseurs
- **UPDATE** : Modifier les fournisseurs existants
- **DELETE** : Supprimer des fournisseurs

### Module Approvisionnement (`procurement`)
- **READ** : Voir la liste des commandes d'approvisionnement
- **CREATE** : Créer de nouvelles commandes
- **UPDATE** : Modifier/annuler des commandes
- **DELETE** : Supprimer des commandes
- **RECEIVE** : Réceptionner des commandes

## Scénarios de test

### 1. Test avec utilisateur administrateur

**Résultat attendu** : Accès complet à toutes les fonctionnalités

1. Se connecter en tant qu'administrateur
2. Aller dans Fournisseurs
   - ✅ Liste visible
   - ✅ Bouton "Ajouter" visible
   - ✅ Actions "Modifier" et "Supprimer" disponibles
3. Aller dans Approvisionnement
   - ✅ Liste visible
   - ✅ Bouton "Nouvelle commande" visible
   - ✅ Actions "Réceptionner" et "Annuler" disponibles

### 2. Test avec utilisateur sans privilèges

**Configuration** : Créer un rôle "Lecture seule" sans privilèges sur suppliers/procurement

1. Se connecter avec cet utilisateur
2. Essayer d'accéder aux Fournisseurs
   - ❌ Page d'accès refusé affichée
   - ❌ Message : "Vous n'avez pas les privilèges nécessaires"
3. Essayer d'accéder à l'Approvisionnement
   - ❌ Page d'accès refusé affichée
   - ❌ Message : "Vous n'avez pas les privilèges nécessaires"

### 3. Test avec privilèges partiels - Lecture seule

**Configuration** : Rôle avec privilèges `suppliers.READ` et `procurement.READ`

1. Se connecter avec cet utilisateur
2. Aller dans Fournisseurs
   - ✅ Liste visible
   - ❌ Bouton "Ajouter" masqué
   - ❌ Actions "Modifier" et "Supprimer" masquées
3. Aller dans Approvisionnement
   - ✅ Liste visible
   - ❌ Bouton "Nouvelle commande" masqué
   - ❌ Actions "Réceptionner" et "Annuler" masquées

### 4. Test avec privilèges de création

**Configuration** : Rôle avec privilèges `suppliers.READ,CREATE` et `procurement.READ,CREATE`

1. Se connecter avec cet utilisateur
2. Aller dans Fournisseurs
   - ✅ Liste visible
   - ✅ Bouton "Ajouter" visible
   - ❌ Actions "Modifier" et "Supprimer" masquées
3. Aller dans Approvisionnement
   - ✅ Liste visible
   - ✅ Bouton "Nouvelle commande" visible
   - ❌ Actions "Réceptionner" et "Annuler" masquées

### 5. Test avec privilèges complets

**Configuration** : Rôle avec tous les privilèges `suppliers.*` et `procurement.*`

1. Se connecter avec cet utilisateur
2. Aller dans Fournisseurs
   - ✅ Liste visible
   - ✅ Bouton "Ajouter" visible
   - ✅ Actions "Modifier" et "Supprimer" disponibles
3. Aller dans Approvisionnement
   - ✅ Liste visible
   - ✅ Bouton "Nouvelle commande" visible
   - ✅ Actions "Réceptionner" et "Annuler" disponibles

## Configuration des rôles de test

### Rôle "Lecture seule"
```json
{
  "nom": "lecture_seule",
  "displayName": "Lecture seule",
  "privileges": {
    "suppliers": ["READ"],
    "procurement": ["READ"]
  }
}
```

### Rôle "Gestionnaire fournisseurs"
```json
{
  "nom": "gestionnaire_fournisseurs",
  "displayName": "Gestionnaire Fournisseurs",
  "privileges": {
    "suppliers": ["READ", "CREATE", "UPDATE", "DELETE"],
    "procurement": ["READ"]
  }
}
```

### Rôle "Gestionnaire approvisionnement"
```json
{
  "nom": "gestionnaire_appro",
  "displayName": "Gestionnaire Approvisionnement",
  "privileges": {
    "suppliers": ["READ"],
    "procurement": ["READ", "CREATE", "UPDATE", "RECEIVE"]
  }
}
```

### Rôle "Réceptionnaire"
```json
{
  "nom": "receptionnaire",
  "displayName": "Réceptionnaire",
  "privileges": {
    "suppliers": ["READ"],
    "procurement": ["READ", "RECEIVE"]
  }
}
```

## Messages d'erreur attendus

### Accès refusé au module
```
Titre: "Accès refusé"
Message: "Vous n'avez pas les privilèges nécessaires pour accéder à la gestion des [fournisseurs/approvisionnements]"
```

### Action non autorisée
```
Titre: "Accès refusé"
Message: "Vous n'avez pas l'autorisation de [créer/modifier/supprimer] des [fournisseurs/commandes]"
```

## Interface utilisateur

### Éléments masqués selon les permissions

**Fournisseurs** :
- Bouton "+" dans l'AppBar (CREATE)
- FloatingActionButton "Ajouter" (CREATE)
- Bouton "Modifier" sur les cartes (UPDATE)
- Bouton "Supprimer" sur les cartes (DELETE)

**Approvisionnement** :
- FloatingActionButton "Nouvelle commande" (CREATE)
- Bouton "Réceptionner" sur les cartes (RECEIVE)
- Bouton "Annuler" sur les cartes (UPDATE)

### Éléments toujours visibles
- Liste des éléments (si READ)
- Bouton "Actualiser"
- Barre de recherche (fournisseurs)
- Statistiques (approvisionnement)

## Dépannage

### Problèmes courants

1. **Permissions non appliquées** :
   - Vérifier que l'utilisateur a un rôle assigné
   - Vérifier le format JSON des privilèges
   - Redémarrer l'application

2. **Erreur "AuthController non trouvé"** :
   - Vérifier que l'utilisateur est connecté
   - Redémarrer l'application

3. **Interface incohérente** :
   - Vérifier les privilèges en base de données
   - Tester avec un utilisateur admin

### Logs utiles

```dart
// Dans le mixin PermissionMixin
print('⚠️ Erreur lors de la récupération du rôle utilisateur: $e');

// Vérification des privilèges
print('Privilèges utilisateur: ${currentUserRole?.privileges}');
print('Module suppliers - READ: ${hasPermission('suppliers', 'READ')}');
```

## Validation finale

### Checklist de validation

- [ ] Administrateur : Accès complet aux deux modules
- [ ] Utilisateur sans privilège : Accès refusé aux deux modules
- [ ] Utilisateur lecture seule : Voir mais pas modifier
- [ ] Utilisateur avec privilèges partiels : Actions limitées
- [ ] Messages d'erreur appropriés
- [ ] Interface cohérente avec les permissions
- [ ] Pas de régression sur les autres modules

### Critères de succès

1. **Sécurité** : Aucun accès non autorisé possible
2. **Ergonomie** : Interface claire selon les permissions
3. **Performance** : Pas de ralentissement notable
4. **Compatibilité** : Autres modules non affectés

## Conclusion

Les contrôles de permissions sont maintenant implémentés pour les modules Fournisseurs et Approvisionnement. Ils garantissent que seuls les utilisateurs autorisés peuvent accéder aux fonctionnalités selon leurs privilèges définis.