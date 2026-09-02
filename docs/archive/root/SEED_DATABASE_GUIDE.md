# 🌱 Guide de Remplissage de la Base de Données LOGESCO

## 🎯 Objectif

Ce guide vous explique comment remplir rapidement votre base de données LOGESCO avec des données de test réalistes pour vos présentations et tests.

## 🚀 Démarrage Rapide

### Afficher l'aide

```bash
cd backend
npm run db:help
```

### Commandes Principales

```bash
# Vérifier le contenu de la base
npm run db:check

# Remplir la base (sans supprimer les données existantes)
npm run db:seed

# Réinitialiser complètement et remplir
npm run db:reset-seed
```

## 📊 Données Créées Automatiquement

Le script `db:seed` crée automatiquement:

### 👥 Utilisateurs (5)
Tous avec le mot de passe: **password123**

| Utilisateur | Email | Rôle |
|------------|-------|------|
| admin | admin@logesco.com | Administrateur |
| gerant | gerant@logesco.com | Gérant |
| caissier1 | caissier1@logesco.com | Caissier |
| caissier2 | caissier2@logesco.com | Caissier |
| stock_manager | stock@logesco.com | Gestionnaire Stock |

### 🛍️ Produits (26)
Répartis dans 8 catégories:
- **Boissons** (5): Coca-Cola, Fanta, Sprite, Eau, Jus
- **Alimentation** (5): Riz, Huile, Sucre, Farine, Pâtes
- **Hygiène** (4): Savon, Dentifrice, Shampoing, Papier Toilette
- **Électronique** (3): Chargeurs, Écouteurs, Câbles
- **Vêtements** (2): T-Shirts, Jeans
- **Papeterie** (3): Cahiers, Stylos, Crayons
- **Ménage** (2): Javel, Éponges
- **Boulangerie** (2): Pain, Croissants

### 🚚 Fournisseurs (5)
Avec contacts complets et comptes crédit

### 👨‍👩‍👧‍👦 Clients (10)
Avec noms, téléphones, emails et adresses

### 📋 Transactions
- **15 commandes** d'approvisionnement (différents statuts)
- **50 ventes** avec détails complets
- Mouvements de stock automatiques
- Reçus générés

### 💵 Gestion Financière
- **3 caisses** configurées avec mouvements
- **30 mouvements financiers** dans 9 catégories
- Catégories: Salaires, Loyer, Électricité, Eau, Transport, etc.

### 📝 Inventaires (5)
Avec différents statuts et écarts de stock

### 🏢 Entreprise
- Nom: LOGESCO SARL
- Adresse: 123 Avenue du Commerce, Kinshasa
- Téléphone: +243 123 456 789
- Email: contact@logesco.com

## 🎬 Workflow pour une Présentation

```bash
# 1. Aller dans le dossier backend
cd backend

# 2. Réinitialiser avec des données fraîches
npm run db:reset-seed

# 3. Vérifier que tout est en place
npm run db:check

# 4. Démarrer le serveur
npm start

# 5. Se connecter avec: admin / password123

# 6. Faire votre présentation ! 🎉
```

## 🧪 Workflow pour les Tests

```bash
cd backend

# Ajouter des données de test
npm run db:seed

# Tester votre fonctionnalité
# ...

# Nettoyer et recommencer
npm run db:reset-seed
```

## ⚠️ Avertissements Importants

### ⛔ Réinitialisation Complète

La commande `npm run db:reset-seed` **SUPPRIME TOUTES LES DONNÉES** de la base !

**Avant de l'utiliser:**
1. ✅ Sauvegardez vos données importantes
2. ✅ Vérifiez que vous êtes sur la bonne base de données
3. ✅ Vérifiez votre fichier `.env`

### 💾 Sauvegarde de la Base

```bash
# Windows
copy backend\database\logesco.db backend\database\logesco.backup.db

# Linux/Mac
cp backend/database/logesco.db backend/database/logesco.backup.db
```

## 📚 Documentation Complète

Pour plus de détails, consultez:

- **`backend/scripts/GUIDE_SEED_FR.md`** - Guide complet en français
- **`backend/scripts/SEED_README.md`** - Documentation technique
- **`backend/scripts/README.md`** - Index de tous les scripts

## 🔧 Personnalisation

Pour personnaliser les données générées, éditez:
**`backend/scripts/seed-full-database.js`**

Exemples de modifications:
- Ajouter plus de produits
- Modifier les catégories
- Changer les informations de l'entreprise
- Ajuster le nombre de ventes/commandes

## 🐛 Résolution de Problèmes

### Erreur: "Cannot find module '@prisma/client'"

```bash
cd backend
npm install
npx prisma generate
```

### Erreur: "Database connection failed"

Vérifiez votre fichier `backend/.env`:
```
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

## 💡 Conseils Pratiques

1. **Avant une démo**: Toujours réinitialiser avec `npm run db:reset-seed`
2. **Tests réguliers**: Utilisez `npm run db:check` pour surveiller votre base
3. **Développement**: Gardez une sauvegarde de votre base de données
4. **Production**: N'utilisez JAMAIS ces scripts en production !

## ✅ Checklist Avant Présentation

- [ ] Base de données réinitialisée (`npm run db:reset-seed`)
- [ ] Données vérifiées (`npm run db:check`)
- [ ] Serveur démarré (`npm start`)
- [ ] Connexion testée (admin / password123)
- [ ] Quelques ventes de test effectuées
- [ ] Rapports vérifiés

## 📞 Support

En cas de problème:
1. Consultez `backend/scripts/GUIDE_SEED_FR.md`
2. Vérifiez les logs d'erreur
3. Assurez-vous que Prisma est à jour
4. Référez-vous à la documentation principale

---

**Bonne présentation ! 🚀**

*Dernière mise à jour: Novembre 2024*
