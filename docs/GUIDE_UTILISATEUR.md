# Guide Utilisateur - LOGESCO v2

## Table des Matières

1. [Introduction](#introduction)
2. [Premiers Pas](#premiers-pas)
3. [Gestion des Produits](#gestion-des-produits)
4. [Gestion des Clients et Fournisseurs](#gestion-des-clients-et-fournisseurs)
5. [Gestion du Stock](#gestion-du-stock)
6. [Approvisionnements](#approvisionnements)
7. [Ventes et Point de Vente](#ventes-et-point-de-vente)
8. [Gestion des Comptes et Crédits](#gestion-des-comptes-et-crédits)
9. [Tableau de Bord](#tableau-de-bord)
10. [FAQ et Dépannage](#faq-et-dépannage)

---

## Introduction

### Qu'est-ce que LOGESCO v2 ?

LOGESCO v2 est un logiciel de gestion commerciale moderne conçu pour simplifier la gestion quotidienne de votre entreprise. Il vous permet de :

- ✅ Gérer votre catalogue de produits
- ✅ Suivre votre stock en temps réel
- ✅ Enregistrer vos ventes et approvisionnements
- ✅ Gérer vos relations clients et fournisseurs
- ✅ Suivre les comptes clients et fournisseurs (crédits)
- ✅ Visualiser vos performances avec des tableaux de bord

### Modes de Déploiement

LOGESCO v2 est disponible en deux versions :

**Version Desktop (Local)**
- Installation sur votre ordinateur Windows
- Fonctionne 100% hors ligne
- Données stockées localement
- Idéal pour une utilisation mono-poste

**Version Web (Cloud)**
- Accessible depuis n'importe quel navigateur
- Nécessite une connexion internet
- Données sécurisées dans le cloud
- Idéal pour un accès multi-utilisateurs

---

## Premiers Pas

### Connexion à l'Application

1. **Lancez LOGESCO v2**
   - Version Desktop : Double-cliquez sur l'icône LOGESCO sur votre bureau
   - Version Web : Ouvrez votre navigateur et accédez à l'URL fournie

2. **Écran de Connexion**
   - Entrez votre **nom d'utilisateur**
   - Entrez votre **mot de passe**
   - Cliquez sur **Se connecter**

3. **Première Connexion**
   - Utilisateur par défaut : `admin`
   - Mot de passe par défaut : `admin123`
   - ⚠️ **Important** : Changez votre mot de passe après la première connexion

### Navigation dans l'Interface

L'interface LOGESCO v2 est organisée en modules accessibles depuis le menu latéral :

- **Tableau de Bord** : Vue d'ensemble de votre activité
- **Produits** : Gestion du catalogue produits
- **Clients** : Gestion des clients et comptes clients
- **Fournisseurs** : Gestion des fournisseurs et comptes fournisseurs
- **Stock** : Suivi des quantités en stock
- **Approvisionnements** : Commandes aux fournisseurs
- **Ventes** : Point de vente et historique des ventes
- **Paramètres** : Configuration de l'application

---

## Gestion des Produits

### Ajouter un Nouveau Produit

1. Cliquez sur **Produits** dans le menu latéral
2. Cliquez sur le bouton **+ Nouveau Produit**
3. Remplissez le formulaire :
   - **Référence** : Code unique du produit (obligatoire)
   - **Nom** : Nom du produit (obligatoire)
   - **Description** : Description détaillée (optionnel)
   - **Prix Unitaire** : Prix de vente (obligatoire)
   - **Catégorie** : Catégorie du produit (optionnel)
   - **Seuil Stock Minimum** : Quantité d'alerte (par défaut : 0)
4. Cliquez sur **Enregistrer**

### Modifier un Produit

1. Dans la liste des produits, cliquez sur le produit à modifier
2. Modifiez les informations souhaitées
3. Cliquez sur **Enregistrer les modifications**

### Rechercher un Produit

- Utilisez la **barre de recherche** en haut de la liste
- Tapez le nom, la référence ou la catégorie
- Les résultats s'affichent en temps réel

### Désactiver un Produit

Si un produit ne doit plus être vendu mais a un historique :

1. Ouvrez le produit
2. Décochez **Produit actif**
3. Enregistrez

⚠️ **Note** : Les produits avec des transactions ne peuvent pas être supprimés, seulement désactivés.

---

## Gestion des Clients et Fournisseurs

### Ajouter un Client

1. Cliquez sur **Clients** dans le menu
2. Cliquez sur **+ Nouveau Client**
3. Remplissez les informations :
   - **Nom** : Nom du client (obligatoire)
   - **Prénom** : Prénom (optionnel)
   - **Téléphone** : Numéro de téléphone
   - **Email** : Adresse email
   - **Adresse** : Adresse complète
4. Cliquez sur **Enregistrer**

### Configurer le Crédit Client

1. Ouvrez la fiche client
2. Cliquez sur l'onglet **Compte**
3. Définissez la **Limite de crédit** autorisée
4. Enregistrez

Le système bloquera automatiquement les ventes à crédit si la limite est dépassée.

### Ajouter un Fournisseur

1. Cliquez sur **Fournisseurs** dans le menu
2. Cliquez sur **+ Nouveau Fournisseur**
3. Remplissez les informations :
   - **Nom** : Nom du fournisseur (obligatoire)
   - **Personne de contact** : Nom du contact
   - **Téléphone** : Numéro de téléphone
   - **Email** : Adresse email
   - **Adresse** : Adresse complète
4. Cliquez sur **Enregistrer**

### Consulter l'Historique

- Ouvrez la fiche client ou fournisseur
- Cliquez sur l'onglet **Historique**
- Vous verrez toutes les transactions associées

---

## Gestion du Stock

### Consulter le Stock

1. Cliquez sur **Stock** dans le menu
2. Vous verrez pour chaque produit :
   - **Quantité disponible** : Stock vendable
   - **Quantité réservée** : Stock en commande
   - **Quantité totale** : Disponible + Réservée
   - **Statut** : Alerte si stock faible

### Alertes de Stock

Les produits avec un stock inférieur au seuil minimum sont marqués en **rouge** avec une icône d'alerte.

### Ajustement Manuel du Stock

Si vous devez corriger le stock (inventaire, casse, etc.) :

1. Dans la liste du stock, cliquez sur le produit
2. Cliquez sur **Ajuster le stock**
3. Entrez la **nouvelle quantité**
4. Ajoutez une **justification** (obligatoire)
5. Cliquez sur **Confirmer**

⚠️ **Important** : Tous les ajustements sont enregistrés dans l'historique pour audit.

### Exporter le Stock

1. Cliquez sur **Exporter** en haut de la liste
2. Choisissez le format :
   - **PDF** : Pour impression
   - **Excel** : Pour analyse
3. Le fichier est téléchargé automatiquement

---

## Approvisionnements

### Créer une Commande d'Approvisionnement

1. Cliquez sur **Approvisionnements** dans le menu
2. Cliquez sur **+ Nouvelle Commande**
3. Sélectionnez le **fournisseur**
4. Ajoutez des produits :
   - Cliquez sur **+ Ajouter un produit**
   - Sélectionnez le produit
   - Entrez la **quantité commandée**
   - Entrez le **coût unitaire**
5. Choisissez le **mode de paiement** :
   - **Comptant** : Paiement immédiat
   - **Crédit** : Ajouté au compte fournisseur
6. Ajoutez des **notes** si nécessaire
7. Cliquez sur **Créer la commande**

### Réceptionner une Livraison

1. Ouvrez la commande d'approvisionnement
2. Cliquez sur **Réceptionner**
3. Pour chaque produit, entrez la **quantité reçue**
4. Cliquez sur **Confirmer la réception**

Le système met automatiquement à jour :
- ✅ Le stock des produits
- ✅ Le statut de la commande
- ✅ Le compte fournisseur (si crédit)

### Statuts des Commandes

- **En attente** : Commande créée, pas encore livrée
- **Partielle** : Livraison partielle reçue
- **Terminée** : Commande entièrement livrée
- **Annulée** : Commande annulée

---

## Ventes et Point de Vente

### Créer une Vente

1. Cliquez sur **Ventes** dans le menu
2. Cliquez sur **+ Nouvelle Vente**
3. Sélectionnez le **client** (optionnel pour vente comptant)
4. Ajoutez des produits au panier :
   - Recherchez le produit
   - Cliquez sur **Ajouter**
   - Ajustez la **quantité** si nécessaire
5. Le système calcule automatiquement le total

### Appliquer une Remise

1. Dans le panier, cliquez sur **Appliquer une remise**
2. Entrez le **montant** ou le **pourcentage**
3. Le total est recalculé automatiquement

### Finaliser la Vente

1. Cliquez sur **Finaliser la vente**
2. Choisissez le **mode de paiement** :
   - **Comptant** : Paiement immédiat complet
   - **Crédit** : Ajouté au compte client
3. Si **Comptant**, entrez le **montant payé**
4. Le système affiche la **monnaie à rendre**
5. Cliquez sur **Confirmer la vente**

### Vérifications Automatiques

Le système vérifie automatiquement :
- ✅ Stock suffisant pour chaque produit
- ✅ Limite de crédit du client (si vente à crédit)
- ✅ Cohérence des montants

### Imprimer le Reçu

Après la vente, cliquez sur **Imprimer le reçu** pour générer un reçu de caisse.

### Annuler une Vente

⚠️ **Attention** : L'annulation d'une vente est irréversible.

1. Ouvrez la vente dans l'historique
2. Cliquez sur **Annuler la vente**
3. Confirmez l'annulation

Le système restaure automatiquement :
- ✅ Le stock des produits
- ✅ Le compte client (si crédit)

---

## Gestion des Comptes et Crédits

### Consulter le Compte Client

1. Cliquez sur **Clients** dans le menu
2. Ouvrez la fiche client
3. Cliquez sur l'onglet **Compte**

Vous verrez :
- **Solde actuel** : Montant dû par le client
- **Limite de crédit** : Crédit maximum autorisé
- **Crédit disponible** : Limite - Solde
- **Historique des transactions**

### Enregistrer un Paiement Client

1. Ouvrez le compte client
2. Cliquez sur **Enregistrer un paiement**
3. Entrez le **montant payé**
4. Ajoutez une **description** (optionnel)
5. Cliquez sur **Confirmer**

Le solde est mis à jour automatiquement.

### Consulter le Compte Fournisseur

1. Cliquez sur **Fournisseurs** dans le menu
2. Ouvrez la fiche fournisseur
3. Cliquez sur l'onglet **Compte**

Vous verrez :
- **Solde actuel** : Montant que vous devez au fournisseur
- **Historique des achats et paiements**

### Enregistrer un Paiement Fournisseur

1. Ouvrez le compte fournisseur
2. Cliquez sur **Enregistrer un paiement**
3. Entrez le **montant payé**
4. Ajoutez une **description** (optionnel)
5. Cliquez sur **Confirmer**

### Alertes de Crédit

Le système affiche des alertes visuelles :
- 🟡 **Jaune** : Crédit proche de la limite (>80%)
- 🔴 **Rouge** : Crédit dépassé (bloque les ventes)

---

## Tableau de Bord

### Vue d'Ensemble

Le tableau de bord affiche en temps réel :

**Indicateurs Clés**
- 💰 **Chiffre d'affaires du jour**
- 📦 **Nombre de ventes**
- 📊 **Stock total**
- ⚠️ **Alertes de stock**

**Graphiques**
- **Ventes par jour** : Évolution sur 7 jours
- **Produits les plus vendus** : Top 5
- **Répartition des ventes** : Par mode de paiement

**Alertes et Notifications**
- Produits en rupture de stock
- Clients en dépassement de crédit
- Commandes en attente de réception

### Actualisation des Données

Les données du tableau de bord sont actualisées automatiquement toutes les 30 secondes.

---

## FAQ et Dépannage

### Questions Fréquentes

**Q : Puis-je supprimer un produit ?**
R : Non, si le produit a des transactions. Vous pouvez le désactiver à la place.

**Q : Comment sauvegarder mes données ?**
R : 
- Version Desktop : Les données sont dans `C:\Program Files\LOGESCO\database\logesco.db`. Copiez ce fichier régulièrement.
- Version Web : Les sauvegardes sont automatiques.

**Q : Que faire si je me trompe dans une vente ?**
R : Annulez la vente depuis l'historique. Le stock et les comptes seront restaurés automatiquement.

**Q : Comment changer mon mot de passe ?**
R : Cliquez sur votre nom en haut à droite > Paramètres > Changer le mot de passe.

**Q : Le système fonctionne-t-il sans internet ?**
R : 
- Version Desktop : Oui, 100% hors ligne
- Version Web : Non, nécessite une connexion internet

### Problèmes Courants

**Problème : "Erreur de connexion à l'API"**
- Version Desktop : Vérifiez que le service LOGESCO API est démarré (voir guide d'installation)
- Version Web : Vérifiez votre connexion internet

**Problème : "Stock insuffisant" lors d'une vente**
- Vérifiez le stock disponible du produit
- Ajustez la quantité ou réapprovisionnez

**Problème : "Limite de crédit dépassée"**
- Le client a atteint sa limite de crédit
- Demandez un paiement ou augmentez la limite

**Problème : L'application est lente**
- Fermez les autres applications
- Redémarrez l'application
- Contactez le support si le problème persiste

### Support Technique

Pour toute assistance :
- 📧 Email : support@logesco.com
- 📞 Téléphone : +XXX XXX XXX XXX
- 🌐 Site web : www.logesco.com/support

---

## Raccourcis Clavier

- `Ctrl + N` : Nouveau (produit, client, vente selon le contexte)
- `Ctrl + S` : Enregistrer
- `Ctrl + F` : Rechercher
- `Ctrl + P` : Imprimer
- `Échap` : Fermer la fenêtre/dialogue
- `F5` : Actualiser les données

---

## Bonnes Pratiques

✅ **Sauvegardez régulièrement** vos données (version desktop)
✅ **Vérifiez le stock** avant de créer une vente
✅ **Définissez des limites de crédit** réalistes pour vos clients
✅ **Ajustez les seuils de stock** pour éviter les ruptures
✅ **Consultez le tableau de bord** quotidiennement
✅ **Formez vos employés** à l'utilisation du logiciel
✅ **Changez les mots de passe** par défaut
✅ **Documentez les ajustements** de stock avec des justifications claires

---

**Version du document** : 1.0
**Dernière mise à jour** : Novembre 2024
**LOGESCO v2** - Logiciel de Gestion Commerciale
