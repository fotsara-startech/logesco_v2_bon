# Guide de Test LOGESCO v2 - Données Réelles

## 🚀 Démarrage Rapide

### Option 1: Script Automatique (Recommandé)
```bash
# Depuis la racine du projet
./test-all-features.bat
```

### Option 2: Étapes Manuelles

#### 1. Désactiver le Rate Limiting
```bash
cd backend
npm run rate-limit:disable
```

#### 2. Configurer l'Environnement
```bash
npm run test:setup
```

#### 3. Démarrer le Serveur
```bash
npm run dev
```

#### 4. Lancer les Tests (dans un autre terminal)
```bash
npm run test:real-data
```

## 🛡️ Gestion du Rate Limiting

### Désactiver pour les Tests
```bash
npm run rate-limit:disable
```
- Modifie automatiquement le fichier `.env`
- Ajoute `TEST_MODE=true`
- Nécessite un redémarrage du serveur

### Réactiver Après les Tests
```bash
npm run rate-limit:enable
```
- Restaure la configuration normale
- Supprime les paramètres de test
- Nécessite un redémarrage du serveur

### Vérification du Statut
Dans les logs du serveur, vous verrez :
- ✅ `Rate limiting désactivé pour les tests` (mode test)
- 🛡️ `Middlewares configurés` (mode normal)

## 📊 Types de Tests Disponibles

### 1. Tests Backend Complets
```bash
npm run test:real-data
```
**Teste :**
- Authentification avec utilisateurs réels
- CRUD complet sur tous les modules
- Fournisseurs avec données d'entreprises réelles
- Clients (particuliers, entreprises, professionnels)
- Produits avec prix et références réalistes
- Comptes bancaires multiples
- Mouvements de stock complexes
- Flux métier end-to-end
- Performance avec volume de données

### 2. Tests Flutter d'Intégration
```bash
cd logesco_v2
flutter test integration_test/integration_test.dart
```
**Teste :**
- Interface utilisateur complète
- Navigation entre écrans
- Formulaires avec validation
- Synchronisation avec le backend
- Gestion d'erreurs réseau

### 3. Tests Manuels
```bash
cd logesco_v2
flutter run
```
**Permet de :**
- Tester l'UX complète
- Vérifier les performances visuelles
- Valider les flux utilisateur
- Tester sur différents appareils

## 📁 Données de Test Créées

### Utilisateurs
- **Admin Test** : `jean-pierre.martin@logesco-test.com`
- **Mot de passe** : `MotDePasseSecurise123!`

### Fournisseurs (3)
1. **Électronique Moderne SARL** (France)
2. **Matériaux Pro Distribution** (Grenoble)
3. **Import Export Global Ltd** (UK)

### Clients (3)
1. **Marie Dupont** (Particulier, Lyon)
2. **TechStart Solutions** (Entreprise, Toulouse)
3. **Restaurant Le Gourmet** (Professionnel, Marseille)

### Produits (5+)
1. **MacBook Pro 16" M3 Pro** (2899€)
2. **Perceuse Bosch Professional** (189.99€)
3. **Machine à café DeLonghi** (599€)
4. **Samsung Galaxy S24 Ultra** (1299€)
5. **Chaise Herman Miller** (1395€)

### Comptes Bancaires (4)
1. **Compte Courant Principal** (25,000€)
2. **Compte Épargne** (50,000€)
3. **Caisse Magasin** (2,000€)
4. **Compte USD Import** (15,000$)

## 📈 Résultats et Rapports

### Rapport Détaillé
```
backend/scripts/test-results/test-results.json
```
**Contient :**
- Résultats de chaque test
- Temps d'exécution
- Données créées
- Erreurs détaillées
- Statistiques de performance

### Logs du Serveur
- Affichage en temps réel dans la console
- Détails des requêtes et réponses
- Erreurs et warnings
- Métriques de performance

## 🧹 Nettoyage

### Nettoyer les Données de Test
```bash
npm run db:reset
```

### Réactiver le Rate Limiting
```bash
npm run rate-limit:enable
```

### Nettoyage Complet
```bash
npm run db:reset
npm run rate-limit:enable
```

## ⚠️ Notes Importantes

### Sécurité
- Le rate limiting est **désactivé** uniquement en mode test
- **Toujours réactiver** avant la production
- Les données de test sont **réalistes** mais fictives

### Performance
- Les tests créent un **volume important** de données
- Temps d'exécution : **5-10 minutes** pour tous les tests
- Recommandé sur **SSD** pour de meilleures performances

### Environnement
- Port **8080** doit être libre
- **Node.js 18+** requis
- **Flutter 3.0+** pour les tests d'intégration
- Base de données **SQLite** en local

## 🆘 Dépannage

### Erreur "Port 8080 occupé"
```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Ou changer le port dans .env
PORT=8081
```

### Erreur "Rate limiting actif"
```bash
npm run rate-limit:disable
# Puis redémarrer le serveur
```

### Base de données corrompue
```bash
npm run db:reset
npm run db:setup
```

### Tests Flutter échouent
```bash
flutter clean
flutter pub get
flutter doctor
```

## 📞 Support

En cas de problème :
1. Vérifiez les logs du serveur
2. Consultez le fichier de résultats JSON
3. Vérifiez que le rate limiting est désactivé
4. Redémarrez le serveur si nécessaire

---

**Bonne phase de test ! 🧪✨**