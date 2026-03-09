# Test de l'Internationalisation - LOGESCO v2

## 🧪 Guide de test rapide

### Prérequis
- Application LOGESCO v2 installée
- Backend démarré
- Accès à l'interface

## 📝 Étapes de test

### 1. Démarrer l'application

```bash
# Dans le terminal, depuis le dossier logesco_v2
flutter run
```

### 2. Vérifier la langue par défaut

✅ **Attendu:** L'application démarre en Français

- Vérifier que les textes sont en français
- Vérifier l'AppBar, les menus, les boutons

### 3. Accéder aux paramètres

1. Se connecter avec les identifiants admin
2. Aller dans le menu latéral
3. Cliquer sur "Paramètres de l'entreprise"

### 4. Tester le changement de langue

Dans la page des paramètres:

1. **Localiser le sélecteur de langue**
   - Doit être visible en haut de la page
   - Carte avec titre "Langue de l'application"
   - Deux options: 🇫🇷 Français et 🇬🇧 English

2. **Changer vers l'anglais**
   - Cliquer sur "🇬🇧 English"
   - ✅ **Attendu:** 
     - Message de succès "Language changed to English"
     - Interface change immédiatement en anglais
     - AppBar affiche "Company Settings"
     - Boutons en anglais

3. **Naviguer dans l'application**
   - Retourner au tableau de bord
   - ✅ **Attendu:** Titre "Dashboard" en anglais
   - Visiter d'autres pages
   - ✅ **Attendu:** Textes traduits (ceux qui utilisent .tr)

4. **Revenir au français**
   - Retourner aux paramètres
   - Cliquer sur "🇫🇷 Français"
   - ✅ **Attendu:**
     - Message "La langue a été changée en Français"
     - Interface revient en français

### 5. Tester la persistance

1. **Changer la langue vers l'anglais**
2. **Fermer complètement l'application**
3. **Redémarrer l'application**
4. ✅ **Attendu:** L'application démarre en anglais

## 🔍 Points de vérification

### Interface traduite (exemples)

| Page | Français | English |
|------|----------|---------|
| Paramètres | "Paramètres de l'entreprise" | "Company Settings" |
| Bouton Actualiser | "Actualiser" | "Refresh" |
| Bouton Annuler | "Annuler les modifications" | "Undo changes" |
| Nom entreprise | "Nom de l'entreprise" | "Company Name" |
| Téléphone | "Téléphone" | "Phone" |
| Logo | "Logo (optionnel)" | "Logo (optional)" |
| Langue factures | "Langue des factures" | "Invoice Language" |
| Sauvegarder | "Sauvegarder les modifications" | "Save Changes" |

### Sélecteur de langue

✅ Vérifier:
- [ ] Carte visible avec icône de langue
- [ ] Titre "Langue de l'application" / "Application Language"
- [ ] Option Français avec drapeau 🇫🇷
- [ ] Option English avec drapeau 🇬🇧
- [ ] Langue active indiquée (bordure bleue + icône check)
- [ ] Clic change la langue immédiatement
- [ ] Message de confirmation affiché

### Persistance

✅ Vérifier:
- [ ] Langue sauvegardée après changement
- [ ] Langue restaurée au redémarrage
- [ ] Pas de régression vers le français

## 🐛 Problèmes potentiels

### Problème 1: Textes non traduits
**Symptôme:** Certains textes restent en français même en anglais

**Cause:** Ces textes sont hardcodés et n'utilisent pas `.tr`

**Solution:** Normal pour l'instant, migration progressive en cours

### Problème 2: Langue ne change pas
**Symptôme:** Clic sur la langue ne fait rien

**Cause possible:**
1. Erreur dans le contrôleur
2. GetStorage non initialisé

**Solution:**
```bash
# Vérifier les logs Flutter
flutter logs
```

### Problème 3: Langue non persistée
**Symptôme:** Langue revient au français au redémarrage

**Cause:** GetStorage n'a pas sauvegardé

**Solution:**
```dart
// Vérifier dans le code
final storage = GetStorage();
print(storage.read('app_language')); // Doit afficher 'en' ou 'fr'
```

## 📊 Checklist de test complet

### Fonctionnalités de base
- [ ] Application démarre en français par défaut
- [ ] Sélecteur de langue visible dans paramètres
- [ ] Changement FR → EN fonctionne
- [ ] Changement EN → FR fonctionne
- [ ] Message de confirmation affiché
- [ ] Interface change immédiatement

### Persistance
- [ ] Langue sauvegardée après changement
- [ ] Langue restaurée au redémarrage
- [ ] Pas de perte de préférence

### Interface utilisateur
- [ ] Sélecteur bien stylé
- [ ] Drapeaux visibles
- [ ] Langue active indiquée
- [ ] Animations fluides
- [ ] Responsive

### Navigation
- [ ] Changement de langue fonctionne sur toutes les pages
- [ ] Pas de crash lors du changement
- [ ] Retour arrière fonctionne

## 🎯 Résultats attendus

### ✅ Test réussi si:
1. Changement de langue fonctionne immédiatement
2. Interface se met à jour en temps réel
3. Langue est sauvegardée et restaurée
4. Pas d'erreur dans les logs
5. Sélecteur fonctionne correctement

### ❌ Test échoué si:
1. Langue ne change pas
2. Application crash
3. Langue non persistée
4. Erreurs dans les logs
5. Interface incohérente

## 📝 Rapport de test

Après les tests, noter:

```
Date: ___________
Testeur: ___________

✅ Changement FR → EN: [ ] OK [ ] KO
✅ Changement EN → FR: [ ] OK [ ] KO
✅ Persistance: [ ] OK [ ] KO
✅ Interface: [ ] OK [ ] KO
✅ Navigation: [ ] OK [ ] KO

Commentaires:
_________________________________
_________________________________
_________________________________
```

## 🚀 Prochains tests

Après validation de base:

1. **Test des pages migrées**
   - Vérifier chaque page traduite
   - Tester tous les boutons et labels

2. **Test des messages**
   - Erreurs
   - Confirmations
   - Validations

3. **Test de performance**
   - Temps de changement de langue
   - Impact sur la fluidité

## 💡 Conseils

1. **Tester régulièrement** pendant le développement
2. **Vérifier les deux langues** pour chaque nouvelle page
3. **Documenter** les problèmes rencontrés
4. **Prendre des captures d'écran** pour référence

---

**Version:** 1.0.0  
**Date:** 2026-03-01  
**Statut:** Prêt pour test
