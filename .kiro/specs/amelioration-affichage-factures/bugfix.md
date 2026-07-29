# Bugfix Requirements Document

## Introduction

L'affichage actuel des factures (formats A4 et A5) présente plusieurs problèmes critiques qui nuisent à l'expérience utilisateur et à la clarté des informations. Ces problèmes incluent des erreurs de syntaxe bloquantes dans le code et des défauts de hiérarchie visuelle qui rendent les factures difficiles à lire et peu professionnelles.

**Impact**: Les erreurs de compilation empêchent l'application de fonctionner correctement, et les problèmes visuels réduisent la clarté et le professionnalisme des documents émis.

**Portée**: Templates de factures A4 et A5 (`receipt_template_base.dart`, `receipt_template_a4.dart`, `receipt_template_a5.dart`)

---

## Bug Analysis

### Current Behavior (Defect)

#### Bugs Bloquants (Erreurs de Compilation)

1.1 WHEN le système tente de compiler `receipt_template_base.dart` THEN une erreur de syntaxe "Expected to find ','" se produit à la ligne 48 avec `chilany.address.isNotEmpty)`

1.2 WHEN le système tente d'afficher un en-tête de facture THEN les variables `subtitleStyle` et `textAlign` ne sont pas définies, causant des erreurs de compilation

1.3 WHEN le système tente de construire l'en-tête dans `buildHeader()` THEN la structure du Container est incomplète (propriété `child` manquante ou mal formée)

#### Bugs Visuels (Hiérarchie et Lisibilité)

1.4 WHEN une facture est affichée THEN l'en-tête n'a pas de hiérarchie visuelle claire, le logo et les coordonnées de l'entreprise apparaissent sur un fond blanc sans distinction

1.5 WHEN une facture est affichée sans logo uploadé THEN un espace vide apparaît au lieu d'un repli visuel (initiales de l'entreprise)

1.6 WHEN une facture est affichée THEN le titre "FACTURE" et le numéro de vente sont présentés de manière plate sans mise en avant, et le statut de paiement n'est pas visible

1.7 WHEN une facture avec client et vendeur est affichée THEN les deux parties ne sont pas visuellement différenciées (affichage en une seule colonne)

1.8 WHEN le tableau des articles est affiché THEN il n'y a pas de zébrage (lignes alternées) et les montants ne sont pas alignés de manière cohérente à droite

1.9 WHEN les totaux sont affichés THEN le bloc TOTAL n'est pas suffisamment mis en valeur par rapport au sous-total, malgré son importance

---

### Expected Behavior (Correct)

#### Correction des Bugs Bloquants

2.1 WHEN le système compile `receipt_template_base.dart` THEN la compilation SHALL réussir sans erreur de syntaxe

2.2 WHEN le système affiche un en-tête de facture THEN toutes les variables nécessaires (`subtitleStyle`, `textAlign`) SHALL être correctement définies dans la portée appropriée

2.3 WHEN le système construit l'en-tête via `buildHeader()` THEN la structure du Container SHALL être complète avec une propriété `child` valide contenant le logo ou les initiales et les informations de l'entreprise

#### Amélioration de l'Affichage Visuel

2.4 WHEN une facture est affichée THEN l'en-tête SHALL avoir un bandeau coloré (couleur: #1565C0) avec le logo de l'entreprise dans un encart blanc (fond blanc quel que soit le fond du logo uploadé)

2.5 WHEN une facture est affichée sans logo uploadé THEN le système SHALL afficher automatiquement les initiales de l'entreprise dans un cercle sur fond blanc à la place du logo

2.6 WHEN une facture est affichée THEN le titre "FACTURE" et le numéro de vente SHALL être mis en avant immédiatement sous l'en-tête, avec un badge de statut de paiement coloré (vert pour "Payé", orange pour "En attente")

2.7 WHEN une facture avec client et vendeur est affichée THEN deux cartes distinctes visuellement séparées SHALL afficher "Émetteur" et "Client" pour une lecture rapide

