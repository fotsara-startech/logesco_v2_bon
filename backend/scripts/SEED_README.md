# Scripts de Remplissage de la Base de Données

Ce dossier contient des scripts pour remplir la base de données LOGESCO avec des données de test réalistes.

## 📋 Scripts Disponibles

### 1. `seed-full-database.js`
Remplit la base de données avec des données de test complètes sans supprimer les données existantes.

**Utilisation:**
```bash
node backend/scripts/seed-full-database.js
```

**Données créées:**
- 4 rôles utilisateur (admin, manager, cashier, stock_manager)
- 5 utilisateurs avec différents rôles
- Paramètres de l'entreprise
- 8 catégories de produits
- 26 produits variés avec stock
- 5 fournisseurs avec comptes
- 10 clients avec comptes
- 15 commandes d'approvisionnement
- 50 ventes avec détails
- 3 caisses avec mouvements
- 9 catégories de mouvements financiers
- 30 mouvements financiers
- 5 inventaires de stock

### 2. `reset-and-seed.js`
Supprime toutes les données existantes puis remplit la base de données.

**⚠️ ATTENTION:** Ce script supprime TOUTES les données de la base de données !

**Utilisation:**
```bash
node backend/scripts/reset-and-seed.js
```

## 🔐 Comptes Utilisateurs Créés

Tous les utilisateurs ont le mot de passe: `password123`

| Nom d'utilisateur | Email | Rôle | Description |
|-------------------|-------|------|-------------|
| admin | admin@logesco.com | Administrateur | Accès complet |
| gerant | gerant@logesco.com | Gérant | Gestion quotidienne |
| caissier1 | caissier1@logesco.com | Caissier | Ventes et caisse |
| caissier2 | caissier2@logesco.com | Caissier | Ventes et caisse |
| stock_manager | stock@logesco.com | Gestionnaire Stock | Gestion inventaire |

## 📦 Données de Test Incluses

### Catégories de Produits
- Boissons
- Alimentation
- Hygiène
- Électronique
- Vêtements
- Papeterie
- Ménage
- Boulangerie

### Exemples de Produits
- Boissons: Coca-Cola, Fanta, Sprite, Eau Minérale, Jus
- Alimentation: Riz, Huile, Sucre, Farine, Pâtes
- Hygiène: Savon, Dentifrice, Shampoing, Papier Toilette
- Électronique: Chargeurs, Écouteurs, Câbles
- Et bien plus...

### Fournisseurs
- Distributeur Boissons SA
- Alimentation Générale SARL
- Hygiène & Beauté Plus
- Électronique Import
- Textile & Mode

### Clients
10 clients avec noms, contacts et adresses réalistes

### Transactions
- Commandes d'approvisionnement avec différents statuts
- Ventes avec différents modes de paiement
- Mouvements de stock automatiques
- Historique des reçus

### Gestion de Caisse
- 3 caisses configurées
- Mouvements d'ouverture, fermeture, entrées, sorties
- Soldes réalistes

### Mouvements Financiers
- Catégories: Salaires, Loyer, Électricité, Eau, Transport, etc.
- 30 mouvements avec dates et montants variés

### Inventaires
- Inventaires partiels et totaux
- Différents statuts (brouillon, en cours, terminé, clôturé)
- Écarts de stock réalistes

## 🚀 Utilisation Recommandée

### Pour les Tests
```bash
# Réinitialiser et remplir la base
node backend/scripts/reset-and-seed.js
```

### Pour les Présentations
```bash
# Remplir avec des données fraîches
node backend/scripts/reset-and-seed.js
```

### Pour Ajouter des Données Supplémentaires
```bash
# Ajouter sans supprimer
node backend/scripts/seed-full-database.js
```

## 📝 Notes Importantes

1. **Sauvegarde**: Avant d'utiliser `reset-and-seed.js`, assurez-vous de sauvegarder vos données importantes.

2. **Environnement**: Ces scripts utilisent la base de données configurée dans votre fichier `.env`.

3. **Dépendances**: Assurez-vous que Prisma est correctement configuré:
   ```bash
   npm install
   npx prisma generate
   ```

4. **Performance**: Le remplissage complet prend environ 10-30 secondes selon votre machine.

5. **Données Réalistes**: Les données sont générées avec des valeurs réalistes pour le contexte congolais (RDC).

## 🔧 Personnalisation

Pour personnaliser les données générées, modifiez le fichier `seed-full-database.js`:

- Ajoutez plus de produits dans `createProducts()`
- Modifiez les catégories dans `createCategories()`
- Ajustez le nombre de ventes dans `createSales()`
- Changez les informations de l'entreprise dans `createCompanySettings()`

## 🐛 Dépannage

### Erreur de connexion à la base de données
```bash
# Vérifiez votre fichier .env
cat backend/.env

# Régénérez le client Prisma
npx prisma generate
```

### Erreur de contraintes
```bash
# Utilisez reset-and-seed pour repartir de zéro
node backend/scripts/reset-and-seed.js
```

### Script bloqué
- Vérifiez que le serveur backend n'est pas en cours d'exécution
- Fermez toutes les connexions à la base de données

## 📞 Support

Pour toute question ou problème, consultez la documentation principale du projet LOGESCO.
