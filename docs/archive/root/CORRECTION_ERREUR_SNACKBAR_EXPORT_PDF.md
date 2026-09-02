# Correction de l'erreur Snackbar lors de l'export PDF

## Problème

Lors de l'export du rapport financier en PDF, une erreur se produisait:

```
Overlay.of.<anonymous closure> (package:flutter/src/widgets/overlay.dart:588:9)
SnackbarController._configureOverlay (package:get/get_navigation/src/snackbar/snackbar_controller.dart:91:29)
```

### Cause

L'erreur était causée par l'utilisation de `Get.snackbar()` dans un contexte où l'Overlay n'était pas disponible. Cela se produit généralement quand:

1. Le snackbar est appelé après une navigation
2. Le widget n'est plus monté dans l'arbre des widgets
3. Le contexte de l'Overlay a été perdu

## Solution appliquée

### 1. Remplacement de `Get.snackbar` par `ScaffoldMessenger`

**Avant:**
```dart
Get.snackbar(
  'financial_movements_reports_export_success'.tr,
  'financial_movements_reports_pdf_saved'.tr,
  backgroundColor: Colors.green.shade100,
  colorText: Colors.green.shade800,
  duration: const Duration(seconds: 3),
);
```

**Après:**
```dart
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${'financial_movements_reports_export_success'.tr}\n${'financial_movements_reports_pdf_saved'.tr}'),
      backgroundColor: Colors.green.shade600,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

### 2. Ajout d'un dialogue de chargement

Pour améliorer l'expérience utilisateur, un dialogue de chargement est maintenant affiché pendant la génération du PDF:

```dart
// Afficher un indicateur de chargement
Get.dialog(
  Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('financial_movements_reports_generating_pdf'.tr),
          ],
        ),
      ),
    ),
  ),
  barrierDismissible: false,
);

try {
  final filePath = await controller.exportToPdf();
  Get.back(); // Fermer le dialogue de chargement
  
  if (filePath != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export réussi\nRapport PDF sauvegardé'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
} catch (e) {
  Get.back(); // Fermer le dialogue de chargement
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

### 3. Vérification du contexte avec `context.mounted`

Avant d'afficher le snackbar, on vérifie que le widget est toujours monté:

```dart
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

Cela évite les erreurs si le widget a été supprimé de l'arbre pendant l'opération asynchrone.

### 4. Gestion des erreurs

Un bloc try-catch a été ajouté pour capturer les erreurs et afficher un message approprié:

```dart
try {
  final filePath = await controller.exportToPdf();
  // Succès
} catch (e) {
  // Erreur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur: $e'),
      backgroundColor: Colors.red.shade600,
    ),
  );
}
```

## Traductions ajoutées

Deux nouvelles traductions ont été ajoutées pour les messages de chargement:

```dart
'financial_movements_reports_generating_pdf': 'Génération du PDF en cours...',
'financial_movements_reports_generating_excel': 'Génération du fichier Excel en cours...',
```

## Fichiers modifiés

1. **logesco_v2/lib/features/financial_movements/views/movement_reports_page.dart**
   - Remplacement de `Get.snackbar` par `ScaffoldMessenger`
   - Ajout du dialogue de chargement
   - Ajout de la gestion des erreurs
   - Vérification du contexte avec `context.mounted`

2. **logesco_v2/lib/core/translations/fr_translations.dart**
   - Ajout des traductions pour les messages de chargement

## Avantages de la solution

1. **Plus d'erreur**: Le snackbar fonctionne maintenant correctement dans tous les contextes
2. **Meilleure UX**: L'utilisateur voit un indicateur de chargement pendant la génération
3. **Gestion des erreurs**: Les erreurs sont capturées et affichées à l'utilisateur
4. **Sécurité**: Vérification que le widget est monté avant d'afficher le snackbar
5. **Cohérence**: Utilisation de `ScaffoldMessenger` qui est la méthode recommandée par Flutter

## Comportement attendu

### Export PDF réussi

1. L'utilisateur clique sur "Exporter en PDF"
2. Un dialogue de chargement s'affiche: "Génération du PDF en cours..."
3. Le PDF est généré et s'ouvre automatiquement
4. Le dialogue se ferme
5. Un snackbar vert s'affiche: "Export réussi - Rapport PDF sauvegardé"

### Export PDF échoué

1. L'utilisateur clique sur "Exporter en PDF"
2. Un dialogue de chargement s'affiche
3. Une erreur se produit
4. Le dialogue se ferme
5. Un snackbar rouge s'affiche: "Erreur: [message d'erreur]"

## Notes techniques

- `ScaffoldMessenger` est préféré à `Get.snackbar` car il utilise le contexte du Scaffold
- `context.mounted` vérifie que le widget est toujours dans l'arbre avant d'afficher le snackbar
- `Get.dialog` est utilisé pour le dialogue de chargement car il gère bien les contextes asynchrones
- Le dialogue est non-dismissible (`barrierDismissible: false`) pour éviter que l'utilisateur le ferme pendant la génération

## Résultat

✅ L'erreur Overlay est corrigée
✅ L'export PDF fonctionne correctement
✅ L'utilisateur a un retour visuel pendant la génération
✅ Les erreurs sont gérées et affichées proprement
