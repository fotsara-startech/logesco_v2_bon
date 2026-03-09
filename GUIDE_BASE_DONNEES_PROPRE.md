# Guide - Base de Données Propre pour Client

## Problème Résolu

Auparavant, le script `preparer-pour-client-optimise.bat` copiait votre base de données de développement avec toutes vos données de test. Maintenant, il crée une base de données propre avec uniquement les données essentielles.

## Solution Implémentée

### 1. Script de Seed (`backend/prisma/seed.js`)

Un nouveau script qui initialise uniquement les données essentielles:

- **Utilisateur Admin**
  - Username: `admin`
  - Password: `admin123`
  - Rôle: ADMIN avec tous les privilèges

- **Caisse Principale**
  - Nom: "Caisse Principale"
  - Solde initial: 0

- **Paramètres Entreprise**
  - Nom: "Mon Entreprise"
  - Devise: FCFA
  - Seuils d'alerte configurés

### 2. Modifications du Build

Le script `backend/build-portable-optimized.js` a été modifié pour:

1. Supprimer toute base de données existante
2. Créer une nouvelle structure vide
3. Initialiser avec le seed (données essentielles uniquement)

### 3. Nouveau Script de Test

`test-seed-clean.bat` permet de tester le seed avant de créer le package client.

## Utilisation

### Créer le Package Client (avec base propre)

```batch
preparer-pour-client-optimise.bat
```

Le package créé dans `release\LOGESCO-Client-Optimise\` contiendra maintenant une base de données propre.

### Tester le Seed Localement

```batch
test-seed-clean.bat
```

Cela crée une base de test dans `backend\prisma\database\logesco-test.db` pour vérifier que le seed fonctionne.

### Exécuter le Seed Manuellement

```batch
cd backend
npm run db:seed-clean
```

## Données Incluses dans la Base Propre

### ✅ Données Essentielles (Incluses)

- 1 utilisateur admin
- 1 caisse principale
- Paramètres entreprise par défaut

### ❌ Données de Test (NON Incluses)

- Produits de test
- Ventes de test
- Clients de test
- Fournisseurs de test
- Transactions de test
- Mouvements de stock de test

## Vérification

Après avoir créé le package, vous pouvez vérifier la base de données:

```batch
cd release\LOGESCO-Client-Optimise\backend
npx prisma studio
```

Vous devriez voir:
- 1 seul utilisateur (admin)
- 1 seule caisse
- 1 seul enregistrement de paramètres
- Toutes les autres tables vides

## Identifiants par Défaut

Pour tous les clients:

```
Utilisateur: admin
Mot de passe: admin123
```

⚠️ **Important**: Demandez au client de changer le mot de passe lors de la première connexion!

## Personnalisation du Seed

Si vous voulez ajouter d'autres données essentielles, modifiez `backend/prisma/seed.js`:

```javascript
// Exemple: Ajouter une catégorie par défaut
const defaultCategory = await prisma.category.create({
  data: {
    name: 'Général',
    description: 'Catégorie par défaut'
  }
});
```

## Avantages

✅ Base de données propre pour chaque client
✅ Pas de données de test dans la production
✅ Taille de base de données minimale
✅ Démarrage rapide (pas de données inutiles)
✅ Confidentialité préservée (pas de vos données de test)

## Commandes Utiles

```batch
# Créer le package client avec base propre
preparer-pour-client-optimise.bat

# Tester le seed
test-seed-clean.bat

# Exécuter le seed manuellement
cd backend
npm run db:seed-clean

# Voir la base de données
cd backend
npx prisma studio
```

## Dépannage

### Le seed échoue

Vérifiez que bcryptjs est installé:
```batch
cd backend
npm install bcryptjs
```

### La base de données n'est pas créée

Vérifiez que Prisma est correctement configuré:
```batch
cd backend
npx prisma generate
npx prisma db push
```

### Erreur "User already exists"

Le seed utilise `upsert`, donc il ne devrait pas y avoir d'erreur. Si c'est le cas, supprimez la base et recommencez:
```batch
cd backend
del prisma\database\logesco.db
npm run db:seed-clean
```

## Notes Importantes

1. **Sauvegarde**: Votre base de développement (`backend/prisma/database/logesco.db`) n'est PAS modifiée
2. **Isolation**: Le package client a sa propre base de données indépendante
3. **Sécurité**: Changez toujours le mot de passe admin chez le client
4. **Personnalisation**: Le client peut configurer ses propres paramètres après installation

## Prochaines Étapes

Après avoir créé le package:

1. Testez le package localement
2. Vérifiez que seules les données essentielles sont présentes
3. Déployez chez le client
4. Guidez le client pour:
   - Changer le mot de passe admin
   - Configurer les paramètres entreprise
   - Créer les utilisateurs nécessaires
   - Ajouter les produits et données métier
