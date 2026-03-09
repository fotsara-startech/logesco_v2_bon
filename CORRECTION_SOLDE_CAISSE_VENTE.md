# Correction Solde Caisse lors des Ventes

## Problème identifié

### Incohérence détectée

**Transaction 1: Vente**
```
Solde attendu session avant: 1800 FCFA
Montant versé: +10000 FCFA
Solde attendu session après: 11800 FCFA ✓
```

**Transaction 2: Paiement dette (quelques secondes après)**
```
Solde actuel caisse: 1000 FCFA ❌ (devrait être 11800 FCFA!)
Montant à ajouter: 11000 FCFA
Nouveau solde: 12000 FCFA ❌ (devrait être 22800 FCFA!)
```

### Perte de données

**Calcul attendu:**
- Après vente: 1800 + 10000 = 11800 FCFA
- Après paiement: 11800 + 11000 = 22800 FCFA ✓

**Calcul réel:**
- Après vente: Session = 11800 FCFA, Caisse = 1800 FCFA ❌
- Après paiement: 1800 + 11000 = 12800 FCFA ❌

**Perte:** 10000 FCFA du montant versé lors de la vente!

## Cause

La route de création de vente mettait à jour:
- ✅ La **session de caisse** (`cashSession.soldeAttendu`)
- ❌ PAS le **solde de la caisse** (`cashRegister.soldeActuel`)

Résultat: Le solde de la session et le solde de la caisse étaient désynchronisés.

## Solution

Mettre à jour **les deux** lors d'une vente:
1. Session de caisse (pour le suivi de session)
2. Solde de la caisse (pour la cohérence globale)

### Code ajouté

```javascript
// Après la mise à jour de la session
await prisma.cashSession.update({
  where: { id: activeSession.id },
  data: { soldeAttendu: newSoldeAttendu }
});

// CORRECTION: Mettre à jour aussi le solde de la caisse
await prisma.cashRegister.update({
  where: { id: activeSession.caisseId },
  data: {
    soldeActuel: {
      increment: montantVerse  // Mise à jour atomique
    }
  }
});
```

## Logs améliorés

### Avant (problématique)

```
💰 Session de caisse mise à jour:
   Solde attendu avant: 1800 FCFA
   Montant vente: +10000 FCFA
   Solde attendu après: 11800 FCFA
```

### Après (corrigé)

```
💰 Session de caisse mise à jour:
   Solde attendu avant: 1800 FCFA
   Montant vente: +10000 FCFA
   Solde attendu après: 11800 FCFA
💰 Mise à jour atomique du solde de la caisse (ID: 3)
✅ Solde caisse mis à jour: 11800 FCFA
```

## Impact

### Avant la correction

**Scénario:** Vente de 21000 FCFA, versé 10000 FCFA, puis paiement dette 11000 FCFA

```
État initial: Caisse = 1800 FCFA

Après vente:
- Session = 11800 FCFA ✓
- Caisse = 1800 FCFA ❌ (pas mis à jour)

Après paiement dette:
- Caisse lit: 1800 FCFA (ancien solde)
- Caisse = 1800 + 11000 = 12800 FCFA ❌

Résultat: Perte de 10000 FCFA!
```

### Après la correction

```
État initial: Caisse = 1800 FCFA

Après vente:
- Session = 11800 FCFA ✓
- Caisse = 11800 FCFA ✓ (mis à jour atomiquement)

Après paiement dette:
- Caisse lit: 11800 FCFA ✓
- Caisse = 11800 + 11000 = 22800 FCFA ✓

Résultat: Cohérent!
```

## Autres opérations à vérifier

Cette correction doit être appliquée à TOUTES les opérations qui modifient l'argent en caisse:

### ✅ Déjà corrigé
- Paiement dette client (avec increment)

### ✅ Maintenant corrigé
- Création de vente (avec increment)

### ⚠️ À vérifier
- Ouverture de caisse
- Fermeture de caisse
- Ajout/retrait manuel de caisse
- Paiement fournisseur
- Remboursement client

## Test

### Scénario de test complet

1. **État initial**
   - Solde caisse: 1000 FCFA

2. **Vente 1: 21000 FCFA, versé 10000 FCFA**
   - Solde attendu: 1000 + 10000 = 11000 FCFA

3. **Paiement dette: 11000 FCFA**
   - Solde attendu: 11000 + 11000 = 22000 FCFA

4. **Vente 2: 5000 FCFA, versé 5000 FCFA**
   - Solde attendu: 22000 + 5000 = 27000 FCFA

5. **Vérification finale**
   - Solde caisse = 27000 FCFA ✓
   - Solde session = 27000 FCFA ✓

### Logs attendus

```
=== VENTE 1 ===
💰 Session de caisse mise à jour:
   Solde attendu avant: 1000 FCFA
   Montant vente: +10000 FCFA
   Solde attendu après: 11000 FCFA
💰 Mise à jour atomique du solde de la caisse (ID: 3)
✅ Solde caisse mis à jour: 11000 FCFA

=== PAIEMENT DETTE ===
💰 Mise à jour atomique de la caisse active: Caisse Principale
  - Solde actuel caisse: 11000 FCFA ✓
  - Montant à ajouter: 11000 FCFA
✅ Caisse mise à jour avec succès (mise à jour atomique)
  - Nouveau solde confirmé: 22000 FCFA ✓

=== VENTE 2 ===
💰 Session de caisse mise à jour:
   Solde attendu avant: 22000 FCFA
   Montant vente: +5000 FCFA
   Solde attendu après: 27000 FCFA
💰 Mise à jour atomique du solde de la caisse (ID: 3)
✅ Solde caisse mis à jour: 27000 FCFA ✓
```

## Fichier modifié

```
backend/src/routes/sales.js
└── POST /sales
    └── Ajout mise à jour atomique du solde caisse
```

## Avantages de la correction

### 1. Cohérence des données
- Session et caisse toujours synchronisées
- Pas de perte de données
- Solde fiable à tout moment

### 2. Traçabilité
- Chaque opération met à jour la caisse
- Historique complet des mouvements
- Audit facilité

### 3. Fiabilité
- Mise à jour atomique (increment)
- Pas de race condition
- Thread-safe

## Statut

**CORRECTION APPLIQUÉE**

- Mise à jour atomique du solde caisse lors des ventes
- Logs améliorés
- Code compilé sans erreur
- Prêt pour test

---

**Date:** 28 février 2026  
**Fichier:** backend/src/routes/sales.js  
**Statut:** PRÊT POUR TEST - REDÉMARRAGE BACKEND REQUIS
