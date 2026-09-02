# Correction Lecture Sale (Dirty Read) - Solde Caisse - SQLITE

## Problème identifié

### Symptôme
```
Solde caisse avant transaction: 1000 FCFA
Log backend: "Solde actuel caisse: 500 FCFA"
Solde caisse après transaction: 1000 FCFA (au lieu de 1500 FCFA)
```

### Cause
**Lecture sale (Dirty Read)** - Le backend lit un solde obsolète de la caisse car une autre transaction concurrente a modifié le solde entre-temps.

## Solution pour SQLite

### Problème avec FOR UPDATE
SQLite ne supporte pas `SELECT ... FOR UPDATE` (fonctionnalité PostgreSQL/MySQL).

### Solution: Mise à jour atomique avec increment

Au lieu de:
1. Lire le solde
2. Calculer le nouveau solde
3. Mettre à jour

On utilise une **mise à jour atomique**:
```javascript
await tx.cashRegister.update({
  where: { id: caisseActive.id },
  data: { 
    soldeActuel: {
      increment: parseFloat(montant)  // Atomique!
    }
  }
});
```

Cela génère du SQL:
```sql
UPDATE cash_registers 
SET solde_actuel = solde_actuel + 500 
WHERE id = 3
```

### Avantages de increment

1. **Atomique**: L'opération est effectuée en une seule requête SQL
2. **Pas de lecture sale**: Le calcul se fait directement dans la base de données
3. **Compatible SQLite**: Fonctionne sur toutes les bases de données
4. **Thread-safe**: Plusieurs transactions peuvent s'exécuter en parallèle

## Comparaison

### Avant (problématique)

```javascript
// Lire le solde
const caisse = await tx.cashRegister.findFirst({...});

// Calculer (peut être obsolète)
const nouveauSolde = caisse.soldeActuel + montant;

// Mettre à jour (peut écraser d'autres changements)
await tx.cashRegister.update({
  where: { id: caisse.id },
  data: { soldeActuel: nouveauSolde }
});
```

**Problème:** Entre la lecture et la mise à jour, une autre transaction peut avoir modifié le solde.

### Après (corrigé)

```javascript
// Mise à jour atomique directe
await tx.cashRegister.update({
  where: { id: caisseActive.id },
  data: { 
    soldeActuel: {
      increment: parseFloat(montant)
    }
  }
});
```

**Avantage:** Le calcul se fait dans la base de données, garantissant la cohérence.

## Scénario de test

### Sans increment (problématique)

```
Temps | Transaction A          | Transaction B
------|------------------------|------------------------
T1    | Lit solde: 1000        |
T2    |                        | Lit solde: 1000
T3    | Calcule: 1000 + 500    |
T4    |                        | Calcule: 1000 + 300
T5    | Update solde = 1500    |
T6    |                        | Update solde = 1300
T7    | COMMIT                 |
T8    |                        | COMMIT

Résultat: 1300 FCFA ❌ (perte de 500 FCFA)
```

### Avec increment (corrigé)

```
Temps | Transaction A                    | Transaction B
------|----------------------------------|----------------------------------
T1    | UPDATE SET solde = solde + 500   |
T2    |                                  | UPDATE SET solde = solde + 300
T3    | COMMIT                           |
T4    |                                  | COMMIT

Résultat: 1800 FCFA ✓ (1000 + 500 + 300)
```

## Logs améliorés

```
🔍 [Payment] Recherche de la caisse active...
✅ [Payment] Caisse active trouvée: Caisse Principale (ID: 3)
💰 [Payment] Mise à jour atomique de la caisse active: Caisse Principale
  - Solde actuel caisse: 1000 FCFA
  - Montant à ajouter: 500 FCFA
✅ [Payment] Caisse mise à jour avec succès (mise à jour atomique)
  - Nouveau solde confirmé: 1500 FCFA ✓
✅ [Payment] Mouvement de caisse créé (ID: 97)
✅ [Payment] Solde de la caisse mis à jour avec succès
```

## Autres opérations atomiques Prisma

### increment
```javascript
{ soldeActuel: { increment: 500 } }  // solde = solde + 500
```

### decrement
```javascript
{ soldeActuel: { decrement: 200 } }  // solde = solde - 200
```

### multiply
```javascript
{ prix: { multiply: 1.1 } }  // prix = prix * 1.1
```

### divide
```javascript
{ prix: { divide: 2 } }  // prix = prix / 2
```

## Fichier modifié

```
backend/src/routes/customers.js
└── POST /customers/:id/payment
    └── Utilisation de increment au lieu de calcul manuel
```

## Test

### Étapes

1. **Redémarrer le backend**
```bash
restart-backend-quick.bat
```

2. **Noter le solde initial**
   - Solde caisse: 1000 FCFA

3. **Effectuer un paiement**
   - Montant: 500 FCFA

4. **Vérifier le solde final**
   - Solde attendu: 1500 FCFA ✓

5. **Effectuer un deuxième paiement immédiatement**
   - Montant: 300 FCFA
   - Solde attendu: 1800 FCFA ✓

### Logs attendus

```
💰 [Payment] Mise à jour atomique de la caisse active: Caisse Principale
  - Solde actuel caisse: 1000 FCFA
  - Montant à ajouter: 500 FCFA
✅ [Payment] Caisse mise à jour avec succès (mise à jour atomique)
  - Nouveau solde confirmé: 1500 FCFA
```

## Statut

**CORRECTION APPLIQUÉE - COMPATIBLE SQLITE**

- Utilisation de increment (atomique)
- Compatible avec SQLite
- Pas besoin de FOR UPDATE
- Code compilé sans erreur
- Prêt pour test

---

**Date:** 28 février 2026  
**Fichier:** backend/src/routes/customers.js  
**Statut:** PRÊT POUR TEST - REDÉMARRAGE BACKEND REQUIS
