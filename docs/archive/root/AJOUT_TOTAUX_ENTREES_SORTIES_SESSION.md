# Ajout des totaux d'entrées et de sorties dans les détails de session

## Fonctionnalité ajoutée

Dans les détails de la session de caisse, affichage de :
- **Total entrées** : Somme de tous les montants réellement perçus (ventes + paiements clients) durant la session
- **Total dépenses** : Somme de toutes les dépenses (mouvements de sortie) durant la session

## Modifications apportées

### 1. Backend - Calcul des totaux

**Fichier** : `backend/src/routes/cash-sessions.js`

Modification de la route `GET /api/v1/cash-sessions/history` pour calculer les totaux :

```javascript
// Calculer les entrées (ventes + paiements clients)
const entrees = await prisma.cashMovement.aggregate({
  where: {
    caisseId: session.caisseId,
    dateCreation: {
      gte: session.dateOuverture,
      ...(session.dateFermeture ? { lte: session.dateFermeture } : {})
    },
    type: { in: ['entree', 'vente'] }
  },
  _sum: {
    montant: true
  }
});

// Calculer les sorties (dépenses)
const sorties = await prisma.cashMovement.aggregate({
  where: {
    caisseId: session.caisseId,
    dateCreation: {
      gte: session.dateOuverture,
      ...(session.dateFermeture ? { lte: session.dateFermeture } : {})
    },
    type: 'sortie'
  },
  _sum: {
    montant: true
  }
});
```

Les totaux sont ajoutés à la réponse :
```javascript
{
  ...session,
  totalEntrees: entrees._sum.montant ? parseFloat(entrees._sum.montant) : 0,
  totalSorties: sorties._sum.montant ? parseFloat(sorties._sum.montant) : 0
}
```

### 2. Frontend - Modèle CashSession

**Fichier** : `logesco_v2/lib/features/cash_registers/models/cash_session_model.dart`

Ajout des champs :
```dart
final double totalEntrees;
final double totalSorties;
```

Mise à jour du constructeur et des méthodes `fromJson`, `toJson`, et `copyWith`.

### 3. Frontend - Affichage dans les détails

**Fichier** : `logesco_v2/lib/features/cash_registers/views/cash_session_history_view.dart`

Ajout de deux sections dans le dialog des détails :

1. **Total entrées** (vert) :
   - Icône flèche vers le bas
   - Montant en vert
   - Fond vert clair

2. **Total dépenses** (rouge) :
   - Icône flèche vers le haut
   - Montant en rouge
   - Fond rouge clair

## Logique de calcul

### Entrées (type: 'entree' ou 'vente')
- Ventes au comptant
- Paiements de dettes clients
- Autres entrées d'argent

### Sorties (type: 'sortie')
- Paiements fournisseurs
- Dépenses diverses
- Retraits

### Période de calcul
- **Session ouverte** : De l'ouverture jusqu'à maintenant
- **Session fermée** : De l'ouverture à la fermeture

## Exemple d'affichage

```
┌─────────────────────────────────────┐
│ ℹ️  Détails de la session           │
├─────────────────────────────────────┤
│ Caisse: Caisse Principale           │
│ Utilisateur: admin                  │
│ ─────────────────────────────────── │
│ Ouverture: 28/02/2026 17:28        │
│ Fermeture: 01/03/2026 06:02        │
│ Durée: 12h 33min                    │
│ ─────────────────────────────────── │
│ Solde ouverture: 0 FCFA            │
│ Solde attendu: 15000 FCFA          │
│ Solde déclaré: 15000 FCFA          │
│ ─────────────────────────────────── │
│ ┌─────────────────────────────────┐ │
│ │ ↓ Total entrées:    3800 FCFA   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ↑ Total dépenses:      0 FCFA   │ │
│ └─────────────────────────────────┘ │
│ ─────────────────────────────────── │
│ ┌─────────────────────────────────┐ │
│ │ Écart:            +0 FCFA       │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Test de la fonctionnalité

### 1. Redémarrer le backend

```bash
restart-backend-with-cash-fix.bat
```

### 2. Ouvrir l'application Flutter

1. Aller dans "Historique des sessions"
2. Cliquer sur une session
3. Vérifier que les totaux s'affichent correctement

### 3. Vérifier les calculs

Pour une session avec :
- 2 ventes de 1000 FCFA chacune
- 1 paiement de dette de 800 FCFA
- 1 dépense de 500 FCFA

Les totaux devraient être :
- Total entrées : 2800 FCFA (1000 + 1000 + 800)
- Total dépenses : 500 FCFA
- Solde attendu : Solde ouverture + 2800 - 500

## Avantages

1. **Transparence** : Voir exactement combien d'argent est entré et sorti
2. **Contrôle** : Vérifier que les montants correspondent aux attentes
3. **Audit** : Facilite la vérification des opérations de la journée
4. **Clarté** : Distinction claire entre entrées et sorties

## Notes techniques

- Les calculs sont effectués côté backend pour garantir la précision
- Les montants sont agrégés directement depuis la table `cash_movements`
- La période de calcul est automatiquement ajustée selon l'état de la session
- Les totaux sont mis en cache dans la réponse pour éviter les recalculs côté frontend

## Prochaines améliorations possibles

1. Afficher le détail des entrées/sorties par catégorie
2. Ajouter un graphique de répartition
3. Exporter les détails en PDF
4. Comparer avec les sessions précédentes
