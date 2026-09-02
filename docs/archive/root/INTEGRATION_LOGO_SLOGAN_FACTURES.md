# Intégration du Logo et Slogan dans les Factures

## Vue d'ensemble

Ce document explique comment intégrer les nouveaux champs `logo` et `slogan` dans les différents templates de facture.

## Emplacement des champs

### Logo
- **Format**: A4 et A5 uniquement
- **Position**: En-tête de la facture, à côté ou au-dessus du nom de l'entreprise
- **Taille recommandée**: 
  - A4: 100x100 pixels maximum
  - A5: 80x80 pixels maximum

### Slogan
- **Format**: Tous les formats (Thermal, A4, A5)
- **Position**: Pied de page de la facture
- **Style**: Texte italique, taille réduite

## Fichiers à modifier

### 1. Template Thermal (80mm)
**Fichier**: `logesco_v2/lib/features/printing/widgets/receipt_template_thermal.dart`

Le logo n'est pas affiché sur les reçus thermiques (espace limité), mais le slogan peut être ajouté en pied de page.

```dart
// Dans la méthode _buildFooter()
Widget _buildFooter() {
  return Column(
    children: [
      // ... contenu existant ...
      
      // Ajouter le slogan si disponible
      if (companyProfile?.slogan != null && companyProfile!.slogan!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          companyProfile!.slogan!,
          style: const TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
      
      // ... reste du pied de page ...
    ],
  );
}
```

### 2. Template A4
**Fichier**: `logesco_v2/lib/features/printing/widgets/receipt_template_a4.dart`

#### Ajouter le logo dans l'en-tête

```dart
// Dans la méthode _buildHeader()
Widget _buildHeader() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Logo (si disponible)
      if (companyProfile?.logo != null && companyProfile!.logo!.isNotEmpty) ...[
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(companyProfile!.logo!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Si l'image ne peut pas être chargée, afficher un placeholder
                return const Icon(Icons.business, size: 50, color: Colors.grey);
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      
      // Informations de l'entreprise
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyProfile?.name ?? 'Entreprise',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ... reste des informations ...
          ],
        ),
      ),
    ],
  );
}
```

#### Ajouter le slogan dans le pied de page

```dart
// Dans la méthode _buildFooter()
Widget _buildFooter() {
  return Column(
    children: [
      const Divider(),
      
      // Slogan (si disponible)
      if (companyProfile?.slogan != null && companyProfile!.slogan!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          companyProfile!.slogan!,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
      
      // ... reste du pied de page ...
    ],
  );
}
```

### 3. Template A5
**Fichier**: `logesco_v2/lib/features/printing/widgets/receipt_template_a5.dart`

Même approche que pour A4, mais avec des tailles réduites:

```dart
// Logo plus petit pour A5
Container(
  width: 80,
  height: 80,
  // ... même code que A4 ...
)

// Slogan avec police plus petite
Text(
  companyProfile!.slogan!,
  style: const TextStyle(
    fontSize: 10,
    fontStyle: FontStyle.italic,
    color: Colors.grey,
  ),
  textAlign: TextAlign.center,
)
```

### 4. Template PDF (pour exports)
**Fichier**: `logesco_v2/lib/features/printing/services/pdf_service.dart`

Pour les exports PDF, utiliser le package `pdf` pour intégrer le logo:

```dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Dans la méthode de génération du PDF
pw.Widget _buildPdfHeader(CompanyProfile? companyProfile) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Logo (si disponible)
      if (companyProfile?.logo != null && companyProfile!.logo!.isNotEmpty) ...[
        pw.Container(
          width: 100,
          height: 100,
          child: pw.Image(
            pw.MemoryImage(
              File(companyProfile.logo!).readAsBytesSync(),
            ),
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.SizedBox(width: 16),
      ],
      
      // Informations de l'entreprise
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              companyProfile?.name ?? 'Entreprise',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            // ... reste des informations ...
          ],
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfFooter(CompanyProfile? companyProfile) {
  return pw.Column(
    children: [
      pw.Divider(),
      
      // Slogan (si disponible)
      if (companyProfile?.slogan != null && companyProfile!.slogan!.isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          companyProfile!.slogan!,
          style: const pw.TextStyle(
            fontSize: 12,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
      ],
      
      // ... reste du pied de page ...
    ],
  );
}
```

## Gestion des erreurs

### Logo introuvable
```dart
Image.file(
  File(companyProfile!.logo!),
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    // Afficher un placeholder si l'image ne peut pas être chargée
    return const Icon(
      Icons.business,
      size: 50,
      color: Colors.grey,
    );
  },
)
```

### Slogan trop long
```dart
Text(
  companyProfile!.slogan!,
  style: const TextStyle(fontSize: 10),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
)
```

## Exemples de mise en page

### A4 avec logo et slogan
```
┌─────────────────────────────────────────┐
│  [LOGO]  NOM DE L'ENTREPRISE            │
│          Adresse                        │
│          Téléphone                      │
├─────────────────────────────────────────┤
│                                         │
│  FACTURE N° 001                         │
│                                         │
│  Articles...                            │
│                                         │
├─────────────────────────────────────────┤
│  "Votre satisfaction, notre priorité"  │
│  Merci de votre confiance              │
└─────────────────────────────────────────┘
```

### Thermal avec slogan
```
┌───────────────────────┐
│  NOM DE L'ENTREPRISE  │
│  Adresse              │
│  Téléphone            │
├───────────────────────┤
│  REÇU N° 001          │
│  Articles...          │
├───────────────────────┤
│  "Votre satisfaction, │
│   notre priorité"     │
│  Merci!               │
└───────────────────────┘
```

## Bonnes pratiques

1. **Toujours vérifier la disponibilité**: Utiliser des conditions `if` pour vérifier que le logo/slogan existe avant de l'afficher

2. **Gérer les erreurs**: Prévoir un fallback si le fichier logo n'est pas trouvé

3. **Optimiser la taille**: Redimensionner le logo si nécessaire pour ne pas ralentir l'impression

4. **Respecter les limites**: 
   - Logo: max 100x100 pour A4, 80x80 pour A5
   - Slogan: max 2 lignes, texte tronqué si trop long

5. **Tester sur différents formats**: Vérifier que le rendu est correct sur tous les formats de facture

## Dépendances nécessaires

Ajouter dans `pubspec.yaml` si pas déjà présent:

```yaml
dependencies:
  # Pour la gestion des images
  image: ^4.0.0
  
  # Pour les PDF
  pdf: ^3.10.0
  printing: ^5.11.0
```

## Checklist d'intégration

- [ ] Template Thermal: Slogan ajouté en pied de page
- [ ] Template A4: Logo ajouté en en-tête
- [ ] Template A4: Slogan ajouté en pied de page
- [ ] Template A5: Logo ajouté en en-tête
- [ ] Template A5: Slogan ajouté en pied de page
- [ ] PDF Service: Logo intégré dans les exports PDF
- [ ] PDF Service: Slogan intégré dans les exports PDF
- [ ] Gestion d'erreur: Placeholder si logo introuvable
- [ ] Gestion d'erreur: Troncature si slogan trop long
- [ ] Tests: Vérifier le rendu sur tous les formats
- [ ] Tests: Vérifier avec et sans logo/slogan

## Notes importantes

1. Le logo doit être stocké localement sur l'appareil ou le serveur
2. Le chemin du logo doit être accessible depuis l'application
3. Pour une utilisation en réseau, prévoir un système d'upload et de synchronisation
4. Considérer la compression des images pour optimiser les performances
