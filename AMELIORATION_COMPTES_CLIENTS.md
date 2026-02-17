# Amélioration du Système de Comptes Clients

## Analyse du Système Actuel

### Structure Existante

**Modèles (`account.dart`)**:
- `TransactionCompte`: Contient `typeTransaction`, `montant`, `description`, `referenceId`, `referenceType`
- Types de transactions: `debit`, `credit`, `paiement`, `achat`
- Pas de lien clair avec les ventes spécifiques

**Problèmes Identifiés**:
1. ❌ Les transactions ne montrent pas clairement quelle vente a été payée
2. ❌ Pas de distinction entre "paiement lors de la vente" et "paiement manuel de dette"
3. ❌ Le numéro de vente n'apparaît pas dans l'historique
4. ❌ Impossible de sélectionner une vente spécifique lors du paiement manuel
5. ❌ Pas de correspondance claire entre paiement et facture

---

## Améliorations Proposées

### 1. Modification du Modèle TransactionCompte

**Ajouts nécessaires**:
```dart
class TransactionCompte {
  // ... champs existants ...
  
  // NOUVEAUX CHAMPS
  final int? venteId;              // ID de la vente associée
  final String? venteReference;     // Numéro de référence de la vente
  final String typeTransactionDetail; // 'paiement_vente', 'paiement_dette', 'vente_credit'
  final bool isPaiementComplet;     // Si le paiement solde complètement la vente
}
```

**Nouveaux types de transactions détaillés**:
- `vente_comptant`: Vente payée comptant (montant payé = montant total)
- `vente_credit`: Vente à crédit (montant payé < montant total)
- `paiement_vente`: Paiement lors de la vente (partiel ou complet)
- `paiement_dette`: Paiement manuel d'une dette existante
- `ajustement`: Ajustement manuel du compte

---

### 2. Modification de l'Affichage des Transactions

**Format actuel**:
```
Paiement de dette
Paiement de 21000 FCFA (8000 FCFA pour dette précédente + 13000 FCFA pour vente VTE-20260210-180642)
```

**Nouveau format proposé**:
```
Paiement Facture #VTE-20260210-180642
Montant: 13000 FCFA | Solde après: -8000 FCFA

Paiement Dette (Vente #VTE-20260210-180642)
Montant: 8000 FCFA | Solde après: 0 FCFA
```

**Avantages**:
- ✅ Correspondance claire entre paiement et vente
- ✅ Numéro de vente visible
- ✅ Distinction entre paiement facture et paiement dette
- ✅ Suivi rigoureux des transactions

---

### 3. Dialog de Paiement Manuel Amélioré

**Fonctionnalités à ajouter**:

1. **Liste des ventes impayées**:
   - Afficher toutes les ventes à crédit du client
   - Montrer le montant restant pour chaque vente
   - Permettre de sélectionner la vente à payer

2. **Sélection de la vente**:
   ```
   ┌─────────────────────────────────────────┐
   │ Ventes impayées de [Nom Client]        │
   ├─────────────────────────────────────────┤
   │ ○ Vente #VTE-001 - 10/02/2026          │
   │   Montant total: 15000 FCFA             │
   │   Déjà payé: 5000 FCFA                  │
   │   Reste à payer: 10000 FCFA             │
   ├─────────────────────────────────────────┤
   │ ○ Vente #VTE-002 - 09/02/2026          │
   │   Montant total: 8000 FCFA              │
   │   Déjà payé: 0 FCFA                     │
   │   Reste à payer: 8000 FCFA              │
   └─────────────────────────────────────────┘
   
   Montant à payer: [_______] FCFA
   
   [Annuler]  [Payer]
   ```

3. **Validation**:
   - Vérifier que le montant ne dépasse pas le reste à payer
   - Afficher un avertissement si paiement partiel
   - Confirmer si le paiement solde complètement la vente

---

### 4. Modifications Backend Nécessaires

**Route à créer**: `GET /api/v1/customers/:id/unpaid-sales`
```javascript
// Retourne les ventes impayées d'un client
{
  "data": [
    {
      "id": 123,
      "reference": "VTE-20260210-180642",
      "dateVente": "2026-02-10T18:06:42Z",
      "montantTotal": 15000,
      "montantPaye": 5000,
      "montantRestant": 10000,
      "details": [...]
    }
  ]
}
```

**Modification de la création de transaction**:
```javascript
// POST /api/v1/accounts/customers/:id/transactions
{
  "montant": 10000,
  "typeTransaction": "paiement_dette",
  "venteId": 123,  // NOUVEAU
  "description": "Paiement vente #VTE-20260210-180642"
}
```

**Mise à jour automatique**:
- Lors d'un paiement de dette, mettre à jour `montantPaye` de la vente
- Recalculer `montantRestant`
- Créer la transaction avec le lien vers la vente

---

### 5. Modifications Frontend Flutter

**Fichiers à modifier**:

