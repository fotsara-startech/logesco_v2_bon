# Test Paiement Dette Client - Mise a jour Caisse

## Correction appliquee

Le solde de la caisse est maintenant mis a jour automatiquement lors du paiement d'une dette client.

## Etapes pour tester

### 1. Redemarrer le backend

**IMPORTANT:** Le backend doit etre redemarre pour que les changements prennent effet.

```bash
# Executer le script
restart-backend-quick.bat
```

Ou manuellement:
1. Arreter le backend (Ctrl+C dans le terminal)
2. Redemarrer: `cd backend && npm start`

### 2. Preparer les donnees de test

**Avant le test, noter:**
- Solde actuel de la caisse active: _______ FCFA
- Dette du client a tester: _______ FCFA

### 3. Effectuer le paiement

1. Ouvrir l'application Flutter
2. Aller dans "Clients"
3. Selectionner un client avec dette
4. Cliquer sur "Voir le compte"
5. Cliquer sur "Payer la dette"
6. Selectionner une vente impayee
7. Entrer le montant (ex: 500 FCFA)
8. Cliquer sur "Confirmer le paiement"

### 4. Verifier les resultats

**A. Compte client**
- Dette reduite du montant paye
- Transaction visible dans l'historique

**B. Solde de la caisse**
1. Aller dans "Caisses"
2. Verifier le solde de la caisse active
3. Le solde devrait avoir augmente du montant paye

**Exemple:**
- Solde avant: 50000 FCFA
- Paiement: 500 FCFA
- Solde apres: 50500 FCFA

**C. Logs backend**

Dans le terminal du backend, vous devriez voir:

```
Calcul du nouveau solde:
  - Solde actuel: -10000
  - Montant paye: 500
  - Nouveau solde: -9500

Mise a jour de la caisse active: Caisse Principale
  - Solde actuel caisse: 50000
  - Montant a ajouter: 500
  - Nouveau solde caisse: 50500

Solde de la caisse mis a jour avec succes
```

### 5. Verifier le mouvement de caisse

1. Aller dans "Caisses"
2. Selectionner la caisse active
3. Voir l'historique des mouvements
4. Un nouveau mouvement "entree" devrait etre visible:
   - Type: entree
   - Montant: 500 FCFA
   - Description: "Paiement dette client: [Nom Client] (Vente [Ref])"

## Cas de test

### Test 1: Paiement partiel
- Dette: 10000 FCFA
- Paiement: 5000 FCFA
- Resultat attendu: Dette = 5000 FCFA, Caisse +5000 FCFA

### Test 2: Paiement total
- Dette: 5000 FCFA
- Paiement: 5000 FCFA
- Resultat attendu: Dette = 0 FCFA, Caisse +5000 FCFA

### Test 3: Plusieurs paiements
- Dette: 10000 FCFA
- Paiement 1: 3000 FCFA
- Paiement 2: 2000 FCFA
- Resultat attendu: Dette = 5000 FCFA, Caisse +5000 FCFA (total)

## Problemes possibles

### Erreur: "Aucune caisse active trouvee"

**Cause:** Aucune caisse n'est ouverte

**Solution:**
1. Aller dans "Caisses"
2. Ouvrir une caisse
3. Reessayer le paiement

### Erreur: "Unknown argument categorie"

**Cause:** Backend pas redemarre apres la correction

**Solution:**
1. Arreter le backend
2. Executer `restart-backend-quick.bat`
3. Reessayer le paiement

### Solde caisse non mis a jour

**Cause:** Timer automatique pas encore passe

**Solution:**
1. Attendre 10 secondes (timer automatique)
2. Ou rafraichir manuellement la page des caisses
3. Ou fermer/rouvrir la page des caisses

## Validation finale

**Le test est reussi si:**
- [x] Paiement enregistre sans erreur
- [x] Dette client reduite
- [x] Solde caisse augmente
- [x] Mouvement de caisse cree
- [x] Logs backend corrects

---

**Date:** 28 fevrier 2026  
**Version:** 1.0  
**Statut:** PRET POUR TEST
