# Plan de test - Champs NUI et RCCM

## Objectif
Valider l'ajout des champs NUI (Numéro d'Identification Unique) et RCCM (Registre du Commerce et du Crédit Mobilier) aux clients.

## Pré-requis
- ✅ Migration appliquée : `npx prisma migrate deploy`
- ✅ Serveur backend redémarré
- ✅ Application Flutter en cours d'exécution

---

## Test 1 : Création d'un client entreprise avec NUI et RCCM

### Étapes
1. Ouvrir l'application Flutter
2. Naviguer vers "Clients" > "Nouveau client"
3. Remplir les informations :
   - Nom : `ENTREPRISE TEST SARL`
   - Prénom : (laisser vide)
   - Téléphone : `+243 123 456 789`
   - Email : `contact@entreprise-test.cd`
   - Adresse : `123 Avenue Commerce, Kinshasa`
4. Faire défiler jusqu'à "Informations entreprise (optionnel)"
5. Remplir :
   - NUI : `A1234567890`
   - RCCM : `CD/KNG/RCCM/12-A-12345`
6. Cliquer sur "Créer"

### Résultat attendu
- ✅ Message de succès "Client créé avec succès"
- ✅ Retour à la liste des clients
- ✅ Client visible avec le nom "ENTREPRISE TEST SARL"

### Vérification backend
```bash
# Requête SQL pour vérifier
SELECT id, nom, nui, rccm FROM clients WHERE nom = 'ENTREPRISE TEST SARL';
```

---

## Test 2 : Modification d'un client existant

### Étapes
1. Ouvrir un client existant (sans NUI/RCCM)
2. Cliquer sur "Modifier"
3. Ajouter :
   - NUI : `B9876543210`
   - RCCM : `CD/BAS/RCCM/23-B-67890`
4. Sauvegarder

### Résultat attendu
- ✅ Message de succès "Client modifié avec succès"
- ✅ Champs NUI et RCCM sauvegardés

---

## Test 3 : Génération de reçu avec NUI/RCCM (Format Thermique)

### Étapes
1. Créer une vente pour "ENTREPRISE TEST SARL"
2. Ajouter des articles à la vente
3. Finaliser la vente
4. Générer le reçu (format thermique 80mm)
5. Prévisualiser ou imprimer

### Résultat attendu
Le reçu doit afficher :
```
================================
N° Vente: V-2026-001
Date: 17/07/2026
Heure: 12:55
Client: ENTREPRISE TEST SARL
NUI: A1234567890
RCCM: CD/KNG/RCCM/12-A-12345
Paiement: Espèces
================================
```

---

## Test 4 : Génération de reçu avec NUI/RCCM (Format A4)

### Étapes
1. Ouvrir la même vente
2. Choisir le format A4
3. Générer le reçu

### Résultat attendu
Le reçu A4 doit afficher dans la section informations :
```
Client:                    ENTREPRISE TEST SARL
NUI:                       A1234567890
RCCM:                      CD/KNG/RCCM/12-A-12345
```

---

## Test 5 : Génération de reçu SANS NUI/RCCM

### Étapes
1. Créer une vente pour un client particulier (sans NUI/RCCM)
2. Finaliser et générer le reçu

### Résultat attendu
- ✅ Le reçu s'affiche normalement
- ✅ Les lignes NUI et RCCM ne sont PAS présentes
- ✅ Format :
```
================================
N° Vente: V-2026-002
Date: 17/07/2026
Client: DUPONT Jean
Paiement: Espèces
================================
(pas de NUI ni RCCM)
```

---

## Test 6 : Impression physique (Imprimante thermique)

### Étapes
1. Connecter une imprimante thermique ESC/POS
2. Créer une vente pour un client avec NUI/RCCM
3. Imprimer le reçu

### Résultat attendu
- ✅ Le reçu s'imprime correctement
- ✅ NUI et RCCM sont visibles sur le papier
- ✅ Pas de caractères manquants ou tronqués

---

## Test 7 : Validation des champs (Frontend)

### Test 7.1 : Champs vides acceptés
1. Créer un client sans remplir NUI et RCCM
2. ✅ Le formulaire se valide sans erreur

### Test 7.2 : Capitalisation automatique
1. Taper `a1234567890` dans le champ NUI
2. ✅ Le texte doit s'afficher en majuscules : `A1234567890`

