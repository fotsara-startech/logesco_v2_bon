# Guide de Débogage - Mode de Paiement Comptant

## Modifications effectuées

### 1. Schéma de validation (backend/src/validation/schemas.js)
✅ Ajout du champ `modePaiement` au schéma de réception

### 2. Route de réception (backend/src/routes/procurement.js)
✅ Extraction et utilisation du `modePaiement` lors de la réception
✅ Création des 2 transactions pour le paiement comptant

### 3. Service frontend (logesco_v2/lib/features/procurement/services/procurement_service.dart)
✅ Ajout de logs de débogage pour tracer les requêtes

## Étapes de test

### 1. Redémarrer le backend
```bash
cd backend
# Arrêter le serveur (Ctrl+C)
npm start
```

### 2. Redémarrer l'application Flutter
```bash
cd logesco_v2
# Arrêter l'app
flutter run
```

### 3. Effectuer un test complet

1. Créer un nouveau fournisseur
2. Créer une commande d'approvisionnement
3. Réceptionner la commande
4. **IMPORTANT**: Sélectionner "Comptant" dans le dialogue de réception
5. Confirmer la réception

### 4. Vérifier les logs

#### Dans la console Flutter:
Vous devriez voir:
```
🔍 ENVOI RÉCEPTION:
   - ID commande: X
   - Mode paiement: comptant  ← DOIT ÊTRE "comptant"
   - Body: {"details":[...],"modePaiement":"comptant"}

📥 RÉPONSE BACKEND:
   - Status: 200
   - Body: {...}
```

#### Dans la console Backend (Node.js):
Vous devriez voir:
```
🔍 Mode de paiement: comptant (reçu: comptant, commande: credit)
💰 Montant de la réception: 4000 FCFA
💵 Commande comptant - Enregistrement achat + paiement immédiat
✅ Paiement comptant enregistré - Solde fournisseur inchangé: 0 FCFA
```

### 5. Vérifier le compte fournisseur

Dans l'application, aller sur le compte du fournisseur:
- **Attendu**: 2 transactions (Achat + Paiement)
- **Solde**: 0 FCFA

## Si ça ne marche toujours pas

### Vérification 1: Le modePaiement est-il envoyé?
Regardez les logs Flutter. Si vous voyez:
```
Mode paiement: null
```
→ Le problème est dans le frontend (dialog)

### Vérification 2: Le backend reçoit-il le modePaiement?
Regardez les logs backend. Si vous voyez:
```
🔍 Vérification mode paiement: credit
```
→ Le backend ne reçoit pas le modePaiement ou la validation le rejette

### Vérification 3: Les transactions sont-elles créées?
Regardez les logs backend. Si vous ne voyez PAS:
```
💵 Commande comptant - Enregistrement achat + paiement immédiat
```
→ Le code de création des transactions n'est pas exécuté

## Cas problématiques possibles

### Cas 1: Validation Joi rejette le modePaiement
**Symptôme**: Erreur 400 dans les logs Flutter
**Solution**: Vérifier que le schéma dans `backend/src/validation/schemas.js` contient bien:
```javascript
reception: Joi.object({
  details: [...],
  modePaiement: baseSchemas.modePaiement.optional()
}),
```

### Cas 2: Le frontend n'envoie pas la bonne valeur
**Symptôme**: Logs Flutter montrent `modePaiement: null` ou valeur incorrecte
**Solution**: Vérifier dans `receive_commande_dialog.dart` ligne 371:
```dart
modePaiement: _selectedModePaiement.value,  // Doit être .value
```

### Cas 3: Le backend n'utilise pas le modePaiement reçu
**Symptôme**: Logs backend montrent toujours "credit"
**Solution**: Vérifier dans `backend/src/routes/procurement.js` ligne 550:
```javascript
const { details, modePaiement: modePaiementReception } = req.body;
const modePaiementFinal = modePaiementReception || commande.modePaiement;
```

## Commandes utiles

### Voir les logs backend en temps réel
```bash
cd backend
npm start
```

### Voir les logs Flutter
```bash
cd logesco_v2
flutter run
# Les logs apparaissent automatiquement
```

### Tester avec le script automatique
```bash
node test-procurement-comptant.js
```

## Contact

Si le problème persiste après ces vérifications, partagez:
1. Les logs Flutter (section 🔍 ENVOI RÉCEPTION)
2. Les logs Backend (toute la section de réception)
3. Une capture d'écran du compte fournisseur
