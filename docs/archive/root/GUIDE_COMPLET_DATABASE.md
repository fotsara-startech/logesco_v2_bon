# 📚 Guide Complet - Base de Données LOGESCO

## 📖 Table des Matières

1. [Objectif](#-objectif)
2. [Démarrage Rapide](#-démarrage-rapide)
3. [Données Créées](#-données-créées-automatiquement)
4. [Workflows](#-workflows)
5. [Scripts Disponibles](#-scripts-disponibles)
6. [Gestion Production](#-gestion-production)
7. [Personnalisation](#-personnalisation)
8. [Résolution de Problèmes](#-résolution-de-problèmes)
9. [Conseils Pratiques](#-conseils-pratiques)

---

## 🎯 Objectif

Ce guide complet vous explique comment gérer votre base de données LOGESCO pour:
- 🎬 Préparer des démonstrations professionnelles
- 🧪 Effectuer des tests avec données réalistes
- 👨‍🎓 Former de nouveaux utilisateurs
- 🚀 Préparer le déploiement en production

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

## 🎬 Workflows

### Workflow 1: Présentation Client

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

### Workflow 2: Tests de Développement

```bash
cd backend

# Ajouter des données de test
npm run db:seed

# Tester votre fonctionnalité
# ...

# Nettoyer et recommencer
npm run db:reset-seed
```

### Workflow 3: Formation Utilisateurs

```bash
# Préparer un environnement de formation
cd backend
npm run db:reset-seed

# Les utilisateurs peuvent:
# - Se connecter avec différents rôles
# - Pratiquer les opérations courantes
# - Voir des données réalistes

# Réinitialiser entre chaque session
npm run db:reset-seed
```

### Workflow 4: Préparation Production

```bash
# Nettoyer et préparer pour la production
cd backend
npm run db:clean-production

# Le script vous guidera pour:
# - Supprimer toutes les données de test
# - Créer un admin avec mot de passe sécurisé
# - Configurer les paramètres entreprise
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

## �  Scripts Disponibles

### Commandes NPM

| Commande | Description | Usage |
|----------|-------------|-------|
| `npm run db:help` | Affiche l'aide complète | Toujours |
| `npm run db:check` | Vérifie l'état de la base | Régulièrement |
| `npm run db:seed` | Remplit la base | Tests/Démo |
| `npm run db:reset-seed` | Réinitialise et remplit | Avant démo |
| `npm run db:clean-production` | Prépare pour production | Déploiement |

### Scripts Techniques

| Script | Fichier | Description |
|--------|---------|-------------|
| Remplissage complet | `seed-full-database.js` | Crée toutes les données |
| Réinitialisation | `reset-and-seed.js` | Supprime et recrée |
| Vérification | `check-database.js` | Affiche les statistiques |
| Aide | `show-seed-help.js` | Guide visuel |
| Production | `clean-for-production.js` | Nettoyage production |

## 🚀 Gestion Production

### Préparation au Déploiement

```bash
cd backend

# 1. Nettoyer la base de test
npm run db:clean-production

# 2. Le script vous demandera:
# - Confirmation de suppression
# - Email de l'administrateur
# - Mot de passe sécurisé
# - Nom de l'entreprise
# - Coordonnées entreprise

# 3. Vérifier
npm run db:check

# 4. Configurer les données réelles
# - Ajouter les vrais produits
# - Créer les vrais utilisateurs
# - Configurer les fournisseurs
# - Paramétrer les caisses
```

### Checklist Production

- [ ] Base de données nettoyée
- [ ] Admin créé avec mot de passe fort
- [ ] Informations entreprise configurées
- [ ] Produits réels ajoutés
- [ ] Utilisateurs réels créés
- [ ] Fournisseurs configurés
- [ ] Caisses paramétrées
- [ ] Sauvegarde effectuée
- [ ] Tests de connexion OK
- [ ] Formation utilisateurs faite

## 📚 Documentation Complète

Pour plus de détails, consultez:

- **`SEED_DATABASE_GUIDE.md`** - Guide principal
- **`RESUME_SEED_DATABASE.md`** - Résumé rapide
- **`backend/DEMO_SEED.md`** - Guide démonstration
- **`backend/GUIDE_PRODUCTION.md`** - Guide production
- **`backend/scripts/README.md`** - Index de tous les scripts

## 🔧 Personnalisation

### Modifier les Données Générées

Éditez `backend/scripts/seed-full-database.js`:

#### Ajouter un Produit

```javascript
const productsData = [
  {
    nom: 'Nouveau Produit',
    reference: 'NP-001',
    prixUnitaire: 15.0,
    prixAchat: 8.0,
    categorieId: categories.find(c => c.nom === 'Électronique').id,
    codeBarre: '1234567890123',
    seuilStockMinimum: 20,
    description: 'Description du produit'
  },
  // ... autres produits
];
```

#### Ajouter une Catégorie

```javascript
const categoriesData = [
  { nom: 'Nouvelle Catégorie', description: 'Description' },
  // ... autres catégories
];
```

#### Modifier le Nombre de Ventes

```javascript
// Ligne ~400 dans seed-full-database.js
const numberOfSales = 100; // Au lieu de 50
```

#### Ajouter un Utilisateur

```javascript
const usersData = [
  {
    nom: 'Nouveau',
    prenom: 'Utilisateur',
    email: 'nouveau@logesco.com',
    motDePasse: await bcrypt.hash('password123', 10),
    roleId: roles.find(r => r.nom === 'Caissier').id,
    telephone: '+243 999 999 999'
  },
  // ... autres utilisateurs
];
```

### Créer un Script Personnalisé

```javascript
// backend/scripts/my-custom-seed.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Mon script personnalisé...');
  
  // Votre code ici
  
  console.log('✅ Terminé!');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
```

Ajoutez dans `package.json`:
```json
"scripts": {
  "db:custom": "node scripts/my-custom-seed.js"
}
```

## 🐛 Résolution de Problèmes

### Erreur: "Cannot find module '@prisma/client'"

```bash
cd backend
npm install
npx prisma generate
```

### Erreur: "Database connection failed"

Vérifiez votre fichier `backend/.env`:
```env
DATABASE_URL="file:./database/logesco.db"
```

### Le script se bloque

1. Fermez le serveur backend s'il est en cours d'exécution (Ctrl+C)
2. Fermez Prisma Studio s'il est ouvert
3. Vérifiez qu'aucun processus n'utilise la base
4. Réessayez

### Données incohérentes

Utilisez la réinitialisation complète:
```bash
npm run db:reset-seed
```

### Erreur de permissions

```bash
# Windows: Exécutez PowerShell en administrateur
# Linux/Mac: Vérifiez les permissions du dossier database
chmod 755 backend/database
```

### Base de données corrompue

```bash
# 1. Sauvegarder si possible
copy backend\database\logesco.db backend\database\logesco.corrupted.db

# 2. Supprimer la base
del backend\database\logesco.db

# 3. Recréer
cd backend
npx prisma migrate reset
npm run db:seed
```

### Commandes de Diagnostic

```bash
# Vérifier Node.js
node --version

# Vérifier npm
npm --version

# Vérifier Prisma
npx prisma --version

# Vérifier la base
npm run db:check

# Voir les logs
npm start
```

## 💡 Conseils Pratiques

### Pour les Développeurs

1. Utilisez `npm run db:check` régulièrement
2. Gardez une sauvegarde de votre base de travail
3. Testez sur une copie avant modifications importantes
4. Documentez vos modifications de schéma

### Pour les Démos

1. Réinitialisez toujours avant une démo (`npm run db:reset-seed`)
2. Préparez un scénario de démonstration
3. Testez le parcours complet avant
4. Ayez un plan B (sauvegarde)

### Pour la Formation

1. Créez des comptes par apprenant
2. Préparez des exercices progressifs
3. Réinitialisez entre les sessions
4. Documentez les cas d'usage courants

### Pour la Production

1. Planifiez la migration
2. Formez les utilisateurs avant
3. Préparez un rollback
4. Surveillez les performances
5. N'utilisez JAMAIS les scripts de seed en production!

## ✅ Checklist Avant Présentation

- [ ] Base de données réinitialisée (`npm run db:reset-seed`)
- [ ] Données vérifiées (`npm run db:check`)
- [ ] Serveur démarré (`npm start`)
- [ ] Connexion testée (admin / password123)
- [ ] Quelques ventes de test effectuées
- [ ] Rapports vérifiés

## � Statirstiques Après Seed

Après exécution de `npm run db:seed`, vous aurez:

```
✅ 4 rôles utilisateur
✅ 5 utilisateurs
✅ 8 catégories de produits
✅ 26 produits avec stock
✅ 5 fournisseurs avec comptes
✅ 10 clients avec comptes
✅ 15 commandes d'approvisionnement
✅ 50 ventes avec détails
✅ 3 caisses avec mouvements
✅ 9 catégories de mouvements
✅ 30 mouvements financiers
✅ 5 inventaires
```

## ⚠️ Avertissements Critiques

### ⛔ PRODUCTION

**JAMAIS** utiliser les scripts de seed en production!
- `npm run db:seed` - ❌ NON en production
- `npm run db:reset-seed` - ❌ NON en production
- `npm run db:clean-production` - ✅ OUI pour préparer la production

### 💾 SAUVEGARDE

Toujours sauvegarder avant:
- `npm run db:reset-seed`
- `npm run db:clean-production`
- Toute modification de schéma
- Toute migration Prisma

### 🔒 SÉCURITÉ

- Changez tous les mots de passe par défaut
- Utilisez des mots de passe forts en production
- Ne commitez jamais le fichier `.env`
- Protégez le fichier de base de données

## 📞 Support et Aide

### En Cas de Problème

1. Consultez cette documentation
2. Vérifiez les logs d'erreur
3. Consultez `backend/scripts/README.md`
4. Vérifiez votre configuration `.env`
5. Assurez-vous que Prisma est à jour

### Réinitialisation Complète

Si tout échoue:

```bash
# 1. Sauvegarder
copy backend\database\logesco.db backup.db

# 2. Nettoyer
del backend\database\logesco.db
rmdir /s /q backend\node_modules

# 3. Réinstaller
cd backend
npm install
npx prisma generate
npx prisma migrate deploy
npm run db:seed
```

---

## 🎉 Conclusion

Vous disposez maintenant d'un système complet et automatisé pour:
- ✅ Remplir rapidement votre base de données
- ✅ Préparer des démonstrations professionnelles
- ✅ Effectuer des tests avec données réalistes
- ✅ Former de nouveaux utilisateurs
- ✅ Préparer le déploiement en production

**Commandes essentielles à retenir:**
```bash
npm run db:help        # Aide rapide
npm run db:check       # Vérifier la base
npm run db:seed        # Remplir
npm run db:reset-seed  # Réinitialiser et remplir
```

---

**Bonne utilisation ! 🚀**

*Dernière mise à jour: Novembre 2024*
