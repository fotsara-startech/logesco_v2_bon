# Instructions de Déploiement des Corrections

## 📋 Checklist de Déploiement

### Phase 1: Préparation (Avant le déploiement)

- [ ] Sauvegarder la base de données actuelle
- [ ] Créer une branche de développement
- [ ] Tester les modifications en environnement local
- [ ] Vérifier les logs de débogage

### Phase 2: Déploiement Backend

1. **Mettre à jour le code**
   ```bash
   git pull origin main
   cd backend
   npm install
   ```

2. **Vérifier les modifications**
   ```bash
   git diff backend/src/routes/sales.js
   ```

3. **Tester le backend**
   ```bash
   npm test
   node backend/test-cancel-sale-with-session.js
   ```

4. **Redémarrer le serveur**
   ```bash
   npm run start
   ```

### Phase 3: Déploiement Frontend

1. **Mettre à jour le code**
   ```bash
   git pull origin main
   cd logesco_v2
   flutter pub get
   ```

2. **Vérifier les modifications**
   ```bash
   git diff logesco_v2/lib/features/reports/services/activity_report_service.dart
   git diff logesco_v2/lib/features/accounting/services/accounting_service.dart
   ```

3. **Tester le frontend**
   ```bash
   flutter test test-cancel-sale-accounting.dart
   ```

4. **Compiler l'application**
   ```bash
   flutter build apk
   # ou
   flutter build ios
   ```

### Phase 4: Tests de Validation

#### Test 1: Annulation Simple
1. Créer une vente de 50 000 FCFA
2. Vérifier que la session de caisse augmente de 50 000 FCFA
3. Annuler la vente
4. Vérifier que la session de caisse diminue de 50 000 FCFA
5. Générer un bilan comptable
6. Vérifier que la vente n'apparaît pas

#### Test 2: Annulation avec Compte Client
1. Créer une vente à crédit de 100 000 FCFA pour un client
2. Vérifier que le compte client affiche une dette de 100 000 FCFA
3. Annuler la vente
4. Vérifier que le compte client affiche 0 FCFA
5. Générer un bilan comptable
6. Vérifier que la vente n'apparaît pas

#### Test 3: Annulation avec Stock
1. Créer une vente de 5 unités d'un produit
2. Vérifier que le stock diminue de 5 unités
3. Annuler la vente
4. Vérifier que le stock augmente de 5 unités
5. Générer un bilan comptable
6. Vérifier que la vente n'apparaît pas

#### Test 4: Bilan Comptable
1. Créer 5 ventes
2. Annuler 2 ventes
3. Générer un bilan comptable
4. Vérifier que seules 3 ventes apparaissent
5. Vérifier que le chiffre d'affaires est correct

### Phase 5: Monitoring Post-Déploiement

1. **Vérifier les logs**
   ```bash
   # Backend
   tail -f backend/logs/app.log | grep "annulation\|annulee"
   
   # Frontend
   flutter logs | grep "annulation\|annulee"
   ```

2. **Vérifier les performances**
   - Temps de génération du bilan comptable
   - Temps d'annulation d'une vente
   - Utilisation mémoire

3. **Vérifier les erreurs**
   - Aucune exception levée
   - Aucun crash de l'application
   - Aucune incohérence de données

## 🔄 Rollback (En cas de problème)

Si des problèmes surviennent:

1. **Arrêter le déploiement**
   ```bash
   git revert HEAD
   ```

2. **Restaurer la version précédente**
   ```bash
   git checkout main~1
   npm install
   flutter pub get
   ```

3. **Redémarrer les services**
   ```bash
   npm run start
   flutter run
   ```

4. **Restaurer la base de données** (si nécessaire)
   ```bash
   # Utiliser la sauvegarde créée en Phase 1
   ```

## 📊 Métriques de Succès

Après le déploiement, vérifier:

- ✅ Aucune vente annulée dans le bilan comptable
- ✅ Session de caisse correctement mise à jour
- ✅ Compte client correctement ajusté
- ✅ Stock correctement restauré
- ✅ Logs de débogage affichent les exclusions
- ✅ Aucune erreur dans les logs
- ✅ Performance acceptable

## 🆘 Dépannage

### Problème: Les ventes annulées apparaissent toujours dans le bilan

**Solution**:
1. Vérifier que les modifications sont bien déployées
2. Vérifier que le cache est vidé
3. Redémarrer l'application
4. Vérifier les logs pour les erreurs

### Problème: La session de caisse n'est pas mise à jour

**Solution**:
1. Vérifier que le backend a bien reçu la requête d'annulation
2. Vérifier les logs du backend
3. Vérifier que la session est active
4. Redémarrer le backend

### Problème: Le compte client n'est pas ajusté

**Solution**:
1. Vérifier que la vente est liée à un client
2. Vérifier que le compte client existe
3. Vérifier les logs du backend
4. Vérifier la base de données

## 📞 Support

En cas de problème:
1. Consulter les logs de débogage
2. Vérifier la documentation
3. Tester avec les scénarios fournis
4. Contacter le support technique

## 📝 Notes Importantes

- Les modifications ne nécessitent pas de migration de données
- Les ventes existantes ne sont pas affectées
- Le filtrage se fait côté client et serveur
- Les logs de débogage aident à tracer les problèmes
- Les tests doivent être exécutés avant le déploiement

## 🎯 Résumé

Les corrections permettent:
1. ✅ Annulation correcte des ventes
2. ✅ Déduction de la session de caisse
3. ✅ Exclusion de la comptabilité
4. ✅ Ajustement du compte client
5. ✅ Restauration du stock

Toutes les modifications sont testées et prêtes pour le déploiement.
