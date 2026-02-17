# Correction - Erreur de Connexion à la Caisse

## Problème Rencontré

Lors de la tentative de connexion à une caisse, une erreur 400 se produisait:

```
POST /api/v1/cash-sessions/connect 400
```

## Cause

**Incompatibilité de noms de paramètres** entre le frontend et le backend:

- **Frontend** (Flutter): Envoyait `soldeOuverture`
- **Backend** (Node.js): Attendait `soldeInitial`

## Solutions Appliquées

### 1. Correction du Service Flutter

**Fichier**: `logesco_v2/lib/features/cash_registers/services/cash_session_service.dart`

**Changement**:
```dart
// AVANT
final body = {
  'cashRegisterId': cashRegisterId,
  'soldeOuverture': soldeOuverture,
};

// APRÈS
final body = {
  'cashRegisterId': cashRegisterId,
  'soldeInitial': soldeOuverture, // Le backend attend 'soldeInitial'
};
```

### 2. Ajout des Champs dans les Réponses Backend

**Fichier**: `backend/src/routes/cash-sessions.js`

#### a) Route GET `/active`
Ajout de `soldeAttendu` et `ecart` dans la réponse:
```javascript
const formattedSession = {
  // ... autres champs
  soldeAttendu: activeSession.soldeAttendu ? parseFloat(activeSession.soldeAttendu) : null,
  ecart: activeSession.ecart ? parseFloat(activeSession.ecart) : null,
  // ... autres champs
};
```

#### b) Route POST `/connect`
- Initialisation de `soldeAttendu` lors de la création:
```javascript
const newSession = await prisma.cashSession.create({
  data: {
    // ... autres champs
    soldeAttendu: parseFloat(soldeInitial), // Initialiser avec le solde d'ouverture
    // ... autres champs
  }
});
```

- Ajout dans la réponse:
```javascript
const formattedSession = {
  // ... autres champs
  soldeAttendu: parseFloat(newSession.soldeOuverture),
  ecart: null,
  // ... autres champs
};
```

## Fichiers Modifiés

1. ✅ `logesco_v2/lib/features/cash_registers/services/cash_session_service.dart`
2. ✅ `backend/src/routes/cash-sessions.js`

## Test de Validation

Pour tester la correction:

1. **Ouvrir l'application Flutter**
2. **Aller dans la gestion de caisse**
3. **Cliquer sur "Se connecter à une caisse"**
4. **Sélectionner une caisse disponible**
5. **Saisir un solde d'ouverture** (ex: 10000)
6. **Confirmer**

**Résultat attendu**:
- ✅ Connexion réussie (status 201)
- ✅ Session créée avec `soldeAttendu` initialisé
- ✅ Affichage du solde de caisse sur le dashboard (admin uniquement)

## Logs Attendus

```
POST /api/v1/cash-sessions/connect 201
info: Request completed {"status":201,"url":"/connect"}
```

## Prochaines Étapes

1. ✅ Correction appliquée
2. ⏳ Tester la connexion à une caisse
3. ⏳ Effectuer une vente pour vérifier la mise à jour du solde
4. ⏳ Créer une dépense pour vérifier l'impact sur le solde
5. ⏳ Clôturer la session et vérifier le calcul des écarts
