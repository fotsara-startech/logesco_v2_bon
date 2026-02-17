# 🌱 Guide de Remplissage de la Base de Données LOGESCO

## 🎯 Objectif

Ces scripts vous permettent de remplir rapidement votre base de données LOGESCO avec des données de test réalistes pour vos démonstrations et tests.

## 🚀 Utilisation Rapide

### Option 1: Commandes NPM (Recommandé)

```bash
# Vérifier le contenu actuel de la base
npm run db:check

# Remplir la base (sans supprimer les données existantes)
npm run db:seed

# Réinitialiser complètement et remplir
npm run db:reset-seed
```

### Option 2: Commandes Node directes

```bash
# Vérifier la base
node backend/scripts/check-database.js

# Remplir la base
node backend/scripts/seed-full-database.js

# Réinitialiser et remplir
node backend/scripts/reset-and-seed.js
```

## 📊 Données Créées

Le script crée automatiquement:

### 👥 Utilisateurs (5)
- **admin** / admin@logesco.com - Administrateur complet
- **gerant** / gerant@logesco.com - Gérant du magasin
- **caissier1** / caissier1@logesco.com - Caissier principal
- **caissier2** / caissier2@logesco.com - Caissier secondaire
- **stock_manager** / stock@logesco.com - Gestionnaire de stock

**Mot de passe pour tous:** `password123`

### 🛍️ Produits (26)
Répartis dans 8 catégories:
- Boissons (5 produits)
- Alimentation (5 produits)
- Hygiène (4 produits)
- Électronique (3 produits)
- Vêtements (2 produits)
- Papeterie (3 produits)
- Ménage (2 produits)
- Boulangerie (2 produits)

### 🚚 Fournisseurs (5)
Avec contacts et comptes crédit

### 👨‍👩‍👧‍👦 Clients (10)
Avec coordonnées complètes

### 📋 Transactions
- 15 commandes d'approvisionnement
- 50 ventes avec détails
- Mouvements de stock automatiques
- Reçus générés

### 💵 Gestion Financière
- 3 caisses configurées
- 30 mouvements financiers
- 9 catégories de dépenses

### 📝 Inventaires (5)
Avec différents statuts et écarts

## 🏢 Informations Entreprise

Le script configure automatiquement:
- **Nom:** LOGESCO SARL
- **Adresse:** 123 Avenue du Commerce, Kinshasa
- **Téléphone:** +243 123 456 789
- **Email:** contact@logesco.com
- **NUI/RCCM:** CD/KIN/RCCM/12-A-12345

## ⚙️ Scénarios d'Utilisation

### 🎬 Avant une Présentation

```bash
# 1. Réinitialiser complètement la base
npm run db:reset-seed

# 2. Vérifier que tout est en place
npm run db:check

# 3. Démarrer le serveur
npm start
```

### 🧪 Pour des Tests

```bash
# Ajouter des données de test
npm run db:seed

# Tester votre fonctionnalité
# ...

# Nettoyer et recommencer
npm run db:reset-seed
```

### 📈 Développement Quotidien

```bash
# Vérifier l'état de la base
npm run db:check

# Ajouter plus de données si nécessaire
npm run db:seed
```

## ⚠️ Avertissements Importants

### ⛔ Réinitialisation Complète
La commande `npm run db:reset-seed` **SUPPRIME TOUTES LES DONNÉES** !

**Avant de l'utiliser:**
1. Sauvegardez vos données importantes
2. Assurez-vous d'être sur la bonne base de données
3. Vérifiez votre fichier `.env`

### 💾 Sauvegarde

Pour sauvegarder votre base SQLite:
```bash
# Windows
copy backend\database\logesco.db backend\database\logesco.backup.db

# Linux/Mac
cp backend/database/logesco.db backend/database/logesco.backup.db
```

## 🔧 Personnalisation

### Modifier les Données Générées

Éditez `backend/scripts/seed-full-database.js`:

```javascript
// Exemple: Ajouter plus de produits
const productsData = [
  { 
    nom: 'Mon Nouveau Produit', 
    reference: 'NP-001', 
    prixUnitaire: 10.0,
    // ...
  },
  // Ajoutez vos produits ici
];
```

### Changer les Informations de l'Entreprise

Dans la fonction `createCompanySettings()`:

```javascript
nomEntreprise: 'VOTRE ENTREPRISE',
adresse: 'Votre adresse',
telephone: 'Votre téléphone',
// ...
```

## 🐛 Résolution de Problèmes

### Erreur: "Cannot find module '@prisma/client'"

```bash
cd backend
npm install
npx prisma generate
```

### Erreur: "Database connection failed"

Vérifiez votre fichier `.env`:
```bash
# backend/.env
DATABASE_URL="file:./database/logesco.db"
```

### Le script se bloque

1. Fermez le serveur backend s'il est en cours d'exécution
2. Fermez Prisma Studio s'il est ouvert
3. Réessayez

### Données incohérentes

Utilisez la réinitialisation complète:
```bash
npm run db:reset-seed
```

## 📞 Aide Supplémentaire

Pour plus d'informations:
- Consultez `backend/scripts/SEED_README.md`
- Vérifiez la documentation principale LOGESCO
- Examinez les scripts dans `backend/scripts/`

## 💡 Conseils

1. **Avant une démo:** Toujours réinitialiser avec `npm run db:reset-seed`
2. **Tests réguliers:** Utilisez `npm run db:check` pour surveiller votre base
3. **Développement:** Gardez une sauvegarde de votre base de données
4. **Production:** N'utilisez JAMAIS ces scripts en production !

## ✅ Checklist Avant Présentation

- [ ] Base de données réinitialisée (`npm run db:reset-seed`)
- [ ] Données vérifiées (`npm run db:check`)
- [ ] Serveur démarré (`npm start`)
- [ ] Connexion testée (admin / password123)
- [ ] Quelques ventes de test effectuées
- [ ] Rapports vérifiés

---

**Bonne présentation ! 🎉**
