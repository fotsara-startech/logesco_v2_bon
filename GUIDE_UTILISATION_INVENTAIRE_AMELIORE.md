# Guide d'utilisation - Module d'inventaire amélioré

## 🚀 Nouvelles fonctionnalités

### 1. Barre de recherche intelligente

#### Recherche simple
- Tapez directement dans la barre de recherche en haut de la page
- La recherche fonctionne sur :
  - **Nom du produit** : "iPhone", "T-shirt", etc.
  - **Référence** : "REF001", "IPH14P", etc.
  - **Code-barre** : "1234567890123"

#### Recherche avancée
1. Cliquez sur l'icône ⚙️ à droite de la barre de recherche
2. Choisissez parmi :
   - **Recherche par référence exacte** : Pour une référence précise
   - **Recherche par code-barre** : Scanner ou saisir un code-barre
   - **Filtrer par catégorie** : Sélectionner une catégorie spécifique
   - **Filtrer par statut de stock** : Stocks en alerte, rupture, etc.

### 2. Filtres par catégorie

#### Utilisation
1. Cliquez sur ⚙️ dans la barre de recherche
2. Sélectionnez "Filtrer par catégorie"
3. Choisissez une catégorie dans la liste :
   - Électronique
   - Vêtements
   - Alimentation
   - Maison & Jardin
   - Sport & Loisirs
   - Beauté & Santé
   - Automobile
   - Livres & Médias

### 3. Filtres par statut de stock

#### Options disponibles
- **Tous les stocks** : Affiche tous les produits
- **Stocks en alerte** : Produits avec stock faible
- **Stocks en rupture** : Produits avec quantité = 0
- **Stocks disponibles** : Produits avec stock suffisant

#### Comment utiliser
1. Cliquez sur ⚙️ dans la barre de recherche
2. Sélectionnez "Filtrer par statut de stock"
3. Choisissez le statut désiré

### 4. Filtres avancés pour les mouvements

#### Accès aux filtres
1. Allez dans l'onglet "Mouvements"
2. Cliquez sur l'icône 📋 "Filtrer les mouvements"

#### Types de filtres disponibles

**Par type de mouvement :**
- Tous les types
- Achat
- Vente
- Ajustement
- Retour
- Approvisionnement

**Par période :**
- **Dates personnalisées** : Sélectionnez début et fin
- **Périodes rapides** :
  - Aujourd'hui
  - 7 derniers jours
  - 30 derniers jours
  - Ce mois

### 5. Gestion des filtres actifs

#### Visualisation
- Les filtres actifs apparaissent sous la barre de recherche
- Chaque filtre est affiché dans un "chip" coloré
- Le nombre de filtres actifs est visible

#### Suppression des filtres
- **Individuelle** : Cliquez sur ❌ à côté de chaque filtre
- **Globale** : Cliquez sur "Effacer tout" à droite

## 📱 Interface utilisateur

### Barre de recherche
```
[🔍 Rechercher par nom, référence ou code-barre...] [❌] [⚙️]
```

### Barre de filtres actifs
```
🔍 Filtres actifs: [Recherche: "iPhone" ❌] [Catégorie: Électronique ❌] [Effacer tout]
```

### Onglet Mouvements
```
Mouvements de stock                                    [📋]
```

## 🎯 Cas d'usage typiques

### Rechercher un produit spécifique
1. Tapez le nom ou la référence dans la barre de recherche
2. Les résultats se filtrent automatiquement
3. Cliquez sur le produit pour voir les détails

### Voir tous les produits en rupture
1. Cliquez sur ⚙️ → "Filtrer par statut de stock"
2. Sélectionnez "Stocks en rupture"
3. Seuls les produits avec quantité = 0 s'affichent

### Analyser les ventes du mois
1. Allez dans l'onglet "Mouvements"
2. Cliquez sur 📋 pour filtrer
3. Sélectionnez "Vente" comme type
4. Cliquez sur "Ce mois" pour la période
5. Appliquez les filtres

### Rechercher dans une catégorie
1. Cliquez sur ⚙️ → "Filtrer par catégorie"
2. Sélectionnez "Électronique"
3. Tapez "iPhone" dans la recherche
4. Seuls les iPhones s'affichent

## ⚡ Conseils d'utilisation

### Performance
- La recherche utilise un délai de 500ms pour éviter trop d'appels
- Les filtres se combinent pour affiner les résultats
- La pagination fonctionne avec les filtres actifs

### Navigation
- Les filtres restent actifs lors du changement d'onglet
- Utilisez "Effacer tout" pour repartir à zéro
- Les filtres sont sauvegardés pendant la session

### Recherche efficace
- Utilisez des mots-clés courts et précis
- Combinez recherche et filtres pour plus de précision
- Utilisez les références pour une recherche exacte

## 🔧 Dépannage

### La recherche ne fonctionne pas
- Vérifiez que vous êtes connecté
- Essayez d'effacer tous les filtres
- Actualisez la page avec le bouton 🔄

### Aucun résultat trouvé
- Vérifiez l'orthographe
- Essayez avec moins de critères
- Utilisez "Effacer tout" pour voir tous les produits

### Les filtres ne s'appliquent pas
- Attendez quelques secondes (debounce)
- Vérifiez votre connexion internet
- Réessayez en actualisant

## 📞 Support

Pour toute question ou problème avec les nouvelles fonctionnalités :
1. Vérifiez ce guide d'utilisation
2. Testez avec des données simples
3. Contactez le support technique si nécessaire

---

*Ces améliorations rendent la gestion d'inventaire plus rapide et plus intuitive. N'hésitez pas à explorer toutes les fonctionnalités !*