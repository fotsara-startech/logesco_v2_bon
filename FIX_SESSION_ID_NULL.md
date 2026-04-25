# Fix: sessionId Null dans Financial Movements

## Problème

Quand vous créez une dépense, le champ `sessionId` est null dans la base de données locale et dans Neon.

## Cause

Le code cherchait une session active avec des critères trop restrictifs:
- `utilisateurId` = l'utilisateur qui crée la dépense
- `isActive` = true
- `dateFermeture` = null
- `boutiqueId` = la boutique

Si aucune session ne correspond à TOUS ces critères, `sessionId` reste null.

## Cas Typiques

### Cas 1: Aucune Session Ouverte
```
User crée une dépense
    ↓
Aucune session de caisse ouverte
    ↓
sessionId = null ❌
```

### Cas 2: Session d'un Autre Utilisateur
```
User A ouvre une session
    ↓
User B crée une dépense
    ↓
Code cherche session de User B
    ↓
Trouve seulement session de User A
    ↓
sessionId = null ❌
```

### Cas 3: Session Fermée
```
User ouvre une session
    ↓
User ferme la session
    ↓
User crée une dépense
    ↓
Session a dateFermeture définie
    ↓
sessionId = null ❌
```

## Solution Implémentée

Le code cherche maintenant en deux étapes:

### Priorité 1: Session de l'Utilisateur
```javascript
// Chercher session de l'utilisateur dans la boutique
WHERE:
  utilisateurId = data.utilisateurId
  boutiqueId = data.boutiqueId
  isActive = true
  dateFermeture = null
```

### Priorité 2: N'importe Quelle Session Active
```javascript
// Si pas trouvé, chercher n'importe quelle session active dans la boutique
WHERE:
  boutiqueId = data.boutiqueId
  isActive = true
  dateFermeture = null
ORDER BY dateOuverture DESC
```

## Comportement Après Fix

### Scénario 1: Session de l'Utilisateur Existe
```
User A crée une dépense
    ↓
Session de User A trouvée
    ↓
sessionId = session de User A ✅
```

### Scénario 2: Session d'un Autre Utilisateur
```
User B crée une dépense
    ↓
Pas de session pour User B
    ↓
Cherche n'importe quelle session active
    ↓
Trouve session de User A
    ↓
sessionId = session de User A ✅
```

### Scénario 3: Aucune Session Active
```
User crée une dépense
    ↓
Aucune session active dans la boutique
    ↓
sessionId = null ⚠️
    ↓
Log: "Aucune session active trouvée"
```

## Vérification

### Étape 1: Vérifier les Sessions Actives

```bash
# Pour utilisateur 1, boutique 7
node check-active-sessions.js 1 7
```

**Attendu**:
```
✅ 1 session(s) active(s) trouvée(s):

Session ID: 52
Caisse: Caisse Express
Utilisateur: admin (ID: 1)
Boutique: Boutique A (ID: 7)
isActive: true
Date Fermeture: N/A
```

### Étape 2: Redémarrer le Backend

```bash
npm start
```

### Étape 3: Créer une Dépense

- Ouvrir l'app
- Créer un mouvement financier

### Étape 4: Vérifier les Logs

**Attendu**:
```
✅ Session active trouvée: ID 52
✅ Mouvement financier créé: MF-20260425-XXXX - 1000€ - boutiqueId: 7
```

**Si aucune session**:
```
⚠️ Aucune session pour cet utilisateur, recherche d'une session active dans la boutique...
⚠️ Aucune session active trouvée - le mouvement sera créé sans session
   Critères: utilisateurId=1, boutiqueId=7, isActive=true
```

### Étape 5: Vérifier la Base de Données

```bash
node check-financial-movements-neon.js
```

Le `sessionId` devrait maintenant être défini.

## Recommandations

### Pour Éviter sessionId Null

1. **Toujours ouvrir une session de caisse** avant de créer des dépenses
2. **Ne pas fermer la session** pendant la journée
3. **Vérifier que isActive = true** dans la base de données

### Ouvrir une Session de Caisse

Dans l'app:
1. Aller dans "Caisse"
2. Cliquer sur "Ouvrir Session"
3. Entrer le solde d'ouverture
4. Confirmer

### Vérifier la Session Active

```bash
node check-active-sessions.js 1 7
```

Devrait montrer au moins une session active.

## Impact du sessionId Null

### ⚠️ Problèmes Potentiels

1. **Rapports**: Les dépenses sans session ne sont pas liées à une session de caisse
2. **Traçabilité**: Difficile de savoir quelle session a effectué la dépense
3. **Comptabilité**: Le solde de la session peut être incorrect

### ✅ Pas de Problème

- La dépense est quand même créée
- Le montant est enregistré
- La synchronisation fonctionne
- Le solde de la caisse est mis à jour

## Alternative: Créer une Session Automatiquement

Si vous voulez créer automatiquement une session quand il n'y en a pas, ajoutez ce code:

```javascript
if (!activeSession && data.boutiqueId) {
  // Créer une session automatique
  const caisse = await this.prisma.cashRegister.findFirst({
    where: {
      boutiqueId: parseInt(data.boutiqueId),
      isActive: true
    }
  });

  if (caisse) {
    activeSession = await this.prisma.cashSession.create({
      data: {
        caisseId: caisse.id,
        utilisateurId: data.utilisateurId,
        boutiqueId: parseInt(data.boutiqueId),
        soldeOuverture: caisse.soldeActuel,
        isActive: true
      }
    });
    console.log(`✅ Session automatique créée: ID ${activeSession.id}`);
  }
}
```

## Conclusion

Le fix permet maintenant de trouver une session active même si elle n'appartient pas à l'utilisateur qui crée la dépense. Cela évite les `sessionId` null dans la plupart des cas.

---

**Status**: ✅ Fix implémenté

**Action**: Redémarrer le backend et tester
