# Correction de la Recherche pour SQLite

## Problème

Erreur lors de la recherche:
```
Unknown argument `mode`. Did you mean `lte`?
```

## Cause

L'option `mode: 'insensitive'` n'est pas supportée par Prisma avec SQLite. Cette option n'est disponible que pour:
- PostgreSQL
- MongoDB
- MySQL (avec certaines limitations)

## Solution

Suppression de l'option `mode: 'insensitive'` et conversion de la recherche en minuscules:

### Avant (ne fonctionne pas avec SQLite):
```javascript
where.OR = [
  {
    numeroCommande: {
      contains: search.trim(),
      mode: 'insensitive'  // ❌ Erreur avec SQLite
    }
  }
]
```

### Après (compatible SQLite):
```javascript
const searchTerm = search.trim().toLowerCase();
where.OR = [
  {
    numeroCommande: {
      contains: searchTerm  // ✅ Fonctionne avec SQLite
    }
  }
]
```

## Comportement

### Recherche insensible à la casse:
SQLite effectue des comparaisons insensibles à la casse par défaut pour les colonnes TEXT, donc:
- Rechercher "cmd" trouvera "CMD", "Cmd", "cmd"
- Rechercher "fournisseur" trouvera "Fournisseur", "FOURNISSEUR"

### Recherche partielle:
La recherche utilise `contains`, donc:
- "CMD" trouve "CMD20240508019"
- "Four" trouve "Fournisseur ABC"
- "2024" trouve toutes les commandes de 2024

## Test

1. Redémarrer le backend (si pas déjà fait):
```bash
cd backend
npm start
```

2. Dans l'application:
   - Aller sur la page des commandes
   - Taper "c" dans la recherche
   - Les commandes doivent s'afficher sans erreur

## Note technique

Si vous migrez vers PostgreSQL ou MySQL plus tard, vous pourrez réactiver `mode: 'insensitive'` pour une recherche encore plus performante.
