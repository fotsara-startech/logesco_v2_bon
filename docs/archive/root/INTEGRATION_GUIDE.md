# Guide d'Intégration - Modules Utilisateurs, Caisses et Inventaire

## 🚀 Démarrage Rapide

### Option 1: Script Automatique (Recommandé)

**Windows:**
```bash
./setup-backend.bat
```

**Linux/Mac:**
```bash
chmod +x setup-backend.sh
./setup-backend.sh
```

### Option 2: Démarrage Manuel

1. **Installation des dépendances:**
   ```bash
   cd backend
   npm install
   ```

2. **Configuration de la base de données:**
   ```bash
   npx prisma generate
   node scripts/setup-database.js
   ```

3. **Démarrage du serveur:**
   ```bash
   node start-with-setup.js
   ```

4. **Démarrage de l'application Flutter:**
   ```bash
   cd ../
   flutter run
   ```

## 📋 Informations de Connexion

- **API Backend:** http://localhost:3002/api/v1
- **Utilisateur Admin:** 
  - Email: `admin@logesco.com`
  - Mot de passe: `admin123`

## 🔧 Configuration

### Basculer entre Données Mock et Réelles

Dans `logesco_v2/lib/core/config/api_config.dart`:

```dart
// Pour utiliser les données réelles (API)
static const bool useTestData = false;

// Pour utiliser les données simulées (Mock)
static const bool useTestData = true;
```

## 📊 Modules Disponibles

### 1. **Gestion des Utilisateurs** (`/users`)
- ✅ Création, modification, suppression d'utilisateurs
- ✅ Gestion des rôles et privilèges
- ✅ Activation/désactivation des comptes
- ✅ Changement de mots de passe

**Endpoints:**
- `GET /api/v1/users` - Liste des utilisateurs
- `POST /api/v1/users` - Créer un utilisateur
- `PUT /api/v1/users/:id` - Modifier un utilisateur
- `DELETE /api/v1/users/:id` - Supprimer un utilisateur
- `PATCH /api/v1/users/:id/status` - Changer le statut
- `PATCH /api/v1/users/:id/password` - Changer le mot de passe

### 2. **Gestion des Rôles** (`/roles`)
- ✅ Récupération des rôles disponibles
- ✅ Privilèges détaillés par rôle

**Endpoints:**
- `GET /api/v1/roles` - Liste des rôles

### 3. **Gestion des Caisses** (`/cash-registers`)
- ✅ Création, modification, suppression de caisses
- ✅ Ouverture/fermeture de caisses
- ✅ Suivi des soldes et mouvements

**Endpoints:**
- `GET /api/v1/cash-registers` - Liste des caisses
- `POST /api/v1/cash-registers` - Créer une caisse
- `PUT /api/v1/cash-registers/:id` - Modifier une caisse
- `DELETE /api/v1/cash-registers/:id` - Supprimer une caisse

### 4. **Inventaire de Stock** (`/stock-inventory`)
- ✅ Création d'inventaires (partiels/totaux)
- ✅ Comptage produit par produit
- ✅ Calcul automatique des écarts
- ✅ Finalisation et équilibrage du stock

**Endpoints:**
- `GET /api/v1/stock-inventory` - Liste des inventaires
- `POST /api/v1/stock-inventory` - Créer un inventaire
- `GET /api/v1/stock-inventory/:id/items` - Articles d'un inventaire
- `PUT /api/v1/stock-inventory/items/:itemId` - Mettre à jour un comptage

## 🗄️ Structure de la Base de Données

### Nouvelles Tables Créées:

1. **`user_roles`** - Rôles utilisateur avec privilèges
2. **`users`** - Utilisateurs étendus avec rôles
3. **`cash_registers`** - Caisses enregistreuses
4. **`cash_movements`** - Mouvements de caisse
5. **`stock_inventories`** - Inventaires de stock
6. **`inventory_items`** - Articles d'inventaire

### Rôles par Défaut:

- **Administrateur** - Tous les privilèges
- **Gestionnaire** - Gestion produits, ventes, inventaire, caisses
- **Caissier** - Ventes uniquement
- **Gestionnaire de Stock** - Produits et inventaire uniquement

## 🔐 Sécurité

- ✅ Mots de passe hashés avec bcrypt
- ✅ Validation des données d'entrée
- ✅ Gestion des permissions par rôle
- ✅ Protection contre les doublons
- ✅ Contraintes de base de données

## 🧪 Tests

### Tester les API avec curl:

```bash
# Récupérer tous les utilisateurs
curl http://localhost:3002/api/v1/users

# Récupérer tous les rôles
curl http://localhost:3002/api/v1/roles

# Récupérer toutes les caisses
curl http://localhost:3002/api/v1/cash-registers

# Récupérer tous les inventaires
curl http://localhost:3002/api/v1/stock-inventory
```

### Tester avec l'application Flutter:

1. Démarrez le backend
2. Lancez l'application Flutter
3. Connectez-vous avec admin/admin123
4. Naviguez vers les nouveaux modules depuis le dashboard

## 🐛 Dépannage

### Problème: "Table doesn't exist"
```bash
cd backend
node scripts/setup-database.js
```

### Problème: "bcrypt not found"
```bash
cd backend
npm install bcrypt bcryptjs
```

### Problème: "Prisma client not generated"
```bash
cd backend
npx prisma generate
```

### Problème: "Port 3002 already in use"
```bash
# Tuer le processus sur le port 3002
netstat -ano | findstr :3002
taskkill /PID <PID> /F
```

## 📝 Logs et Monitoring

Le serveur affiche des logs détaillés:
- ✅ Démarrage et configuration
- ✅ Requêtes API avec timestamps
- ✅ Erreurs avec stack traces
- ✅ Statistiques de base de données

## 🔄 Migration des Données

Si vous avez des données existantes, le système:
- ✅ Préserve les données existantes
- ✅ Ajoute seulement les nouvelles tables
- ✅ Insère les données par défaut si nécessaire
- ✅ Ne supprime aucune donnée existante

## 📞 Support

En cas de problème:
1. Vérifiez les logs du serveur
2. Consultez ce guide
3. Vérifiez que toutes les dépendances sont installées
4. Redémarrez le serveur avec le script de setup

---

**🎉 Félicitations ! Vos nouveaux modules sont maintenant intégrés et fonctionnels avec de vraies données !**