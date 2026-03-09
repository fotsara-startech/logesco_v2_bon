# Guide de test - Paiement fournisseurs

## Préparation

### 1. Redémarrer le backend
```bash
restart-backend-supplier-payment.bat
```

### 2. Vérifier les prérequis
- [ ] Backend démarré et accessible
- [ ] Application Flutter lancée
- [ ] Au moins un fournisseur avec des commandes
- [ ] Une session de caisse ouverte (pour test mouvement financier)

## Tests à effectuer

### Test 1: Impression du relevé ✓

**Objectif**: Vérifier que le relevé PDF est généré correctement

**Étapes**:
1. Aller dans "Fournisseurs"
2. Cliquer sur un fournisseur
3. Cliquer sur "Consulter le compte"
4. Cliquer sur le bouton "Imprimer"
5. Attendre la génération du PDF

**Résultat attendu**:
- ✅ Message "Génération du relevé..."
- ✅ PDF généré et ouvert automatiquement
- ✅ PDF contient:
  - En-tête entreprise
  - Informations fournisseur
  - Solde du compte (en rouge si dette, vert si équilibré)
  - Tableau des transactions
  - Date d'impression

**En cas d'erreur**:
- Vérifier que l'endpoint `/accounts/suppliers/:id/statement` existe
- Vérifier les logs backend
- Vérifier que le fournisseur a un compte

---

### Test 2: Paiement simple (sans mouvement financier) ✓

**Objectif**: Vérifier qu'on peut payer une commande sans créer de mouvement financier

**Étapes**:
1. Aller dans le compte d'un fournisseur avec dette
2. Cliquer sur "Payer le fournisseur"
3. Cliquer sur "Sélectionner une commande"
4. Choisir une commande dans la liste
5. Vérifier que le montant est pré-rempli
6. Modifier le montant si nécessaire (paiement partiel)
7. NE PAS cocher "Créer un mouvement financier"
8. Cliquer sur "Confirmer le paiement"

**Résultat attendu**:
- ✅ Bouton "Confirmer" désactivé tant qu'aucune commande n'est sélectionnée
- ✅ Après sélection, montant pré-rempli avec le montant restant
- ✅ Description pré-remplie avec "Paiement Commande #XXX"
- ✅ Paiement enregistré avec succès
- ✅ Solde fournisseur mis à jour
- ✅ Transaction visible dans l'historique
- ✅ AUCUN mouvement financier créé

**Vérifications**:
```sql
-- Vérifier la transaction
SELECT * FROM TransactionCompte 
WHERE typeCompte = 'fournisseur' 
ORDER BY dateTransaction DESC LIMIT 1;

-- Vérifier qu'aucun mouvement financier n'a été créé
SELECT * FROM MouvementFinancier 
WHERE referenceType = 'transaction_compte' 
ORDER BY dateCreation DESC LIMIT 1;
```

---

### Test 3: Paiement avec mouvement financier (succès) ✓

**Objectif**: Vérifier la création du mouvement financier et la déduction de la caisse

**Prérequis**:
- Session de caisse ouverte
- Solde de caisse suffisant (ex: 100 000 FCFA)

**Étapes**:
1. Noter le solde actuel de la caisse
2. Aller dans le compte d'un fournisseur
3. Cliquer sur "Payer le fournisseur"
4. Sélectionner une commande
5. Entrer un montant (ex: 50 000 FCFA)
6. COCHER "Créer un mouvement financier"
7. Lire le message d'avertissement
8. Cliquer sur "Confirmer le paiement"

**Résultat attendu**:
- ✅ Paiement enregistré
- ✅ Solde fournisseur mis à jour (-50 000)
- ✅ Mouvement financier créé:
  - Type: "sortie"
  - Catégorie: "paiement_fournisseur"
  - Montant: 50 000
  - Description: "Paiement fournisseur [Nom] - Commande #[Ref]"
