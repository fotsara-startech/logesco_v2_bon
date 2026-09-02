# 🧪 Guide de Test - Sessions de Caisse LOGESCO v2

## 🎯 Objectif
Tester le système complet de sessions de caisse avec la devise FCFA.

## 📋 Prérequis
- ✅ Backend démarré sur le port 3002
- ✅ Base de données initialisée avec des données de test
- ✅ Application Flutter configurée pour le port 3002

## 🚀 Étapes de test

### **1. Démarrage du système**

```bash
# 1. Démarrer le backend (si pas déjà fait)
cd backend
npm start

# 2. Vérifier que le backend fonctionne
curl http://localhost:3002/

# 3. Démarrer l'application Flutter
cd logesco_v2
flutter run -d windows
```

### **2. Connexion à l'application**

1. **Ouvrir l'application LOGESCO v2**
2. **Se connecter avec :**
   - Utilisateur : `admin`
   - Mot de passe : `password123`

### **3. Test des sessions de caisse**

#### **Étape 1 : Vérifier l'indicateur de session**
- Dans la barre d'application, vous devriez voir un indicateur rouge "Aucune caisse"
- Cliquer dessus pour accéder aux sessions de caisse

#### **Étape 2 : Se connecter à une caisse**
1. Cliquer sur "Se connecter à une caisse"
2. Sélectionner une caisse disponible (ex: "Caisse Express")
3. Saisir un montant initial (ex: 10000 FCFA)
4. Confirmer la connexion

#### **Étape 3 : Vérifier la session active**
- L'indicateur devient vert avec le nom de la caisse
- La vue des sessions affiche les détails de la session
- Durée de session mise à jour en temps réel

#### **Étape 4 : Tenter une vente**
1. Naviguer vers "Ventes" → "Nouvelle vente"
2. Ajouter des produits au panier
3. Vérifier que la vente est autorisée (session active)

#### **Étape 5 : Clôturer la session**
1. Retourner aux sessions de caisse
2. Cliquer sur "Clôturer la session"
3. Saisir le montant final (ex: 12000 FCFA)
4. Confirmer la clôture

#### **Étape 6 : Vérifier l'historique**
- Consulter l'historique des sessions
- Vérifier les montants et durées
- Contrôler les différences calculées

## ✅ Points de vérification

### **Interface utilisateur**
- [ ] Indicateur de session dans l'AppBar
- [ ] Affichage correct des montants en FCFA
- [ ] Pas de décimales pour les montants
- [ ] Icônes monétaires appropriées
- [ ] Messages d'erreur clairs

### **Fonctionnalités**
- [ ] Connexion exclusive à une caisse
- [ ] Blocage des ventes sans session
- [ ] Calcul correct des différences
- [ ] Historique des sessions
- [ ] Durée de session en temps réel

### **Sécurité**
- [ ] Une seule session par utilisateur
- [ ] Une seule session par caisse
- [ ] Vérification avant les ventes
- [ ] Traçabilité complète

## 🐛 Problèmes courants et solutions

### **"Impossible de charger les caisses"**
- Vérifier que le backend fonctionne sur le port 3002
- Contrôler la configuration API dans l'application

### **"Erreur de connexion"**
- Redémarrer le backend
- Vérifier les logs du serveur
- Tester avec `curl http://localhost:3002/`

### **"Aucune caisse disponible"**
- Exécuter le script de seed : `node scripts/seed-full-database.js`
- Vérifier la base de données

### **"Session bloquée"**
- Utiliser l'API pour forcer la déconnexion
- Redémarrer le backend si nécessaire

## 📊 Données de test disponibles

### **Utilisateurs**
- `admin` / `password123` (Administrateur)
- `caissier1` / `password123` (Caissier)
- `gerant` / `password123` (Gérant)

### **Caisses**
- Caisse Express (solde variable)
- Caisse Principale (solde variable)
- Caisse Secondaire (solde variable)

### **Produits**
- 26 produits de test avec différents prix
- Catégories variées
- Stocks disponibles

## 🎉 Résultats attendus

À la fin des tests, vous devriez avoir :
- ✅ Sessions de caisse fonctionnelles
- ✅ Affichage correct en FCFA
- ✅ Exclusivité respectée
- ✅ Historique complet
- ✅ Intégration avec les ventes

## 📞 Support

En cas de problème :
1. Vérifier les logs du backend
2. Consulter la console Flutter
3. Tester les APIs directement avec curl
4. Redémarrer les services si nécessaire

---

**Bonne chance pour les tests ! 🚀**