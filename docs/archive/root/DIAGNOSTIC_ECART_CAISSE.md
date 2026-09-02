# Diagnostic - Problème d'Écart de Caisse

## Problèmes Rapportés

1. ❌ Lors d'une dépense, le montant de la caisse n'est pas mis à jour automatiquement
2. ❌ Les écarts ne sont pas toujours pris en compte lors de la clôture

## Scripts de Diagnostic

### 1. Vérifier le Schéma de la Base de Données

```bash
cd backend
node verify-cash-session-schema.js
```

**Ce script vérifie**:
- ✅ Présence des colonnes `solde_attendu` et `ecart`
- ✅ Sessions actives et leurs valeurs
- ✅ Dernières sessions fermées avec leurs écarts

### 2. Tester le Flux Complet

```bash
cd backend
node test-cash-session-flow.js
```

**Ce script teste**:
- ✅ Création d'une session
- ✅ Mise à jour après vente
- ✅ Mise à jour après dépense
- ✅ Calcul de l'écart à la clôture

## Vérifications à Faire

### A. Backend Redémarré?

⚠️ **IMPORTANT**: Les modifications ne seront actives qu'après redémarrage du backend!

```bash
# Arrêter le backend (Ctrl+C dans le terminal)
# Puis redémarrer:
cd backend
npm run dev
```

### B. Colonnes Présentes?

Exécuter:
```bash
cd backend
node verify-cash-session-schema.js
```

Vérifier que vous voyez:
```
✅ solde_attendu - Présente
✅ ecart - Présente
```

Si elles sont manquantes:
```bash
cd backend
node add-cash-session-columns.js
npx prisma generate
```

### C. Logs du Backend

Lors d'une **vente**, vous devriez voir:
```
💰 Session de caisse mise à jour:
   Solde attendu avant: 10000 FCFA
   Montant vente: +5000 FCFA
   Solde attendu après: 15000 FCFA
```

Lors d'une **dépense**, vous devriez voir:
```
💰 Session de caisse mise à jour:
   Solde attendu avant: 15000 FCFA
   Dépense: -2000 FCFA
   Solde attendu après: 13000 FCFA
```

Lors de la **clôture**, vous devriez voir:
```
📊 Clôture caisse Caisse Principale:
   Solde ouverture: 10000 FCFA
   Solde attendu: 13000 FCFA
   Solde déclaré: 12500 FCFA
   Écart: -500 FCFA
```

### D. Vérifier les Fichiers Modifiés

**1. Ventes** (`backend/src/routes/sales.js`):
```bash
# Chercher "Session de caisse mise à jour"
grep -n "Session de caisse mise à jour" backend/src/routes/sales.js
```

Devrait retourner une ligne (autour de la ligne 765).

**2. Dépenses** (`backend/src/services/financial-movement.js`):
```bash
# Chercher "Session de caisse mise à jour"
grep -n "Session de caisse mise à jour" backend/src/services/financial-movement.js
```

Devrait retourner une ligne (autour de la ligne 125).

## Procédure de Test Complète

### 1. Préparation

```bash
# Terminal 1: Backend
cd backend
npm run dev

# Terminal 2: Vérifications
cd backend
node verify-cash-session-schema.js
```

### 2. Test Manuel

1. **Ouvrir l'application Flutter**
2. **Se connecter en tant qu'admin**
3. **Ouvrir une session de caisse**:
   - Drawer → Sessions de Caisse → Se connecter
   - Solde ouverture: 10 000 FCFA

4. **Faire une vente**:
   - Créer une vente de 5 000 FCFA
   - **Vérifier les logs backend**: Solde attendu devrait passer à 15 000 FCFA

5. **Créer une dépense**:
   - Menu → Mouvements Financiers → Créer
   - Montant: 2 000 FCFA
   - **Vérifier les logs backend**: Solde attendu devrait passer à 13 000 FCFA

6. **Clôturer la session**:
   - Drawer → Sessions de Caisse → Clôturer
   - Déclarer: 12 500 FCFA
   - **Vérifier les logs backend**: Écart devrait être -500 FCFA

7. **Vérifier l'historique**:
   - Drawer → Sessions de Caisse
   - La session fermée devrait afficher: **Écart: -500 FCFA** (en rouge)

### 3. Vérification Base de Données

```bash
cd backend
node verify-cash-session-schema.js
```

Vérifier que la dernière session fermée affiche:
```
Session ID: X
├─ Solde ouverture: 10000 FCFA
├─ Solde attendu: 13000 FCFA
├─ Solde fermeture: 12500 FCFA
└─ Écart: -500 FCFA
```

## Solutions aux Problèmes Courants

### Problème 1: Colonnes Manquantes

**Symptôme**: Erreur "Unknown argument `soldeAttendu`"

**Solution**:
```bash
cd backend
node add-cash-session-columns.js
npx prisma generate
# Redémarrer le backend
```

### Problème 2: Backend Non Redémarré

**Symptôme**: Pas de logs "Session de caisse mise à jour"

**Solution**:
```bash
# Arrêter le backend (Ctrl+C)
cd backend
npm run dev
```

### Problème 3: Écart Toujours à Zéro

**Symptôme**: Écart = 0 même avec des montants différents

**Causes possibles**:
1. Backend non redémarré
2. Modifications non appliquées
3. Session créée avant les modifications

**Solution**:
```bash
# 1. Vérifier les fichiers
git status

# 2. Redémarrer le backend
cd backend
npm run dev

# 3. Créer une NOUVELLE session (les anciennes ne seront pas mises à jour)
```

### Problème 4: soldeAttendu NULL

**Symptôme**: soldeAttendu reste NULL dans la base

**Solution**:
```sql
-- Mettre à jour les sessions actives
UPDATE cash_sessions 
SET solde_attendu = solde_ouverture 
WHERE solde_attendu IS NULL AND is_active = 1;
```

Ou via script:
```bash
cd backend
node -e "const {PrismaClient} = require('@prisma/client'); const p = new PrismaClient(); p.cashSession.updateMany({where: {soldeAttendu: null, isActive: true}, data: {soldeAttendu: {set: p.cashSession.fields.soldeOuverture}}}).then(() => p.\$disconnect())"
```

## Checklist de Validation

- [ ] Colonnes `solde_attendu` et `ecart` présentes
- [ ] Backend redémarré après modifications
- [ ] Logs "Session de caisse mise à jour" visibles lors des ventes
- [ ] Logs "Session de caisse mise à jour" visibles lors des dépenses
- [ ] Logs "Clôture caisse" affichent le bon écart
- [ ] Historique affiche les écarts correctement
- [ ] Test manuel complet réussi

## Support

Si le problème persiste après toutes ces vérifications:

1. **Capturer les logs**:
   ```bash
   cd backend
   npm run dev > logs.txt 2>&1
   ```

2. **Faire un test complet** et envoyer `logs.txt`

3. **Exporter la base de données**:
   ```bash
   cd backend
   node verify-cash-session-schema.js > schema-check.txt
   ```

4. **Vérifier les fichiers modifiés**:
   ```bash
   git diff backend/src/routes/sales.js > sales-diff.txt
   git diff backend/src/services/financial-movement.js > movement-diff.txt
   ```
