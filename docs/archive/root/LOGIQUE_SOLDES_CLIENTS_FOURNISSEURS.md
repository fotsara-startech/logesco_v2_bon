# Logique des soldes: Clients vs Fournisseurs

## Principe de base

Les soldes des clients et des fournisseurs fonctionnent de manière **INVERSE**.

## CLIENTS (Comptes débiteurs)

### Solde NÉGATIF (-) 
**Le client DOIT à l'entreprise**
- Exemple: Solde = -5000 FCFA
- Signification: Le client a acheté pour 5000 FCFA à crédit
- Action: Bouton "Payer la dette" visible (rouge)
- Transaction de paiement: CRÉDIT (réduit la dette)

### Solde POSITIF (+)
**L'entreprise DOIT au client**
- Exemple: Solde = +2000 FCFA
- Signification: Le client a un crédit (trop-perçu, remboursement dû)
- Action: Pas de bouton (remboursement immédiat dans la pratique)
- Cas rare dans le logiciel

### Solde ZÉRO (0)
- Compte équilibré, aucune dette

## FOURNISSEURS (Comptes créditeurs)

### Solde POSITIF (+)
**L'entreprise DOIT au fournisseur**
- Exemple: Solde = +2744 FCFA
- Signification: Marchandise reçue à crédit, pas encore payée
- Action: Bouton "Payer le fournisseur" visible (rouge)
- Transaction de paiement: CRÉDIT (réduit la dette)

### Solde NÉGATIF (-)
**Le fournisseur DOIT à l'entreprise**
- Exemple: Solde = -1000 FCFA
- Signification: Avance payée au fournisseur
- Action: Bouton "Effectuer un paiement" (outlined)
- Cas possible mais rare

### Solde ZÉRO (0)
- Compte équilibré, aucune dette

## Résumé visuel

```
CLIENTS:
Solde: -5000 FCFA (rouge) → Client doit 5000 → Payer la dette
Solde: 0 FCFA (vert) → Équilibré
Solde: +2000 FCFA (vert) → Entreprise doit 2000 → Remboursement

FOURNISSEURS:
Solde: +2744 FCFA (rouge) → Entreprise doit 2744 → Payer le fournisseur
Solde: 0 FCFA (vert) → Équilibré
Solde: -1000 FCFA (vert) → Avance payée
```

## Types de transactions

### Pour les CLIENTS:
- **Débit** (rouge, -): Achat à crédit → Augmente la dette du client
- **Crédit** (vert, +): Paiement → Réduit la dette du client

### Pour les FOURNISSEURS:
- **Débit** (rouge, -): Achat/Réception → Augmente la dette de l'entreprise
- **Crédit** (vert, +): Paiement → Réduit la dette de l'entreprise

## Correction appliquée

Dans le code, la condition était inversée:
```dart
// AVANT (incorrect)
final bool aDette = solde < 0; // Pour fournisseurs

// APRÈS (correct)
final bool aDette = solde > 0; // Pour fournisseurs
```

Maintenant, un solde positif de 2744 FCFA affiche correctement le bouton "Payer le fournisseur" en rouge.
