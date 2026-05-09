# Script Vidéo 02 — Gestion des Produits et Catégories

**Durée estimée : 8-10 minutes**
**Public cible : Tous les utilisateurs**

---

## SCRIPT AUDIO (à lire pour ElevenLabs)

Dans cette vidéo, nous allons apprendre à gérer votre catalogue de produits dans LOGESCO v2. C'est une étape fondamentale, car tous les autres modules — les ventes, le stock, les approvisionnements — reposent sur vos produits.

Nous allons d'abord créer une catégorie, puis enregistrer un produit complet en détaillant chaque champ du formulaire. Pour rendre cela concret, nous allons prendre un exemple réel tout au long de la démonstration : nous allons enregistrer un produit appelé "Eau minérale 1,5L".

---

### Partie 1 — Les catégories

Avant d'ajouter des produits, il est recommandé de créer vos catégories. Les catégories vous permettent d'organiser votre catalogue et de retrouver vos produits plus facilement lors des ventes ou des inventaires.

Dans le menu principal, cliquez sur le module Produits, puis accédez à la section Catégories.

Vous voyez la liste de toutes vos catégories existantes.

Pour créer une nouvelle catégorie, cliquez sur le bouton d'ajout en haut à droite de l'écran.

Saisissez le nom de la catégorie. Dans notre exemple, nous allons créer la catégorie "Boissons".

Vous pouvez ajouter une description si vous le souhaitez, pour préciser le contenu de cette catégorie.

Cliquez sur Enregistrer. Votre catégorie "Boissons" apparaît maintenant dans la liste.

Pour modifier une catégorie existante, cliquez dessus et apportez vos modifications. Pour la supprimer, utilisez l'option de suppression — mais assurez-vous qu'aucun produit n'y est rattaché avant de procéder.

---

### Partie 2 — Créer un produit : le formulaire en détail

Maintenant, passons à la création d'un produit. Dans la section Produits, cliquez sur le bouton Nouveau produit.

Le formulaire de création s'ouvre. Nous allons parcourir chaque champ dans l'ordre, en utilisant notre exemple "Eau minérale 1,5L".

**Champ 1 — La référence**

Le premier champ est la référence du produit. Bonne nouvelle : ce champ se remplit automatiquement. Le logiciel génère une référence unique pour chaque nouveau produit, vous n'avez donc rien à faire.

Cependant, si vous souhaitez utiliser votre propre système de référencement — par exemple pour correspondre à votre catalogue fournisseur ou à votre système de gestion existant — vous pouvez effacer la valeur générée et saisir la vôtre. Dans notre exemple, nous allons laisser la référence automatique telle quelle.

**Champ 2 — Le nom du produit**

Le nom du produit est un champ obligatoire. C'est le nom qui apparaîtra dans toutes les listes, lors des ventes, et sur les reçus clients. Soyez précis et clair.

Nous saisissons : "Eau minérale 1,5L".

**Champ 3 — La description**

La description est un champ optionnel. Vous pouvez l'utiliser pour ajouter des précisions sur le produit : sa marque, ses caractéristiques, ou toute information utile pour vos équipes.

Pour notre eau minérale, nous pouvons saisir : "Bouteille d'eau minérale naturelle de 1,5 litre". Ce champ n'est pas obligatoire, vous pouvez le laisser vide si vous préférez.

**Champ 4 — Le prix de vente**

Le prix de vente est un champ obligatoire. C'est le prix auquel vous vendrez ce produit à vos clients. Il apparaîtra automatiquement lors de la création d'une vente.

Pour notre eau minérale, nous saisissons le prix de vente, par exemple 500.

**Champ 5 — Le prix d'achat**

Le prix d'achat est un champ optionnel. Il correspond au coût auquel vous avez acheté ce produit auprès de votre fournisseur.

Même s'il est optionnel, nous vous recommandons fortement de le renseigner. En effet, c'est grâce à cette information que le logiciel peut calculer votre marge bénéficiaire et vous donner des rapports financiers précis.

Pour notre eau minérale, nous saisissons le prix d'achat, par exemple 300.

**Champ 6 — La remise maximale autorisée**

Ce champ vous permet de définir la remise maximale que l'on peut accorder sur ce produit lors d'une vente. Il s'agit d'une valeur en pourcentage.

Par exemple, si vous saisissez 100, cela signifie qu'un vendeur ne pourra pas accorder plus de 100 FCFA de réduction sur ce produit. Cela vous protège contre les remises excessives qui pourraient nuire à votre rentabilité.

Si vous ne souhaitez pas limiter les remises sur ce produit, laissez ce champ à zéro.

Pour notre eau minérale, nous allons saisir 5, ce qui autorise une remise maximale de 50 FCFA.

