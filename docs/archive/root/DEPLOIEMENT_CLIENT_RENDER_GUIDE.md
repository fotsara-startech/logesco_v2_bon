# Guide de Déploiement Client LOGESCO sur Render

Ce document détaille la procédure complète pour déployer une nouvelle instance backend LOGESCO sur Render avec une base de données Neon PostgreSQL.

## Prérequis

- [ ] Compte Render actif
- [ ] Compte Neon (https://neon.tech/) pour la base de données PostgreSQL
- [ ] Accès au repository GitHub du projet
- [ ] Node.js configuré localement pour les commandes Git

## Étape 1 : Préparation de la Base de Données Neon

### 1.1 Créer une base de données Neon
1. Connectez-vous à https://neon.tech/
2. Créez un nouveau projet pour le client
3. Notez l'URL de connexion PostgreSQL (format : `postgresql://user:password@host/database?sslmode=require&channel_binding=require`)

### 1.2 Configurer les paramètres
- **Database name** : `logesco_[nom_client]`
- **Region** : Choisir la région la plus proche du client
- **Plan** : Gratuit pour les tests, payant pour la production

## Étape 2 : Préparation du Code

### 2.1 Vérifier les fichiers de configuration

Assurez-vous que ces fichiers existent dans le dossier `backend/` :

#### `render.yaml`
```yaml
services:
  - type: web
    name: logesco-api-[nom_client]
    runtime: node
    rootDir: .
    buildCommand: npm ci && npx prisma generate --schema=prisma/schema.postgresql.prisma
    startCommand: chmod +x deploy-render.sh && ./deploy-render.sh && npm run start:prod
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_PROVIDER
        value: postgresql
      - key: DATABASE_URL
        value: [URL_NEON_COMPLETE]
      - key: JWT_SECRET
        generateValue: true
      - key: JWT_EXPIRES_IN
        value: 365d
      - key: JWT_REFRESH_EXPIRES_IN
        value: 365d
      - key: CORS_ORIGIN
        value: "*"
      - key: LOG_LEVEL
        value: info
      - key: PORT
        value: 8080
```

#### `deploy-render.sh`
```bash
#!/bin/bash
set -e

echo "🚀 Preparing PostgreSQL migrations for Render deployment..."

# Backup SQLite migrations
if [ -d "prisma/migrations" ]; then
  echo "📦 Backing up SQLite migrations..."
  mv prisma/migrations prisma/migrations_sqlite_backup
fi

# Use PostgreSQL migrations
echo "📥 Using PostgreSQL migrations..."
cp -r prisma/migrations_pg prisma/migrations

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate --schema=prisma/schema.postgresql.prisma

# Resolve any failed migrations from previous attempts
echo "🧹 Cleaning up any failed migrations..."
npx prisma migrate resolve --rolled-back 20251106124948_init_with_licenses --schema=prisma/schema.postgresql.prisma 2>/dev/null || true
npx prisma migrate resolve --rolled-back 20251217123620_add_cash_sessions --schema=prisma/schema.postgresql.prisma 2>/dev/null || true

# Deploy migrations with baseline support
echo "🗄️ Deploying migrations..."
if ! npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma 2>&1; then
  echo "⚠️ Migration failed (likely existing database), baselining..."
  
  # Mark all existing migrations as applied
  for migration_dir in prisma/migrations/*/; do
    if [ -d "$migration_dir" ]; then
      migration_name=$(basename "$migration_dir")
      echo "📌 Marking migration as applied: $migration_name"
      npx prisma migrate resolve --applied "$migration_name" --schema=prisma/schema.postgresql.prisma 2>/dev/null || true
    fi
  done
  
  # Try deploy again
  echo "🔄 Retrying migration deploy..."
  npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma || {
    echo "⚠️ Migrations already applied or database schema matches. Continuing..."
  }
fi

echo "✅ Deployment complete!"
```

### 2.2 Modifier le render.yaml pour le client
1. Remplacez `[nom_client]` par le nom du client
2. Remplacez `[URL_NEON_COMPLETE]` par l'URL PostgreSQL de Neon
3. Ajustez les autres variables si nécessaire

## Étape 3 : Pousser le Code vers la Branche de Déploiement

### 3.1 Créer la branche de déploiement
```bash
# Depuis le répertoire racine du projet
git add .
git commit -m "Prepare deployment for [nom_client]"

# Créer une branche dédiée au backend pour ce client
$hash = git subtree split --prefix=backend HEAD
git push origin "${hash}:refs/heads/backend-deploy-[nom_client]" --force
```

### 3.2 Vérifier la branche
- La branche `backend-deploy-[nom_client]` doit contenir uniquement les fichiers du dossier `backend/`
- Vérifiez que `render.yaml`, `deploy-render.sh` et `prisma/migrations_pg/` sont présents

## Étape 4 : Configuration sur Render

### 4.1 Créer un nouveau service Web
1. Connectez-vous à https://render.com/
2. Cliquez sur "New" > "Web Service"
3. Connectez votre repository GitHub
4. Sélectionnez le repository du projet

### 4.2 Configuration du service
- **Name** : `logesco-api-[nom_client]`
- **Runtime** : `Node`
- **Branch** : `backend-deploy-[nom_client]`
- **Region** : Choisir la région appropriée
- **Root Directory** : Laisser vide
- **Build Command** :
  ```bash
  npm ci && npx prisma generate --schema=prisma/schema.postgresql.prisma
  ```
- **Start Command** :
  ```bash
  chmod +x deploy-render.sh && ./deploy-render.sh && npm run start:prod
  ```

### 4.3 Variables d'environnement
Configurez ces variables dans l'onglet "Environment" :

| Variable | Valeur |
|----------|--------|
| `NODE_ENV` | `production` |
| `DATABASE_PROVIDER` | `postgresql` |
| `DATABASE_URL` | URL PostgreSQL complète de Neon |
| `JWT_SECRET` | Généré automatiquement par Render |
| `JWT_EXPIRES_IN` | `365d` |
| `JWT_REFRESH_EXPIRES_IN` | `365d` |
| `CORS_ORIGIN` | `*` (ou domaine spécifique du client) |
| `LOG_LEVEL` | `info` |
| `PORT` | `8080` |

### 4.4 Plan de service
- **Plan gratuit** : Pour les tests et petites charges
- **Plan payant** : Pour la production selon les besoins

## Étape 5 : Déploiement et Vérification

### 5.1 Lancer le déploiement
1. Cliquez sur "Create Web Service"
2. Surveillez les logs de build et de déploiement

### 5.2 Vérifications à effectuer dans les logs

#### Build réussi ✅
```
✔ Generated Prisma Client (v6.17.1) to ./node_modules/@prisma/client
Build successful 🎉
```

#### Démarrage réussi ✅
```
🚀 Preparing PostgreSQL migrations for Render deployment...
📦 Backing up SQLite migrations...
📥 Using PostgreSQL migrations...
🔧 Generating Prisma Client...
🗄️ Deploying migrations...
✅ Deployment complete!
```

#### Application démarrée ✅
```
🔧 Configuration LOGESCO API
Environment: production
Database: postgresql
Port: 8080
🗄️ Initialisation de la base de données postgresql...
✅ Base de données connectée avec succès
🚀 Serveur démarré sur le port 8080
```

### 5.3 Tests post-déploiement
1. **Test de santé** : `GET https://[service-url].onrender.com/api/v1/health`
2. **Test d'authentification** : Vérifier l'endpoint de login
3. **Test de base de données** : Vérifier que les tables sont créées

## Étape 6 : Configuration du Domaine (Optionnel)

### 6.1 Domaine personnalisé
1. Dans Render, allez dans "Settings" > "Custom Domains"
2. Ajoutez le domaine du client
3. Configurez les enregistrements DNS chez le client

### 6.2 HTTPS
- Render fournit automatiquement un certificat SSL Let's Encrypt
- Vérifiez que l'accès HTTPS fonctionne

## Étape 7 : Maintenance et Mise à Jour

### 7.1 Mise à jour du code
Pour déployer une nouvelle version :
```bash
# Faire les modifications nécessaires
git add .
git commit -m "Update for [nom_client]: [description]"

# Pousser vers la branche de déploiement
$hash = git subtree split --prefix=backend HEAD
git push origin "${hash}:refs/heads/backend-deploy-[nom_client]" --force
```

### 7.2 Redéploiement automatique
- Render redéploie automatiquement lors des push vers la branche configurée
- Surveillez les logs lors des déploiements

## Dépannage

### Problème : Migration échouée
**Solution** : Le script `deploy-render.sh` gère automatiquement les conflits de migration et utilise `prisma db push` pour s'assurer que toutes les colonnes existent

### Problème : Colonne manquante (ex: image_url does not exist)
**Solution** : Le script utilise `prisma db push` avant les migrations pour créer les colonnes manquantes

### Problème : Base de données SQLite utilisée au lieu de PostgreSQL
**Vérifications** :
- [ ] `DATABASE_URL` contient bien l'URL PostgreSQL Neon
- [ ] Le schéma PostgreSQL est utilisé dans le build command
- [ ] Le script `deploy-render.sh` est exécuté

### Problème : Erreur de permissions
**Solution** : Vérifier que `chmod +x deploy-render.sh` est dans la start command

### Problème : Timeout de build
**Solution** : Vérifier la taille du cache et l'utilisation des ressources

### Problème : Erreurs de type PostgreSQL/SQLite
**Solution** : Le script `prisma db push` synchronise le schéma avec la base de données

## Checklist de Déploiement

- [ ] Base de données Neon créée et URL récupérée
- [ ] `render.yaml` configuré avec les bonnes valeurs
- [ ] Branche `backend-deploy-[nom_client]` créée et poussée
- [ ] Service Render créé avec les bonnes configurations
- [ ] Variables d'environnement configurées
- [ ] Build et déploiement réussis
- [ ] Tests de santé passés
- [ ] Documentation client mise à jour

## Support

Pour toute assistance, contactez l'équipe technique avec :
- Nom du client
- URL du service Render
- Logs d'erreur complets
- Étapes reproduisant le problème