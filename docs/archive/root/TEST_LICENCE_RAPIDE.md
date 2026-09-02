# 🧪 Test Rapide de Validation de Licence

## ✅ Vérification que la Correction Fonctionne

Suivez ces étapes pour tester que votre système de licence fonctionne maintenant correctement.

## 📝 Étapes de Test

### 1. Obtenir l'Empreinte de Votre Appareil

1. **Ouvrez** l'application `logesco_v2`
2. **Naviguez** vers : Paramètres → Abonnement → "Obtenir l'empreinte de l'appareil"
   - OU si l'app est bloquée : Cliquez sur "Obtenir l'empreinte" sur l'écran de blocage
3. **Copiez** l'empreinte affichée (64 caractères hexadécimaux)

**Exemple d'empreinte** :
```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### 2. Générer une Licence dans logesco_license_admin

1. **Ouvrez** l'application `logesco_license_admin`
2. **Créez un nouveau client** (ou sélectionnez un client existant)
3. **Cliquez** sur "Générer une licence"
4. **Remplissez** les informations :
   - **Client ID** : Votre identifiant (ex: CLIENT001)
   - **Type d'abonnement** : Choisissez (trial, monthly, annual, ou lifetime)
   - **Empreinte de l'appareil** : Collez l'empreinte copiée à l'étape 1
5. **Cliquez** sur "Générer"
6. **Copiez** la clé de licence générée

**Exemple de clé** :
```
LOGESCO_V1_eyJ1c2VySWQiOiJDTElFTlQwMDEiLCJ0eXBlIjoiYW5udWFsIiwiaXNzdWVkIjoiMjAyNC0xMS0wN1QxMDozMDowMC4wMDBaIiwiZXhwaXJlcyI6IjIwMjUtMTEtMDdUMTA6MzA6MDAuMDAwWiIsImRldmljZSI6ImExYjJjM2Q0ZTVmNjc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MGFiY2RlZjEyMzQ1Njc4OTBhYmNkZWYxMjM0NTYiLCJmZWF0dXJlcyI6WyJmdWxsX2ludmVudG9yeSIsInNhbGVzIiwicmVwb3J0cyIsImFkdmFuY2VkX2FuYWx5dGljcyIsImNhc2hfcmVnaXN0ZXIiLCJleHBlbnNlX21hbmFnZW1lbnQiLCJ1c2VyX21hbmFnZW1lbnQiLCJyb2xlX21hbmFnZW1lbnQiLCJiYWNrdXBfcmVzdG9yZSIsIm11bHRpX2RldmljZV9zeW5jIl0sInNpZ25hdHVyZSI6ImRHVnpkSE5wWjI1aGRIVnlaUT09In0=
```

### 3. Activer la Licence dans logesco_v2

1. **Retournez** dans l'application `logesco_v2`
2. **Naviguez** vers : Paramètres → Abonnement → "Activer une licence"
   - OU si l'app est bloquée : Collez directement dans le champ sur l'écran de blocage
3. **Collez** la clé de licence copiée à l'étape 2
4. **Cliquez** sur "Activer"

### 4. Résultat Attendu

✅ **SUCCÈS** : Vous devriez voir :
- Message : "Licence activée avec succès"
- Accès complet à toutes les fonctionnalités de l'application
- Informations de licence affichées (type, date d'expiration, etc.)

❌ **ÉCHEC** : Si vous voyez encore "Clé d'activation invalide" :
- Vérifiez que vous avez bien copié l'empreinte complète (64 caractères)
- Vérifiez que la clé de licence est complète (commence par LOGESCO_V1_)
- Consultez les logs de l'application pour plus de détails

## 🔍 Vérification des Logs

### Dans logesco_v2

Recherchez dans la console les messages suivants :

✅ **Succès** :
```
✅ [CryptoService] Signature de développement valide
✅ [LicenseService] Licence validée avec succès
```

❌ **Échec** :
```
❌ [CryptoService] Erreur vérification signature: ...
❌ [LicenseService] Erreur validation de licence (tentative X): ...
```

### Dans logesco_license_admin

Vérifiez que la licence a été générée :
```
✅ Licence générée pour CLIENT001
✅ Type: annual
✅ Expire le: 2025-11-07
```

## 🐛 Dépannage

### Problème : "Clé d'activation invalide"

**Causes possibles** :

1. **Empreinte incorrecte**
   - ✅ Solution : Vérifiez que vous avez copié l'empreinte depuis le MÊME appareil
   - ✅ Solution : L'empreinte doit faire exactement 64 caractères hexadécimaux

2. **Clé de licence incomplète**
   - ✅ Solution : Vérifiez que la clé commence par `LOGESCO_V1_`
   - ✅ Solution : Vérifiez qu'il n'y a pas d'espaces ou de retours à la ligne

3. **Format de clé invalide**
   - ✅ Solution : Régénérez la licence dans logesco_license_admin
   - ✅ Solution : Vérifiez que logesco_license_admin est à jour

### Problème : "Cette licence est liée à un autre appareil"

**Cause** : L'empreinte dans la licence ne correspond pas à l'appareil actuel

**Solution** :
1. Obtenez la nouvelle empreinte de l'appareil actuel
2. Générez une nouvelle licence avec cette empreinte
3. N'essayez pas de réutiliser une licence d'un autre appareil

### Problème : "Licence expirée"

**Cause** : La date d'expiration est dépassée

**Solution** :
1. Vérifiez la date d'expiration dans logesco_license_admin
2. Générez une nouvelle licence avec une date d'expiration future
3. Pour les tests, utilisez le type "lifetime" qui expire en 2099

### Problème : "Signature cryptographique invalide"

**Cause** : Problème avec la génération ou la vérification de la signature

**Solution** :
1. Vérifiez que les modifications ont été appliquées dans `crypto_service.dart`
2. Redémarrez complètement l'application logesco_v2
3. Régénérez une nouvelle licence
4. Si le problème persiste, consultez `CORRECTION_LICENCE_PROBLEME.md`

## 📊 Scénarios de Test Complets

### Test 1 : Licence Trial (7 jours)

```
Type: trial
Durée: 7 jours
Fonctionnalités: Toutes
```

**Résultat attendu** : Accès complet pendant 7 jours

### Test 2 : Licence Monthly (30 jours)

```
Type: monthly
Durée: 30 jours
Fonctionnalités: Toutes
```

**Résultat attendu** : Accès complet pendant 30 jours

### Test 3 : Licence Annual (365 jours)

```
Type: annual
Durée: 365 jours
Fonctionnalités: Toutes
```

**Résultat attendu** : Accès complet pendant 1 an

### Test 4 : Licence Lifetime (Permanente)

```
Type: lifetime
Durée: Jusqu'au 31/12/2099
Fonctionnalités: Toutes
```

**Résultat attendu** : Accès complet permanent

## ✅ Checklist de Validation

Cochez chaque étape au fur et à mesure :

- [ ] Empreinte de l'appareil obtenue (64 caractères)
- [ ] Licence générée dans logesco_license_admin
- [ ] Clé de licence copiée (commence par LOGESCO_V1_)
- [ ] Clé collée dans logesco_v2
- [ ] Message "Licence activée avec succès" affiché
- [ ] Accès aux fonctionnalités de l'application
- [ ] Informations de licence visibles dans les paramètres

## 🎯 Résultat Final

Si tous les tests passent :
- ✅ Votre système de licence fonctionne correctement
- ✅ Vous pouvez générer et activer des licences
- ✅ Le problème initial est résolu

Si des tests échouent :
- ❌ Consultez la section Dépannage ci-dessus
- ❌ Vérifiez les logs pour plus de détails
- ❌ Consultez `CORRECTION_LICENCE_PROBLEME.md` pour plus d'informations

## 📞 Prochaines Étapes

Une fois les tests réussis :

1. **Pour le développement** : Continuez à utiliser le système actuel
2. **Pour la production** : Suivez le guide dans `CORRECTION_LICENCE_PROBLEME.md` pour implémenter les vraies clés RSA
3. **Documentation** : Consultez `PROMPT_SYSTEME_LICENCE_ADMIN.md` pour les spécifications complètes

---

**Bonne chance avec vos tests !** 🚀
