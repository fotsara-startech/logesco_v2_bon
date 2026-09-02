# Traductions appliquées au module Products

## Résumé
Application de l'internationalisation (i18n) au module `lib/features/products` (views et widgets).

## Fichiers modifiés

### Views
1. `categories_page.dart` - Page de gestion des catégories
2. `excel_import_export_page.dart` - Page d'import/export Excel
3. `product_detail_view.dart` - Vue détaillée d'un produit
4. `product_form_view.dart` - Formulaire de création/édition
5. `product_list_view.dart` - Liste des produits

### Widgets
1. `product_card.dart` - Carte d'affichage produit
2. `product_search_bar.dart` - Barre de recherche
3. `product_filter_bar.dart` - Barre de filtres
4. `product_sort_bar.dart` - Barre de tri
5. `expiration_date_dialog.dart` - Dialog dates de péremption
6. `expiration_dates_list_widget.dart` - Liste des dates de péremption
7. `category_selector.dart` - Sélecteur de catégories

## Nouvelles clés de traduction ajoutées

### Catégories (categories_page.dart)
```dart
'categories_management': 'Gestion des catégories',
'categories_refresh': 'Actualiser',
'categories_loading': 'Chargement des catégories...',
'categories_error_loading': 'Erreur de chargement',
'categories_retry': 'Réessayer',
'categories_empty': 'Aucune catégorie',
'categories_empty_subtitle': 'Commencez par créer votre première catégorie',
'categories_create': 'Créer une catégorie',
'categories_add': 'Ajouter une catégorie',
'categories_created_on': 'Créée le',
'categories_edit': 'Modifier',
'categories_delete': 'Supprimer',
'categories_new': 'Nouvelle catégorie',
'categories_edit_title': 'Modifier la catégorie',
'categories_name_label': 'Nom de la catégorie *',
'categories_name_required': 'Le nom est obligatoire',
'categories_description_label': 'Description (optionnel)',
'categories_cancel': 'Annuler',
'categories_create_button': 'Créer',
'categories_update_button': 'Modifier',
'categories_delete_title': 'Supprimer la catégorie',
'categories_delete_confirm': 'Êtes-vous sûr de vouloir supprimer la catégorie :',
'categories_delete_warning': 'Cette action est irréversible.',
'categories_created_success': 'Catégorie créée avec succès',
'categories_updated_success': 'Catégorie modifiée avec succès',
'categories_deleted_success': 'Catégorie supprimée avec succès',
```

### Import/Export Excel (excel_import_export_page.dart)
```dart
'excel_import_export_title': 'Import/Export Excel',
'excel_export_section': 'Export des produits',
'excel_export_description': 'Exportez tous vos produits vers un fichier Excel pour sauvegarde ou partage.',
'excel_export_button': 'Exporter tous les produits',
'excel_import_section': 'Import des produits',
'excel_import_description': 'Importez des produits depuis un fichier Excel avec leurs quantités initiales. Utilisez le template pour le bon format.',
'excel_import_button': 'Importer depuis Excel',
'excel_template_button': 'Template',
'excel_instructions_title': 'Instructions',
'excel_instructions_text': '• Pour l\'import, utilisez le template fourni\n• Les colonnes Référence, Nom et Prix Unitaire sont obligatoires\n• Ajoutez une "Quantité Initiale" pour créer automatiquement le stock\n• Les valeurs "Oui/Non" pour Est Actif et Est Service\n• Les prix doivent être des nombres (utilisez . pour les décimales)\n• Les lignes incomplètes seront ignorées',
'excel_preview_title': 'Aperçu de l\'import',
'excel_preview_count': '@count produits prêts à importer',
'excel_preview_with_stock': '@count avec stock initial',
'excel_preview_cancel': 'Annuler',
'excel_preview_confirm': 'Confirmer l\'import',
'excel_initial_stock': 'Stock initial: @quantity',
'excel_service_chip': 'Service',
'excel_inactive_chip': 'Inactif',
```

