# Guide d'utilisation - Antidatage des ventes

## Vue d'ensemble

La fonctionnalité d'antidatage permet aux utilisateurs autorisés de créer des ventes avec une date antérieure à la date actuelle. Cette fonctionnalité est utile pour :

- Enregistrer des ventes qui ont eu lieu dans le passé mais qui n'ont pas été saisies immédiatement
- Corriger des erreurs de saisie de date
- Maintenir un historique précis des ventes

## Privilèges requis

### Nouveau privilège : BACKDATE

Un nouveau privilège `BACKDATE` a été ajouté au module `sales`. Seuls les utilisateurs ayant ce privilège peuvent antidater les ventes.

**Configuration des rôles :**
- **Administrateurs** : Ont automatiquement accès à toutes les fonctionnalités, y compris l'antidatage
- **Autres rôles** : Doivent avoir explicitement le privilège `sales.BACKDATE`

## Interface utilisateur

### 1. Accès à la fonctionnalité

La sélection de date personnalisée apparaît dans le dialogue de finalisation de vente, uniquement si l'utilisateur a les privilèges nécessaires.

### 2. Sélection de date

- **Icône** : Calendrier orange pour indiquer la fonctionnalité spéciale
- **Restriction** : Seules les dates antérieures ou égales à aujourd'hui sont autorisées
- **Par défaut** : Si aucune date n'est sélectionnée, la date actuelle est utilisée

### 3. Interface

```
🗓️ Date de vente personnalisée
┌─────────────────────────────────────────────────────────┐
│ ℹ️ Vous pouvez antidater cette vente (date antérieure)  │
│                                                         │
│ 📅 [Date actuelle (12/12/2025)] [❌]                   │
└─────────────────────────────────────────────────────────┘
```

## Fonctionnement technique

### 1. Validation côté client

- Vérification des privilèges utilisateur
- Interface masquée si pas de privilège
- Validation de la date sélectionnée

### 2. Validation côté serveur

```javascript
// Vérification des privilèges d'antidatage
if (dateVente && customDate < today) {
  const hasBackdatePrivilege = user.isAdmin || 
    (user.role?.privileges?.sales?.includes('BACKDATE'));
  
  if (!hasBackdatePrivilege) {
    return res.status(403).json({
      message: 'Vous n\'avez pas l\'autorisation d\'antidater les ventes'
    });
  }
}
```

### 3. Stockage

La date personnalisée est stockée dans le champ `dateVente` de la table `vente`.

## Configuration des rôles

### Ajouter le privilège BACKDATE à un rôle

1. **Via l'interface d'administration** :
   - Aller dans Gestion des utilisateurs > Rôles
   - Sélectionner le rôle à modifier
   - Dans la section "Ventes", cocher "Antidater"

2. **Via l'API** :
```json
{
  "privileges": {
    "sales": ["READ", "CREATE", "UPDATE", "DELETE", "BACKDATE"]
  }
}
```

### Exemples de configuration

**Gestionnaire avec antidatage :**
```json
{
  "nom": "gestionnaire_complet",
  "displayName": "Gestionnaire Complet",
  "privileges": {
    "sales": ["READ", "CREATE", "UPDATE", "BACKDATE"],
    "products": ["READ", "CREATE", "UPDATE"],
    "reports": ["READ", "EXPORT"]
  }
}
```

**Vendeur sans antidatage :**
```json
{
  "nom": "vendeur_standard",
  "displayName": "Vendeur Standard",
  "privileges": {
    "sales": ["READ", "CREATE"],
    "products": ["READ"]
  }
}
```

## Sécurité et contrôles

### 1. Contrôles d'accès

- **Authentification** : Utilisateur connecté requis
- **Autorisation** : Privilège `sales.BACKDATE` requis
- **Validation** : Date ne peut pas être dans le futur

### 2. Audit et traçabilité

- Toutes les ventes antidatées sont enregistrées avec l'ID du vendeur
- Les logs système enregistrent les tentatives d'antidatage
- L'historique des modifications est conservé

### 3. Limitations

- **Date limite** : Pas de limite inférieure (peut être configurée si nécessaire)
- **Date future** : Interdite
- **Modification** : Une fois créée, la date ne peut plus être modifiée

## Messages d'erreur

### Erreurs courantes

1. **Privilège insuffisant** :
   ```
   "Vous n'avez pas l'autorisation d'antidater les ventes"
   ```

2. **Date invalide** :
   ```
   "La date de vente ne peut pas être dans le futur"
   ```

3. **Utilisateur non authentifié** :
   ```
   "Utilisateur non authentifié"
   ```

## Test de la fonctionnalité

### Script de test automatisé

Un script de test `test-backdate-sales.dart` est disponible pour vérifier :

1. Connexion utilisateur avec privilèges
2. Vérification des privilèges
3. Création de vente antidatée
4. Test avec utilisateur sans privilège

### Test manuel

1. **Prérequis** :
   - Utilisateur avec privilège `sales.BACKDATE`
   - Produits disponibles en stock

2. **Étapes** :
   - Créer une nouvelle vente
   - Ajouter des produits au panier
   - Cliquer sur "Finaliser la vente"
   - Sélectionner une date antérieure
   - Confirmer la vente

3. **Vérification** :
   - La vente apparaît avec la date sélectionnée
   - L'historique des ventes reflète la bonne date

## Bonnes pratiques

### 1. Attribution des privilèges

- **Principe du moindre privilège** : N'accorder l'antidatage qu'aux utilisateurs qui en ont besoin
- **Rôles spécialisés** : Créer des rôles spécifiques pour les gestionnaires
- **Révision régulière** : Vérifier périodiquement les privilèges accordés

### 2. Utilisation

- **Documentation** : Justifier les ventes antidatées
- **Cohérence** : Maintenir la chronologie logique des opérations
- **Vérification** : Double-vérifier les dates avant validation

### 3. Monitoring

- **Surveillance** : Monitorer l'utilisation de l'antidatage
- **Alertes** : Configurer des alertes pour les antidatages fréquents
- **Rapports** : Générer des rapports sur les ventes antidatées

## Dépannage

### Problèmes courants

1. **Interface non visible** :
   - Vérifier les privilèges utilisateur
   - Redémarrer l'application
   - Vérifier la connexion

2. **Erreur de validation** :
   - Vérifier le format de date
   - Confirmer que la date n'est pas future
   - Vérifier les privilèges serveur

3. **Vente non créée** :
   - Vérifier les logs serveur
   - Confirmer la disponibilité des produits
   - Vérifier la connexion réseau

### Logs utiles

```bash
# Logs d'authentification
grep "BACKDATE" backend/logs/auth.log

# Logs de ventes
grep "dateVente" backend/logs/sales.log

# Logs d'erreurs
grep "antidater" backend/logs/error.log
```

## Conclusion

La fonctionnalité d'antidatage des ventes offre une flexibilité importante pour la gestion des ventes tout en maintenant des contrôles de sécurité stricts. Elle permet une meilleure précision dans l'enregistrement des transactions historiques.

Pour toute question ou problème, consulter les logs système ou contacter l'administrateur système.