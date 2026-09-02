# Correction - Écart Toujours à Zéro lors de la Clôture

## Problème Identifié

L'écart était systématiquement calculé à **0 FCFA** lors de la clôture de caisse, peu importe le montant saisi par l'utilisateur.

### Cause Racine

Le champ `soldeAttendu` de la session de caisse n'était **jamais mis à jour** lors des ventes et des dépenses. Il restait égal au `soldeOuverture`, donc:

```
Écart = soldeFermeture - soldeAttendu
Écart = soldeFermeture - soldeOuverture  ❌ INCORRECT
```

Au lieu de:

```
Écart = soldeFermeture - (soldeOuverture + ventes - dépenses)  ✅ CORRECT
```

## Solutions Appliquées

### 1. Mise à Jour lors des Ventes

**Fichier**: `backend/src/routes/sales.js`

**Ajout après la création de la vente**:

```javascript
// Mettre à jour le solde attendu de la session de caisse active
try {
  const activeSession = await prisma.cashSession.findFirst({
    where: {
      utilisateurId: req.user?.id || 1,
      isActive: true,
      dateFermeture: null
    }
  });

  if (activeSession) {
    const currentSoldeAttendu = activeSession.soldeAttendu 
      ? parseFloat(activeSession.soldeAttendu) 
      : parseFloat(activeSession.soldeOuverture);
    const newSoldeAttendu = currentSoldeAttendu + montantVerse; // Ajouter le montant payé

    await prisma.cashSession.update({
      where: { id: activeSession.id },
      data: {
        soldeAttendu: newSoldeAttendu
      }
    });

    console.log(`💰 Session de caisse mise à jour:`);
    console.log(`   Solde attendu avant: ${currentSoldeAttendu} FCFA`);
    console.log(`   Montant vente: +${montantVerse} FCFA`);
    console.log(`   Solde attendu après: ${newSoldeAttendu} FCFA`);
  }
} catch (error) {
  console.error('⚠️ Erreur lors de la mise à jour de la session de caisse:', error);
  // Ne pas bloquer la vente si la mise à jour de la session échoue
}
```

**Logique**:
- Récupère la session active de l'utilisateur
- Ajoute le `montantVerse` (montant payé) au `soldeAttendu`
- Met à jour la session dans la base de données
- Affiche des logs pour le suivi

### 2. Mise à Jour lors des Dépenses

**Fichier**: `backend/src/services/financial-movement.js`

**Modification de la méthode `updateActiveCashRegister`**:

```javascript
// Mettre à jour le soldeAttendu de la session (réduire car c'est une dépense)
const currentSoldeAttendu = activeSession.soldeAttendu 
  ? parseFloat(activeSession.soldeAttendu) 
  : parseFloat(activeSession.soldeOuverture);
const newSoldeAttendu = currentSoldeAttendu - parseFloat(montant);

await this.prisma.cashSession.update({
  where: { id: activeSession.id },
  data: {
    soldeAttendu: newSoldeAttendu
  }
});

console.log(`💰 Session de caisse mise à jour:`);
console.log(`   Solde attendu avant: ${currentSoldeAttendu} FCFA`);
console.log(`   Dépense: -${montant} FCFA`);
console.log(`   Solde attendu après: ${newSoldeAttendu} FCFA`);
```

**Logique**:
- Récupère la session active de l'utilisateur
- Soustrait le montant de la dépense du `soldeAttendu`
- Met à jour la session dans la base de données
- Affiche des logs pour le suivi

## Calcul de l'Écart (Inchangé)

Le calcul de l'écart dans `backend/src/routes/cash-sessions.js` reste le même:

```javascript
const soldeAttendu = activeSession.soldeAttendu 
  ? parseFloat(activeSession.soldeAttendu) 
  : parseFloat(activeSession.soldeOuverture);
const soldeFermetureFloat = parseFloat(soldeFermeture);
const ecart = soldeFermetureFloat - soldeAttendu;
```

Maintenant que `soldeAttendu` est correctement mis à jour, l'écart sera calculé correctement!

## Exemple de Fonctionnement

### Scénario

1. **Ouverture de caisse**: 10 000 FCFA
   - `soldeOuverture` = 10 000
   - `soldeAttendu` = 10 000

2. **Vente 1**: Client paie 5 000 FCFA
   - `soldeAttendu` = 10 000 + 5 000 = **15 000 FCFA**

3. **Vente 2**: Client paie 3 000 FCFA
   - `soldeAttendu` = 15 000 + 3 000 = **18 000 FCFA**

4. **Dépense**: Achat fournitures 2 000 FCFA
   - `soldeAttendu` = 18 000 - 2 000 = **16 000 FCFA**

5. **Clôture**: Caissier déclare 15 500 FCFA
   - `soldeFermeture` = 15 500
   - `soldeAttendu` = 16 000
   - **Écart** = 15 500 - 16 000 = **-500 FCFA** (manque)

## Fichiers Modifiés

1. ✅ `backend/src/routes/sales.js` - Mise à jour lors des ventes
2. ✅ `backend/src/services/financial-movement.js` - Mise à jour lors des dépenses

## Test de Validation

Pour tester la correction:

### 1. Ouvrir une Session
```
Solde ouverture: 10 000 FCFA
```

### 2. Faire une Vente
```
Montant payé: 5 000 FCFA
→ Vérifier dans les logs: "Solde attendu après: 15000 FCFA"
```

### 3. Créer une Dépense
```
Montant: 1 000 FCFA
→ Vérifier dans les logs: "Solde attendu après: 14000 FCFA"
```

### 4. Clôturer la Session
```
Montant déclaré: 13 500 FCFA
→ Écart attendu: 13 500 - 14 000 = -500 FCFA (manque)
```

### 5. Vérifier l'Historique
- Aller dans "Sessions de Caisse" (drawer)
- Vérifier que l'écart est bien affiché: **-500 FCFA** (rouge)

## Logs à Surveiller

### Lors d'une Vente
```
💰 Session de caisse mise à jour:
   Solde attendu avant: 10000 FCFA
   Montant vente: +5000 FCFA
   Solde attendu après: 15000 FCFA
```

### Lors d'une Dépense
```
💰 Session de caisse mise à jour:
   Solde attendu avant: 15000 FCFA
   Dépense: -1000 FCFA
   Solde attendu après: 14000 FCFA
```

### Lors de la Clôture
```
📊 Clôture caisse Caisse Principale:
   Solde ouverture: 10000 FCFA
   Solde attendu: 14000 FCFA
   Solde déclaré: 13500 FCFA
   Écart: -500 FCFA
```

## Gestion des Erreurs

Les deux mises à jour sont dans des blocs `try-catch` pour ne pas bloquer:
- La vente si la mise à jour de la session échoue
- La dépense si la mise à jour de la session échoue

Les erreurs sont loggées mais n'empêchent pas l'opération principale.

## Redémarrage Requis

⚠️ **Important**: Redémarrer le backend pour que les modifications prennent effet:

```bash
cd backend
npm run dev
```

Ou utiliser le script:
```bash
restart-backend-with-migration.bat
```

## Prochaines Améliorations

- 📊 Afficher le solde attendu en temps réel sur le dashboard (admin)
- 🔔 Alertes si l'écart dépasse un seuil
- 📈 Graphiques d'évolution du solde pendant la session
- 📧 Notification automatique à l'admin en cas d'écart important
