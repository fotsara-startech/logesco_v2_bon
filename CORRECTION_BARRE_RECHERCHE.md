# Correction de la Barre de Recherche des Commandes

## Problème
La barre de recherche dans la page des commandes d'approvisionnement ne fonctionnait pas.

## Cause
Le backend ne gérait pas le paramètre `search` envoyé par le frontend.

## Solution

### Fichiers modifiés

#### 1. backend/src/routes/procurement.js
Ajout de la logique de recherche dans la route GET /procurement:

```javascript
const { 
  fournisseurId, 
  statut, 
  dateDebut, 
  dateFin,
  search,  // ← AJOUTÉ
  page = 1, 
  limit = 20 
} = req.query;

// Recherche par numéro de commande ou nom de fournisseur
if (search && search.trim()) {
  where.OR = [
    {
      numeroCommande: {
        contains: search.trim(),
        mode: 'insensitive'
      }
    },
    {
      fournisseur: {
        nom: {
          contains: search.trim(),
          mode: 'insensitive'
        }
      }
    }
  ];
}
```

#### 2. backend/src/validation/schemas.js
Ajout du paramètre `search` au schéma de validation:

```javascript
search: Joi.object({
  fournisseurId: baseSchemas.id,
  boutiqueId: baseSchemas.id,
  statut: baseSchemas.statut,
  dateDebut: baseSchemas.date,
  dateFin: baseSchemas.date,
  search: Joi.string().max(100).allow('', null),  // ← AJOUTÉ
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
})
```

## Fonctionnalités

La recherche permet de filtrer les commandes par:
- **Numéro de commande**: Ex: "CMD20240508"
- **Nom du fournisseur**: Ex: "Fournisseur ABC"

La recherche est:
- **Insensible à la casse**: "abc" trouve "ABC"
- **Partielle**: "Four" trouve "Fournisseur ABC"
- **En temps réel**: Les résultats se mettent à jour automatiquement

## Test

1. Redémarrer le backend:
```bash
cd backend
npm start
```

2. Dans l'application:
   - Aller sur la page des commandes d'approvisionnement
   - Taper dans la barre de recherche
   - Les commandes doivent se filtrer automatiquement

## Exemples de recherche

- Rechercher "CMD" → Trouve toutes les commandes
- Rechercher "Fournisseur" → Trouve les commandes de ce fournisseur
- Rechercher "20240508" → Trouve les commandes de cette date
- Effacer la recherche → Affiche toutes les commandes