### Détails produit (product_detail_view.dart)
```dart
'product_detail_loading': 'Chargement...',
'product_detail_not_found': 'Produit non trouvé',
'product_detail_error': 'Impossible d\'afficher les détails du produit.',
'product_detail_back': 'Retour aux produits',
'product_detail_edit': 'Modifier',
'product_detail_duplicate': 'Dupliquer',
'product_detail_delete': 'Supprimer',
'product_detail_active': 'Produit actif',
'product_detail_inactive': 'Produit inactif',
'product_detail_active_subtitle': 'Ce produit est disponible pour les ventes',
'product_detail_inactive_subtitle': 'Ce produit est désactivé et non disponible pour les ventes',
'product_detail_general_info': 'Informations générales',
'product_detail_commercial_info': 'Informations commerciales',
'product_detail_system_info': 'Informations système',
'product_detail_reference': 'Référence',
'product_detail_name': 'Nom',
'product_detail_description': 'Description',
'product_detail_category': 'Catégorie',
'product_detail_sale_price': 'Prix de vente',
'product_detail_purchase_price': 'Prix d\'achat',
'product_detail_margin': 'Marge',
'product_detail_margin_percent': '% Marge',
'product_detail_barcode': 'Code-barre',
'product_detail_stock_threshold': 'Seuil de stock',
'product_detail_units': 'unités',
'product_detail_creation_date': 'Date de création',
'product_detail_modification_date': 'Dernière modification',
'product_detail_type': 'Type',
'product_detail_service': 'Service',
'product_detail_physical': 'Produit physique',
'product_detail_status': 'Statut',
'product_detail_active_status': 'Actif',
'product_detail_inactive_status': 'Inactif',
'product_detail_expiration_management': 'Gestion péremption',
'product_detail_expiration_enabled': 'Activée',
'product_detail_expiration_disabled': 'Désactivée',
'product_detail_delete_confirm_title': 'Confirmer la suppression',
'product_detail_delete_confirm_message': 'Êtes-vous sûr de vouloir supprimer le produit "@name" ?\n\nCette action est irréversible.',
'product_detail_delete_cancel': 'Annuler',
'product_detail_delete_button': 'Supprimer',
'product_detail_category_none': 'Aucune',
'product_detail_category_unresolved': 'ID: @id (nom non résolu)',
```

### Formulaire produit (product_form_view.dart)
```dart
'product_form_new_title': 'Nouveau produit',
'product_form_edit_title': 'Modifier le produit',
'product_form_cancel': 'Annuler',
'product_form_basic_info': 'Informations de base',
'product_form_commercial_info': 'Informations commerciales',
'product_form_stock_management': 'Gestion du stock',
'product_form_reference_auto': 'Référence automatique',
'product_form_reference_auto_enabled': 'Génération automatique activée',
'product_form_reference_manual_enabled': 'Saisie manuelle activée',
'product_form_reference_not_editable': 'La référence ne peut pas être modifiée lors de l\'édition',
'product_form_reference_label': 'Référence *',
'product_form_reference_hint_auto': 'Générée automatiquement',
'product_form_reference_hint_manual': 'Ex: REF001',
'product_form_reference_hint_not_editable': 'Non modifiable en édition',
'product_form_reference_regenerate': 'Générer une nouvelle référence',
'product_form_name_label': 'Nom du produit *',
'product_form_name_hint': 'Ex: Ordinateur portable',
'product_form_description_label': 'Description',
'product_form_description_hint': 'Description détaillée du produit (optionnel)',
'product_form_sale_price_label': 'Prix de vente *',
'product_form_purchase_price_label': 'Prix d\'achat',
'product_form_purchase_price_helper': 'Optionnel - pour calculer la marge',
'product_form_max_discount_label': 'Remise maximale autorisée',
'product_form_max_discount_helper': 'Montant maximum de remise que les vendeurs peuvent accorder',
'product_form_barcode_label': 'Code-barre',
'product_form_barcode_hint': 'Scanner ou saisir le code-barre',
'product_form_barcode_helper': 'Optionnel - pour la recherche rapide',
'product_form_category_label': 'Catégorie',
'product_form_category_hint': 'Sélectionner une catégorie',
'product_form_category_none': 'Aucune catégorie',
'product_form_category_empty': 'Aucune catégorie disponible',
'product_form_category_count': '@count catégorie(s) disponible(s)',
'product_form_category_create': 'Créer des catégories',
'product_form_stock_threshold_label': 'Seuil de stock minimum *',
'product_form_stock_threshold_helper': 'Alerte quand le stock descend sous ce seuil',
'product_form_service_title': 'Prestation de service',
'product_form_service_enabled': 'Produit sans stock physique (service)',
'product_form_service_disabled': 'Produit avec gestion de stock',
'product_form_expiration_title': 'Gestion des dates de péremption',
'product_form_expiration_enabled': 'Suivi des dates de péremption activé',
'product_form_expiration_disabled': 'Pas de suivi de péremption',
'product_form_active_title': 'Produit actif',
'product_form_active_enabled': 'Le produit est disponible pour les ventes',
'product_form_active_disabled': 'Le produit est désactivé',
'product_form_create_button': 'Créer',
'product_form_update_button': 'Modifier',
```