1. **`account.dart`** (Modèle):
   - Ajouter les nouveaux champs à `TransactionCompte`
   - Ajouter méthode `get isPaymentForSale`
   - Ajouter méthode `get formattedTransactionType`

2. **`transaction_list_item.dart`** (Widget):
   - Afficher le numéro de vente si disponible
   - Distinguer visuellement paiement facture vs paiement dette
   - Ajouter icône spécifique selon le type

3. **`transaction_form_dialog.dart`** (Dialog):
   - Ajouter option "Payer une vente spécifique"
   - Charger les ventes impayées du client
   - Permettre la sélection d'une vente
   - Pré-remplir le montant avec le reste à payer

4. **`account_api_service.dart`** (Service):
   - Ajouter méthode `getUnpaidSales(clientId)`
   - Modifier `createTransaction` pour accepter `venteId`

5. **`account_controller.dart`** (Contrôleur):
   - Ajouter `RxList<Sale> unpaidSales`
   - Ajouter méthode `loadUnpaidSales(clientId)`
   - Gérer la sélection de vente dans le paiement

---

## Plan d'Implémentation

### Phase 1: Backend (Priorité Haute)
1. ✅ Modifier le schéma de `TransactionCompte` (ajouter `venteId`, `venteReference`)
2. ✅ Créer route `GET /customers/:id/unpaid-sales`
3. ✅ Modifier route de création de transaction pour accepter `venteId`
4. ✅ Mettre à jour automatiquement `montantPaye` de la vente

### Phase 2: Frontend - Modèles (Priorité Haute)
1. ✅ Modifier `TransactionCompte` dans `account.dart`
2. ✅ Ajouter getters pour le formatage
3. ✅ Créer modèle `UnpaidSale` si nécessaire

### Phase 3: Frontend - Services (Priorité Haute)
1. ✅ Ajouter `getUnpaidSales()` dans `account_api_service.dart`
2. ✅ Modifier `createTransaction()` pour envoyer `venteId`

### Phase 4: Frontend - UI (Priorité Moyenne)
1. ✅ Modifier `transaction_list_item.dart` pour afficher le numéro de vente
2. ✅ Créer widget `UnpaidSalesSelector`
3. ✅ Modifier `transaction_form_dialog.dart` pour intégrer le sélecteur

### Phase 5: Tests (Priorité Moyenne)
1. ✅ Tester création de vente à crédit
2. ✅ Tester paiement lors de la vente
3. ✅ Tester paiement manuel de dette
4. ✅ Vérifier l'affichage dans l'historique
5. ✅ Vérifier la correspondance vente-paiement

---

## Exemple de Flux Utilisateur

### Scénario 1: Vente à Crédit
1. Vendeur crée une vente de 15000 FCFA
2. Client paie 5000 FCFA comptant
3. **Transaction créée**: "Paiement Facture #VTE-001" - 5000 FCFA
4. Dette client: +10000 FCFA

### Scénario 2: Paiement Manuel de Dette
1. Client revient payer sa dette
2. Vendeur clique "Payer la dette"
3. **Dialog affiche**: Liste des ventes impayées
4. Vendeur sélectionne "Vente #VTE-001 (reste 10000 FCFA)"
5. Vendeur saisit 10000 FCFA
6. **Transaction créée**: "Paiement Dette (Vente #VTE-001)" - 10000 FCFA
7. Dette client: 0 FCFA
8. Vente #VTE-001 marquée comme complètement payée

### Scénario 3: Paiement Partiel de Dette
1. Client revient payer partiellement
2. Vendeur sélectionne "Vente #VTE-001 (reste 10000 FCFA)"
3. Vendeur saisit 3000 FCFA
4. **Transaction créée**: "Paiement Dette Partiel (Vente #VTE-001)" - 3000 FCFA
5. Dette client: -7000 FCFA
6. Vente #VTE-001 reste impayée (reste 7000 FCFA)

---

## Bénéfices Attendus

1. **Traçabilité complète**: Chaque paiement est lié à une vente spécifique
2. **Clarté pour l'utilisateur**: Distinction nette entre types de paiements
3. **Suivi rigoureux**: Impossible de perdre la trace d'un paiement
4. **Rapports précis**: Possibilité de générer des rapports par vente
5. **Gestion des litiges**: Facile de retrouver l'historique d'une vente
6. **Conformité comptable**: Correspondance claire facture-paiement

---

## Notes Techniques

### Compatibilité
- Les anciennes transactions sans `venteId` seront affichées normalement
- Ajout d'un flag `isLegacyTransaction` pour les distinguer
- Migration progressive sans perte de données

### Performance
- Index sur `venteId` dans la table `TransactionCompte`
- Cache des ventes impayées côté client
- Pagination de l'historique des transactions

### Sécurité
- Vérifier que la vente appartient bien au client
- Valider que le montant ne dépasse pas le reste à payer
- Logger toutes les modifications de paiement
