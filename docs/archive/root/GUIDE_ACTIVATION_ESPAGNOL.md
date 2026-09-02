# Guide d'activation de l'espagnol - LOGESCO v2

## 🚀 Démarrage rapide

### Étape 1 : Redémarrer le backend (OBLIGATOIRE)

Le backend doit être redémarré pour accepter la langue espagnole.

**Option A - Script automatique :**
```bash
restart-backend-with-spanish.bat
```

**Option B - Manuel :**
1. Arrêter le backend actuel (Ctrl+C ou fermer la fenêtre)
2. Ouvrir un terminal dans le dossier `backend`
3. Exécuter : `node src/server.js`

### Étape 2 : Vérifier que le backend accepte 'es'

Le backend doit afficher au démarrage :
```
✓ Serveur démarré sur le port 3000
✓ Base de données connectée
```

### Étape 3 : Configurer la langue dans l'application

#### Pour l'interface utilisateur :
1. Ouvrir l'application Flutter
2. Aller dans **Paramètres** → **Langue de l'application**
3. Sélectionner **Español 🇪🇸**
4. L'interface se met à jour immédiatement

#### Pour les factures :
1. Aller dans **Administration** → **Paramètres de l'entreprise**
2. Trouver **Langue des factures**
3. Sélectionner **Español 🇪🇸**
4. Cliquer sur **Enregistrer**

## ✅ Vérification

### Test 1 : Interface en espagnol
- Les menus doivent être en espagnol
- Les boutons affichent du texte espagnol
- Les messages sont en espagnol

### Test 2 : Sauvegarde des paramètres
Si vous obtenez l'erreur :
```
"langueFacture" must be one of [fr, en]
```
→ **Le backend n'a pas été redémarré**. Retournez à l'Étape 1.

### Test 3 : Génération de facture
1. Créer une vente
2. Imprimer la facture
3. Vérifier que les textes sont en espagnol :
   - FACTURA (au lieu de FACTURE)
   - Cliente (au lieu de Client)
   - Subtotal, Descuento, TOTAL

## 🔧 Dépannage

### Problème : Erreur de validation "must be one of [fr, en]"

**Cause :** Le backend n'a pas été redémarré après la modification.

**Solution :**
1. Arrêter complètement le backend
2. Vérifier qu'aucun processus node.exe ne tourne (Gestionnaire des tâches)
3. Redémarrer le backend
4. Réessayer de sauvegarder

### Problème : L'interface ne change pas de langue

**Cause :** Le cache de l'application.

**Solution :**
1. Fermer complètement l'application Flutter
2. Redémarrer l'application
3. Sélectionner à nouveau la langue

### Problème : Les factures sont toujours en français

**Cause :** La langue des factures n'a pas été changée dans les paramètres.

**Solution :**
1. Aller dans **Paramètres de l'entreprise**
2. Changer **Langue des factures** à **Español**
3. Sauvegarder
4. Générer une nouvelle facture

### Problème : Certains textes ne sont pas traduits

**Cause :** Clé de traduction manquante (rare).

**Solution :**
1. Noter le texte non traduit
2. Vérifier dans `es_translations.dart` si la clé existe
3. Si manquante, l'ajouter

## 📋 Checklist de vérification

Avant de considérer l'intégration comme terminée :

- [ ] Backend redémarré avec succès
- [ ] Langue de l'interface changeable à Español
- [ ] Langue des factures changeable à Español
- [ ] Sauvegarde des paramètres sans erreur
- [ ] Facture générée en espagnol
- [ ] Reçu thermique en espagnol (si applicable)
- [ ] Messages de confirmation en espagnol
- [ ] Navigation complète en espagnol

## 🎯 Langues supportées

| Langue | Code | Locale | Drapeau | Statut |
|--------|------|--------|---------|--------|
| Français | fr | fr_FR | 🇫🇷 | ✅ Actif |
| English | en | en_US | 🇬🇧 | ✅ Actif |
| Español | es | es_ES | 🇪🇸 | ✅ Actif |

## 📞 Support

Si vous rencontrez des problèmes persistants :

1. Vérifier les logs du backend
2. Vérifier les logs Flutter (console)
3. Consulter `INTEGRATION_ESPAGNOL_COMPLETE.md` pour plus de détails
4. Vérifier que tous les fichiers ont été modifiés correctement

## 🔄 Commandes utiles

### Redémarrer le backend
```bash
cd backend
node src/server.js
```

### Vérifier les processus Node
```bash
tasklist | findstr node.exe
```

### Arrêter tous les processus Node
```bash
taskkill /F /IM node.exe
```

### Lancer l'application Flutter
```bash
cd logesco_v2
flutter run
```

---

**Date** : 8 mars 2026  
**Version** : LOGESCO v2  
**Statut** : ✅ Prêt pour utilisation
