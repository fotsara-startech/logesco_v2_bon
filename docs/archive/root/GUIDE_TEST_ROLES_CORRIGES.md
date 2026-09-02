# 🧪 GUIDE DE TEST - SYSTÈME DE RÔLES CORRIGÉ

## 🎯 OBJECTIF DES TESTS
Valider que le système de rôles unifié fonctionne correctement avec les privilèges dynamiques de la base de données.

## ⚡ TEST RAPIDE (5 minutes)

### 1. Démarrer l'application
```bash
# Terminal 1: Backend
cd backend
npm run dev

# Terminal 2: Frontend
cd logesco_v2
flutter run -d windows
```

### 2. Se connecter avec Admin
```
Utilisateur: admin
Mot de passe: admin123
```

**Vérifications:**
- ✅ Connexion réussie
- ✅ Tous les menus visibles dans le drawer
- ✅ Accès à "Utilisateurs" et "Rôles"

### 3. Créer un rôle "VENDEUR"

**Navigation:** Dashboard → Menu → Rôles → Nouveau rôle

**Configuration:**
```
Nom du rôle: VENDEUR
Nom d'affichage: Vendeur
Type: Non-administrateur

Privilèges à sélectionner:
✅ Dashboard
   - Lecture
   
✅ Ventes
   - Lecture
   - Création
   
✅ Produits
   - Lecture
   
✅ Clients
   - Lecture
   - Création
   
✅ Caisses
   - Lecture
   - Ouverture
   - Fermeture
   
✅ Impression
   - Lecture
   - Impression
```

**Cliquer:** Créer

### 4. Créer un utilisateur vendeur

**Navigation:** Dashboard → Menu → Utilisateurs → Nouvel utilisateur

**Configuration:**
```
Nom d'utilisateur: vendeur1
Email: vendeur1@logesco.com
Mot de passe: vendeur123
Rôle: VENDEUR (sélectionner dans la liste)
```

**Cliquer:** Créer

### 5. Se déconnecter et reconnecter

**Déconnexion:** Menu → Déconnexion

**Reconnexion:**
```
Utilisateur: vendeur1
Mot de passe: vendeur123
```

### 6. Vérifier les restrictions

**Menus VISIBLES (autorisés):**
- ✅ Dashboard
- ✅ Ventes
- ✅ Produits (lecture seule)
- ✅ Clients
- ✅ Caisses

**Menus INVISIBLES (non autorisés):**
- ❌ Catégories
- ❌ Stock
- ❌ Inventaire
- ❌ Fournisseurs
- ❌ Commandes
- ❌ Comptabilité
- ❌ Mouvements financiers
- ❌ Rapports
- ❌ Utilisateurs
- ❌ Rôles
- ❌ Entreprise
- ❌ Impressions (paramètres)

### 7. Tester les actions

**Dans Ventes:**
- ✅ Peut voir la liste des ventes
- ✅ Peut créer une nouvelle vente
- ❌ Ne peut pas modifier/supprimer (si non autorisé)

**Dans Produits:**
- ✅ Peut voir la liste des produits
- ❌ Bouton "Nouveau produit" invisible ou désactivé

**Dans Clients:**
- ✅ Peut voir la liste des clients
- ✅ Peut créer un nouveau client

## 🔍 TESTS DÉTAILLÉS

### Test A: Vérification des Logs

**Ouvrir la console de l'application et observer:**

```
🔐 [PermissionService] sales.READ = true (role: VENDEUR, isAdmin: false)
🔐 [PermissionService] sales.CREATE = true (role: VENDEUR, isAdmin: false)
🔐 [PermissionService] users.READ = false (role: VENDEUR, isAdmin: false)
🔐 [PermissionService] products.CREATE = false (role: VENDEUR, isAdmin: false)
```

**Validation:**
- ✅ Les logs montrent le bon rôle (VENDEUR)
- ✅ isAdmin = false
- ✅ Les privilèges correspondent à ce qui a été configuré

### Test B: Modification de Rôle

**1. Reconnecter avec admin**

**2. Modifier le rôle VENDEUR:**
- Ajouter: Rapports → Lecture

**3. Déconnecter et reconnecter avec vendeur1**

**4. Vérifier:**
- ✅ Le menu "Rapports" est maintenant visible
- ✅ Les autres restrictions restent en place

### Test C: Rôle Manager

**1. Créer un rôle "MANAGER":**
```
Privilèges étendus:
- Dashboard: Lecture, Statistiques
- Produits: Lecture, Création, Modification, Suppression
- Catégories: Lecture, Création, Modification, Suppression
- Stock: Lecture, Création, Modification, Ajustement
- Ventes: Lecture, Création, Modification, Suppression
- Clients: Lecture, Création, Modification, Suppression
- Fournisseurs: Lecture, Création, Modification, Suppression
- Commandes: Lecture, Création, Modification, Suppression
- Caisses: Lecture, Création, Modification, Ouverture, Fermeture
- Rapports: Lecture, Exportation
- Impression: Lecture, Impression
```