- ✅ Solde de caisse déduit (-50 000)
- ✅ Nouveau solde caisse = Ancien solde - 50 000

**Vérifications**:
```sql
-- Vérifier le mouvement financier
SELECT * FROM MouvementFinancier 
WHERE type = 'sortie' 
AND categorie = 'paiement_fournisseur'
ORDER BY dateCreation DESC LIMIT 1;

-- Vérifier le solde de la session
SELECT soldeActuel FROM SessionCaisse 
WHERE statut = 'ouverte' 
ORDER BY dateOuverture DESC LIMIT 1;

-- Vérifier le lien entre transaction et mouvement
SELECT 
  tc.id as transaction_id,
  tc.montant as montant_transaction,
  mf.id as mouvement_id,
  mf.montant as montant_mouvement
FROM TransactionCompte tc
LEFT JOIN MouvementFinancier mf 
  ON mf.referenceType = 'transaction_compte' 
  AND mf.referenceId = tc.id
WHERE tc.typeCompte = 'fournisseur'
ORDER BY tc.dateTransaction DESC LIMIT 1;
```

---

### Test 4: Paiement avec mouvement financier (pas de session) ✓

**Objectif**: Vérifier le message d'erreur quand aucune session n'est active

**Prérequis**:
- AUCUNE session de caisse ouverte

**Étapes**:
1. Fermer toutes les sessions de caisse
2. Aller dans le compte d'un fournisseur
3. Sélectionner une commande
4. Cocher "Créer un mouvement financier"
5. Cliquer sur "Confirmer le paiement"

**Résultat attendu**:
- ✅ Message d'erreur: "Aucune session de caisse active. Veuillez ouvrir une session de caisse."
- ✅ Paiement NON enregistré
- ✅ Solde fournisseur inchangé

---

### Test 5: Paiement avec mouvement financier (solde insuffisant) ✓

**Objectif**: Vérifier le message d'erreur quand le solde est insuffisant

**Prérequis**:
- Session de caisse ouverte avec petit solde (ex: 1 000 FCFA)

**Étapes**:
1. Ouvrir une session avec 1 000 FCFA
2. Aller dans le compte d'un fournisseur
3. Sélectionner une commande
4. Entrer un montant de 50 000 FCFA
5. Cocher "Créer un mouvement financier"
6. Cliquer sur "Confirmer le paiement"

**Résultat attendu**:
- ✅ Message d'erreur: "Solde de caisse insuffisant. Solde actuel: 1000 FCFA"
- ✅ Paiement NON enregistré
- ✅ Solde fournisseur inchangé
- ✅ Solde caisse inchangé

---

### Test 6: Paiement partiel d'une commande ✓

**Objectif**: Vérifier qu'on peut payer partiellement une commande

**Étapes**:
1. Sélectionner une commande de 100 000 FCFA
2. Modifier le montant à 30 000 FCFA
3. Confirmer le paiement

**Résultat attendu**:
- ✅ Paiement de 30 000 enregistré
- ✅ Commande toujours dans les "impayées" avec montant restant = 70 000
- ✅ Possibilité de payer à nouveau la même commande

---

### Test 7: Paiement complet d'une commande ✓

**Objectif**: Vérifier qu'une commande payée complètement disparaît de la liste

**Étapes**:
1. Sélectionner une commande
2. Payer le montant restant complet
3. Rouvrir le dialogue de sélection de commande

**Résultat attendu**:
- ✅ Commande payée complètement
- ✅ Commande n'apparaît plus dans la liste des commandes impayées
- ✅ Solde fournisseur mis à jour correctement

---

## Checklist finale

### Interface utilisateur
- [ ] Bouton "Imprimer" visible et fonctionnel
- [ ] Sélection de commande obligatoire (bouton désactivé sinon)
- [ ] Checkbox "Créer un mouvement financier" visible
- [ ] Message d'avertissement sur la caisse affiché
- [ ] Montant pré-rempli avec le montant restant de la commande
- [ ] Description pré-remplie avec référence commande

