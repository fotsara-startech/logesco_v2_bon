# Carte de Référence Rapide - LOGESCO v2

## 🚀 Démarrage Rapide

### Première Connexion
- **Utilisateur** : `admin`
- **Mot de passe** : `admin123`
- ⚠️ Changez le mot de passe après la première connexion !

### Lancer l'Application
- **Desktop** : Double-clic sur l'icône LOGESCO
- **Web** : Ouvrir le navigateur → URL fournie

---

## ⌨️ Raccourcis Clavier

| Raccourci | Action |
|-----------|--------|
| `Ctrl + N` | Nouveau (produit, client, vente) |
| `Ctrl + S` | Enregistrer |
| `Ctrl + F` | Rechercher |
| `Ctrl + P` | Imprimer |
| `Échap` | Fermer dialogue |
| `F5` | Actualiser |

---

## 📦 Gestion des Produits

### Créer un Produit
1. Menu > **Produits**
2. Clic sur **+ Nouveau Produit**
3. Remplir : Référence, Nom, Prix
4. **Enregistrer**

### Rechercher un Produit
- Utiliser la barre de recherche
- Taper nom, référence ou catégorie

---

## 💰 Enregistrer une Vente

### Processus Rapide
1. Menu > **Ventes** > **+ Nouvelle Vente**
2. Sélectionner le **client** (optionnel)
3. **Ajouter des produits** au panier
4. Appliquer une **remise** (optionnel)
5. Clic sur **Finaliser la vente**
6. Choisir **mode de paiement** :
   - **Comptant** : Paiement immédiat
   - **Crédit** : Ajouté au compte client
7. **Confirmer**

### Vérifications Automatiques
- ✅ Stock suffisant
- ✅ Limite de crédit client
- ✅ Calculs corrects

---

## 📊 Gestion du Stock

### Consulter le Stock
- Menu > **Stock**
- Voir : Disponible, Réservé, Total
- 🔴 Rouge = Stock faible

### Ajuster le Stock
1. Clic sur le produit
2. **Ajuster le stock**
3. Entrer nouvelle quantité
4. Ajouter **justification** (obligatoire)
5. **Confirmer**

---

## 🛒 Approvisionnements

### Créer une Commande
1. Menu > **Approvisionnements**
2. **+ Nouvelle Commande**
3. Sélectionner **fournisseur**
4. Ajouter **produits** et **quantités**
5. Choisir **mode de paiement**
6. **Créer**

### Réceptionner une Livraison
1. Ouvrir la commande
2. **Réceptionner**
3. Entrer **quantités reçues**
4. **Confirmer**
- ✅ Stock mis à jour automatiquement

---

## 👥 Gestion des Clients

### Créer un Client
1. Menu > **Clients**
2. **+ Nouveau Client**
3. Remplir : Nom, Téléphone, Email
4. Définir **limite de crédit**
5. **Enregistrer**

### Enregistrer un Paiement
1. Ouvrir le client
2. Onglet **Compte**
3. **Enregistrer un paiement**
4. Entrer **montant**
5. **Confirmer**

---

## 📈 Tableau de Bord

### Indicateurs Clés
- 💰 Chiffre d'affaires du jour
- 📦 Nombre de ventes
- 📊 Stock total
- ⚠️ Alertes de stock

### Actualisation
- Automatique toutes les 30 secondes
- Manuelle : Appuyer sur `F5`

---

## 🚨 Alertes Importantes

### Stock
- 🔴 **Rouge** : Stock en dessous du seuil
- 🟡 **Jaune** : Stock proche du seuil

### Crédit Client
- 🟡 **Jaune** : Crédit > 80% de la limite
- 🔴 **Rouge** : Crédit dépassé (bloque les ventes)

---

## 🔧 Dépannage Rapide

### "Impossible de se connecter"
1. Vérifier identifiants (sensible à la casse)
2. Vérifier que le service API est démarré
3. Contacter l'administrateur

### "Stock insuffisant"
- Vérifier le stock disponible
- Réapprovisionner si nécessaire
- Ajuster la quantité de vente

### "Limite de crédit dépassée"
- Demander un paiement au client
- Ou augmenter la limite de crédit

### "Application lente"
- Fermer les autres applications
- Redémarrer l'application
- Contacter le support si persiste

---

## 📞 Support

### Aide
- 📖 Guide Utilisateur : `docs/GUIDE_UTILISATEUR.md`
- 🚨 Dépannage : `docs/GUIDE_DEPANNAGE_COMPLET.md`
- 🎓 Formation : `docs/GUIDE_FORMATION.md`

### Contact
- 📧 Email : support@logesco.com
- 📞 Téléphone : +XXX XXX XXX XXX
- 💬 Forum : community.logesco.com

---

## 💡 Astuces

### Productivité
- Utilisez les **raccourcis clavier**
- Configurez les **seuils de stock** appropriés
- Consultez le **tableau de bord** quotidiennement
- Effectuez des **sauvegardes** régulières (Desktop)

### Bonnes Pratiques
- ✅ Changez le mot de passe par défaut
- ✅ Définissez des limites de crédit réalistes
- ✅ Justifiez les ajustements de stock
- ✅ Vérifiez le stock avant les ventes
- ✅ Formez tous les utilisateurs

---

## 📋 Checklist Quotidienne

### Matin
- [ ] Consulter le tableau de bord
- [ ] Vérifier les alertes de stock
- [ ] Vérifier les comptes clients en dépassement

### Soir
- [ ] Vérifier les ventes du jour
- [ ] Enregistrer les paiements reçus
- [ ] Planifier les approvisionnements nécessaires

---

## 🎯 Flux de Travail Typique

### Flux Vente Comptant
```
1. Nouvelle Vente
2. Ajouter Produits
3. Finaliser
4. Mode: Comptant
5. Confirmer
6. Imprimer Reçu
```

### Flux Vente à Crédit
```
1. Nouvelle Vente
2. Sélectionner Client
3. Ajouter Produits
4. Finaliser
5. Mode: Crédit
6. Vérifier Limite
7. Confirmer
```

### Flux Approvisionnement
```
1. Nouvelle Commande
2. Sélectionner Fournisseur
3. Ajouter Produits
4. Créer Commande
5. Réceptionner Livraison
6. Stock Mis à Jour
```

---

## 📊 Statuts et Significations

### Statuts Ventes
- **Terminée** : Vente complétée
- **Annulée** : Vente annulée (stock restauré)

### Statuts Commandes
- **En attente** : Pas encore livrée
- **Partielle** : Livraison partielle
- **Terminée** : Entièrement livrée
- **Annulée** : Commande annulée

### Statuts Produits
- **Actif** : Produit vendable
- **Inactif** : Produit désactivé

---

## 🔐 Sécurité

### Mot de Passe Fort
- Minimum 8 caractères
- Majuscules et minuscules
- Chiffres et caractères spéciaux
- Changez régulièrement

### Déconnexion
- Toujours se déconnecter après utilisation
- Session expire après 30 min d'inactivité

---

## 📱 Accès Rapide

### Navigation Rapide
- **Tableau de Bord** : Vue d'ensemble
- **Produits** : Catalogue
- **Clients** : Contacts clients
- **Fournisseurs** : Contacts fournisseurs
- **Stock** : Inventaire
- **Approvisionnements** : Commandes
- **Ventes** : Point de vente
- **Paramètres** : Configuration

---

**Version** : 1.0  
**LOGESCO v2** - Carte de Référence Rapide  
**Imprimez cette page pour un accès rapide !**

