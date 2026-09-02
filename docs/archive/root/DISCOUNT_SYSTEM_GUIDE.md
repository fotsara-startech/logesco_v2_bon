# Guide du Système de Remises Sécurisées - LOGESCO v2

## Vue d'ensemble

Le système de remises sécurisées de LOGESCO v2 permet aux gérants et vendeurs d'appliquer des remises contrôlées sur les produits, tout en maintenant la traçabilité et en empêchant les abus.

## Fonctionnalités principales

### ✅ **Contrôle des remises par produit**
- Remise maximale configurable pour chaque produit (en FCFA)
- Validation automatique lors de la vente
- Impossible de dépasser la limite autorisée

### ✅ **Traçabilité complète**
- Enregistrement du prix affiché vs prix final
- Montant exact de la remise appliquée
- Justification optionnelle de la remise
- Horodatage automatique de chaque transaction
- Identification du vendeur

### ✅ **Sécurité et intégrité**
- Ventes verrouillées après validation
- Aucune modification possible après création
- Validation en temps réel des remises

### ✅ **Rapports et analyses**
- Rapports de remises par vendeur
- Statistiques détaillées par période
- Top des plus grosses remises accordées

## Configuration

### 1. Configuration des produits

Pour chaque produit, vous pouvez définir une remise maximale autorisée :

```json
{
  "reference": "PRD24001",
  "nom": "Smartphone XYZ",
  "prixUnitaire": 150000,
  "remiseMaxAutorisee": 15000,
  "description": "Remise max: 10% du prix"
}
```

### 2. Paramètres recommandés

| Type de produit | Remise suggérée | Exemple |
|----------------|-----------------|---------|
| Électronique | 5-10% | 15000 FCFA sur 150000 FCFA |
| Vêtements | 10-20% | 5000 FCFA sur 25000 FCFA |
| Alimentaire | 2-5% | 500 FCFA sur 10000 FCFA |
| Services | 0-15% | Variable selon le service |

## Utilisation

### 1. Validation d'une remise

Avant d'appliquer une remise, vous pouvez la valider :

**Endpoint:** `POST /api/v1/sales/validate-discount`

```json
{
  "produitId": 123,
  "remiseAppliquee": 5000,
  "justificationRemise": "Client fidèle - remise de fidélité"
}
```

**Réponse:**
```json
{
  "success": true,
  "data": {
    "isValid": true,
    "produit": {
      "nom": "Smartphone XYZ",
      "prixUnitaire": 150000
    },
    "remise": {
      "appliquee": 5000,
      "maxAutorisee": 15000
    },
    "prixFinal": 145000,
    "message": "Remise autorisée"
  }
}
```

### 2. Création d'une vente avec remise

**Endpoint:** `POST /api/v1/sales`

```json
{
  "clientId": 456,
  "modePaiement": "comptant",
  "details": [
    {
      "produitId": 123,
      "quantite": 1,
      "prixAffiche": 150000,
      "prixUnitaire": 145000,
      "remiseAppliquee": 5000,
      "justificationRemise": "Promotion Black Friday"
    }
  ]
}
```

### 3. Cas d'erreur - Remise non autorisée

Si vous tentez d'appliquer une remise trop élevée :

```json
{
  "success": false,
  "message": "Remise non autorisée pour Smartphone XYZ (PRD24001). Maximum autorisé: 15000 FCFA, Demandé: 20000 FCFA"
}
```

## Rapports

### 1. Rapport par vendeur

**Endpoint:** `GET /api/v1/discount-reports/by-vendor`

Paramètres optionnels :
- `vendeurId` : ID du vendeur spécifique
- `dateDebut` : Date de début (ISO 8601)
- `dateFin` : Date de fin (ISO 8601)
- `page` : Numéro de page
- `limit` : Nombre d'éléments par page

### 2. Résumé des remises

**Endpoint:** `GET /api/v1/discount-reports/summary`

Paramètres :
- `groupBy` : `vendeur`, `produit`, `jour`, `mois`
- `dateDebut` : Date de début
- `dateFin` : Date de fin

### 3. Top des remises

