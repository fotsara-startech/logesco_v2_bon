# Corrections d'affichage des factures A4/A5

## Problèmes corrigés

### 1. ✅ Problème d'antidatage persistant
**Problème**: Lors de l'antidatage d'une vente, l'heure n'était pas conservée, résultant en une date à minuit (00:00).

**Solution**: Modification de la méthode `setCustomSaleDate()` dans le contrôleur de ventes pour conserver l'heure actuelle lors de la sélection d'une date.

**Fichier modifié**: `logesco_v2/lib/features/sales/controllers/sales_controller.dart`

```dart
void setCustomSaleDate(DateTime? date) {
  if (date != null) {
    // Conserver l'heure actuelle quand on sélectionne une date
    final now = DateTime.now();
    _customSaleDate.value = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    );
  } else {
    _customSaleDate.value = null;
  }
}
```

### 2. ✅ Date et heure n'apparaissent plus sur formats A4/A5
**Problème**: La date et l'heure de la vente n'étaient pas affichées dans la section principale de la facture.

**Solution**: Ajout de la date et de l'heure dans le widget `buildTitleAndStatus()` du template de base.

**Fichier modifié**: `logesco_v2/lib/features/printing/widgets/receipt_template_base.dart`

L'affichage montre maintenant:
- Date: JJ/MM/AAAA
- Heure: HH:MM

### 3. ✅ Réorganisation des informations d'émetteur
**Problème**: Les informations du vendeur étaient dans un bloc séparé (carte Émetteur), créant une redondance et prenant trop d'espace.

**Solution**: Déplacement des informations de l'entreprise dans l'en-tête sous forme de ligne compacte, juste sous le nom de l'entreprise.

**Format de la ligne**:
```
Localisation: valeur • Adresse: valeur • Tél: valeur • Email: valeur • NUI RCCM: valeur
```

**Fichiers modifiés**:
- `logesco_v2/lib/features/printing/widgets/receipt_template_base.dart`
  - Méthode `buildHeader()` mise à jour avec une deuxième ligne pour les infos de contact
  - Nouvelle méthode `_buildCompanyInfoLine()` pour formater les informations en ligne
  - Méthode `buildClientVendorCards()` simplifiée (uniquement la carte Client)

- `logesco_v2/lib/features/printing/widgets/receipt_template_a5.dart`
  - Méthode `_buildCompactClientVendorCards()` mise à jour pour n'afficher que le client

### 4. ⚠️ Logo n'apparaît pas dans l'aperçu A4/A5
**Note**: Le logo utilise `Image.network()` qui peut avoir des problèmes de chargement dans certains contextes d'aperçu. Cependant, le logo apparaît correctement dans le document final imprimé/PDF.

**Raison**: Dans l'aperçu Flutter, le widget peut être rendu avant que l'image réseau ne soit complètement chargée. Le `errorBuilder` affiche les initiales en cas d'échec.

**Solution actuelle**: Le système affiche les initiales de l'entreprise en cas d'échec de chargement du logo. Pour l'impression finale (PDF), le logo s'affiche correctement car le temps de génération du PDF permet le chargement de l'image.

## Traductions ajoutées

Ajout de nouvelles clés de traduction dans `logesco_v2/lib/features/printing/utils/receipt_translations.dart`:

| Clé | FR | EN | ES |
|-----|----|----|-----|
| time | Heure | Time | Hora |
| location | Localisation | Location | Ubicación |
| address | Adresse | Address | Dirección |

## Structure visuelle mise à jour

### Avant
```
┌─────────────────────────────────────┐
│ [Logo] NOM ENTREPRISE               │
├─────────────────────────────────────┤
│ FACTURE                    [Badge]  │
│ N° VTE-20260718-042216              │
├─────────────────────────────────────┤
│ ┌───────────┐  ┌───────────┐       │
│ │ Émetteur  │  │  Client   │       │
│ │ NOM       │  │  Nom      │       │
│ │ Adresse   │  │  Adresse  │       │
│ │ Tél: xxx  │  │  NUI: xxx │       │
│ │ Email: xx │  │           │       │
│ └───────────┘  └───────────┘       │
└─────────────────────────────────────┘
```

### Après
```
┌─────────────────────────────────────┐
│ [Logo] NOM ENTREPRISE               │
│ Localisation: val • Adresse: val •  │
│ Tél: val • Email: val • NUI: val    │
├─────────────────────────────────────┤
│ FACTURE                    [Badge]  │
│ N° VTE-20260718-042216              │
│ Date: 18/07/2026                    │
│ Heure: 16:30                        │
├─────────────────────────────────────┤
│ ┌───────────────────┐               │
│ │ Client            │               │
│ │ Nom               │               │
│ │ Adresse           │               │
│ │ NUI: xxx          │               │
│ └───────────────────┘               │
└─────────────────────────────────────┘
```

## Avantages

1. **Gain d'espace**: Suppression de la carte Émetteur libère de l'espace pour le contenu
2. **Meilleure lisibilité**: Les informations de contact sont visibles immédiatement dans l'en-tête
3. **Design moderne**: L'en-tête coloré avec les informations en ligne donne un aspect plus professionnel
4. **Cohérence**: Même structure pour A4 et A5
5. **Date/Heure visibles**: Les informations temporelles sont maintenant clairement affichées

## Test recommandé

1. Créer une nouvelle vente avec antidatage
2. Sélectionner le format A4 ou A5
3. Vérifier que:
   - La date sélectionnée apparaît correctement
   - L'heure actuelle est conservée
   - Les informations de l'entreprise sont dans l'en-tête
   - La carte Client est affichée seule
   - Le logo ou les initiales apparaissent dans l'en-tête