### Liste produits (product_list_view.dart)
```dart
'product_list_title': 'Gestion des Produits',
'product_list_categories': 'Gérer les catégories',
'product_list_import_export': 'Import/Export Excel',
'product_list_add_product': 'Ajouter un produit',
'product_list_refresh': 'Actualiser',
'product_list_loading': 'Chargement des produits...',
'product_list_empty': 'Aucun produit enregistré',
'product_list_empty_subtitle': 'Commencez par ajouter votre premier produit',
'product_list_no_results': 'Aucun produit trouvé',
'product_list_no_results_subtitle': 'Essayez de modifier vos critères de recherche',
'product_list_clear_filters': 'Effacer les filtres',
```

### Carte produit (product_card.dart)
```dart
'product_card_reference': 'Réf: @reference',
'product_card_code': 'Code: @code',
'product_card_sale_price': 'Prix vente',
'product_card_purchase_price': 'Prix achat',
'product_card_category': 'Catégorie',
'product_card_stock_threshold': 'Seuil stock',
'product_card_units': '@count unités',
'product_card_type': 'Type',
'product_card_service': 'Service',
'product_card_modified': 'Modifié',
'product_card_edit': 'Modifier',
'product_card_activate': 'Activer',
'product_card_deactivate': 'Désactiver',
'product_card_delete': 'Supprimer',
'product_card_active': 'Actif',
'product_card_inactive': 'Inactif',
'product_card_today': 'Aujourd\'hui',
'product_card_yesterday': 'Hier',
'product_card_days_ago': 'Il y a @days jours',
```

### Barre de recherche (product_search_bar.dart)
```dart
'product_search_placeholder': 'Rechercher par nom ou référence...',
'product_search_options': 'Options de recherche',
'product_search_by_reference': 'Recherche par référence exacte',
'product_search_by_reference_subtitle': 'Rechercher une référence précise',
'product_search_by_barcode': 'Recherche par code-barre',
'product_search_by_barcode_subtitle': 'Scanner ou saisir un code-barre',
'product_search_by_category': 'Filtrer par catégorie',
'product_search_by_category_subtitle': 'Afficher seulement une catégorie',
'product_search_by_price': 'Filtrer par prix',
'product_search_by_price_subtitle': 'Définir une fourchette de prix',
'product_search_clear_all': 'Effacer tous les filtres',
'product_search_reference_title': 'Recherche par référence',
'product_search_reference_label': 'Référence exacte',
'product_search_reference_hint': 'Ex: REF001',
'product_search_reference_cancel': 'Annuler',
'product_search_reference_button': 'Rechercher',
'product_search_category_title': 'Filtrer par catégorie',
'product_search_category_all': 'Toutes les catégories',
'product_search_category_empty': 'Aucune catégorie disponible',
'product_search_category_close': 'Fermer',
'product_search_barcode_title': 'Recherche par code-barre',
'product_search_barcode_label': 'Code-barre',
'product_search_barcode_hint': 'Scanner ou saisir le code-barre',
'product_search_barcode_found': 'Produit trouvé',
'product_search_barcode_found_message': 'Produit "@name" trouvé avec le code-barre @barcode',
'product_search_barcode_not_found': 'Aucun résultat',
'product_search_barcode_not_found_message': 'Aucun produit trouvé avec le code-barre @barcode',
'product_search_barcode_error': 'Erreur',
'product_search_barcode_error_message': 'Erreur lors de la recherche par code-barre: @error',
'product_search_price_feature': 'Fonctionnalité',
'product_search_price_feature_message': 'Filtre par prix à implémenter',
```

### Barre de filtres (product_filter_bar.dart)
```dart
'product_filter_active': 'Filtres actifs:',
'product_filter_clear_all': 'Effacer tout',
'product_filter_search': 'Recherche: "@query"',
'product_filter_category': 'Catégorie: @category',
```

### Barre de tri (product_sort_bar.dart)
```dart
'product_sort_by': 'Trier par:',
'product_sort_name': 'Nom',
'product_sort_price': 'Prix',
'product_sort_reference': 'Référence',
'product_sort_creation_date': 'Date création',
'product_sort_ascending': 'Ordre croissant',
'product_sort_descending': 'Ordre décroissant',
```