### Fonctionnalités
- [ ] Impression du relevé PDF
- [ ] Paiement sans mouvement financier
- [ ] Paiement avec mouvement financier (session active)
- [ ] Erreur si pas de session active
- [ ] Erreur si solde insuffisant
- [ ] Paiement partiel possible
- [ ] Paiement complet retire la commande de la liste

### Base de données
- [ ] Transaction créée dans TransactionCompte
- [ ] Solde fournisseur mis à jour dans CompteFournisseur
- [ ] Mouvement financier créé si demandé
- [ ] Solde caisse déduit si mouvement créé
- [ ] Lien entre transaction et mouvement (referenceType/referenceId)

### Logs backend
- [ ] Logs de création de transaction visibles
- [ ] Logs de vérification session caisse
- [ ] Logs de création mouvement financier
- [ ] Logs de mise à jour solde caisse

## Commandes SQL utiles

```sql
-- Voir les dernières transactions fournisseurs
SELECT 
  tc.*,
  f.nom as fournisseur
FROM TransactionCompte tc
JOIN CompteFournisseur cf ON tc.compteId = cf.id
JOIN Fournisseur f ON cf.fournisseurId = f.id
WHERE tc.typeCompte = 'fournisseur'
ORDER BY tc.dateTransaction DESC
LIMIT 10;

-- Voir les mouvements financiers liés aux paiements fournisseurs
SELECT * FROM MouvementFinancier
WHERE categorie = 'paiement_fournisseur'
ORDER BY dateCreation DESC
LIMIT 10;

-- Voir le solde des sessions de caisse actives
SELECT 
  sc.id,
  sc.soldeActuel,
  sc.dateOuverture,
  u.nom as utilisateur,
  c.nom as caisse
FROM SessionCaisse sc
JOIN Utilisateur u ON sc.utilisateurId = u.id
JOIN Caisse c ON sc.caisseId = c.id
WHERE sc.statut = 'ouverte'
ORDER BY sc.dateOuverture DESC;

-- Voir les commandes impayées d'un fournisseur
SELECT 
  ca.id,
  ca.numeroCommande,
  ca.montantTotal,
  COALESCE(SUM(tc.montant), 0) as montantPaye,
  ca.montantTotal - COALESCE(SUM(tc.montant), 0) as montantRestant
FROM CommandeApprovisionnement ca
LEFT JOIN TransactionCompte tc 
  ON tc.referenceType = 'approvisionnement' 
  AND tc.referenceId = ca.id
  AND tc.typeTransaction IN ('paiement', 'credit')
WHERE ca.fournisseurId = ? 
  AND ca.statut != 'annulee'
GROUP BY ca.id
HAVING montantRestant > 0
ORDER BY ca.dateCommande DESC;
```

## En cas de problème

### Le relevé ne s'imprime pas
1. Vérifier que le backend est redémarré
2. Vérifier l'endpoint dans les logs: `GET /accounts/suppliers/:id/statement`
3. Vérifier que le package `open_file` est installé
4. Vérifier les permissions d'écriture dans le dossier Documents

### Le mouvement financier n'est pas créé
1. Vérifier que la checkbox est cochée
2. Vérifier qu'une session de caisse est ouverte
3. Vérifier le solde de la caisse
4. Vérifier les logs backend pour voir l'erreur exacte

### La commande n'apparaît pas dans la liste
1. Vérifier que la commande n'est pas annulée
2. Vérifier qu'il reste un montant à payer
3. Vérifier l'endpoint: `GET /accounts/suppliers/:id/unpaid-procurements`
4. Vérifier les logs backend

### Le bouton "Confirmer" reste désactivé
1. Vérifier qu'une commande est bien sélectionnée
2. Vérifier que le montant est valide (> 0)
3. Vérifier les logs Flutter pour voir les erreurs