**2. Créer un utilisateur manager1**

**3. Se connecter avec manager1**

**4. Vérifier:**
- ✅ Accès à la plupart des modules
- ❌ Pas d'accès à Utilisateurs/Rôles/Paramètres entreprise

### Test D: Sécurité

**Tentative de contournement:**

**1. Connecté comme vendeur1**

**2. Essayer d'accéder directement à une route non autorisée:**
- Taper manuellement l'URL ou utiliser un lien direct
- Exemple: /users, /roles, /settings

**3. Vérifier:**
- ✅ Accès refusé ou redirection
- ✅ Message d'erreur approprié
- ✅ Pas de crash de l'application

## 📊 CHECKLIST DE VALIDATION

### Fonctionnalités de Base
- [ ] Connexion admin fonctionne
- [ ] Création de rôle personnalisé fonctionne
- [ ] Création d'utilisateur avec rôle personnalisé fonctionne
- [ ] Connexion avec utilisateur personnalisé fonctionne

### Restrictions d'Accès
- [ ] Menus filtrés selon les privilèges
- [ ] Boutons d'action filtrés selon les privilèges
- [ ] Routes protégées contre l'accès direct
- [ ] Messages d'erreur appropriés

### Dynamisme
- [ ] Modification de rôle prise en compte après reconnexion
- [ ] Nouveaux privilèges appliqués correctement
- [ ] Suppression de privilèges appliquée correctement

### Logs et Débogage
- [ ] Logs de permissions visibles dans la console
- [ ] Logs montrent le bon rôle
- [ ] Logs montrent les bons privilèges
- [ ] Pas d'erreurs dans la console

### Performance
- [ ] Pas de ralentissement notable
- [ ] Vérification des permissions rapide
- [ ] Pas de requêtes API excessives

## 🐛 PROBLÈMES POTENTIELS

### Problème 1: Tous les menus visibles pour vendeur
**Cause possible:** Backend ne renvoie pas l'objet role complet
**Solution:** Vérifier la réponse de `/auth/login` et `/auth/me`

### Problème 2: Aucun menu visible pour vendeur
**Cause possible:** Parsing des privilèges échoue
**Solution:** Vérifier les logs, format des privilèges dans la BDD

### Problème 3: Modifications de rôle non prises en compte
**Cause possible:** Cache ou token non rafraîchi
**Solution:** Déconnexion/reconnexion complète

### Problème 4: Erreurs de compilation
**Cause possible:** Import manquant ou conflit de noms
**Solution:** Vérifier les imports dans les fichiers modifiés

## 📝 RAPPORT DE TEST

### Template à remplir:

```
Date: ___________
Testeur: ___________

TEST 1 - Connexion Admin
[ ] Réussi  [ ] Échoué
Notes: _______________________

TEST 2 - Création Rôle Vendeur
[ ] Réussi  [ ] Échoué
Notes: _______________________

TEST 3 - Création Utilisateur Vendeur
[ ] Réussi  [ ] Échoué
Notes: _______________________

TEST 4 - Connexion Vendeur
[ ] Réussi  [ ] Échoué
Notes: _______________________

TEST 5 - Vérification Restrictions
[ ] Réussi  [ ] Échoué
Menus visibles: _______________________
Menus invisibles: _______________________

TEST 6 - Modification Rôle
[ ] Réussi  [ ] Échoué
Notes: _______________________

TEST 7 - Logs Permissions
[ ] Réussi  [ ] Échoué
Exemple de log: _______________________

RÉSULTAT GLOBAL
[ ] Tous les tests réussis
[ ] Quelques tests échoués (détails ci-dessus)
[ ] Échec majeur

COMMENTAIRES:
_______________________
_______________________
_______________________
```

## 🎉 CRITÈRES DE SUCCÈS

Le système est considéré comme fonctionnel si:

1. ✅ Un utilisateur avec rôle personnalisé voit uniquement les menus autorisés
2. ✅ Les modifications de rôle sont prises en compte après reconnexion
3. ✅ Les logs montrent les bonnes vérifications de permissions
4. ✅ Aucune erreur dans la console
5. ✅ Les tentatives d'accès non autorisé sont bloquées

## 📞 SUPPORT

En cas de problème:
1. Vérifier les logs dans la console
2. Vérifier la réponse du backend (Network tab)
3. Consulter `ANALYSE_PROBLEME_ROLES.md`
4. Consulter `CORRECTION_SYSTEME_ROLES_COMPLETE.md`
