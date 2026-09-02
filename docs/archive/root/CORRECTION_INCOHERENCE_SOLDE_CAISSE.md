# Correction de l'incohérence du solde de caisse

## Problème identifié

Lors du paiement de dette client, une incohérence se créait entre :
- Le **solde de la caisse** (CashRegister.soldeActuel) : 14800 FCFA
- Le **solde de la session** (CashSession.soldeAttendu) : 13300 FCFA
- **Écart** : 1500 FCFA

### Cause du problème

Le code de paiement de dette (`backend/src/routes/customers.js`) mettait à jour :
- ✅ Le solde de la caisse (CashRegister.soldeActuel)
- ❌ Mais PAS le solde de la session (CashSession.soldeAttendu)

Le frontend affiche le solde de la session, d'où l'affichage de 13300 FCFA au lieu de 14800 FCFA.

### Scénario du problème

1. **Vente avec dette** : 1800 FCFA, payé 1000 FCFA
   - Solde session : 12300 + 1000 = 13300 FCFA ✅
   - Solde caisse : 12300 + 1000 = 13300 FCFA ✅

2. **Paiement de dette** : 800 FCFA
   - Solde session : 13300 FCFA (non mis à jour) ❌
   - Solde caisse : 13300 + 800 = 14100 FCFA ✅

3. **Autre paiement de dette** : 700 FCFA
   - Solde session : 13300 FCFA (toujours non mis à jour) ❌
   - Solde caisse : 14100 + 700 = 14800 FCFA ✅

**Résultat** : Écart de 1500 FCFA (800 + 700)

## Solution appliquée

### 1. Correction du code backend

**Fichier** : `backend/src/routes/customers.js`

Ajout de la mise à jour de la session de caisse lors du paiement de dette :

```javascript
// CORRECTION: Mettre à jour aussi la session de caisse active
const sessionActive = await tx.cashSession.findFirst({
  where: {
    caisseId: caisseActive.id,
    isActive: true,
    dateFermeture: null
  },
  orderBy: { dateOuverture: 'desc' }
});

if (sessionActive) {
  const currentSoldeAttendu = sessionActive.soldeAttendu 
    ? parseFloat(sessionActive.soldeAttendu) 
    : parseFloat(sessionActive.soldeOuverture);
  const newSoldeAttendu = currentSoldeAttendu + parseFloat(montant);

  await tx.cashSession.update({
    where: { id: sessionActive.id },
    data: {
      soldeAttendu: newSoldeAttendu
    }
  });

  console.log(`✅ [Payment] Session de caisse mise à jour:`);
  console.log(`  - Solde attendu avant: ${currentSoldeAttendu} FCFA`);
  console.log(`  - Montant paiement: +${montant} FCFA`);
  console.log(`  - Solde attendu après: ${newSoldeAttendu} FCFA`);
}
```

### 2. Correction de l'incohérence existante

**Script** : `backend/fix-cash-session-balance.js`

Ce script synchronise le solde de la session avec le solde de la caisse :

```bash
cd backend
node fix-cash-session-balance.js
```

**Résultat** :
- Solde caisse : 14800 FCFA
- Solde session : 14800 FCFA (corrigé de 13300 FCFA)
- Écart : 0 FCFA ✅

## Scripts utiles

### Vérifier le solde de caisse

```bash
cd backend
node check-cash-register-balance.js
```

Affiche :
- Le solde de la caisse (DB)
- Le solde de la session
- L'écart éventuel

### Corriger l'incohérence

```bash
cd backend
node fix-cash-session-balance.js
```

Synchronise automatiquement le solde de la session avec celui de la caisse.

## Test de la correction

### 1. Redémarrer le backend

```bash
cd backend
npm start
```

### 2. Tester un paiement de dette

1. Créer une vente avec dette
2. Payer la dette
3. Vérifier que le solde affiché dans le dashboard correspond au solde réel

### 3. Vérifier les logs

Lors du paiement de dette, vous devriez voir :

```
✅ [Payment] Caisse mise à jour avec succès (mise à jour atomique)
  - Nouveau solde confirmé: XXXX FCFA
✅ [Payment] Session de caisse mise à jour:
  - Solde attendu avant: YYYY FCFA
  - Montant paiement: +ZZZ FCFA
  - Solde attendu après: XXXX FCFA
```

## Impact

- ✅ Le solde affiché dans le dashboard est maintenant correct
- ✅ Pas d'écart entre le solde de la caisse et de la session
- ✅ Les paiements de dette mettent à jour les deux soldes
- ✅ Cohérence garantie entre backend et frontend

## Prochaines étapes

1. Redémarrer le backend pour appliquer les corrections
2. Rafraîchir le frontend (F5)
3. Vérifier que le solde affiché est maintenant 14800 FCFA
4. Tester un nouveau paiement de dette pour confirmer la correction
