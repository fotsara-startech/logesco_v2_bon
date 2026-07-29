# Plan d'Implémentation - Amélioration Affichage Factures

## Vue d'Ensemble

Ce plan d'implémentation suit la méthodologie Bug Condition pour corriger les erreurs de syntaxe et améliorer la hiérarchie visuelle des factures A4 et A5. L'approche est séquentielle en deux phases :
1. **Phase Exploration** : Démontrer les bugs AVANT correction (tests d'exploration et préservation)
2. **Phase Implémentation** : Appliquer les corrections et valider

---

## Tâches d'Implémentation

- [x] 1. Write bug condition exploration test (compilation et structure)
  - **Property 1: Bug Condition** - Erreurs de Compilation et Structure Malformée
  - **IMPORTANT**: Écrire ce test de propriété AVANT d'implémenter la correction
  - **CRITIQUE**: Ce test DOIT ÉCHOUER sur le code non corrigé - l'échec confirme que le bug existe
  - **NE PAS tenter de corriger le test ou le code lorsqu'il échoue**
  - **NOTE**: Ce test encode le comportement attendu - il validera la correction quand il passera après l'implémentation
  - **OBJECTIF**: Faire apparaître des contre-exemples démontrant l'existence du bug
  - **Approche PBT Scoped**: Pour les bugs déterministes, limiter la propriété aux cas d'échec concrets pour assurer la reproductibilité
  - Tester que le code actuel dans `receipt_template_base.dart` échoue à la compilation avec les erreurs suivantes :
    - Ligne 48 : Erreur "Expected to find ','" causée par `chilany.address.isNotEmpty)`
    - Variables `subtitleStyle` et `textAlign` non définies
    - Méthode `buildCompanyHeader()` non définie dans la classe de base mais appelée par A4/A5
  - Exécuter `flutter analyze` sur les fichiers modifiés
  - **RÉSULTAT ATTENDU**: Le test ÉCHOUE (c'est correct - cela prouve que le bug existe)
  - Documenter les contre-exemples trouvés pour comprendre la cause racine :
    - Messages d'erreur exacts de compilation
    - Numéros de ligne où les erreurs se produisent
    - Variables ou méthodes manquantes identifiées
  - Marquer la tâche comme complète lorsque le test est écrit, exécuté, et l'échec documenté
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Write bug condition exploration test (hiérarchie visuelle)
  - **Property 1: Bug Condition** - Défauts de Hiérarchie Visuelle
  - **IMPORTANT**: Écrire ce test de propriété AVANT d'implémenter la correction
  - **CRITIQUE**: Ce test DOIT ÉCHOUER sur le code non corrigé - l'échec confirme que le bug existe
  - **NE PAS tenter de corriger le test ou le code lorsqu'il échoue**
  - **NOTE**: Ce test encode le comportement attendu - il validera la correction quand il passera après l'implémentation
  - **OBJECTIF**: Faire apparaître des contre-exemples démontrant l'existence des défauts visuels
  - **Approche PBT Scoped**: Pour les défauts visuels déterministes, capturer des cas concrets (avec et sans logo, statuts différents)
  - Si la compilation permet de générer des factures partiellement, tester visuellement :
    - Absence de bandeau coloré (#1565C0) dans l'en-tête
    - Absence de système de repli pour afficher les initiales quand le logo est manquant
    - Absence de badge de statut de paiement (vert/orange)
    - Absence de cartes séparées pour Émetteur et Client
    - Absence de zébrage dans le tableau des articles
    - Absence de mise en valeur du bloc TOTAL (fond coloré, texte blanc, police plus grande)
  - Générer une facture test sans logo uploadé et observer le rendu
  - Générer une facture test avec 5 articles et observer l'absence de zébrage
  - **RÉSULTAT ATTENDU**: Le test ÉCHOUE (c'est correct - cela prouve que les défauts visuels existent)
  - Documenter les contre-exemples trouvés (captures d'écran ou descriptions détaillées) :
    - En-tête sans bandeau coloré
    - Espace vide ou icône générique au lieu des initiales
    - Titre "FACTURE" sans mise en valeur
    - Tableau sans zébrage
    - Bloc TOTAL sans emphase visuelle
  - Marquer la tâche comme complète lorsque le test est écrit, exécuté, et l'échec documenté
  - _Requirements: 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_

- [x] 3. Write preservation property tests (AVANT d'implémenter la correction)
  - **Property 2: Preservation** - Contenu Informationnel et Calculs Préservés
  - **IMPORTANT**: Suivre la méthodologie observation-first
  - Observer le comportement sur le code NON CORRIGÉ pour les entrées non-buggy :
    - Factures avec logo uploadé valide : observer l'affichage correct du logo
    - Informations entreprise complètes : observer l'affichage de nom, adresse, téléphone, email, NUI, RCCM
    - Informations de vente : observer l'affichage de numéro, date, client, méthode de paiement
    - Liste d'articles : observer l'affichage de nom, référence, quantité, prix unitaire, total pour chaque ligne
    - Calculs de totaux : observer sous-total, remise, TVA, total, payé, monnaie rendue, reste à payer
    - Facture A5 : observer l'adaptation de mise en page conservant la lisibilité
    - Réimpression : observer l'affichage de l'indicateur avec date et utilisateur
    - Facture proforma : observer l'affichage de "Facture Proforma"
    - Pied de page : observer l'affichage du message de remerciement et informations légales
    - Traductions : observer le fonctionnement des traductions FR/EN/ES
  - Écrire des tests de propriété capturant les patterns de comportement observés depuis Preservation Requirements :
    - Pour toutes les factures avec logo valide, le logo s'affiche correctement
    - Pour toutes les factures, les informations de l'entreprise sont complètes et exactes
    - Pour toutes les factures, les informations de vente sont précises
    - Pour toutes les factures, tous les articles sont listés avec leurs propriétés
    - Pour toutes les factures, tous les calculs de totaux sont exacts
    - Pour toutes les factures A5, la mise en page est adaptée et lisible
    - Pour toutes les réimpressions, l'indicateur est affiché
    - Pour toutes les factures proforma, le label correct est affiché
    - Pour toutes les factures, le pied de page est correct
    - Pour toutes les factures, les traductions fonctionnent selon la langue sélectionnée
  - Les tests de propriété génèrent de nombreux cas de test pour des garanties plus fortes
  - Exécuter les tests sur le code NON CORRIGÉ
  - **RÉSULTAT ATTENDU**: Les tests PASSENT (cela confirme le comportement de base à préserver)
  - Marquer la tâche comme complète lorsque les tests sont écrits, exécutés, et passent sur le code non corrigé
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

- [x] 4. Corriger les erreurs de syntaxe et implémenter les améliorations visuelles

  - [x] 4.1 Corriger la structure de buildHeader() dans receipt_template_base.dart
    - Supprimer le code orphelin `chilany.address.isNotEmpty)` et tout le texte orphelin suivant à la ligne 48
    - Reconstruire complètement la propriété `child` du Container principal
    - Implémenter le bandeau coloré : envelopper le contenu dans un Container avec `decoration: BoxDecoration(color: _headerBg)` (#1565C0)
    - Appliquer padding vertical 12, horizontal 16 au bandeau
    - Implémenter la logique de repli logo/initiales :
      - SI logo uploadé ET URL valide : afficher `Image.network(logoUrl)` dans Container 56x56, borderRadius 8, fond blanc
      - SINON : extraire les initiales du nom de l'entreprise (premiers caractères des mots séparés par espaces)
      - Afficher les initiales dans Container blanc 56x56, borderRadius 8, texte bleu (#1565C0), fontSize + 4, bold, centré
    - Utiliser `_headerText` (blanc) pour tous les textes de l'en-tête
    - _Bug_Condition: isBugCondition(input) où input.hasSyntaxError() OR input.hasVisualHierarchyDefect()_
    - _Expected_Behavior: buildHeader() compile sans erreur, affiche bandeau coloré avec logo ou initiales_
    - _Preservation: Les informations de l'entreprise affichées restent identiques (nom, adresse, contacts)_
    - _Requirements: 1.1, 1.3, 2.4, 2.5_

  - [x] 4.2 Créer la méthode buildCompanyHeader() dans receipt_template_base.dart
    - Définir nouvelle méthode : `Widget buildCompanyHeader(BuildContext context, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start, TextAlign textAlign = TextAlign.left})`
    - Définir `subtitleStyle` localement dans la méthode : `TextStyle(fontSize: template.fontSize - 1, color: _headerText, fontWeight: FontWeight.w400)`
    - Retourner un widget Column avec `crossAxisAlignment` paramétrable contenant :
      - Nom de l'entreprise (fontSize + 2, fontWeight.bold, color _headerText)
      - Adresse (subtitleStyle, textAlign paramétrable) SI non vide
      - Localisation (subtitleStyle, textAlign paramétrable) SI non vide
      - Téléphone avec icône (subtitleStyle) SI non vide
      - Email avec icône (subtitleStyle) SI non vide
      - NUI et RCCM (subtitleStyle) SI non vides
    - Utiliser SizedBox(height: 4) entre chaque ligne pour l'espacement
    - _Bug_Condition: isBugCondition(input) où input.hasUndefinedVariable("subtitleStyle") OR input.hasMissingMethod("buildCompanyHeader")_
    - _Expected_Behavior: buildCompanyHeader() définie et accessible, subtitleStyle et textAlign définis localement_
    - _Preservation: Les informations de l'entreprise affichées restent complètes et dans le même ordre_
    - _Requirements: 1.2, 1.3, 2.4_

  - [x] 4.3 Créer la méthode buildTitleAndStatus() dans receipt_template_base.dart
    - Définir nouvelle méthode : `Widget buildTitleAndStatus(BuildContext context)`
    - Retourner un widget Row avec `MainAxisAlignment.spaceBetween` contenant :
      - Titre "FACTURE" ou "Facture Proforma" (fontSize + 4, fontWeight.bold, color Colors.black87)
      - Badge de statut : Container avec borderRadius 12, padding EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        - Fond vert (#4CAF50) si statut "paid" (payé)
        - Fond orange (#FF9800) si statut "pending" ou autre (en attente)
        - Texte badge : traduit selon locale ("Payé"/"Paid"/"Pagado" ou "En attente"/"Pending"/"Pendiente")
        - Style texte : fontSize - 1, fontWeight.w600, color Colors.white
    - Ajouter padding horizontal 16 et vertical 12 au Row
    - _Bug_Condition: isBugCondition(input) où input.titleNotHighlighted OR input.paymentStatusNotVisible_
    - _Expected_Behavior: Titre mis en valeur, badge de statut coloré et visible_
    - _Preservation: Le type de facture (normale/proforma) reste correctement affiché_
    - _Requirements: 1.6, 2.6_

  - [x] 4.4 Créer la méthode buildClientVendorCards() dans receipt_template_base.dart
    - Définir nouvelle méthode : `Widget buildClientVendorCards(BuildContext context)`
    - Retourner un widget Row contenant deux cartes Expanded :
      - **Carte Émetteur** (gauche) :
        - Container avec `decoration: BoxDecoration(color: Color(0xFFFAFAFA), border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8))`
        - Padding 12
        - Column contenant titre "Émetteur" (fontSize + 1, fontWeight.w600, color Colors.black87) suivi de buildCompanyHeader() avec paramètres adaptés
      - **SizedBox(width: 16)** pour espacement
      - **Carte Client** (droite) :
        - Container avec même decoration que carte Émetteur
        - Padding 12
        - Column contenant titre "Client" (fontSize + 1, fontWeight.w600, color Colors.black87) suivi des informations client (nom, adresse, NUI, RCCM) SI client renseigné
        - SI pas de client : Text("Client non spécifié", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
    - Ajouter padding horizontal 16 et vertical 8 au Row principal
    - _Bug_Condition: isBugCondition(input) où input.clientVendorNotDifferentiated_
    - _Expected_Behavior: Deux cartes visuellement séparées pour Émetteur et Client_
    - _Preservation: Les informations de l'entreprise et du client restent complètes et identiques_
    - _Requirements: 1.7, 2.7_

  - [x] 4.5 Modifier buildItemsList() pour ajouter le zébrage dans receipt_template_base.dart
    - Localiser la boucle `.map((item)` qui génère les TableRow du tableau d'articles
    - Remplacer par `.asMap().entries.map((entry)` pour obtenir l'index de chaque ligne
    - Accéder à l'article via `entry.value` au lieu de `item` dans la boucle
    - Ajouter la propriété `decoration` au TableRow :
      ```dart
      decoration: BoxDecoration(
        color: entry.key.isEven ? _rowEven : _rowOdd,
      ),
      ```
    - Utiliser `_rowEven` (Colors.white) pour les lignes paires et `_rowOdd` (Color(0xFFF5F7FA)) pour les lignes impaires
    - Conserver tout le reste du code existant (colonnes, textes, calculs) sans modification
    - _Bug_Condition: isBugCondition(input) où input.tableHasNoZebra_
    - _Expected_Behavior: Alternance de couleurs blanc / #F5F7FA dans le tableau_
    - _Preservation: Les articles, quantités, prix unitaires et totaux restent affichés identiquement_
    - _Requirements: 1.8, 2.8_

  - [x] 4.6 Modifier buildTotals() pour mettre en valeur le bloc TOTAL dans receipt_template_base.dart
    - Localiser la section qui affiche les totaux (sous-total, remise, TVA, total)
    - Isoler la ligne affichant le TOTAL dans un Container séparé
    - Appliquer au Container du TOTAL :
      - `decoration: BoxDecoration(color: _totalBg, borderRadius: BorderRadius.circular(8))` où _totalBg est Color(0xFF1565C0)
      - `padding: EdgeInsets.all(12)`
    - Appliquer au texte du label "TOTAL" et de la valeur :
      - `TextStyle(fontSize: template.fontSize + 3, fontWeight: FontWeight.bold, color: Colors.white)`
    - Ajouter `SizedBox(height: 8)` avant et après le Container du TOTAL pour l'espacement
    - Conserver le style existant pour sous-total, remise, TVA (pas de modification)
    - _Bug_Condition: isBugCondition(input) où input.totalBlockNotEmphasized_
    - _Expected_Behavior: Bloc TOTAL avec fond bleu (#1565C0), texte blanc, police plus grande_
    - _Preservation: Les valeurs de sous-total, remise, TVA, total restent calculées et affichées identiquement_
    - _Requirements: 1.9, 2.9_

  - [x] 4.7 Mettre à jour receipt_template_a4.dart pour utiliser les nouvelles méthodes
    - Dans la méthode `_buildHeader()`, remplacer l'appel à `buildCompanyHeader()` local par un appel à la méthode héritée de `ReceiptTemplateBase`
    - Supprimer toute logique de logo locale et déléguer l'affichage logo/initiales à `buildHeader()` de la classe de base
    - Passer les paramètres `logoPath` et `serverUrl` lors de l'appel si nécessaire
    - Ajouter un appel à `buildTitleAndStatus()` après l'en-tête dans la méthode `build()`
    - Ajouter un appel à `buildClientVendorCards()` après le titre dans la méthode `build()`
    - Conserver tous les autres appels existants : `buildSaleInfo()`, `buildItemsList()`, `buildTotals()`, `buildFooter()`, `_buildLegalInfo()`
    - _Bug_Condition: isBugCondition(input) où input est template A4 avec méthode non définie ou hiérarchie visuelle manquante_
    - _Expected_Behavior: Template A4 utilise les méthodes de la classe de base, affiche la nouvelle hiérarchie visuelle_
    - _Preservation: Toutes les informations de vente, articles, totaux restent affichées identiquement_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9_

  - [x] 4.8 Mettre à jour receipt_template_a5.dart pour utiliser les nouvelles méthodes (format adapté)
    - Dans la méthode `_buildCompactHeader()`, remplacer l'appel à `buildCompanyHeader()` local par un appel à la méthode héritée de `ReceiptTemplateBase`
    - Adapter pour le format compact : logo 48x48 au lieu de 56x56, fontSize réduit
    - Ajouter un appel à `buildTitleAndStatus()` avec fontSize adapté (fontSize + 3 au lieu de +4) dans la méthode `build()`
    - Pour `buildClientVendorCards()`, utiliser une version empilée verticale (Column) au lieu de Row pour économiser l'espace horizontal :
      - Carte Émetteur en haut
      - SizedBox(height: 8) pour espacement
      - Carte Client en bas
    - Conserver tous les autres appels existants adaptés au format A5
    - _Bug_Condition: isBugCondition(input) où input est template A5 avec méthode non définie ou hiérarchie visuelle manquante_
    - _Expected_Behavior: Template A5 utilise les méthodes de la classe de base avec adaptation format compact_
    - _Preservation: Toutes les informations de vente, articles, totaux restent affichées identiquement en format A5_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3.6_

  - [x] 4.9 Vérifier que le test d'exploration de condition de bug (compilation) passe maintenant
    - **Property 1: Expected Behavior** - Code Compilable et Structure Complète
    - **IMPORTANT**: Ré-exécuter le MÊME test de la tâche 1 - NE PAS écrire un nouveau test
    - Le test de la tâche 1 encode le comportement attendu
    - Quand ce test passe, il confirme que le comportement attendu est satisfait
    - Exécuter `flutter analyze` sur les fichiers modifiés
    - **RÉSULTAT ATTENDU**: Le test PASSE (confirme que le bug de compilation est corrigé)
    - Vérifier :
      - Aucune erreur de syntaxe à la ligne 48 de `receipt_template_base.dart`
      - Variables `subtitleStyle` et `textAlign` définies correctement
      - Méthode `buildCompanyHeader()` définie dans la classe de base
      - Aucune autre erreur de compilation
    - _Requirements: Expected Behavior Properties 1 et 2 du design_

  - [x] 4.10 Vérifier que le test d'exploration de condition de bug (hiérarchie visuelle) passe maintenant
    - **Property 1: Expected Behavior** - Hiérarchie Visuelle Claire
    - **IMPORTANT**: Ré-exécuter le MÊME test de la tâche 2 - NE PAS écrire un nouveau test
    - Le test de la tâche 2 encode le comportement attendu
    - Quand ce test passe, il confirme que le comportement attendu est satisfait
    - Générer des factures tests couvrant les cas suivants :
      - Facture avec logo uploadé : vérifier affichage du logo dans encart blanc sur bandeau coloré
      - Facture sans logo : vérifier affichage des initiales dans cercle blanc sur bandeau coloré
      - Facture avec statut "Payé" : vérifier badge vert affiché
      - Facture avec statut "En attente" : vérifier badge orange affiché
      - Facture avec client : vérifier cartes séparées Émetteur et Client
      - Facture avec 5 articles : vérifier zébrage (lignes alternées blanc / #F5F7FA)
      - Observer bloc TOTAL avec fond bleu (#1565C0), texte blanc, police plus grande
    - **RÉSULTAT ATTENDU**: Le test PASSE (confirme que les défauts visuels sont corrigés)
    - _Requirements: Expected Behavior Properties 1 et 2 du design_

  - [x] 4.11 Vérifier que les tests de préservation passent toujours
    - **Property 2: Preservation** - Contenu Informationnel Préservé
    - **IMPORTANT**: Ré-exécuter les MÊMES tests de la tâche 3 - NE PAS écrire de nouveaux tests
    - Exécuter les tests de propriété de préservation de la tâche 3
    - **RÉSULTAT ATTENDU**: Les tests PASSENT (confirment qu'il n'y a pas de régressions)
    - Vérifier que pour toutes les factures :
      - Les informations de l'entreprise (nom, adresse, téléphone, email, NUI, RCCM) sont complètes et exactes
      - Les informations de vente (numéro, date, client, méthode de paiement) sont précises
      - Tous les articles sont listés avec nom, référence, quantité, prix unitaire, total
      - Tous les calculs de totaux (sous-total, remise, TVA, total, payé, monnaie, reste) sont exacts
      - L'adaptation A5 conserve la lisibilité
      - L'indicateur de réimpression s'affiche correctement
      - Le label "Facture Proforma" s'affiche pour les proformas
      - Le pied de page est correct
      - Les traductions fonctionnent selon la langue
    - Confirmer que tous les tests passent toujours après la correction (pas de régressions)
    - _Requirements: Preservation Requirements du design_

- [x] 5. Checkpoint - S'assurer que tous les tests passent
  - Exécuter `flutter analyze` sur l'ensemble du projet - aucune erreur
  - Exécuter tous les tests d'exploration (tâches 1 et 2) - doivent PASSER après correction
  - Exécuter tous les tests de préservation (tâche 3) - doivent toujours PASSER
  - Générer des factures tests couvrant tous les cas (avec/sans logo, statuts différents, A4/A5, réimpressions, proformas)
  - Vérifier visuellement chaque facture générée pour conformité au design
  - Si des questions se posent, demander à l'utilisateur

---

## Notes d'Implémentation

**Ordre d'Exécution Critique** :
1. D'abord, écrire et exécuter les tests d'exploration (tâches 1 et 2) sur le code NON CORRIGÉ - ils doivent ÉCHOUER
2. Ensuite, écrire et exécuter les tests de préservation (tâche 3) sur le code NON CORRIGÉ - ils doivent PASSER
3. Puis, implémenter les corrections (tâche 4)
4. Enfin, ré-exécuter tous les tests (tâches 4.9, 4.10, 4.11) - ils doivent tous PASSER

**Fichiers Affectés** :
- `logesco_v2/lib/features/printing/widgets/receipt_template_base.dart` (corrections principales)
- `logesco_v2/lib/features/printing/widgets/receipt_template_a4.dart` (intégration)
- `logesco_v2/lib/features/printing/widgets/receipt_template_a5.dart` (intégration adaptée)

**Références Design** :
- Bug Condition : Sections "Bug Condition" et "Examples" dans design.md
- Expected Behavior : Section "Expected Behavior" et "Correctness Properties" dans design.md
- Preservation Requirements : Section "Preservation Requirements" dans design.md

**Couleurs Utilisées** :
- Bandeau en-tête : #1565C0 (bleu foncé)
- Texte en-tête : blanc (Colors.white)
- Badge Payé : #4CAF50 (vert)
- Badge En attente : #FF9800 (orange)
- Lignes paires tableau : blanc (Colors.white)
- Lignes impaires tableau : #F5F7FA (gris très clair)
- Fond cartes : #FAFAFA (gris ultra clair)
- Bordure cartes : Colors.grey.shade300
- Fond bloc TOTAL : #1565C0 (bleu foncé)
- Texte bloc TOTAL : blanc (Colors.white)
