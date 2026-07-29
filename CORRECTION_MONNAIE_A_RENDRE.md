# CORRECTION: Monnaie à rendre vs Crédit client

## Problème identifié

Lorsqu'un client verse un montant supérieur au montant TTC d'une vente, le système enregistrait la différence comme un **crédit client** au lieu de la traiter comme de la **monnaie à rendre**.

### Exemple concret
- **Montant TTC**: 17888 FCFA
- **Montant versé**: 20000 FCFA  
- **Différence**: 2113 FCFA

**Comportement incorrect** : Les 2113 FCFA étaient enregistrés dans le compte client comme crédit ❌

**Comportement attendu** : Les 2113 FCFA doivent être rendus au client sous forme de monnaie, sans crédit ✅

## Cause du problème

Dans `backend/src/routes/sales.js` (ligne ~1029), le calcul du solde client était :

```javascript
// Calcul INCORRECT
const nouveauSolde = montantVerse - montantTotalAPayer;
```

Ce calcul créait systématiquement un crédit positif quand `montantVerse > montantTotalAPayer`.

## Solution appliquée

Le code a été corrigé pour distinguer **monnaie à rendre** et **crédit client** :

```javascript
// CORRECTION appliquée
let nouveauSolde;
if (montantRestantADistribuer > 0) {
  // Il reste de l'argent après paiement de toutes les dettes
  // C'est de la MONNAIE À RENDRE, pas un crédit client
  nouveauSolde = 0;
  console.log(`💵 Monnaie à rendre au client: ${montantRestantADistribuer} FCFA`);
} else {
  // Le client a payé exactement ou moins que le total
  nouveauSolde = montantVerse - montantTotalAPayer;
}
```

## Logique corrigée

### Cas 1 : Paiement comptant avec excédent (monnaie)
- **Montant TTC**: 17888 FCFA
- **Montant versé**: 20000 FCFA
- **Résultat**: 
  - Monnaie à rendre : 2113 FCFA 💵
  - Solde client : 0 FCFA ✅

### Cas 2 : Paiement partiel (crédit/dette)
- **Montant TTC**: 17888 FCFA
- **Montant versé**: 15000 FCFA
- **Résultat**:
  - Monnaie à rendre : 0 FCFA
  - Solde client : -2888 FCFA (dette) ✅

### Cas 3 : Paiement exact
- **Montant TTC**: 17888 FCFA
- **Montant versé**: 17888 FCFA
- **Résultat**:
  - Monnaie à rendre : 0 FCFA
  - Solde client : 0 FCFA ✅

## Fichiers modifiés

- `backend/src/routes/sales.js` (ligne ~1029-1044)

## Test de la correction

Pour tester la correction :

1. **Redémarrer le backend** :
   ```bash
   cd backend
   npm start
   ```

2. **Créer une vente test** :
   - Montant TTC : 17888 FCFA
   - Montant versé : 20000 FCFA

3. **Vérifier** :
   - L'interface affiche "Monnaie à rendre: 2113 FCFA" ✅
   - Le compte client reste à 0 FCFA (pas de crédit) ✅
   - Les logs backend affichent : `💵 Monnaie à rendre au client: 2113 FCFA`

## Notes importantes

- La monnaie à rendre est **calculée et affichée** dans l'interface de paiement
- Elle **n'est PAS enregistrée** dans le compte client
- Le solde client ne doit refléter que les **dettes** (paiements partiels) ou les **crédits volontaires** (avances de paiement)

## Prochaines étapes

Le backend est maintenant corrigé. **Redémarrez le serveur backend** pour appliquer les modifications.
