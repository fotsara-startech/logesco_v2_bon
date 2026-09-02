# 🏪 Guide des Sessions de Caisse - LOGESCO v2

## 📋 Vue d'ensemble

Le système de sessions de caisse permet de gérer l'accès exclusif aux caisses pour les ventes. Chaque utilisateur doit se connecter à une caisse disponible avant de pouvoir effectuer des ventes.

## 🎯 Fonctionnalités principales

### ✅ **Gestion des sessions**
- Connexion exclusive à une caisse
- Un seul utilisateur par caisse à la fois
- Session automatique avec suivi du temps
- Clôture avec récapitulatif des encaissements

### ✅ **Sécurité et contrôle**
- Vérification obligatoire avant les ventes
- Exclusivité garantie (pas de double connexion)
- Traçabilité complète des sessions
- Historique des activités

### ✅ **Interface utilisateur**
- Indicateur de session dans la barre d'application
- Vue dédiée pour la gestion des sessions
- Sélection facile des caisses disponibles
- Clôture guidée avec saisie du solde final

## 🚀 Utilisation

### **1. Se connecter à une caisse**

1. **Accéder aux sessions** :
   - Cliquer sur l'indicateur rouge "Aucune caisse" dans la barre d'application
   - Ou naviguer vers "Session de Caisse" dans le menu

2. **Sélectionner une caisse** :
   - Cliquer sur "Se connecter à une caisse"
   - Choisir une caisse disponible dans la liste
   - Saisir le montant initial en caisse
   - Confirmer la connexion

3. **Session active** :
   - L'indicateur devient vert avec le nom de la caisse
   - Vous pouvez maintenant effectuer des ventes
   - La durée de session est suivie automatiquement

### **2. Effectuer des ventes**

- **Vérification automatique** : Le système vérifie qu'une session est active
- **Blocage si nécessaire** : Redirection vers les sessions si aucune caisse connectée
- **Ventes normales** : Toutes les fonctionnalités de vente sont disponibles

### **3. Clôturer la session**

1. **Initier la clôture** :
   - Cliquer sur "Clôturer la session" dans la vue des sessions
   - Ou utiliser le bouton dans l'indicateur de session

2. **Saisir le solde final** :
   - Entrer le montant réel en caisse
   - Le système calcule automatiquement la différence
   - Confirmer la clôture

3. **Récapitulatif** :
   - Affichage du résumé de la session
   - Durée totale et montants
   - Ajout automatique à l'historique

## 🔧 Configuration technique

### **Backend (API)**

```javascript
// Routes disponibles
GET    /api/v1/cash-sessions/active                    // Session active
GET    /api/v1/cash-sessions/available-cash-registers  // Caisses disponibles
POST   /api/v1/cash-sessions/connect                   // Se connecter
POST   /api/v1/cash-sessions/disconnect                // Se déconnecter
GET    /api/v1/cash-sessions/history                   // Historique
GET    /api/v1/cash-sessions/stats                     // Statistiques
```

### **Frontend (Flutter)**

```dart
// Contrôleurs principaux
CashSessionController    // Gestion des sessions
CashRegisterController   // Gestion des caisses

// Widgets utiles
CashSessionIndicator     // Indicateur dans l'AppBar
CashSessionView         // Vue principale des sessions
CashSessionFAB          // Bouton d'action flottant
```

### **Base de données**

```sql
-- Table des sessions
CREATE TABLE cash_sessions (
    id INTEGER PRIMARY KEY,
    caisse_id INTEGER NOT NULL,
    utilisateur_id INTEGER NOT NULL,
    solde_ouverture REAL NOT NULL,
    solde_fermeture REAL,
    date_ouverture DATETIME NOT NULL,
    date_fermeture DATETIME,
    is_active BOOLEAN DEFAULT 1,
    metadata TEXT
);
```

## 📊 Statistiques et rapports

### **Données disponibles**
- Nombre total de sessions
- Sessions actives en cours
- Chiffre d'affaires par session
- Durée moyenne des sessions
- Historique détaillé

### **Utilisation des données**
- Analyse de performance des vendeurs
- Optimisation des horaires d'ouverture
- Suivi des encaissements par caisse
- Détection d'anomalies

## 🛡️ Sécurité et bonnes pratiques

### **Règles de sécurité**
- ✅ Une seule session active par utilisateur
- ✅ Une seule session par caisse
- ✅ Vérification obligatoire avant les ventes
- ✅ Traçabilité complète des actions

### **Bonnes pratiques**
- 🔄 Clôturer les sessions en fin de journée
- 💰 Vérifier les soldes lors de la clôture
- 📝 Consulter l'historique régulièrement
- ⚠️ Signaler les anomalies immédiatement

## 🔍 Dépannage

### **Problèmes courants**

**❌ "Aucune caisse disponible"**
- Vérifier que des caisses sont créées et actives
- S'assurer qu'elles ne sont pas utilisées par d'autres utilisateurs

**❌ "Impossible de se connecter"**
- Vérifier la connexion réseau
- Redémarrer l'application si nécessaire

**❌ "Session bloquée"**
- Contacter un administrateur pour forcer la déconnexion
- Vérifier les permissions utilisateur

### **Commandes de test**

```bash
# Tester les sessions de caisse
dart test-cash-sessions.dart

# Vérifier la base de données
sqlite3 backend/database.db "SELECT * FROM cash_sessions;"

# Redémarrer le backend
cd backend && npm start
```

## 📈 Évolutions futures

### **Fonctionnalités prévues**
- 📱 Notifications de session
- 📊 Rapports avancés
- 🔄 Synchronisation multi-appareils
- 🎯 Objectifs de vente par session

### **Améliorations techniques**
- ⚡ Optimisation des performances
- 🔒 Sécurité renforcée
- 📡 Mode hors ligne
- 🎨 Interface améliorée

---

## 🎉 Conclusion

Le système de sessions de caisse apporte une gestion professionnelle et sécurisée des points de vente. Il garantit l'exclusivité d'accès aux caisses tout en offrant une traçabilité complète des activités commerciales.

**Avantages clés :**
- ✅ Sécurité et contrôle d'accès
- ✅ Traçabilité complète
- ✅ Interface intuitive
- ✅ Intégration transparente avec les ventes
- ✅ Statistiques et rapports détaillés