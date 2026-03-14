# Guide de Débogage - Relevé de Compte Client

## Problème Rapporté
- **Transactions**: 30 reçues mais 0 affichées dans le PDF
- **Logo**: Affiche `null` malgré une valeur en base de données

## Flux de Données Complet

```
1. FRONTEND - Appel API
   ↓
   GET /api/v1/customers/34/statement?format=a4
   ↓
   
2. BACKEND - Récupération des données
   ↓
   - Récupère le client (ID: 34)
   - Récupère le compte client (compteId)
   - Récupère l'entreprise (logoPath)
   - Récupère les transactions (100 dernières)
   ↓
   
3. BACKEND - Réponse
   ↓
   {
     "success": true,
     "message": "Relevé de compte généré",
     "data": {
       "entreprise": { "logoPath": "..." },
       "client": { ... },
       "compte": { ... },
       "transactions": [ ... ]
     }
   }
   ↓
   
4. FRONTEND SERVICE - Extraction
   ↓
   ApiCustomerService.getCustomerStatement()
   - Reçoit response.data
   - Extrait response.data['data']
   - Retourne les données extraites
   ↓
   
5. FRONTEND CONTROLLER - Passage au PDF
   ↓
   CustomerController.getCustomerStatement()
   - Retourne les données du service
   ↓
   
6. FRONTEND VIEW - Génération PDF
   ↓
   StatementPdfService.generateStatementPDF(statementData)
   - Reçoit les données
   - Affiche les transactions
   - Charge le logo
   ↓
   
7. PDF Généré
```

## Points de Vérification

### 1. Backend - Vérifier les logs

Quand vous générez le relevé, cherchez ces logs dans la console du backend:

```
📋 Informations entreprise: Trouvées
   Nom: [NOM_ENTREPRISE]

📊 Relevé de compte client 34:
   Compte ID: [ID_COMPTE]
   Transactions trouvées: 30
   Première transaction: {...}

📊 Données du relevé:
   Transactions: 30
   Logo: [CHEMIN_LOGO]
   Structure complète: {...}
```

**Si vous voyez:**
- `Transactions trouvées: 0` → Le compte n'a pas de transactions
- `Logo: Non défini` → Le logoPath n'est pas en base de données
- `Transactions trouvées: 30` mais pas d'affichage → Problème dans le frontend

### 2. Frontend Service - Vérifier les logs

Cherchez ces logs dans la console Flutter:

```
📄 Récupération relevé de compte pour client 34
📡 Réponse relevé de compte:
  - Success: true
  - Response data type: Map<String, dynamic>
  - Response data keys: [success, message, data]

✅ Données du relevé extraites:
  - Entreprise: Présente
  - Client: Présent
  - Compte: Présent
  - Transactions: 30
  - Logo path: [CHEMIN_LOGO]
```

**Si vous voyez:**
- `Response data keys: [success, message, data]` → Structure correcte
- `Transactions: 0` → Les données ne sont pas extraites correctement
- `Logo path: null` → Le logoPath n'est pas dans la réponse

### 3. Frontend PDF - Vérifier les logs

Cherchez ces logs dans la console Flutter:

```
📊 [PDF] Données reçues:
   - Type: Map<String, dynamic>
   - Clés: [entreprise, client, compte, transactions, dateGeneration, format]
   - Contenu complet: {...}

📊 Génération PDF relevé de compte:
   Transactions reçues: 30
   Type transactions: List<dynamic>
   Première transaction: {...}
   Logo path: [CHEMIN_LOGO]
   Entreprise: [NOM_ENTREPRISE]

📝 [PDF] Traitement transaction #0
   - Type: Map<String, dynamic>
   - Contenu: {...}
   - Description: [DESCRIPTION]
   - Type transaction: [TYPE]
   ✅ Montant: [MONTANT], Solde: [SOLDE]
```

**Si vous voyez:**
- `Transactions reçues: 0` → Les données ne sont pas passées correctement
- `Traitement transaction #0` → Les transactions sont traitées
- Pas de logs de traitement → Les transactions ne sont pas dans la boucle

## Scénarios de Débogage

### Scénario 1: Transactions = 0 dans le PDF

**Étape 1**: Vérifier le backend
```bash
# Cherchez dans les logs du backend:
# "Transactions trouvées: 30"
# Si vous voyez "Transactions trouvées: 0":
#   → Le compte n'a pas de transactions
#   → Vérifier que le compteId est correct
```

