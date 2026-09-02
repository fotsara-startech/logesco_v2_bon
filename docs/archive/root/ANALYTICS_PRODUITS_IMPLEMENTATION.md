# Analyse des Ventes par Produit - Implémentation

## Vue d'ensemble

Cette fonctionnalité permet de visualiser la répartition du chiffre d'affaires par produit sur une période définie, avec un classement décroissant du produit le plus vendu au moins vendu. L'objectif est d'identifier rapidement les produits à faible performance pour prendre des décisions appropriées.

## Fonctionnalités Implémentées

### Backend (API)

#### Endpoint Principal
- **Route**: `GET /api/v1/sales/analytics/products`
- **Authentification**: Requise (Bearer Token)
- **Paramètres de requête**:
  - `dateDebut` (optionnel): Date de début au format YYYY-MM-DD
  - `dateFin` (optionnel): Date de fin au format YYYY-MM-DD
  - `categorieId` (optionnel): ID de la catégorie pour filtrer
  - `limit` (optionnel): Nombre maximum de produits à retourner (défaut: 50)
  - `includeServices` (optionnel): Inclure les services (défaut: true)

#### Données Retournées
```json
{
  "success": true,
  "data": {
    "periode": {
      "dateDebut": "2024-11-01",
      "dateFin": "2024-12-10"
    },
    "filtres": {
      "categorieId": null,
      "includeServices": true
    },
    "statistiquesGlobales": {
      "nombreProduitsVendus": 26,
      "chiffreAffairesTotal": 1443.15,
      "quantiteTotaleVendue": 150,
      "nombreTransactionsTotal": 85
    },
    "produits": [
      {
        "produit": {
          "id": 1,
          "nom": "Jean Homme 32",
          "reference": "VT-002",
          "prixUnitaire": 35.0,
          "prixAchat": 25.0,
          "estService": false,
          "categorie": {
            "id": 1,
            "nom": "Vêtements"
          }
        },
        "statistiques": {
          "quantiteVendue": 9,
          "chiffreAffaires": 315.0,
          "nombreTransactions": 3,
          "prixMoyenVente": 35.0,
          "margeUnitaire": 10.0,
          "pourcentageMarge": 28.57
        }
      }
    ],
    "produitsAFaiblePerformance": [
      {
        "produit": { ... },
        "statistiques": { ... },
        "recommandation": "Analyser les raisons de la faible performance et envisager des actions correctives"
      }
    ]
  }
}
```

#### Calculs Effectués
- **Chiffre d'affaires**: Somme des prix totaux des ventes
- **Quantité vendue**: Somme des quantités vendues
- **Nombre de transactions**: Nombre de lignes de vente
- **Prix moyen de vente**: Chiffre d'affaires / Quantité vendue
- **Marge unitaire**: Prix moyen de vente - Prix d'achat
- **Pourcentage de marge**: (Marge unitaire / Prix moyen de vente) × 100

### Frontend (Flutter)

#### Pages Créées
1. **ProductAnalyticsPage** (`logesco_v2/lib/features/analytics/views/product_analytics_page.dart`)
   - Interface utilisateur complète pour visualiser les analytics
   - Sélecteur de période (7 jours, 30 jours, 90 jours, ce mois, etc.)
   - Statistiques globales avec cartes colorées
   - Liste des top produits par chiffre d'affaires
   - Section des produits à faible performance avec recommandations

#### Modèles de Données
1. **ProductAnalytics** (`logesco_v2/lib/features/analytics/models/product_analytics.dart`)
   - Modèles pour désérialiser les données de l'API
   - Classes: `ProductAnalytics`, `ProductInfo`, `ProductStatistics`, `GlobalStatistics`, etc.

#### Services
1. **AnalyticsService** (`logesco_v2/lib/features/analytics/services/analytics_service.dart`)
   - Service pour communiquer avec l'API analytics
   - Méthodes pour récupérer les analytics par période prédéfinie
   - Gestion des erreurs et de l'authentification

#### Navigation
- **Route ajoutée**: `/analytics/products`
- **Binding**: `AnalyticsBinding` pour l'injection de dépendances
- **Menu**: Ajouté dans le drawer du dashboard sous "RAPPORTS" → "Analytics Produits"

## Utilisation

### Accès à la Fonctionnalité
1. Se connecter à l'application LOGESCO v2
2. Ouvrir le menu latéral (drawer)
3. Aller dans "RAPPORTS" → "Analytics Produits"

### Fonctionnalités Disponibles
1. **Sélection de Période**:
   - 7 derniers jours
   - 30 derniers jours
   - 90 derniers jours
   - Ce mois
   - Mois dernier
   - Cette année
   - Toutes les données

2. **Statistiques Globales**:
   - Nombre de produits vendus
   - Chiffre d'affaires total
   - Quantité totale vendue
   - Nombre de transactions

3. **Top Produits**:
   - Classement par chiffre d'affaires décroissant
   - Informations détaillées (CA, quantité, transactions, marge)
   - Badges colorés pour le classement

4. **Produits à Faible Performance**:
   - Identification automatique des 20% moins performants
   - Recommandations d'actions correctives
   - Suggestions d'amélioration

## Avantages Business

### Identification Rapide
- **Produits Stars**: Identification immédiate des produits les plus rentables
- **Produits en Difficulté**: Détection rapide des produits nécessitant une attention

### Prise de Décision
- **Stratégie de Prix**: Analyse des marges pour optimiser les prix
- **Gestion de Stock**: Priorisation des commandes selon les performances
- **Actions Marketing**: Ciblage des produits nécessitant une promotion

### Optimisation
- **Rotation de Stock**: Identification des produits à rotation lente
- **Rentabilité**: Focus sur les produits les plus rentables
- **Élimination**: Décision éclairée sur l'arrêt de certains produits

## Sécurité et Permissions

- **Authentification**: Requise pour accéder aux analytics
- **Permissions**: Contrôlée par le système de rôles existant
- **Middleware**: Protection par `SubscriptionMiddleware` et authentification

## Performance

- **Optimisation Base de Données**: Utilisation de `groupBy` pour l'agrégation
- **Pagination**: Limitation configurable du nombre de résultats
- **Cache**: Possibilité d'ajouter du cache pour les requêtes fréquentes

## Extensions Futures Possibles

1. **Filtres Avancés**:
   - Par catégorie de produit
   - Par vendeur
   - Par mode de paiement

2. **Graphiques**:
   - Graphiques en barres pour le CA
   - Graphiques en secteurs pour la répartition
   - Évolution temporelle

3. **Export**:
   - Export PDF des rapports
   - Export Excel pour analyse approfondie

4. **Alertes**:
   - Notifications pour produits en baisse
   - Seuils de performance configurables

## Tests

L'endpoint a été testé avec succès :
- ✅ Authentification fonctionnelle
- ✅ Récupération des données analytics
- ✅ Calculs corrects des statistiques
- ✅ Tri décroissant par chiffre d'affaires
- ✅ Identification des produits à faible performance

## Conclusion

Cette implémentation fournit une base solide pour l'analyse des performances produits, permettant aux gestionnaires de prendre des décisions éclairées basées sur des données concrètes de vente.