# 🔐 Identifiants de Connexion - LOGESCO v2

## 👤 Utilisateurs disponibles

### **Administrateur** ⭐ (MODIFIÉ)
- **Nom d'utilisateur :** `admin`
- **Mot de passe :** `admin123` ✅ (anciennement `password123`)
- **Email :** admin@logesco.com
- **Rôle :** Administrateur complet
- **Permissions :** Toutes les fonctionnalités
- **Caisse assignée :** Caisse Principale (créée automatiquement)

### **Gérant**
- **Nom d'utilisateur :** `gerant`
- **Mot de passe :** `admin123` ✅ (anciennement `password123`)
- **Email :** gerant@logesco.com
- **Rôle :** Manager
- **Permissions :** Gestion et supervision

### **Caissier 1**
- **Nom d'utilisateur :** `caissier1`
- **Mot de passe :** `admin123` ✅ (anciennement `password123`)
- **Email :** caissier1@logesco.com
- **Rôle :** Caissier
- **Permissions :** Ventes et caisses

### **Caissier 2**
- **Nom d'utilisateur :** `caissier2`
- **Mot de passe :** `admin123` ✅ (anciennement `password123`)
- **Email :** caissier2@logesco.com
- **Rôle :** Caissier
- **Permissions :** Ventes et caisses

### **Gestionnaire de Stock**
- **Nom d'utilisateur :** `stock_manager`
- **Mot de passe :** `admin123` ✅ (anciennement `password123`)
- **Email :** stock@logesco.com
- **Rôle :** Gestionnaire de stock
- **Permissions :** Inventaire et approvisionnement

## 🏪 Caisses disponibles

### **Caisse Principale** ⭐ (CRÉÉE AUTOMATIQUEMENT)
- **Nom :** Caisse Principale
- **Description :** Caisse principale créée automatiquement lors de l'initialisation
- **Solde initial :** 0 FCFA (puis variable selon les transactions)
- **Assignée à :** admin ✅ (NOUVEAU - anciennement caissier1)
- **Création :** Automatique avec l'utilisateur admin

### **Caisse Secondaire**
- **Nom :** Caisse Secondaire
- **Description :** Caisse secondaire
- **Solde initial :** Variable
- **Assignée à :** caissier2

### **Caisse Express**
- **Nom :** Caisse Express
- **Description :** Caisse pour paiements rapides
- **Solde initial :** Variable
- **Assignée à :** caissier1

## � Init ialisation (NOUVEAU)

### **Pour une nouvelle installation :**
```bash
# Exécuter le script d'initialisation
init-admin-and-cash.bat

# Ou manuellement
node backend/scripts/ensure-admin-and-cash.js
```

### **Ce qui est créé automatiquement :**
- ✅ Utilisateur admin avec mot de passe `admin123`
- ✅ Caisse Principale assignée à admin
- ✅ Rôle administrateur avec tous les privilèges
- ✅ Mouvement d'ouverture de caisse

## 🚀 Test rapide des sessions de caisse

### **Étapes recommandées :**

1. **Se connecter en tant qu'administrateur :**
   - Utilisateur : `admin`
   - Mot de passe : `admin123` ✅ (NOUVEAU)

2. **Accéder aux sessions de caisse :**
   - Cliquer sur l'indicateur rouge "Aucune caisse"
   - Ou naviguer vers "Session de Caisse"

3. **Se connecter à une caisse :**
   - Choisir "Caisse Express" ou "Caisse Principale"
   - Saisir un montant initial (ex: 50000 FCFA)
   - Confirmer la connexion

4. **Tester une vente :**
   - Aller dans "Ventes" → "Nouvelle vente"
   - Ajouter des produits
   - Finaliser la vente

5. **Clôturer la session :**
   - Retourner aux sessions de caisse
   - Saisir le montant final
   - Confirmer la clôture

## 💡 Conseils d'utilisation

### **Pour tester l'exclusivité :**
1. Se connecter avec `admin` et ouvrir une caisse
2. Dans un autre navigateur/onglet, se connecter avec `caissier1`
3. Essayer d'ouvrir la même caisse → Doit être bloqué

### **Pour tester les permissions :**
- `admin` : Accès à tout
- `caissier1` : Accès limité aux ventes et caisses
- `stock_manager` : Accès à l'inventaire principalement

### **Pour tester les montants FCFA :**
- Vérifier que tous les montants s'affichent en FCFA
- Pas de décimales pour les montants
- Séparateurs de milliers pour les gros montants

## 🔧 En cas de problème

### **"Nom d'utilisateur ou mot de passe incorrect"**
- Vérifier que vous utilisez `admin123` ✅ (NOUVEAU mot de passe)
- Anciennement `password123` (ne fonctionne plus)
- Essayer avec un autre utilisateur

### **"Aucune caisse disponible"**
- Vérifier que le script de seed a été exécuté
- Redémarrer le backend si nécessaire

### **"Erreur de connexion"**
- Vérifier que le backend fonctionne sur le port 3002
- Tester avec : `curl http://localhost:3002/`

---

**Bon test ! 🎉**