**Champ 7 — Le code-barres**

Si votre produit possède un code-barres, vous pouvez le saisir dans ce champ. Cela vous permettra de scanner le produit directement lors des ventes, ce qui accélère considérablement le passage en caisse.

Si votre produit n'a pas de code-barres, laissez simplement ce champ vide.

Pour notre eau minérale, nous allons saisir le code-barres figurant sur la bouteille.

**Champ 8 — La catégorie**

Sélectionnez la catégorie à laquelle appartient ce produit dans la liste déroulante. Nous avons créé la catégorie "Boissons" tout à l'heure, nous la sélectionnons ici.

Si la catégorie dont vous avez besoin n'existe pas encore, vous devrez d'abord la créer dans la section Catégories avant de revenir créer votre produit.

**Champ 9 — Le seuil de stock minimum**

Le seuil de stock minimum est la quantité en dessous de laquelle le logiciel vous enverra une alerte. C'est votre filet de sécurité pour ne jamais tomber en rupture de stock sans le savoir.

Par exemple, si vous saisissez 10, dès que la quantité de ce produit descendra en dessous de 10 unités, une alerte dans le module stock.

Définissez ce seuil en fonction de votre rythme de vente et du délai de réapprovisionnement de votre fournisseur. Pour notre eau minérale qui se vend rapidement, nous allons saisir 24.

**Champ 10 — Prestation de service**

Ce champ vous permet de préciser si ce que vous enregistrez est un produit physique ou une prestation de service.

Si vous activez cette option, le logiciel comprend qu'il s'agit d'un service — par exemple une réparation, une consultation, ou une livraison — et n'effectuera pas de déduction de stock lors des ventes, puisqu'un service n'a pas de stock physique.

Pour notre eau minérale, qui est bien un produit physique, nous laissons cette option désactivée.

**Champ 11 — Gestion des dates de péremption**

Ce champ vous permet d'indiquer si votre produit est périssable et doit faire l'objet d'un suivi des dates de péremption.

Si vous activez cette option, le logiciel vous donnera la possibiliter de saisir une date de péremption pour un ou plusieurs quantite en stock de ce produit, et vous alertera lorsque des produits approchent de leur date limite.

C'est particulièrement utile pour les produits alimentaires, les médicaments, ou tout produit ayant une durée de vie limitée.

Pour notre eau minérale, nous activons cette option car les bouteilles ont bien une date de péremption.

**Champ 12 — Produit actif**

Le dernier champ vous permet de définir si ce produit est actif ou inactif.

Un produit actif apparaît dans les listes lors des ventes et des approvisionnements. Un produit inactif est masqué de ces listes mais reste dans votre base de données.

Cette option est utile lorsque vous arrêtez temporairement de vendre un produit sans vouloir le supprimer définitivement. Vous pouvez le réactiver à tout moment.

Par défaut, tout nouveau produit est actif. Nous laissons cette option activée pour notre eau minérale.

---

### Partie 3 — Enregistrer et vérifier

Maintenant que tous les champs sont remplis, prenons un moment pour vérifier notre saisie.

Référence générée automatiquement — nom : Eau minérale 1,5L — catégorie : Boissons — prix de vente : 500 — prix d'achat : 300 — remise maximale : 50 FCFA — seuil d'alerte : 24 unités — dates de péremption activées — produit physique actif.

Tout est correct. Cliquez sur Enregistrer.

Votre produit est maintenant créé et apparaît dans votre catalogue. Vous pouvez cliquer dessus pour consulter sa fiche détaillée, qui affiche toutes les informations ainsi que l'historique des mouvements de stock et les statistiques de vente.

---

### Partie 4 — Rechercher et filtrer les produits

Lorsque votre catalogue contient de nombreux produits, utilisez la barre de recherche en haut de la liste pour trouver rapidement un produit par son nom, sa référence, ou son code-barres.

Vous pouvez également filtrer les produits par catégorie en utilisant le filtre disponible, ce qui est très pratique lorsque vous avez un large catalogue.

---

Dans la prochaine vidéo, nous verrons comment importer et exporter vos produits en masse à partir d'un fichier Excel.

---

## NOTES DE RÉALISATION

- Créer la catégorie "Boissons" en direct avant de commencer le formulaire
- Ouvrir le formulaire produit et remplir chaque champ lentement, en laissant le temps à l'audio de se synchroniser
- Zoomer sur chaque champ au moment où il est expliqué
- Montrer la référence auto-générée, puis effacer et retaper pour montrer qu'on peut la modifier
- Activer visuellement les toggles "Dates de péremption" et "Prestation de service" pour montrer la différence
- Après enregistrement, ouvrir la fiche produit créée
- Terminer en montrant la recherche et le filtre par catégorie