**Endpoint:** `GET /api/v1/discount-reports/top-discounts`

Retourne les plus grosses remises accordées avec :
- Montant de la remise
- Pourcentage utilisé de la remise maximale
- Économie réalisée par le client
- Justification fournie

## Exemples d'utilisation

### Scénario 1: Vente normale avec remise

```javascript
// 1. Valider la remise
const validation = await fetch('/api/v1/sales/validate-discount', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({
    produitId: 123,
    remiseAppliquee: 5000,
    justificationRemise: 'Client VIP'
  })
});

// 2. Si valide, créer la vente
if (validation.data.isValid) {
  const vente = await fetch('/api/v1/sales', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({
      details: [{
        produitId: 123,
        quantite: 1,
        prixAffiche: 150000,
        prixUnitaire: 145000,
        remiseAppliquee: 5000,
        justificationRemise: 'Client VIP'
      }]
    })
  });
}
```

### Scénario 2: Rapport mensuel des remises

```javascript
const rapport = await fetch('/api/v1/discount-reports/summary?groupBy=vendeur&dateDebut=2024-11-01&dateFin=2024-11-30', {
  headers: { 'Authorization': `Bearer ${token}` }
});

console.log('Remises du mois:', rapport.data.totaux);
```

## Bonnes pratiques

### 1. Configuration des remises
- **Soyez conservateur** : Commencez par des remises faibles (5-10%)
- **Analysez régulièrement** : Utilisez les rapports pour ajuster les limites
- **Différenciez par catégorie** : Produits de luxe vs produits courants

### 2. Formation des vendeurs
- **Expliquez les limites** : Pourquoi certaines remises sont bloquées
- **Encouragez la justification** : Demandez toujours une raison
- **Surveillez les patterns** : Identifiez les vendeurs qui abusent

### 3. Contrôle et audit
- **Vérifiez quotidiennement** : Consultez le top des remises
- **Analysez par vendeur** : Identifiez les comportements suspects
- **Ajustez si nécessaire** : Modifiez les limites selon les résultats

## Sécurité

### Mesures de protection
1. **Validation côté serveur** : Impossible de contourner les limites
2. **Traçabilité complète** : Chaque remise est enregistrée avec son contexte
3. **Immutabilité** : Les ventes ne peuvent pas être modifiées après création
4. **Authentification** : Seuls les utilisateurs connectés peuvent appliquer des remises

### Alertes recommandées
- Remise proche de la limite maximale (>90%)
- Vendeur avec beaucoup de remises dans la journée
- Justifications vides ou répétitives
- Remises sur des produits inhabituels

## Migration et installation

### 1. Appliquer la migration

```bash
# Depuis le répertoire racine du projet
node scripts/apply-discount-migration.js
```

### 2. Tester le système

```bash
# Lancer les tests automatisés
node test-discount-system.js
```

### 3. Vérifier l'installation

1. Créez un produit avec une remise maximale
2. Testez une vente avec remise autorisée
3. Testez une vente avec remise non autorisée (doit échouer)
4. Consultez les rapports de remises

## Support et dépannage

### Problèmes courants

**Erreur: "Remise non autorisée"**
- Vérifiez la configuration du produit
- Assurez-vous que `remiseMaxAutorisee` est définie
- Contrôlez que la remise demandée ne dépasse pas la limite

**Erreur: "Prix affiché incorrect"**
- Le `prixAffiche` doit correspondre au `prixUnitaire` du produit
- Vérifiez que les prix sont à jour dans la base de données

**Rapports vides**
- Assurez-vous qu'il y a des ventes avec remises dans la période
- Vérifiez les paramètres de date (format ISO 8601)
- Contrôlez les permissions d'accès aux rapports

### Logs et debugging

Les logs du système incluent :
- Tentatives de remises non autorisées
- Créations de ventes avec remises
- Accès aux rapports de remises
- Erreurs de validation

Consultez les logs dans `/backend/logs/` pour diagnostiquer les problèmes.

---

**Version:** 1.0  
**Dernière mise à jour:** Novembre 2024  
**Auteur:** Équipe LOGESCO v2