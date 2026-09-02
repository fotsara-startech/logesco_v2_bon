# Solution 2 : Système de Compte Client Centralisé

## Vue d'ensemble

Cette solution simplifie la gestion des crédits en centralisant toute la logique au niveau du **compte client**, plutôt qu'au niveau des ventes individuelles.

## Principe de fonctionnement

### Avant (Problème)
```
Vente 1 : 10 000 FCFA → Payé 5 000 → Statut "incomplete" ❌
Vente 2 : 15 000 FCFA + 5 000 dette → Client paie 20 000
Résultat : Vente 1 reste "incomplete" alors que la dette est soldée ❌
```

### Après (Solution 2)
```
Vente 1 : 10 000 FCFA → Payé 5 000 → Statut "terminee" ✅
  → Compte client : -5 000 FCFA (dette)

Vente 2 : 15 000 FCFA → Client paie 20 000
  → Paiement de 20 000 FCFA
  → Achat de 15 000 FCFA
  → Compte client : 0 FCFA (soldé) ✅

Toutes les ventes sont "terminee" ✅
Le compte client est la source de vérité ✅
```

## Changements implémentés

### 1. Backend (sales.js)

**Modification principale :**
- Toutes les ventes sont créées avec `statut: 'terminee'`
- Le champ `montantRestant` garde la valeur pour info historique
- Le compte client gère les dettes via son `soldeActuel`

**Transactions créées :**
1. **Transaction ACHAT** : Débit du montant de la vente
2. **Transaction PAIEMENT** : Crédit du montant versé

**Calcul du solde :**
```javascript
soldeActuel = Paiements - Achats
// Solde négatif = Dette
// Solde positif = Crédit disponible
```

### 2. Frontend (Flutter)

#### Modèle Sale (sale.dart)
- Ajout de commentaires explicatifs
- Nouvelle propriété `isPartialPayment`
- Clarification que le statut est toujours "terminee"

#### Affichage des ventes (sales_list_item.dart)
- Badge "Paiement partiel" au lieu de "Incomplete"
- Affichage du montant payé et restant pour cette vente

#### Dialogue de finalisation (finalize_sale_dialog.dart)
- Message clair sur l'impact au compte client
- Validation améliorée pour paiements partiels
- Obligation de sélectionner un client pour paiement partiel

#### Nouvelle vue : Compte Client (customer_account_view.dart)
- Affichage du solde actuel (positif ou négatif)
- Historique complet des transactions
- Distinction claire entre achats et paiements

### 3. Routes

Mise à jour de la route `/customers/:id/transactions` pour pointer vers `CustomerAccountView`

## Avantages de cette solution

### ✅ Simplicité
- Pas de logique complexe de répartition des paiements
- Une seule source de vérité : le compte client

### ✅ Clarté
- Le statut "incomplete" n'existe plus
- Toutes les ventes créées = ventes terminées
- La dette est visible au niveau du compte

### ✅ Traçabilité
- Historique complet dans les transactions
- Chaque paiement et achat est enregistré
- Solde après chaque opération

### ✅ Flexibilité
- Le client peut payer plusieurs dettes en une fois
- Les paiements sont automatiquement répartis
- Pas de confusion sur quelle vente est payée

## Utilisation

### Pour le vendeur

1. **Créer une vente avec paiement partiel :**
   - Sélectionner le client
   - Entrer le montant payé (inférieur au total)
   - Confirmer → La dette est ajoutée au compte
   - La vente est marquée "Terminée" ✅

2. **Consulter la dette d'un client :**
   - Aller dans Clients
   - Sélectionner le client
   - Cliquer sur "Voir les transactions et le solde"
   - Le solde négatif = dette

3. **Encaisser un paiement :**
   - **IMPORTANT** : Il n'y a plus de bouton "Ajouter paiement" sur les ventes
   - Pour encaisser, créer une nouvelle vente (même avec 0 article)
   - Le système affiche automatiquement la dette précédente
   - Le client paie le total (vente + dette)
   - Le compte est mis à jour automatiquement

### Changements importants

❌ **Ce qui n'existe PLUS :**
- Badge "Partiel" ou "Incomplete" sur les ventes
- Bouton "Ajouter paiement" dans le détail d'une vente
- Affichage du "montant restant" comme information principale

✅ **Ce qui existe MAINTENANT :**
- Toutes les ventes sont "Terminée" (sauf si annulées)
- Badge vert pour toutes les ventes terminées
- Affichage du "montant payé lors de cette vente"
- Message indiquant de consulter le compte client pour la dette
- Compte client comme source unique de vérité

### Pour le client

Le compte client montre :
- **Solde négatif** : Dette à payer
- **Solde positif** : Crédit disponible
- **Solde zéro** : Compte soldé

## Exemple concret

### Scénario complet

**Jour 1 - Première vente**
```
Client : Jean Dupont
Vente : 50 000 FCFA
Payé : 30 000 FCFA
→ Vente créée avec statut "terminee"
→ Compte client : -20 000 FCFA (dette)
```

**Jour 2 - Deuxième vente**
```
Client : Jean Dupont (dette : 20 000 FCFA)
Vente : 40 000 FCFA
Total à payer : 60 000 FCFA (40 000 + 20 000)
Payé : 60 000 FCFA
→ Vente créée avec statut "terminee"
→ Compte client : 0 FCFA (soldé)
```

**Transactions enregistrées :**
```
1. Achat de 50 000 FCFA (Vente 1)
2. Paiement de 30 000 FCFA (Vente 1)
   → Solde : -20 000 FCFA

3. Achat de 40 000 FCFA (Vente 2)
4. Paiement de 60 000 FCFA (Vente 2)
   → Solde : 0 FCFA
```

## Migration depuis l'ancien système

Si vous avez des ventes avec statut "incomplete" :

1. **Option 1 : Ne rien faire**
   - Les anciennes ventes restent "incomplete"
   - Les nouvelles ventes utilisent le nouveau système
   - Pas d'impact sur le fonctionnement

2. **Option 2 : Migration manuelle**
   - Identifier les ventes "incomplete"
   - Mettre à jour leur statut en "terminee"
   - Vérifier que les comptes clients sont corrects

## Support et questions

Pour toute question sur cette solution :
- Consulter le compte client pour voir la dette réelle
- Vérifier l'historique des transactions
- Le solde du compte est toujours la référence

---

**Date d'implémentation :** 10 novembre 2025
**Version :** LOGESCO v2
**Statut :** ✅ Implémenté et testé
