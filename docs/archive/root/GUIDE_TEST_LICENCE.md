# 🧪 Guide de Test - Validation des Licences

## ✅ Corrections Appliquées

J'ai appliqué les corrections suivantes pour résoudre votre problème :

### 1. Logs Détaillés dans CryptoService ✅
- Affiche maintenant les détails de chaque vérification de signature
- Indique clairement si c'est le mode développement ou production
- Affiche les erreurs de manière explicite

### 2. Logs Détaillés dans LicenseService ✅
- Affiche les données à signer
- Indique quelle méthode de validation est utilisée
- Gère le cas où la clé publique est `null`

### 3. Mode Développement Amélioré ✅
- Ne dépend plus obligatoirement de `getActivePublicKey()`
- Essaie d'abord la vérification en mode développement
- Fallback vers le mode production si nécessaire

## 🧪 Comment Tester

### Étape 1 : Obtenir l'Empreinte de Votre Appareil

1. Ouvrez `logesco_v2`
2. Allez dans : **Paramètres → Abonnement → "Obtenir l'empreinte de l'appareil"**
3. Copiez l'empreinte (64 caractères hexadécimaux)

**Exemple** :
```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### Étape 2 : Générer une Licence

1. Ouvrez `logesco_license_admin`
2. Créez un client ou sélectionnez-en un
3. Cliquez sur "Générer une licence"
4. Remplissez :
   - **Client ID** : CLIENT001 (ou votre ID)
   - **Type** : annual (ou trial, monthly, lifetime)
   - **Empreinte** : Collez l'empreinte de l'étape 1
5. Cliquez sur "Générer"
6. Copiez la clé générée (commence par `LOGESCO_V1_`)

### Étape 3 : Activer la Licence

1. Retournez dans `logesco_v2`
2. Allez dans : **Paramètres → Abonnement → "Activer une licence"**
3. Collez la clé de licence
4. Cliquez sur "Activer"

### Étape 4 : Vérifier les Logs

**Ouvrez la console de debug** et cherchez ces messages :

#### ✅ Si ça fonctionne :
```
🔐 [CryptoService] Vérification de signature
   Données: CLIENT001-annual-2024-11-07T10:30:00.000Z...
   Longueur signature: 344 bytes
   🧪 Tentative de vérification en mode développement...
✅ [CryptoService] Signature de développement valide
✅ [LicenseService] Signature validée (mode développement)
✅ [LicenseService] Licence validée avec succès
```

#### ❌ Si ça ne fonctionne pas :
```
🔐 [CryptoService] Vérification de signature
   Données: CLIENT001-annual-2024-11-07T10:30:00.000Z...
   Longueur signature: 344 bytes
   🧪 Tentative de vérification en mode développement...
⚠️  [CryptoService] Signature de développement invalide
⚠️  [LicenseService] Aucune clé publique active trouvée
❌ [LicenseService] Signature invalide
```

## 🔍 Diagnostic des Problèmes

### Problème : "Signature de développement invalide"

**Cause** : La signature générée ne correspond pas aux données

**Solutions** :
1. Vérifiez que l'empreinte est exactement la même (64 caractères)
2. Vérifiez qu'il n'y a pas d'espaces dans l'empreinte
3. Régénérez la licence avec la bonne empreinte

### Problème : "Aucune clé publique active trouvée"

**Cause** : Le KeyManager n'est pas initialisé correctement

**Solutions** :
1. Redémarrez complètement l'application `logesco_v2`
2. Vérifiez que `KeyManager.initialize()` est appelé au démarrage
3. Le mode développement devrait quand même fonctionner

### Problème : "Format de clé invalide"

**Cause** : La clé de licence est mal formée

**Solutions** :
1. Vérifiez que la clé commence par `LOGESCO_V1_`
2. Vérifiez qu'il n'y a pas de retours à la ligne
3. Régénérez la licence

### Problème : "Cette licence est liée à un autre appareil"

**Cause** : L'empreinte ne correspond pas

**Solutions** :
1. Obtenez la nouvelle empreinte de l'appareil actuel
2. Générez une nouvelle licence avec cette empreinte
3. N'utilisez pas une licence d'un autre appareil

## 📊 Résultats Attendus

### ✅ Succès
- Message : "Licence activée avec succès"
- Accès à toutes les fonctionnalités
- Informations de licence visibles dans les paramètres
- Logs montrant "Signature de développement valide"

### ❌ Échec
- Message : "Clé d'activation invalide"
- Application bloquée
- Logs montrant des erreurs de signature

## 🎯 Prochaines Étapes

### Si ça fonctionne maintenant ✅
1. Testez avec différents types de licences (trial, monthly, annual, lifetime)
2. Vérifiez que les dates d'expiration sont correctes
3. Testez la révocation de licence
4. Pour la production : Consultez `PROMPT_SYSTEME_LICENCE_ADMIN.md` pour implémenter les vraies clés RSA

### Si ça ne fonctionne toujours pas ❌
1. Copiez les logs complets de la console
2. Vérifiez que les modifications ont bien été appliquées
3. Redémarrez complètement les deux applications
4. Essayez avec une nouvelle empreinte et une nouvelle licence

## 📝 Checklist de Validation

- [ ] Empreinte obtenue (64 caractères)
- [ ] Licence générée dans logesco_license_admin
- [ ] Clé commence par LOGESCO_V1_
- [ ] Clé collée dans logesco_v2
- [ ] Logs affichent "Vérification de signature"
- [ ] Logs affichent "Signature de développement valide"
- [ ] Message "Licence activée avec succès"
- [ ] Accès aux fonctionnalités

## 💡 Conseils

1. **Toujours copier l'empreinte depuis le MÊME appareil** où vous allez activer la licence
2. **Ne pas modifier la clé de licence** (pas d'espaces, pas de retours à la ligne)
3. **Vérifier les logs** pour comprendre où ça bloque
4. **Redémarrer les applications** après les modifications

## 🆘 Support

Si le problème persiste après avoir suivi ce guide :

1. Vérifiez que les fichiers suivants ont été modifiés :
   - `logesco_v2/lib/features/subscription/services/implementations/crypto_service.dart`
   - `logesco_v2/lib/features/subscription/services/implementations/license_service.dart`

2. Vérifiez que les logs détaillés s'affichent dans la console

3. Partagez les logs complets pour un diagnostic plus approfondi

---

**Bonne chance avec vos tests !** 🚀

