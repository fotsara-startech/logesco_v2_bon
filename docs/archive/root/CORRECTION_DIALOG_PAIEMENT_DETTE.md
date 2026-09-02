# Correction - Dialog de Paiement de Dette avec Sélection de Vente

## 🎯 Problème Identifié

L'utilisateur ne voyait pas l'option pour sélectionner une vente spécifique lors du paiement de dette dans le dialog "Payer la dette" de la vue `customer_account_view.dart`.

## 🔍 Cause

Il existait deux dialogs différents pour le paiement de dette:

1. **`TransactionFormDialog`** (dans `accounts/widgets/`) - Avec l'option de sélection de vente ✅
2. **`_showPaymentDialog`** (dans `customers/views/customer_account_view.dart`) - Sans l'option ❌

L'utilisateur utilisait le second dialog qui n'avait pas encore été mis à jour avec la nouvelle fonctionnalité.

---

## ✅ Corrections Apportées

### 1. Fichier: `logesco_v2/lib/features/customers/views/customer_account_view.dart`

#### Imports ajoutés:
```dart
import '../../accounts/models/account.dart';
import '../../accounts/widgets/unpaid_sales_selector_dialog.dart';
```

#### Méthode `_showPaymentDialog` modifiée:
- Ajout de `StatefulBuilder` pour gérer l'état local
- Ajout de variables `selectedSale` et `isPayingSpecificSale`
- Ajout d'une `CheckboxListTile` "Payer une vente spécifique"
- Ajout d'un bouton pour ouvrir le `UnpaidSalesSelectorDialog`
- Affichage des détails de la vente sélectionnée
- Pré-remplissage automatique du montant et de la description
- Validation que la vente est sélectionnée si l'option est cochée

#### Méthode `_processPayment` modifiée:
- Ajout du paramètre `UnpaidSale? selectedSale`
- Appel de `payCustomerDebtForSale` si une vente est sélectionnée
- Sinon, appel de `payCustomerDebt` (comportement normal)

---

### 2. Fichier: `logesco_v2/lib/features/customers/controllers/customer_controller.dart`

#### Nouvelle méthode ajoutée:
```dart
Future<bool> payCustomerDebtForSale(
  int customerId, 
  double montant, 
  int venteId, 
  {String? description}
) async
```

Cette méthode:
- Appelle le service API avec les paramètres de la vente
- Affiche les messages de succès/erreur
- Retourne `true` si le paiement est enregistré avec succès

---

### 3. Fichier: `logesco_v2/lib/features/customers/services/api_customer_service.dart`

#### Nouvelle méthode ajoutée:
```dart
Future<bool> payCustomerDebtForSale(
  int customerId, 
  double montant, 
  int venteId, 
  {String? description}
) async
```

Cette méthode:
- Appelle l'endpoint `/accounts/customers/:id/transactions`
- Envoie les paramètres:
  - `montant`: Montant du paiement
  - `typeTransaction`: 'paiement'
  - `typeTransactionDetail`: 'paiement_dette'
  - `venteId`: ID de la vente
  - `description`: Description du paiement
- Retourne `true` si la requête réussit

---

## 🎨 Interface Utilisateur

### Avant
```
┌─────────────────────────────────────┐
│ Payer la dette                      │
├─────────────────────────────────────┤
│ Dette actuelle: 5000 FCFA           │
│                                     │
│ Montant à payer: [5000] FCFA       │
│                                     │
│ Description (optionnel): [____]     │
│                                     │
│ [Annuler]  [Confirmer le paiement] │
└─────────────────────────────────────┘
```

### Après
```
┌─────────────────────────────────────┐
│ Payer la dette                      │
├─────────────────────────────────────┤
│ Dette actuelle: 5000 FCFA           │
│                                     │
│ ☑ Payer une vente spécifique       │
│   Sélectionner une vente impayée    │
│                                     │
│ [📄 Sélectionner une vente]         │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Vente #VTE-20260211-001         │ │
│ │ Date: 11/02/2026                │ │
│ │ Total: 15000 FCFA               │ │
│ │ Déjà payé: 10000 FCFA           │ │
│ │ Reste: 5000 FCFA                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Montant à payer: [5000] FCFA       │
│                                     │
│ Description: [Paiement Dette...]    │
│                                     │
│ [Annuler]  [Confirmer le paiement] │
└─────────────────────────────────────┘
```

---

## 🔄 Flux Utilisateur

### Scénario: Payer une vente spécifique

1. **Ouvrir le compte client**
   - Naviguer vers Clients > Sélectionner un client
   - Cliquer sur "Payer la dette"

2. **Activer l'option**
   - Cocher "Payer une vente spécifique"
   - Le bouton "Sélectionner une vente" apparaît

3. **Sélectionner la vente**
   - Cliquer sur "Sélectionner une vente"
   - Un dialog s'ouvre avec la liste des ventes impayées
   - Sélectionner la vente à payer
   - Ajuster le montant si nécessaire
   - Cliquer sur "Payer"

4. **Confirmer le paiement**
   - Les détails de la vente s'affichent
   - Le montant et la description sont pré-remplis
   - Cliquer sur "Confirmer le paiement"

5. **Résultat**
   - Transaction créée avec lien vers la vente
   - Libellé: "Paiement Dette (Vente #VTE-XXX)"
   - Montant payé de la vente mis à jour
   - Dette client diminuée

---

## 🧪 Tests à Effectuer

### Test 1: Paiement avec vente spécifique
1. Ouvrir un compte client avec des ventes impayées
2. Cliquer sur "Payer la dette"
3. Cocher "Payer une vente spécifique"
4. Sélectionner une vente
5. Confirmer le paiement
6. Vérifier que la transaction apparaît avec le numéro de vente

### Test 2: Paiement sans vente spécifique
1. Ouvrir un compte client
2. Cliquer sur "Payer la dette"
3. Ne pas cocher "Payer une vente spécifique"
4. Saisir un montant
5. Confirmer le paiement
6. Vérifier que la transaction est créée normalement

### Test 3: Validation
1. Cocher "Payer une vente spécifique"
2. Ne pas sélectionner de vente
3. Essayer de confirmer
4. Vérifier que l'erreur est affichée

### Test 4: Client sans ventes impayées
1. Ouvrir un compte client sans ventes impayées
2. Cocher "Payer une vente spécifique"
3. Cliquer sur "Sélectionner une vente"
4. Vérifier que le message "Aucune vente impayée" s'affiche

---

## 📝 Fichiers Modifiés

1. ✅ `logesco_v2/lib/features/customers/views/customer_account_view.dart`
2. ✅ `logesco_v2/lib/features/customers/controllers/customer_controller.dart`
3. ✅ `logesco_v2/lib/features/customers/services/api_customer_service.dart`

---

## 🎉 Résultat

Le dialog de paiement de dette dans la vue `customer_account_view.dart` offre maintenant la même fonctionnalité que le `TransactionFormDialog`:

✅ Option pour payer une vente spécifique
✅ Sélection de vente impayée
✅ Affichage des détails de la vente
✅ Pré-remplissage automatique
✅ Validation appropriée
✅ Liaison vente-transaction

L'utilisateur peut maintenant choisir de payer une vente spécifique ou de faire un paiement général, offrant un suivi rigoureux des transactions client.
