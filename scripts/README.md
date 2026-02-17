# 📁 Scripts LOGESCO Backend

Ce dossier contient tous les scripts utilitaires pour la gestion de la base de données et les tests du backend LOGESCO.

## 🌱 Scripts de Remplissage de Base de Données (NOUVEAU)

### Commandes Rapides

```bash
# Afficher l'aide
npm run db:help

# Vérifier la base de données
npm run db:check

# Remplir la base (sans supprimer)
npm run db:seed

# Réinitialiser et remplir
npm run db:reset-seed
```

### Fichiers Principaux

- **`seed-full-database.js`** - Remplit la base avec des données de test complètes
- **`reset-and-seed.js`** - Réinitialise puis remplit la base
- **`check-database.js`** - Vérifie le contenu de la base
- **`show-seed-help.js`** - Affiche l'aide rapide

### Documentation

- **`GUIDE_SEED_FR.md`** - Guide complet en français
- **`SEED_README.md`** - Documentation technique détaillée
- **`QUICK_START_SEED.txt`** - Aide rapide visuelle

## 🗄️ Scripts de Base de Données

### Configuration et Migration

- **`setup-database.js`** - Configuration initiale de la base
- **`apply-indexes.js`** - Application des index pour performance
- **`ensure-base-data.js`** - Assure les données de base minimales

### Gestion des Utilisateurs

- **`add-user-roles.js`** - Ajoute les rôles utilisateur
- **`add-test-user.js`** - Ajoute un utilisateur de test
- **`ensure-admin.js`** - Assure qu'un admin existe
- **`check-roles.js`** - Vérifie les rôles
- **`clean-roles.js`** - Nettoie les rôles
- **`cleanup-test-users.js`** - Supprime les utilisateurs de test

### Données de Test

- **`add-test-products-with-prices.js`** - Ajoute des produits de test
- **`add-test-transactions.js`** - Ajoute des transactions de test
- **`seed-categories.js`** - Remplit les catégories

### Modules Spécifiques

- **`init-licenses.js`** - Initialise le système de licences
- **`init-movement-categories.js`** - Initialise les catégories de mouvements financiers

## 🧪 Scripts de Test

### Tests d'API

- **`test-license-api.js`** - Test de l'API des licences
- **`test-license-database.js`** - Test de la base de données des licences

### Tests d'Environnement

- **`setup-test-environment.js`** - Configure l'environnement de test
- **`comprehensive-real-data-test.js`** - Tests complets avec données réelles

## ⚙️ Scripts de Configuration

### Rate Limiting

- **`disable-rate-limiting.js`** - Désactive la limitation de taux
- **`enable-rate-limiting.js`** - Active la limitation de taux
- **`temp-no-rate-limit.json`** - Configuration temporaire

### Migrations

- **`apply-discount-migration.js`** - Applique la migration des remises

## 📊 Utilisation Typique

### Pour une Présentation

```bash
# 1. Réinitialiser avec données fraîches
npm run db:reset-seed

# 2. Vérifier
npm run db:check

# 3. Démarrer
npm start
```

### Pour le Développement

```bash
# Vérifier l'état
npm run db:check

# Ajouter des données si nécessaire
npm run db:seed

# Configurer la base
npm run db:setup
```

### Pour les Tests

```bash
# Configurer l'environnement de test
npm run test:setup

# Ajouter des données de test
npm run db:seed

# Lancer les tests
npm test
```

## 🔧 Scripts NPM Disponibles

### Base de Données

```bash
npm run db:setup          # Configuration complète
npm run db:reset          # Réinitialisation
npm run db:indexes        # Application des index
npm run db:cleanup        # Nettoyage
npm run db:seed           # Remplissage
npm run db:reset-seed     # Réinitialisation + remplissage
npm run db:check          # Vérification
npm run db:help           # Aide
```

### Tests

```bash
npm run test              # Tests de base
npm run test:all          # Tous les tests
npm run test:setup        # Configuration test
npm run test:real-data    # Tests avec données réelles
```

### Utilitaires

```bash
npm run rate-limit:disable  # Désactiver rate limiting
npm run rate-limit:enable   # Activer rate limiting
```

## ⚠️ Avertissements

1. **Production**: N'utilisez JAMAIS les scripts de seed en production
2. **Sauvegarde**: Sauvegardez toujours avant `db:reset-seed`
3. **Environnement**: Vérifiez votre `.env` avant d'exécuter les scripts
4. **Données**: Les scripts de reset SUPPRIMENT toutes les données

## 📚 Documentation Complète

Pour plus de détails, consultez:
- `GUIDE_SEED_FR.md` - Guide complet en français
- `SEED_README.md` - Documentation technique
- Documentation principale LOGESCO

## 💡 Conseils

- Utilisez `npm run db:help` pour un rappel rapide
- Utilisez `npm run db:check` régulièrement
- Gardez une sauvegarde de votre base de données
- Testez les scripts sur une copie avant utilisation

## 🆘 Support

En cas de problème:
1. Vérifiez votre configuration `.env`
2. Assurez-vous que Prisma est à jour: `npx prisma generate`
3. Consultez les logs d'erreur
4. Référez-vous à la documentation

---

**Dernière mise à jour:** Novembre 2024
