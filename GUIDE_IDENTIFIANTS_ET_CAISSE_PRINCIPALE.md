# Guide - Identifiants par Défaut et Caisse Principale

## 🎯 Modifications Apportées

### 1. Identifiants de Connexion Modifiés
- **AVANT** : `admin` / `password123`
- **APRÈS** : `admin` / `admin123`

### 2. Création Automatique de Caisse
- **Nom** : "Caisse Principale"
- **Création** : Automatique lors de l'initialisation
- **Assignation** : Utilisateur admin
- **Solde initial** : 0 FCFA

## 🔧 Fichiers Modifiés

### `backend/scripts/seed-full-database.js`
```javascript
// AVANT
const hashedPassword = await bcrypt.hash('password123', 10);

// APRÈS  
const hashedPassword = await bcrypt.hash('admin123', 10);
```

### `backend/scripts/ensure-base-data.js`
Ajout de la section création automatique de caisse :
```javascript
// 3. Créer une caisse principale par défaut
const cashRegisterCount = await prisma.cashRegister.count();

if (cashRegisterCount === 0) {
  // Création de la "Caisse Principale"
  // ...
}
```

### `backend/scripts/ensure-admin-and-cash.js` (NOUVEAU)
Script combiné qui s'assure que :
- Le rôle admin existe
- L'utilisateur admin existe avec le bon mot de passe
- La caisse principale est créée

## 🚀 Utilisation

### Option 1 : Script Automatique (Recommandé)
```bash
# Exécuter le script batch
init-admin-and-cash.bat
```

### Option 2 : Commande Manuelle
```bash
cd backend
node scripts/ensure-admin-and-cash.js
```

### Option 3 : Seed Complet (Données de Test)
```bash
cd backend
node scripts/seed-full-database.js
```

## 📋 Résultat de l'Initialisation

### Utilisateur Admin Créé
- **Nom d'utilisateur** : `admin`
- **Mot de passe** : `admin123`
- **Email** : `admin@logesco.com`
- **Rôle** : Administrateur (privilèges complets)
- **Statut** : Actif

### Caisse Principale Créée
- **Nom** : `Caisse Principale`
- **Description** : `Caisse principale créée automatiquement lors de l'initialisation`
- **Solde initial** : `0.0 FCFA`
- **Solde actuel** : `0.0 FCFA`
- **Statut** : `Active`
- **Assignée à** : `admin`
- **Date d'ouverture** : Date de création automatique

### Mouvement d'Ouverture Créé
- **Type** : `ouverture`
- **Montant** : `0.0 FCFA`
- **Description** : `Ouverture automatique de la caisse principale`
- **Utilisateur** : `admin`
- **Métadonnées** : Source de création automatique

## 🧪 Test de Validation

### 1. Connexion à l'Application
1. Démarrer le backend : `npm run dev`
2. Démarrer l'application Flutter
3. Utiliser les identifiants : `admin` / `admin123`
4. ✅ La connexion doit réussir

### 2. Vérification de la Caisse
1. Naviguer vers le module **Caisses**
2. ✅ "Caisse Principale" doit être visible
3. ✅ Statut : Active
4. ✅ Solde : 0 FCFA
5. ✅ Assignée à : admin

### 3. Logs d'Initialisation
```
🚀 Initialisation des données essentielles...
============================================================

📋 Étape 1: Vérification du rôle admin...
✅ Rôle admin créé avec ID: 1

👤 Étape 2: Vérification de l'utilisateur admin...
✅ Utilisateur admin créé avec ID: 1

💵 Étape 3: Vérification de la caisse principale...
✅ Caisse principale créée avec ID: 1

============================================================
🎉 INITIALISATION TERMINÉE AVEC SUCCÈS !
============================================================

🔑 Identifiants de connexion:
   📧 Nom d'utilisateur: admin
   🔒 Mot de passe: admin123

💵 Caisse disponible:
   📦 Nom: Caisse Principale
   💰 Solde actuel: 0 FCFA
   👤 Assignée à: admin
   ✅ Statut: Active
```

## 🔄 Cas d'Usage

### Première Installation
1. Installer LOGESCO
2. Configurer la base de données
3. Exécuter `init-admin-and-cash.bat`
4. Se connecter avec `admin/admin123`
5. Commencer à utiliser la caisse principale

### Réinitialisation
1. Si besoin de repartir à zéro
2. Exécuter le script d'initialisation
3. L'admin et la caisse seront recréés si nécessaires

### Environnement de Production
1. Exécuter l'initialisation une seule fois
2. Changer le mot de passe admin après la première connexion
3. Configurer d'autres caisses selon les besoins

## 🛡️ Sécurité

### Recommandations
- **Changer le mot de passe** après la première connexion
- **Créer d'autres utilisateurs** avec des rôles appropriés
- **Limiter l'accès admin** aux tâches d'administration
- **Sauvegarder régulièrement** la base de données

### Mot de Passe par Défaut
- Le mot de passe `admin123` est temporaire
- Il doit être changé lors de la première utilisation
- Utiliser un mot de passe fort en production

## 📞 Support

### En Cas de Problème
1. **Vérifier** que la base de données est accessible
2. **S'assurer** que les migrations Prisma sont appliquées
3. **Contrôler** le fichier `.env` de configuration
4. **Consulter** les logs d'erreur détaillés

### Commandes de Diagnostic
```bash
# Vérifier la base de données
cd backend
npx prisma db push

# Tester la connexion
node scripts/check-database.js

# Réinitialiser complètement
node scripts/reset-and-seed.js
```

---

**✅ CONFIGURATION TERMINÉE**  
Les identifiants sont maintenant `admin/admin123` et une caisse principale est créée automatiquement lors de l'initialisation.