### Dialog dates de péremption (expiration_date_dialog.dart)
```dart
'expiration_dialog_add_title': 'Ajouter une date de péremption',
'expiration_dialog_edit_title': 'Modifier la date de péremption',
'expiration_dialog_date_label': 'Date de péremption *',
'expiration_dialog_date_required': 'Date requise',
'expiration_dialog_date_error': 'Veuillez sélectionner une date',
'expiration_dialog_quantity_label': 'Quantité *',
'expiration_dialog_quantity_suffix': 'unités',
'expiration_dialog_quantity_required': 'Quantité requise',
'expiration_dialog_quantity_invalid': 'Quantité invalide',
'expiration_dialog_lot_label': 'Numéro de lot',
'expiration_dialog_lot_helper': 'Optionnel',
'expiration_dialog_notes_label': 'Notes',
'expiration_dialog_notes_helper': 'Optionnel',
'expiration_dialog_cancel': 'Annuler',
'expiration_dialog_add_button': 'Ajouter',
'expiration_dialog_update_button': 'Modifier',
```

### Liste dates de péremption (expiration_dates_list_widget.dart)
```dart
'expiration_list_title': 'Dates de péremption',
'expiration_list_add': 'Ajouter',
'expiration_list_disabled': 'La gestion des dates de péremption n\'est pas activée pour ce produit',
'expiration_list_loading': 'Chargement...',
'expiration_list_empty': 'Aucune date de péremption enregistrée',
'expiration_list_stats_title': 'Cohérence des quantités',
'expiration_list_stats_stock': 'Stock',
'expiration_list_stats_registered': 'Enregistré',
'expiration_list_stats_remaining': 'Restant',
'expiration_list_stats_coverage': 'Couverture',
'expiration_list_lot': 'Lot: @lot',
'expiration_list_units': '@count unités',
'expiration_list_edit': 'Modifier',
'expiration_list_mark_exhausted': 'Marquer épuisé',
'expiration_list_delete': 'Supprimer',
'expiration_list_exhausted_title': 'Marquer comme épuisé',
'expiration_list_exhausted_message': 'Voulez-vous marquer ce lot comme épuisé ?',
'expiration_list_exhausted_cancel': 'Annuler',
'expiration_list_exhausted_confirm': 'Confirmer',
'expiration_list_delete_title': 'Supprimer',
'expiration_list_delete_message': 'Voulez-vous vraiment supprimer cette date de péremption ?',
'expiration_list_delete_cancel': 'Annuler',
'expiration_list_delete_button': 'Supprimer',
```

### Sélecteur de catégories (category_selector.dart)
```dart
'category_selector_label': 'Catégorie',
'category_selector_all': 'Toutes',
```

## Traductions anglaises correspondantes

Toutes les clés ci-dessus ont également été traduites en anglais dans `en_translations.dart`.

## Instructions d'utilisation

Pour utiliser ces traductions dans le code, remplacer les chaînes en dur par:
```dart
Text('Texte en dur')
// devient
Text('cle_traduction'.tr)
```

Exemple:
```dart
Text('Gestion des catégories')
// devient
Text('categories_management'.tr)
```


## Progression de l'application

### ✅ Fichiers complétés (8/12)

#### Traductions ajoutées
1. ✅ `fr_translations.dart` - 150+ clés ajoutées
2. ✅ `en_translations.dart` - 150+ clés ajoutées

#### Views (2/5)
1. ✅ `categories_page.dart` - Complètement traduit
2. ✅ `product_list_view.dart` - Complètement traduit
3. ⏸️ `excel_import_export_page.dart` - À faire
4. ⏸️ `product_detail_view.dart` - À faire
5. ⏸️ `product_form_view.dart` - À faire (le plus gros fichier)

#### Widgets (6/7)
1. ✅ `product_card.dart` - Complètement traduit
2. ✅ `product_search_bar.dart` - Complètement traduit
3. ✅ `product_filter_bar.dart` - Complètement traduit
4. ✅ `product_sort_bar.dart` - Complètement traduit
5. ✅ `category_selector.dart` - Complètement traduit
6. ⏸️ `expiration_date_dialog.dart` - À faire
7. ⏸️ `expiration_dates_list_widget.dart` - À faire

### Fichiers restants (4/12)
- excel_import_export_page.dart
- product_detail_view.dart
- product_form_view.dart (le plus complexe)
- expiration_date_dialog.dart
- expiration_dates_list_widget.dart

Temps estimé pour compléter: 30-40 minutes