**Étape 2**: Vérifier le service
```dart
// Les logs doivent montrer:
// "Transactions: 30"
// Si vous voyez "Transactions: 0":
//   → Les données ne sont pas extraites correctement
//   → Vérifier response.data['data']['transactions']
```

**Étape 3**: Vérifier le PDF
```dart
// Les logs doivent montrer:
// "Transactions reçues: 30"
// Si vous voyez "Transactions reçues: 0":
//   → Les données ne sont pas passées au PDF
//   → Vérifier statementData['transactions']
```

### Scénario 2: Logo = null

**Étape 1**: Vérifier la base de données
```sql
-- Vérifier que le logoPath est défini
SELECT logoPath FROM parametresEntreprise ORDER BY dateCreation DESC LIMIT 1;
-- Doit retourner un chemin, pas NULL
```

**Étape 2**: Vérifier le backend
```javascript
// Les logs doivent montrer:
// "Logo: /path/to/logo.png"
// Si vous voyez "Logo: Non défini":
//   → Le logoPath n'est pas en base de données
//   → Vérifier parametresEntreprise.logoPath
```

**Étape 3**: Vérifier le service
```dart
// Les logs doivent montrer:
// "Logo path: /path/to/logo.png"
// Si vous voyez "Logo path: null":
//   → Le logoPath n'est pas dans la réponse
//   → Vérifier response.data['data']['entreprise']['logoPath']
```

**Étape 4**: Vérifier le PDF
```dart
// Les logs doivent montrer:
// "Logo path: /path/to/logo.png"
// Si vous voyez "Logo path: null":
//   → Les données ne sont pas passées au PDF
//   → Vérifier data['entreprise']['logoPath']
```

## Commandes de Test

### Test 1: Vérifier les transactions en base de données

```sql
-- Vérifier qu'il y a des transactions pour le client 34
SELECT COUNT(*) FROM transactionCompte 
WHERE typeCompte = 'client' 
AND compteId = (SELECT id FROM compteClient WHERE clientId = 34);

-- Doit retourner: 30 (ou le nombre attendu)
```

### Test 2: Vérifier le logoPath en base de données

```sql
-- Vérifier que le logoPath est défini
SELECT logoPath FROM parametresEntreprise 
ORDER BY dateCreation DESC LIMIT 1;

-- Doit retourner: /path/to/logo.png (ou une URL)
```

### Test 3: Tester l'endpoint directement

```bash
# Avec curl
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8080/api/v1/customers/34/statement?format=a4"

# Doit retourner:
# {
#   "success": true,
#   "message": "Relevé de compte généré",
#   "data": {
#     "transactions": [...],
#     "entreprise": { "logoPath": "..." }
#   }
# }
```

## Checklist de Vérification

- [ ] Backend retourne 30 transactions (vérifier les logs)
- [ ] Backend retourne logoPath (vérifier les logs)
- [ ] Service extrait correctement les données (vérifier les logs)
- [ ] PDF reçoit 30 transactions (vérifier les logs)
- [ ] PDF reçoit logoPath (vérifier les logs)
- [ ] PDF affiche les transactions dans le tableau
- [ ] PDF affiche le logo dans l'en-tête
- [ ] PDF est généré sans erreur

## Fichiers Clés

1. **Backend**: `backend/src/routes/customers.js` - Endpoint `/customers/:id/statement`
2. **Service**: `logesco_v2/lib/features/customers/services/api_customer_service.dart` - `getCustomerStatement()`
3. **PDF**: `logesco_v2/lib/features/customers/services/statement_pdf_service.dart` - `generateStatementPDF()`
4. **View**: `logesco_v2/lib/features/customers/views/customer_account_view.dart` - `_generateAndPrintStatement()`

## Prochaines Étapes

1. Générer un relevé de compte
2. Vérifier les logs du backend
3. Vérifier les logs du frontend
4. Identifier le point de rupture
5. Appliquer la correction appropriée
6. Tester à nouveau

## Notes

- Les logs sont très détaillés pour faciliter le débogage
- Chaque étape du flux affiche des informations de diagnostic
- Si une étape affiche 0 transactions, le problème est avant cette étape
- Si une étape affiche 30 transactions mais la suivante affiche 0, le problème est dans la transmission
