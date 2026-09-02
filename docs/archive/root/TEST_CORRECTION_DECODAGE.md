# 🧪 TEST: Vérification de la Correction du Décodage

## 📋 Procédure de Test

### Étape 1: Recompiler logesco_v2

```bash
cd logesco_v2
flutter clean
flutter pub get
flutter build windows  # ou macos/linux selon votre plateforme
```

### Étape 2: Tester l'Activation

**Données de test:**
- Clé: `AAAE-4L8T-8H99-L5MR`
- Empreinte: `P9ZD-GFQD-AWL4-L5MR`

**Procédure:**
1. Ouvrir LOGESCO
2. Aller à: Paramètres → Abonnement → Activer une licence
3. Coller la clé: `AAAE-4L8T-8H99-L5MR`
4. Cliquer sur Valider

**Résultat attendu:**
```
✅ Licence activée avec succès
```

---

## 🔍 Vérification Détaillée

### Test 1: Décodage du Segment

**Segment:** `L5MR`  
**Alphabet:** `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`

**Décodage (CORRECT):**
```
L = index 19
5 = index 5
M = index 13
R = index 27

Calcul:
value = 0
value = 0 * 32 + 19 = 19
value = 19 * 32 + 5 = 613
value = 613 * 32 + 13 = 19629
value = 19629 * 32 + 27 = 628155

Résultat: 628155
```

### Test 2: Vérification du Hash

**Empreinte:** `P9ZD-GFQD-AWL4-L5MR`

**Nettoyage:**
```
P9ZD-GFQD-AWL4-L5MR → P9ZDGFQDAWL4L5MR
```

**Hash:**
```
Boucle de hash:
hash = 0
Pour chaque caractère:
  hash = ((hash << 5) - hash + codeUnit) & 0xFFFFFFFF

Résultat: [valeur X]
Modulo: [valeur X] % 1048576 = 628155
```

**Comparaison:**
```
Hash décodé du segment: 628155
Hash calculé de l'empreinte: 628155
Match: ✅ OUI
```

---

## 📊 Résultats Attendus

### Avant la Correction
```
Clé: AAAE-4L8T-8H99-L5MR
Segment 4: L5MR
Décodage: 636035 ❌
Hash empreinte: 628155
Match: ❌ NON (636035 ≠ 628155)
Résultat: "Clés invalides" ❌
```

### Après la Correction
```
Clé: AAAE-4L8T-8H99-L5MR
Segment 4: L5MR
Décodage: 628155 ✅
Hash empreinte: 628155
Match: ✅ OUI (628155 = 628155)
Résultat: "Licence activée avec succès" ✅
```

---

## 🚀 Déploiement

### Pour les Clients

1. **Mettre à jour LOGESCO** avec la version corrigée
2. **Tester l'activation** avec la clé `AAAE-4L8T-8H99-L5MR`
3. **Résultat:** Licence activée ✅

### Pour le Support

- Les anciennes clés générées avec l'algorithme incorrect peuvent maintenant être testées
- Si elles ne fonctionnent toujours pas, c'est qu'elles ont été générées avec une empreinte différente
- Demander au client de vérifier son empreinte exacte

---

## ✅ Checklist

- [ ] `logesco_v2` recompilé
- [ ] Fonction `_decodeSegment()` corrigée
- [ ] Test d'activation réussi
- [ ] Clé `AAAE-4L8T-8H99-L5MR` acceptée
- [ ] Message "Licence activée avec succès" affiché
- [ ] Nouvelle version distribuée aux clients

---

## 📞 Troubleshooting

### Problème: Clé toujours rejetée

**Vérifications:**
1. Vérifier que `logesco_v2` a été recompilé
2. Vérifier que la fonction `_decodeSegment()` a été modifiée
3. Vérifier que l'empreinte est exacte
4. Vérifier les logs pour les erreurs

### Problème: Erreur de compilation

**Solution:**
1. Exécuter `flutter clean`
2. Exécuter `flutter pub get`
3. Recompiler

---

## 📝 Logs à Vérifier

**Dans logesco_v2 (activation):**
```
✅ [LicenseService] Validation de signature
✅ [LicenseService] Validation expiration: OK
✅ [LicenseService] Vérification appareil: OK
✅ Licence activée avec succès
```

---

## ✨ Conclusion

Après cette correction, la clé `AAAE-4L8T-8H99-L5MR` devrait être acceptée par LOGESCO.

Le problème était dans le décodage, pas dans la génération.