2.8 WHEN le tableau des articles est affiché THEN le système SHALL appliquer un zébrage avec alternance de couleurs (lignes paires: blanc, lignes impaires: #F5F7FA) et tous les montants SHALL être alignés à droite de manière cohérente

2.9 WHEN les totaux sont affichés THEN le bloc "TOTAL" SHALL être isolé dans un encart avec fond coloré (#1565C0), texte blanc, et police plus grande que le sous-total pour le rendre nettement plus visible

---

### Unchanged Behavior (Regression Prevention)

3.1 WHEN une facture avec logo uploadé valide est générée THEN le système SHALL CONTINUE TO afficher le logo correctement à la résolution et taille appropriées

3.2 WHEN les informations de l'entreprise (nom, adresse, téléphone, email, NUI, RCCM) sont affichées THEN le système SHALL CONTINUE TO afficher toutes ces informations complètes et correctes

3.3 WHEN les informations de vente (numéro, date, client, méthode de paiement) sont affichées THEN le système SHALL CONTINUE TO afficher ces données avec précision

3.4 WHEN les articles de vente sont listés dans le tableau THEN le système SHALL CONTINUE TO afficher le nom du produit, la référence, la quantité, le prix unitaire et le total pour chaque ligne

3.5 WHEN les calculs de totaux (sous-total, remise, TVA, total TTC, payé, monnaie rendue, reste à payer) sont affichés THEN le système SHALL CONTINUE TO calculer et afficher ces montants avec exactitude

3.6 WHEN une facture est générée en format A5 THEN le système SHALL CONTINUE TO adapter la mise en page pour la taille réduite tout en conservant la lisibilité

3.7 WHEN une facture est réimprimée THEN le système SHALL CONTINUE TO afficher l'indicateur de réimpression avec la date et l'utilisateur

3.8 WHEN une facture proforma est générée THEN le système SHALL CONTINUE TO afficher "Facture Proforma" au lieu de "Facture"

3.9 WHEN le message de remerciement et les informations légales sont affichés en pied de page THEN le système SHALL CONTINUE TO les afficher correctement

3.10 WHEN une facture est générée dans une langue différente (FR, EN, ES) THEN le système SHALL CONTINUE TO traduire correctement tous les labels selon la langue sélectionnée

---

## Bug Condition Derivation

### Bug Condition Functions

```pascal
// Condition 1: Erreurs de syntaxe bloquantes
FUNCTION isSyntaxError(X)
  INPUT: X of type SourceCode
  OUTPUT: boolean
  
  RETURN X.hasCompilationError() OR 
         X.hasUndefinedVariable() OR 
         X.hasMalformedStructure()
END FUNCTION

// Condition 2: Problèmes visuels d'affichage
FUNCTION hasVisualHierarchyIssue(X)
  INPUT: X of type InvoiceDisplay
  OUTPUT: boolean
  
  RETURN X.headerHasNoColoredBanner OR
         X.logoMissingFallback OR
         X.titleNotHighlighted OR
         X.paymentStatusNotVisible OR
         X.clientVendorNotDifferentiated OR
         X.tableHasNoZebra OR
         X.totalBlockNotEmphasized
END FUNCTION
```

### Property Specifications

```pascal
// Property: Fix Checking - Compilation
FOR ALL X WHERE isSyntaxError(X) DO
  result ← compile'(X)
  ASSERT result.success = true AND 
         result.noErrors = true
END FOR

// Property: Fix Checking - Visual Display
FOR ALL X WHERE hasVisualHierarchyIssue(X) DO
  display ← renderInvoice'(X)
  ASSERT display.hasColoredHeader = true AND
         display.logoOrInitials = true AND
         display.titleHighlighted = true AND
         display.paymentStatusBadgeVisible = true AND
         display.clientVendorSeparated = true AND
         display.tableHasZebra = true AND
         display.totalBlockEmphasized = true
END FOR
```

### Preservation Goal

```pascal
// Property: Preservation Checking
FOR ALL X WHERE NOT (isSyntaxError(X) OR hasVisualHierarchyIssue(X)) DO
  ASSERT renderInvoice(X) = renderInvoice'(X)
END FOR
```

Ceci garantit que pour toutes les factures qui s'affichent actuellement correctement (sans erreurs de syntaxe et sans problèmes visuels), le rendu reste identique après la correction.

---

## Counterexamples

### Exemple 1: Erreur de Syntaxe Bloquante
**Input**: Compilation de `receipt_template_base.dart` ligne 48
**Current Behavior**: Erreur "Expected to find ','" - compilation échoue
**Expected Behavior**: Compilation réussit, pas d'erreur

### Exemple 2: Logo Manquant
**Input**: Facture pour entreprise sans logo uploadé
**Current Behavior**: Espace vide dans l'en-tête
**Expected Behavior**: Cercle blanc avec initiales de l'entreprise (ex: "LC" pour "Logesco")

### Exemple 3: Statut de Paiement Non Visible
**Input**: Facture avec statut "Payé"
**Current Behavior**: Statut non affiché visuellement
**Expected Behavior**: Badge vert avec texte "Payé" affiché en haut de la facture

### Exemple 4: Tableau Sans Zébrage
**Input**: Facture avec 5 articles
**Current Behavior**: Toutes les lignes sur fond blanc
**Expected Behavior**: Alternance blanc / #F5F7FA pour les lignes

### Exemple 5: Bloc Total Non Mis en Valeur
**Input**: Facture avec sous-total 10000 FCFA, total 11800 FCFA
**Current Behavior**: Sous-total et total affichés avec même style
**Expected Behavior**: Total dans encart bleu (#1565C0) avec texte blanc, plus grand que le sous-total
