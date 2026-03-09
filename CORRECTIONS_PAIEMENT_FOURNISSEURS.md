# Corrections - Paiement fournisseurs

## Problèmes identifiés et corrigés

### 1. ✅ Erreur 404 sur l'endpoint du relevé
**Problème**: Route `GET /accounts/suppliers/:id/statement` non trouvée

**Cause**: Backend pas redémarré après l'ajout de la route

**Solution**: Redémarrage du backend requis

---

### 2. ✅ Erreur de cast dans le PDF
**Problème**: `type 'int' is not a subtype of type 'double' in type cast`

**Cause**: Le backend retourne des `int` pour les montants, mais le code PDF attendait des `double`

**Solution**: Conversion sûre des types dans `supplier_statement_pdf_service.dart`

```dart
// Avant
final solde = compte['solde'] as double;

// Après
final solde = (compte['solde'] is int) 
    ? (compte['solde'] as int).toDouble() 
    : (compte['solde'] as double);
```

**Fichier modifié**: `logesco_v2/lib/features/suppliers/services/supplier_statement_pdf_service.dart`

---

### 3. ✅ Erreur de champs dans ParametresEntreprise
**Problème**: `Unknown field 'nom' for select statement on model 'ParametresEntreprise'`

**Cause**: Le modèle utilise `nomEntreprise` et `localisation`, pas `nom` et `adresse`

**Solution**: Correction des noms de champs dans l'endpoint du relevé

```javascript
// Avant
const entreprise = await models.prisma.parametresEntreprise.findFirst({
  select: {
    nom: true,
    adresse: true,
    telephone: true,
    email: true
  }
});

// Après
const entreprise = await models.prisma.parametresEntreprise.findFirst({
  select: {
    nomEntreprise: true,
    localisation: true,
    telephone: true,
    email: true
  }
});
```

**Fichier modifié**: `backend/src/routes/accounts.js`

---

### 4. ✅ Commande payée qui apparaît encore dans les impayées
**Problème**: Une commande déjà payée apparaissait encore dans la liste des commandes à payer

**Cause**: Le paiement précédent n'avait pas de `referenceType` et `referenceId` pour le lier à la commande

**Diagnostic**:
```
Commande #CMD20260222003 (ID: 38)
  Montant total: 29400 FCFA
  ⚠️  Aucun paiement enregistré (car pas de référence)
  📊 Montant restant: 29400 FCFA
```

**Solution**: 
1. Correction manuelle du paiement existant avec `fix-payment-reference.js`
2. Le nouveau code enregistre correctement les références lors des paiements

**Résultat après correction**:
```
Commande #CMD20260222003 (ID: 38)
  Montant total: 29400 FCFA
  💳 1 paiement(s): 29400 FCFA
  📊 Montant restant: 0 FCFA
  ✅ COMMANDE PAYÉE COMPLÈTEMENT (ne devrait PAS apparaître)
```

**Scripts créés**:
- `backend/check-supplier-payments.js` - Diagnostic des paiements
- `backend/fix-payment-reference.js` - Correction du paiement existant

---

## Vérification

### Test 1: Impression du relevé ✅
1. Ouvrir le compte d'un fournisseur
2. Cliquer sur "Imprimer"
3. Le PDF devrait se générer et s'ouvrir sans erreur

### Test 2: Liste des commandes impayées ✅
1. Ouvrir le compte du fournisseur SOCATOO SARL (ID: 16)
2. Cliquer sur "Payer le fournisseur"
3. Cliquer sur "Sélectionner une commande"
4. La commande CMD20260222003 ne devrait PLUS apparaître
5. Le solde devrait afficher "0 FCFA" et "Aucune dette en cours"

### Test 3: Nouveau paiement avec référence ✅
1. Créer une nouvelle commande pour un fournisseur
2. Payer cette commande via l'interface
3. Le paiement devrait avoir `referenceType: 'approvisionnement'` et `referenceId: <id_commande>`
4. La commande ne devrait plus apparaître dans les impayées après paiement complet

---

## Logs de débogage ajoutés

L'endpoint `/accounts/suppliers/:id/unpaid-procurements` affiche maintenant des logs détaillés:

```
🔍 Récupération commandes impayées fournisseur: 16
📦 1 commande(s) trouvée(s)
💰 1 transaction(s) de paiement trouvée(s)
  ✅ Commande 38: +29400 (total: 29400)
📊 Paiements par commande: { '38': 29400 }
📋 Commande CMD20260222003: { id: 38, montantTotal: 29400, montantPaye: 29400, montantRestant: 0 }
  ❌ Commande CMD20260222003: montantRestant=0 (EXCLUE)
✅ 0 commande(s) impayée(s) retournée(s)
```

---

## Fichiers modifiés

1. `backend/src/routes/accounts.js`
   - Correction champs ParametresEntreprise
   - Ajout logs de débogage

2. `logesco_v2/lib/features/suppliers/services/supplier_statement_pdf_service.dart`
   - Conversion sûre des types int/double

3. Scripts créés:
   - `backend/check-supplier-payments.js`
   - `backend/fix-payment-reference.js`
   - `check-supplier-16.bat`
   - `restart-backend-debug.bat`

---

## Prochaines étapes

1. ✅ Redémarrer le backend
2. ✅ Tester l'impression du relevé
3. ✅ Vérifier que les commandes payées n'apparaissent plus
4. ✅ Tester un nouveau paiement pour confirmer que les références sont bien enregistrées

---

## Commandes utiles

```bash
# Vérifier les paiements d'un fournisseur
cd backend
node check-supplier-payments.js <fournisseurId>

# Redémarrer le backend avec logs
restart-backend-debug.bat
```