---

## Test 8 : API Backend

### Test 8.1 : POST /api/customers (Création)
```bash
curl -X POST http://localhost:3000/api/customers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "nom": "SOCIETE ABC",
    "telephone": "+243987654321",
    "nui": "C1111111111",
    "rccm": "CD/LUB/RCCM/24-C-99999"
  }'
```

**Résultat attendu** : Status 201, client créé avec NUI et RCCM

### Test 8.2 : PUT /api/customers/:id (Modification)
```bash
curl -X PUT http://localhost:3000/api/customers/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "nui": "D2222222222",
    "rccm": "CD/GOM/RCCM/24-D-88888"
  }'
```

**Résultat attendu** : Status 200, client modifié

### Test 8.3 : GET /api/customers/:id (Récupération)
```bash
curl -X GET http://localhost:3000/api/customers/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Résultat attendu** : 
```json
{
  "success": true,
  "data": {
    "id": 1,
    "nom": "SOCIETE ABC",
    "nui": "D2222222222",
    "rccm": "CD/GOM/RCCM/24-D-88888",
    ...
  }
}
```

---

## Test 9 : Base de données

### Vérification de la structure
```sql
-- Vérifier que les colonnes existent
\d clients;

-- Ou
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'clients' 
  AND column_name IN ('nui', 'rccm');
```

**Résultat attendu** :
```
column_name | data_type        | is_nullable
------------|------------------|-------------
nui         | character varying| YES
rccm        | character varying| YES
```

### Vérification des index
```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'clients' 
  AND indexname IN ('idx_clients_nui', 'idx_clients_rccm');
```

---

## Test 10 : Rétrocompatibilité

### Objectif
Vérifier que les clients existants (sans NUI/RCCM) fonctionnent toujours

### Étapes
1. Ouvrir un ancien client (créé avant la migration)
2. Générer une vente
3. Créer un reçu

### Résultat attendu
- ✅ Le client s'affiche normalement
- ✅ La vente se crée sans erreur
- ✅ Le reçu se génère sans erreur
- ✅ NUI et RCCM n'apparaissent pas (car vides)

---

## Checklist finale

### Backend
- [ ] Migration appliquée avec succès
- [ ] Client Prisma généré
- [ ] API POST /customers accepte NUI et RCCM
- [ ] API PUT /customers accepte NUI et RCCM
- [ ] API GET /customers retourne NUI et RCCM
- [ ] Validation Joi fonctionne correctement

### Frontend
- [ ] Formulaire affiche les champs NUI et RCCM
- [ ] Capitalisation automatique fonctionne
- [ ] Champs sont optionnels (validation OK)
- [ ] Sauvegarde fonctionne (création et modification)
- [ ] Champs s'affichent en mode édition

### Reçus
- [ ] NUI/RCCM s'affichent sur reçu thermique
- [ ] NUI/RCCM s'affichent sur reçu A4
- [ ] NUI/RCCM s'affichent sur reçu A5
- [ ] NUI/RCCM s'affichent sur preview PDF
- [ ] Affichage conditionnel fonctionne (n'apparaît que si renseigné)
- [ ] Impression physique fonctionne

### Compatibilité
- [ ] Clients existants sans NUI/RCCM fonctionnent
- [ ] Ventes avec anciens clients fonctionnent
- [ ] Reçus pour anciens clients fonctionnent

---

## Problèmes connus et solutions

### Problème : Caractères accentués mal affichés
**Solution** : Vérifier l'encodage UTF-8 des fichiers

### Problème : Champs non sauvegardés
**Solution** : 
1. Vérifier que la migration est appliquée
2. Redémarrer le serveur backend
3. Vider le cache de l'application Flutter

### Problème : NUI/RCCM non affichés sur reçu
**Solution** :
1. Vérifier que les valeurs sont présentes dans l'objet customer
2. Vérifier la console pour les erreurs
3. Recréer la vente

---

## Date du test
À compléter lors de l'exécution des tests

## Testeur
À compléter

## Résultat global
- [ ] ✅ Tous les tests passent
- [ ] ⚠️ Tests passent avec des remarques mineures
- [ ] ❌ Des tests échouent (détailler ci-dessous)

## Remarques
_À compléter lors des tests_
