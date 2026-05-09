# Correction des Commandes Impayées

## Problème

Après avoir réceptionné une commande avec paiement **comptant**:
- ✅ Les 2 transactions sont créées (achat + paiement)
- ✅ Le solde du compte fournisseur = 0 FCFA
- ❌ **MAIS** la commande apparaît encore dans "Payer le fournisseur" comme impayée

## Cause

Incohérence dans le `referenceType` utilisé pour les transactions:

### Dans procurement.js (création des transactions):
```javascript
referenceType: 'commande_approvisionnement'
```

### Dans accounts.js (recherche des paiements):
```javascript
referenceType: 'approvisionnement'  // ❌ Ne trouve pas les transactions!
```

## Solution

Harmonisation du `referenceType` dans accounts.js:

### Avant:
```javascript
const transactions = await prisma.transactionCompte.findMany({
  where: {
    typeCompte: 'fournisseur',
    compteId: compteFournisseur.id,
    referenceType: 'approvisionnement'  // ❌ Incorrect
  }
});
```

### Après:
```javascript
const transactions = await prisma.transactionCompte.findMany({
  where: {
    typeCompte: 'fournisseur',
    compteId: compteFournisseur.id,
    referenceType: 'commande_approvisionnement'  // ✅ Correct
  }
});
```

## Résultat attendu

Après cette correction:

### Paiement COMPTANT:
1. Réception de la commande avec mode "Comptant"
2. 2 transactions créées (achat + paiement)
3. Solde fournisseur = 0 FCFA
4. **La commande N'APPARAÎT PLUS dans "Payer le fournisseur"** ✅

### Paiement À CRÉDIT:
1. Réception de la commande avec mode "À crédit"
2. 1 transaction créée (achat seulement)
3. Solde fournisseur = montant de la commande
4. **La commande APPARAÎT dans "Payer le fournisseur"** ✅

## Test

1. Redémarrer le backend:
```bash
cd backend
npm start
```

2. Créer un nouveau fournisseur

3. Test paiement comptant:
   - Créer une commande
   - Réceptionner avec mode "Comptant"
   - Aller dans "Payer le fournisseur"
   - **Vérifier**: La commande ne doit PAS apparaître

4. Test paiement à crédit:
   - Créer une autre commande
   - Réceptionner avec mode "À crédit"
   - Aller dans "Payer le fournisseur"
   - **Vérifier**: La commande DOIT apparaître

## Logs de débogage

Le backend affiche maintenant des logs détaillés:
```
📋 Commande CMD20240508001:
  montantTotal: 26400
  montantReceptionne: 26400
  montantPaye: 26400
  montantRestant: 0
  ❌ Commande CMD20240508001: montantRestant=0 (EXCLUE)
```

Si `montantRestant = 0`, la commande est exclue de la liste des impayées.
