# Comment Activer la Synchronisation des Mouvements Financiers

## Contexte

Par défaut, `financial_movements` et `cash_movements` ne sont PAS synchronisés car ce sont des tables internes. Cependant, si vous avez besoin de partager ces données entre utilisateurs, voici comment activer la synchronisation.

## Pourquoi c'est désactivé par défaut

1. **Confidentialité**: Les dépenses d'une boutique ne regardent pas les autres
2. **Isolation**: Chaque boutique gère sa propre comptabilité
3. **Performance**: Moins de données = synchronisation plus rapide
4. **Redondance**: Le solde de la caisse (`cash_sessions`) est déjà synchronisé

## Cas d'usage pour activer la sync

Vous devriez activer la synchronisation si:

- ✅ Vous avez un système de comptabilité centralisé
- ✅ Plusieurs utilisateurs doivent voir les mêmes mouvements financiers
- ✅ Vous voulez un historique partagé des dépenses
- ✅ Vous avez besoin de rapports consolidés en temps réel

Vous ne devriez PAS activer si:

- ❌ Chaque boutique est indépendante
- ❌ Les dépenses sont confidentielles
- ❌ Vous voulez minimiser le trafic réseau

## Comment Activer

### Étape 1: Modifier le Middleware de Sync

**Fichier**: `backend/src/middleware/sync-middleware.js`

**Avant**:
```javascript
'/financial-movements': { 
  table: 'financial_movements', model: 'financialMovement',
  skip: true  // ← Désactivé
},
```

**Après**:
```javascript
'/financial-movements': { 
  table: 'financial_movements', model: 'financialMovement',
  allowedColumns: [
    'id','reference','sessionId','boutiqueId','montant','categorieId',
    'description','date','utilisateurId','notes','dateCreation','dateModification'
  ]
  // skip: true  ← Commenté ou supprimé
},
```

### Étape 2: Ajouter financial_movements au Pull

**Fichier**: `backend/src/services/sync-service.js`

**Avant**:
```javascript
const PULL_TABLES = [
  'user_roles',
  'utilisateurs',
  'boutiques',
  'categories',
  'produits',
  'stock',
  'stock_boutiques',
  'fournisseurs',
  'clients',
  'cash_registers',
  'cash_sessions',
  'ventes',
  'details_ventes',
  'mouvements_stock',
];
```

**Après**:
```javascript
const PULL_TABLES = [
  'user_roles',
  'utilisateurs',
  'boutiques',
  'categories',
  'produits',
  'stock',
  'stock_boutiques',
  'fournisseurs',
  'clients',
  'cash_registers',
  'cash_sessions',
  'financial_movements',  // ← Ajouté
  'ventes',
  'details_ventes',
  'mouvements_stock',
];
```

### Étape 3: Ajouter à l'ordre de sync dans _pushLocalToCloud

**Fichier**: `backend/src/services/sync-service.js`

Dans la méthode `_pushLocalToCloud()`, ajoutez `financial_movements` dans l'ordre:

```javascript
async _pushLocalToCloud() {
  const pending = await this.localPrisma.$queryRawUnsafe(
    `SELECT * FROM sync_queue WHERE synced = 0 ORDER BY
     CASE table_name
       WHEN 'user_roles' THEN 1
       WHEN 'utilisateurs' THEN 2
       WHEN 'boutiques' THEN 3
       WHEN 'categories' THEN 4
       WHEN 'produits' THEN 5
       WHEN 'cash_registers' THEN 6
       WHEN 'cash_sessions' THEN 7
       WHEN 'clients' THEN 8
       WHEN 'fournisseurs' THEN 9
       WHEN 'financial_movements' THEN 10  // ← Ajouté
       WHEN 'ventes' THEN 11
       ELSE 20
     END, id ASC LIMIT 100`
  );
  // ...
}
```

### Étape 4: Redémarrer le Backend

```bash
# Arrêter le backend
# Redémarrer:
npm start
```

### Étape 5: Vérifier

```bash
# Créer une dépense dans l'app
# Vérifier la queue:
node debug-sync-queue.js

# Devrait montrer:
# financial_movements (INSERT): X synced
```

## Impact de l'Activation

### Avantages
- ✅ Historique partagé des mouvements financiers
- ✅ Rapports consolidés en temps réel
- ✅ Visibilité complète pour tous les utilisateurs

### Inconvénients
- ⚠️ Plus de données à synchroniser (plus lent)
- ⚠️ Perte de confidentialité entre boutiques
- ⚠️ Plus de trafic réseau

## Alternative: Synchronisation Sélective

Si vous voulez synchroniser seulement certains mouvements financiers (par exemple, seulement pour une boutique spécifique), vous pouvez modifier le middleware pour filtrer:

```javascript
'/financial-movements': { 
  table: 'financial_movements', 
  model: 'financialMovement',
  allowedColumns: [...],
  filter: (data) => {
    // Synchroniser seulement si boutiqueId = 7 (par exemple)
    return data.boutiqueId === 7;
  }
},
```

## Recommandation

**Pour la plupart des cas d'usage, il est préférable de NE PAS synchroniser financial_movements.**

Le solde de la caisse (`cash_sessions`) est déjà synchronisé, ce qui suffit pour:
- Voir l'état de la caisse en temps réel
- Savoir combien d'argent est disponible
- Éviter les conflits entre utilisateurs

Les mouvements financiers restent locaux, ce qui:
- Protège la confidentialité
- Réduit le trafic réseau
- Simplifie la gestion des données

## Conclusion

La synchronisation des mouvements financiers est désactivée par défaut pour de bonnes raisons. Si vous avez vraiment besoin de cette fonctionnalité, suivez les étapes ci-dessus, mais soyez conscient des implications en termes de confidentialité et de performance.

---

**Status**: Documentation complète pour activer la sync si nécessaire
