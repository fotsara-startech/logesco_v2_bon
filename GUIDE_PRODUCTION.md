# 🚀 Guide de Préparation pour la Production

## ⚠️ Important

Ce guide explique comment nettoyer votre base de données de test et la préparer pour une utilisation en production réelle.

## 🔄 Méthodes de Nettoyage

### Méthode 1 : Script Automatique (Recommandé)

```bash
cd backend
node scripts/clean-for-production.js
```

Ce script va:
1. ✅ Supprimer toutes les données de test
2. ✅ Créer un rôle administrateur
3. ✅ Créer un utilisateur admin avec mot de passe personnalisé
4. ✅ Créer les paramètres entreprise de base

**Avantages:**
- Interactif et sécurisé
- Demande confirmation avant suppression
- Permet de personnaliser le mot de passe admin
- Permet de configurer le nom de l'entreprise

### Méthode 2 : Suppression Manuelle

```bash
# 1. Arrêter le serveur
# Ctrl+C dans le terminal

# 2. Supprimer la base de données
# Windows
del backend\database\logesco.db

# Linux/Mac
rm backend/database/logesco.db

# 3. Recréer la structure
cd backend
npx prisma migrate deploy
npx prisma generate

# 4. Créer l'admin initial
node scripts/ensure-admin.js

# 5. Redémarrer
npm start
```

### Méthode 3 : Sauvegarde et Restauration

```bash
# 1. Créer une sauvegarde de la base vide (à faire une fois)
cd backend
npx prisma migrate deploy
copy database\logesco.db database\logesco.production.template.db

# 2. Pour revenir à l'état initial plus tard
copy database\logesco.production.template.db database\logesco.db
```

## 📋 Checklist de Préparation Production

### Avant le Nettoyage

- [ ] Sauvegarder les données importantes (si nécessaire)
- [ ] Arrêter le serveur backend
- [ ] Fermer Prisma Studio
- [ ] Vérifier que vous êtes sur la bonne base de données

### Après le Nettoyage

- [ ] Vérifier la connexion avec admin
- [ ] Configurer les paramètres de l'entreprise
- [ ] Créer les rôles utilisateurs nécessaires
- [ ] Créer les utilisateurs réels
- [ ] Ajouter les catégories de produits
- [ ] Ajouter les produits réels
- [ ] Configurer les fournisseurs
- [ ] Tester les fonctionnalités principales

## 🔐 Sécurité Production

### Changements Importants

1. **Mot de passe Admin**
   ```bash
   # Utilisez un mot de passe fort
   # Minimum 12 caractères
   # Mélange de majuscules, minuscules, chiffres, symboles
   ```

2. **Variables d'Environnement**
   ```bash
   # backend/.env
   NODE_ENV=production
   JWT_SECRET=votre_secret_jwt_tres_long_et_complexe
   DATABASE_URL="file:./database/logesco.db"
   ```

3. **Désactiver les Scripts de Test**
   - Ne jamais exécuter `npm run db:seed` en production
   - Ne jamais exécuter `npm run db:reset-seed` en production

## 📊 Vérification Post-Nettoyage

```bash
# Vérifier la base de données
cd backend
npm run db:check

# Devrait afficher:
# - 1 rôle (admin)
# - 1 utilisateur (admin)
# - 0 produits
# - 0 clients
# - 0 ventes
# etc.
```

## 🔧 Configuration Initiale Production

### 1. Paramètres Entreprise

Connectez-vous et configurez:
- Nom de l'entreprise
- Adresse complète
- Téléphone
- Email
- NUI/RCCM

### 2. Utilisateurs

Créez les utilisateurs réels:
- Gérants
- Caissiers
- Gestionnaires de stock

### 3. Catégories et Produits

Ajoutez vos données réelles:
- Catégories de produits
- Produits avec prix réels
- Codes-barres
- Seuils de stock

### 4. Fournisseurs et Clients

Configurez:
- Fournisseurs principaux
- Clients réguliers (si applicable)

## 🚨 En Cas de Problème

### Base de données corrompue

```bash
# Supprimer et recréer
del backend\database\logesco.db
cd backend
npx prisma migrate deploy
node scripts/clean-for-production.js
```

### Mot de passe admin oublié

```bash
cd backend
node scripts/ensure-admin.js
# Cela réinitialisera le mot de passe à "admin123"
```

### Données de test restantes

```bash
cd backend
node scripts/clean-for-production.js
# Répondre "oui" pour tout nettoyer
```

## 📝 Commandes NPM Ajoutées

Ajoutez cette commande à `package.json`:

```json
"db:clean-production": "node scripts/clean-for-production.js"
```

Puis utilisez:
```bash
npm run db:clean-production
```

## ⚠️ Avertissements Critiques

1. **Ne JAMAIS** utiliser les scripts de seed en production
2. **Toujours** sauvegarder avant de nettoyer
3. **Vérifier** que vous êtes sur la bonne base de données
4. **Tester** après le nettoyage avant de mettre en production
5. **Documenter** les mots de passe de manière sécurisée

## 🔄 Workflow Complet

```bash
# 1. Développement et Tests
npm run db:reset-seed    # Données de test
npm run db:check         # Vérification
# ... développement et tests ...

# 2. Préparation Production
npm run db:clean-production  # Nettoyage
# Configurer l'entreprise
# Créer les utilisateurs réels
# Ajouter les données réelles

# 3. Mise en Production
npm start
# Tester toutes les fonctionnalités
# Former les utilisateurs
```

## 📞 Support

En cas de problème lors de la préparation production:
1. Consultez ce guide
2. Vérifiez les logs d'erreur
3. Assurez-vous que Prisma est à jour
4. Contactez le support technique

---

**Bonne mise en production ! 🚀**
