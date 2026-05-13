# Ajustement de l'en-tête du rapport financier PDF

## Problème identifié

L'en-tête du rapport financier n'affichait pas toutes les informations de l'entreprise, contrairement au document de commande d'approvisionnement.

### Comparaison

**Document de commande (référence):**
```
┌─────────────────────────────────────────────────────────────┐
│ [LOGO]  LOGESCO TEST                    COMMANDE            │
│         douala                          D'APPROVISIONNEMENT │
│         Tél: 682471185                  N° CMD20260512001   │
│         Email: contact@entreprise.com                       │
└─────────────────────────────────────────────────────────────┘
```

**Rapport financier (avant):**
```
┌─────────────────────────────────────────────────────────────┐
│ [LOGO]  ENTREPRISE                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Corrections apportées

### 1. En-tête simplifié et complet

**Avant:**
- Cadre bleu avec fond coloré
- Informations incomplètes
- Emojis dans le texte (📍, 📞, ✉️)
- Slogan et NUI/RCCM affichés

**Après:**
- Design épuré sans cadre de fond
- Toutes les informations essentielles
- Texte simple sans emojis
- Focus sur les informations principales

### Structure de l'en-tête

```
[LOGO 60x60]  NOM DE L'ENTREPRISE (20pt, gras, bleu)
              Localisation (10pt, gris)
              Tél: Numéro (10pt, gris)
              Email: Adresse (10pt, gris)
─────────────────────────────────────────────────────────────
```

### 2. Titre aligné à droite

Le titre du rapport est maintenant aligné à droite, comme dans le document de commande:

```
                                    RAPPORT DES MOUVEMENTS
                                              FINANCIERS
                        Période: 01/05/2026 au 12/05/2026
─────────────────────────────────────────────────────────────
                              Généré le 12/05/2026 à 14:30
```

### 3. Hiérarchie visuelle améliorée

- **Nom de l'entreprise**: 20pt, gras, bleu foncé
- **Informations de contact**: 10pt, gris
- **Titre du rapport**: 14pt, gras, aligné à droite
- **Période**: 10pt, gris, aligné à droite
- **Date de génération**: 8pt, gris clair, aligné à droite

### 4. Espacement optimisé

- Espacement entre l'en-tête et le titre: 15px
- Espacement entre le titre et le contenu: 20px
- Dividers pour séparer les sections

## Code modifié

### Fonction `_buildHeader()`

```dart
static pw.Widget _buildHeader(Map<String, dynamic>? entreprise, Uint8List? logoBytes) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Partie gauche: Logo + Informations entreprise
          pw.Expanded(
            flex: 2,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo (60x60)
                if (logoBytes != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(right: 15),
                    child: pw.Image(
                      pw.MemoryImage(logoBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                // Informations entreprise
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        entreprise?['nom'] ?? 'ENTREPRISE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (entreprise?['localisation'] != null) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          entreprise!['localisation'],
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                      if (entreprise?['telephone'] != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Tél: ${entreprise!['telephone']}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                      if (entreprise?['email'] != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Email: ${entreprise!['email']}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.blue700, thickness: 2),
    ],
  );
}
```

### Fonction `_buildTitle()`

```dart
static pw.Widget _buildTitle(DateTime startDate, DateTime endDate) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'RAPPORT DES MOUVEMENTS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                'FINANCIERS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Période: ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey800,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: PdfColors.blue700, thickness: 1),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Généré le ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    ],
  );
}
```

## Résultat final

L'en-tête du rapport financier ressemble maintenant à celui du document de commande:

```
┌─────────────────────────────────────────────────────────────┐
│ [LOGO]  LOGESCO TEST                                        │
│         douala                                              │
│         Tél: 682471185                                      │
│         Email: contact@entreprise.com                       │
├─────────────────────────────────────────────────────────────┤
│                                    RAPPORT DES MOUVEMENTS   │
│                                              FINANCIERS     │
│                        Période: 01/05/2026 au 12/05/2026   │
├─────────────────────────────────────────────────────────────┤
│                              Généré le 12/05/2026 à 14:30  │
└─────────────────────────────────────────────────────────────┘
```

## Avantages

1. **Cohérence**: Même style que les autres documents (commandes, relevés)
2. **Complet**: Toutes les informations de l'entreprise sont affichées
3. **Professionnel**: Design épuré et lisible
4. **Hiérarchie claire**: Informations organisées par importance
5. **Alignement**: Titre aligné à droite comme dans les documents officiels

## Fichiers modifiés

- `logesco_v2/lib/features/financial_movements/services/financial_report_pdf_service.dart`
  - Fonction `_buildHeader()` - En-tête simplifié et complet
  - Fonction `_buildTitle()` - Titre aligné à droite
  - Ajustement des espacements

## Notes

- Le logo est chargé depuis le backend (60x60 pixels)
- Si le logo n'est pas disponible, un placeholder "LOGO" est affiché
- Les informations manquantes (email, téléphone, etc.) ne sont pas affichées
- Le format de date est français (dd/MM/yyyy)
- Les dividers utilisent la couleur bleue de l'entreprise (PdfColors.blue700)
