# Guide: Annulation de Ventes

## Vue d'ensemble

Lorsque vous annulez une vente dans LOGESCO, le système effectue automatiquement les opérations suivantes:

1. **Déduction de la session de caisse** - Le montant payé est retiré du solde de la session
2. **Exclusion de la comptabilité** - La vente n'apparaît plus dans les rapports
3. **Ajustement du compte client** - Si applicable, le compte client est crédité
4. **Restauration du stock** - Les produits sont remis en stock

## Procédure d'Annulation

### Étape 1: Accéder à la liste des ventes
1. Allez dans le menu **Ventes**
2. Cliquez sur **Historique des ventes** ou **Rechercher une vente**

### Étape 2: Sélectionner la vente à annuler
1. Trouvez la vente que vous souhaitez annuler
2. Cliquez sur la vente pour voir ses détails

### Étape 3: Annuler la vente
1. Cliquez sur le bouton **Annuler vente** (ou **Cancel sale** en anglais)
2. Une boîte de dialogue de confirmation apparaît
3. Confirmez l'annulation en cliquant **Oui, annuler**

### Étape 4: Vérification
- Un message de confirmation s'affiche
- La vente est marquée comme "annulée"
- Le montant est déduit de la session de caisse

## Impacts de l'Annulation

### Sur la Session de Caisse
- **Avant**: Solde attendu = 100 000 FCFA
- **Après annulation d'une vente de 50 000 FCFA**: Solde attendu = 50 000 FCFA

### Sur la Comptabilité
- La vente n'apparaît plus dans les rapports
- Le chiffre d'affaires est recalculé sans cette vente
- Les mouvements financiers liés sont supprimés

### Sur le Compte Client
- Si la vente était à crédit, le compte client est crédité
- La dette du client est réduite du montant de la vente
- Les transactions de paiement sont annulées

### Sur le Stock
- Les produits vendus sont remis en stock
- Les services ne sont pas affectés (pas de gestion de stock)
- Un mouvement de stock de type "retour" est créé

## Restrictions

### Ventes qui ne peuvent pas être annulées
- ❌ Les ventes déjà annulées (ne peuvent pas être annulées deux fois)
- ⚠️ Les ventes très anciennes (selon la politique de votre entreprise)

### Permissions requises
- Vous devez avoir la permission **"Annuler une vente"**
- Généralement accordée aux rôles: Admin, Gérant, Comptable

## Exemples de Scénarios

### Scénario 1: Annulation d'une vente comptant
**Situation**: Un client a acheté pour 50 000 FCFA en comptant, mais change d'avis

**Avant annulation**:
- Session de caisse: 100 000 FCFA
- Vente: 50 000 FCFA (payée)

**Après annulation**:
- Session de caisse: 50 000 FCFA (réduite de 50 000)
- Vente: Marquée comme "annulée"
- Stock: Produits remis en stock

### Scénario 2: Annulation d'une vente à crédit
**Situation**: Un client a acheté pour 100 000 FCFA à crédit, mais ne peut pas payer

**Avant annulation**:
- Compte client: -100 000 FCFA (dette)
- Vente: 100 000 FCFA (non payée)

**Après annulation**:
- Compte client: 0 FCFA (dette annulée)
- Vente: Marquée comme "annulée"
- Stock: Produits remis en stock

### Scénario 3: Annulation d'une vente partiellement payée
**Situation**: Un client a acheté pour 100 000 FCFA, payé 60 000 FCFA, doit 40 000 FCFA

**Avant annulation**:
- Session de caisse: 100 000 FCFA
- Compte client: -40 000 FCFA (dette)
- Vente: 100 000 FCFA (60 000 payés, 40 000 dus)

**Après annulation**:
- Session de caisse: 40 000 FCFA (réduite de 60 000)
- Compte client: 0 FCFA (dette annulée)
- Vente: Marquée comme "annulée"
- Stock: Produits remis en stock

## Vérifications Recommandées

Après une annulation, vérifiez:

1. **Session de caisse**
   - Le solde attendu a diminué du montant de la vente
   - L'écart de caisse est correct

2. **Comptabilité**
   - La vente n'apparaît plus dans les rapports
   - Le chiffre d'affaires est correct

3. **Compte client** (si applicable)
   - Le solde du client est correct
   - Les transactions sont cohérentes

4. **Stock**
   - Les produits sont remis en stock
   - Les mouvements de stock sont enregistrés

## Dépannage

### Problème: "Cette vente est déjà annulée"
**Cause**: Vous essayez d'annuler une vente qui a déjà été annulée
**Solution**: Vérifiez que vous avez sélectionné la bonne vente

### Problème: "Vous n'avez pas l'autorisation d'annuler une vente"
**Cause**: Votre rôle n'a pas la permission d'annuler les ventes
**Solution**: Contactez votre administrateur pour obtenir la permission

### Problème: Le solde de caisse n'a pas changé
**Cause**: La vente n'avait pas de montant payé (vente à crédit non payée)
**Solution**: C'est normal - seules les ventes payées affectent le solde de caisse

### Problème: Le compte client n'a pas été ajusté
**Cause**: La vente n'était pas liée à un client
**Solution**: C'est normal - seules les ventes avec client affectent le compte client

## Questions Fréquemment Posées

**Q: Puis-je annuler une vente après la fermeture de la session de caisse?**
R: Oui, mais cela affectera le solde attendu de la session fermée. Consultez votre administrateur.

**Q: Que se passe-t-il si j'annule une vente avec plusieurs produits?**
R: Tous les produits sont remis en stock, et le montant total est déduit de la session.

**Q: Puis-je annuler partiellement une vente?**
R: Non, vous devez annuler la vente entière. Pour des remboursements partiels, contactez votre administrateur.

**Q: Les mouvements financiers sont-ils vraiment supprimés?**
R: Oui, pour exclure la vente de la comptabilité. Un enregistrement d'annulation est créé pour traçabilité.

**Q: Puis-je récupérer une vente annulée?**
R: Non, l'annulation est définitive. Vous devriez créer une nouvelle vente si nécessaire.

## Support

Pour toute question ou problème:
1. Consultez votre administrateur système
2. Vérifiez les logs de l'application
3. Contactez le support LOGESCO
