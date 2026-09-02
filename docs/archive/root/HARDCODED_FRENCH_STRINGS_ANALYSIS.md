# Financial Movements Widgets - Hardcoded French Strings Analysis

## Overview
This document provides a comprehensive list of all hardcoded French strings found in the financial_movements widgets that need to be replaced with translation keys.

---

## 1. daily_expenses_summary_widget.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 95 | `'Dépenses du jour'` | `financial_movements_daily_expenses_title` | Widget title in loading state |
| 104 | `'Chargement...'` | `common_loading` | Loading indicator text |
| 125 | `'Dépenses du jour'` | `financial_movements_daily_expenses_title` | Widget title in error state |
| 131 | `'Erreur de chargement'` | `financial_movements_loading_error` | Error message |
| 135 | `'Réessayer'` | `common_retry` | Retry button tooltip |
| 155 | `'Dépenses du jour'` | `financial_movements_daily_expenses_title` | Widget title in no-data state |
| 164 | `'Aucune dépense aujourd\'hui'` | `financial_movements_no_expenses_today` | No data message |
| 171 | `'0 FCFA • 0 mouvement'` | `financial_movements_empty_summary` | Empty state summary |
| 195 | `'Dépenses du jour'` | `financial_movements_daily_expenses_title` | Widget title in summary content |
| 237 | `'mouvement'` / `'mouvements'` | `financial_movements_movement_singular` / `financial_movements_movement_plural` | Movement count label |
| 250 | `'Moy: '` | `financial_movements_average_label` | Average amount prefix |
| 280 | `'Dernier: '` | `financial_movements_last_movement_label` | Last movement time prefix |
| 295 | `'Aucune dépense'` | `financial_movements_no_expenses` | Expense level text |
| 300 | `'Dépenses faibles'` | `financial_movements_low_expenses` | Low expense level |
| 301 | `'Dépenses modérées'` | `financial_movements_moderate_expenses` | Moderate expense level |
| 302 | `'Dépenses élevées'` | `financial_movements_high_expenses` | High expense level |
| 318 | `'Impossible d\'ouvrir les mouvements financiers'` | `financial_movements_navigation_error` | Navigation error message |
| 330 | `'Erreur lors du rechargement du résumé quotidien'` | `financial_movements_daily_summary_retry_error` | Retry error message |

---

## 2. category_analysis_widget.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 50 | `'Type de graphique:'` | `financial_movements_chart_type_label` | Chart type selector label |
| 56 | `'Camembert'` | `financial_movements_chart_pie` | Pie chart button label |
| 57 | `'Barres'` | `financial_movements_chart_bars` | Bar chart button label |
| 58 | `'Barres H.'` | `financial_movements_chart_horizontal_bars` | Horizontal bar chart button label |
| 169 | `'Classement des dépenses'` | `financial_movements_expense_ranking` | Ranking section title |

---

## 3. financial_charts_widget.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 35 | `'Répartition par catégorie'` | `financial_movements_category_distribution` | Category chart title |
| 80 | `'Évolution quotidienne'` | `financial_movements_daily_evolution` | Daily trend chart title |
| 155 | `'Moyenne'` | `financial_movements_trend_average` | Trend stat label |
| 156 | `'Maximum'` | `financial_movements_trend_maximum` | Trend stat label |
| 157 | `'Minimum'` | `financial_movements_trend_minimum` | Trend stat label |

---

## 4. movement_card.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 95 | `'Modifier'` | `common_edit` | Edit button tooltip |
| 107 | `'Supprimer'` | `common_delete` | Delete button tooltip |

---

## 5. movement_filters.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 50 | `'Période rapide'` | `financial_movements_quick_period` | Quick period filter section title |
| 62 | `'Aujourd\'hui'` | `financial_movements_period_today` | Today period chip |
| 63 | `'Hier'` | `financial_movements_period_yesterday` | Yesterday period chip |
| 64 | `'Cette semaine'` | `financial_movements_period_this_week` | This week period chip |
| 65 | `'Semaine dernière'` | `financial_movements_period_last_week` | Last week period chip |
| 66 | `'Ce mois'` | `financial_movements_period_this_month` | This month period chip |
| 67 | `'Mois dernier'` | `financial_movements_period_last_month` | Last month period chip |
| 68 | `'Cette année'` | `financial_movements_period_this_year` | This year period chip |
| 82 | `'Catégorie'` | `financial_movements_category_label` | Category filter section title |
| 89 | `'Toutes'` | `financial_movements_all_categories` | All categories chip |
| 104 | `'Plage de dates personnalisée'` | `financial_movements_custom_date_range` | Custom date range section title |
| 113 | `'Date de début'` | `financial_movements_start_date_label` | Start date field label |
| 119 | `'Date de fin'` | `financial_movements_end_date_label` | End date field label |
| 127 | `'Sélectionner'` | `common_select` | Date picker placeholder |
| 141 | `'Plage de montants (FCFA)'` | `financial_movements_amount_range_label` | Amount range section title |
| 150 | `'Montant minimum'` | `financial_movements_min_amount_label` | Min amount field label |
| 156 | `'Montant maximum'` | `financial_movements_max_amount_label` | Max amount field label |
| 165 | `'Recherche avancée'` | `financial_movements_advanced_search` | Advanced search section title |
| 173 | `'Description'` | `financial_movements_description_label` | Description search field |
| 179 | `'Référence'` | `financial_movements_reference_label` | Reference search field |
| 185 | `'Notes'` | `financial_movements_notes_label` | Notes search field |
| 191 | `'Utilisateur'` | `financial_movements_user_label` | User search field |
| 200 | `'Suggestions intelligentes'` | `financial_movements_smart_suggestions` | Smart suggestions section title |
| 217 | `'Presets sauvegardés'` | `financial_movements_saved_presets` | Saved presets dialog title |
| 224 | `'Aucun preset personnalisé sauvegardé'` | `financial_movements_no_custom_presets` | No presets message |
| 235 | `'Appliquer'` | `common_apply` | Apply preset button tooltip |
| 240 | `'Supprimer'` | `common_delete` | Delete preset button tooltip |
| 252 | `'Fermer'` | `common_close` | Close button label |
| 260 | `'Supprimer le preset'` | `financial_movements_delete_preset_title` | Delete preset confirmation title |
| 261 | `'Êtes-vous sûr de vouloir supprimer le preset "@name" ?'` | `financial_movements_delete_preset_confirm` | Delete preset confirmation message |
| 265 | `'Annuler'` | `common_cancel` | Cancel button |
| 268 | `'Supprimer'` | `common_delete` | Delete button |
| 280 | `'Sauvegarder les filtres'` | `financial_movements_save_filters_title` | Save filters dialog title |
| 285 | `'Nom du preset *'` | `financial_movements_preset_name_label` | Preset name field label |
| 291 | `'Description (optionnelle)'` | `financial_movements_preset_description_label` | Preset description field label |
| 300 | `'Annuler'` | `common_cancel` | Cancel button |
| 305 | `'Sauvegarder'` | `common_save` | Save button |
| 312 | `'Filtres rapides'` | `financial_movements_quick_filters` | Quick filters section title |

---

## 6. period_comparison_widget.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 24 | `'Comparaison entre périodes'` | `financial_movements_period_comparison_title` | Widget title |
| 32 | `'Période principale'` | `financial_movements_main_period_label` | Main period selector title |
| 42 | `'Période de comparaison'` | `financial_movements_comparison_period_label` | Comparison period selector title |
| 52 | `'Périodes de comparaison suggérées:'` | `financial_movements_suggested_comparison_periods` | Suggested periods label |
| 57 | `'Période précédente'` | `financial_movements_period_previous` | Previous period chip |
| 58 | `'Mois précédent'` | `financial_movements_period_previous_month` | Previous month chip |
| 59 | `'Année précédente'` | `financial_movements_period_previous_year` | Previous year chip |
| 60 | `'Trimestre précédent'` | `financial_movements_period_previous_quarter` | Previous quarter chip |
| 68 | `'Comparer les périodes'` | `financial_movements_compare_periods_button` | Compare button label |
| 69 | `'Comparaison...'` | `financial_movements_comparing` | Comparing state label |
| 75 | `'Échanger les périodes'` | `financial_movements_swap_periods_tooltip` | Swap periods button tooltip |
| 85 | `'Comparaison des périodes'` | `financial_movements_comparison_results_title` | Results title |
| 92 | `'Fermer la comparaison'` | `financial_movements_close_comparison_tooltip` | Close comparison tooltip |
| 98 | `'Période 1'` | `financial_movements_period_1_label` | Period 1 label |
| 106 | `'Période 2'` | `financial_movements_period_2_label` | Period 2 label |
| 130 | `'Statistiques générales'` | `financial_movements_general_statistics` | General statistics section title |
| 138 | `'Montant total'` | `financial_movements_total_amount_label` | Total amount stat label |
| 145 | `'Nombre de mouvements'` | `financial_movements_movement_count_label` | Movement count stat label |
| 152 | `'Montant moyen'` | `financial_movements_average_amount_label` | Average amount stat label |
| 200 | `'Comparaison par catégorie'` | `financial_movements_category_comparison_title` | Category comparison section title |
| 210 | `'Aucune donnée de catégorie disponible'` | `financial_movements_no_category_data` | No category data message |
| 225 | `'Comparaison par catégorie'` | `financial_movements_category_comparison_title` | Category comparison section title |
| 232 | `'Sélectionner une période'` | `financial_movements_select_period_placeholder` | Date range selector placeholder |

---

## 7. summary_statistics_widget.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 50 | `'Moyenne par mouvement'` | `financial_movements_average_per_movement` | Average per movement stat label |
| 59 | `'Moyenne quotidienne'` | `financial_movements_daily_average` | Daily average stat label |
| 68 | `'Montant maximum'` | `financial_movements_max_amount_label` | Maximum amount stat label |
| 76 | `'Montant minimum'` | `financial_movements_min_amount_label` | Minimum amount stat label |

---

## 8. weekly_financial_summary_widget.dart

### Hardcoded French Strings

| Line | French String | Suggested Translation Key | Context |
|------|---------------|--------------------------|---------|
| 65 | `'Résumé hebdomadaire'` | `financial_movements_weekly_summary_title` | Widget title in loading state |
| 74 | `'Chargement...'` | `common_loading` | Loading indicator text |
| 95 | `'Résumé hebdomadaire'` | `financial_movements_weekly_summary_title` | Widget title in error state |
| 101 | `'Erreur de chargement'` | `financial_movements_loading_error` | Error message |
| 105 | `'Réessayer'` | `common_retry` | Retry button tooltip |
| 125 | `'Résumé hebdomadaire'` | `financial_movements_weekly_summary_title` | Widget title in no-data state |
| 134 | `'Aucune dépense cette semaine'` | `financial_movements_no_expenses_this_week` | No data message |
| 141 | `'0 FCFA • 0 mouvement'` | `financial_movements_empty_summary` | Empty state summary |
| 165 | `'Résumé hebdomadaire'` | `financial_movements_weekly_summary_title` | Widget title in summary content |
| 195 | `'mouvement'` / `'mouvements'` | `financial_movements_movement_singular` / `financial_movements_movement_plural` | Movement count label |
| 203 | `'Moy/jour: '` | `financial_movements_average_per_day_label` | Average per day prefix |
| 230 | `'Cette semaine'` | `financial_movements_this_week_label` | This week label |
| 240 | `'Aucune dépense'` | `financial_movements_no_expenses` | Expense level text |
| 245 | `'Dépenses faibles'` | `financial_movements_low_expenses` | Low expense level |
| 246 | `'Dépenses modérées'` | `financial_movements_moderate_expenses` | Moderate expense level |
| 247 | `'Dépenses élevées'` | `financial_movements_high_expenses` | High expense level |
| 262 | `'Impossible d\'ouvrir les rapports financiers'` | `financial_movements_reports_navigation_error` | Navigation error message |
| 274 | `'Erreur lors du rechargement du résumé hebdomadaire'` | `financial_movements_weekly_summary_retry_error` | Retry error message |

---

## Summary Statistics

### Total Hardcoded French Strings: **89**

### Distribution by File:
- **daily_expenses_summary_widget.dart**: 18 strings
- **category_analysis_widget.dart**: 5 strings
- **financial_charts_widget.dart**: 5 strings
- **movement_card.dart**: 2 strings
- **movement_filters.dart**: 42 strings
- **period_comparison_widget.dart**: 10 strings
- **summary_statistics_widget.dart**: 4 strings
- **weekly_financial_summary_widget.dart**: 18 strings

### Translation Key Naming Pattern

Following the existing pattern in the codebase:
- **Prefix**: `financial_movements_` for widget-specific strings
- **Prefix**: `common_` for generic/reusable strings (loading, cancel, save, etc.)
- **Format**: `snake_case` with descriptive suffixes
- **Examples**:
  - `financial_movements_daily_expenses_title`
  - `financial_movements_period_today`
  - `financial_movements_no_expenses_today`
  - `common_loading`
  - `common_retry`

---

## Recommended Translation Keys (Unique List)

### Financial Movements Specific Keys (54 unique keys)
1. `financial_movements_daily_expenses_title`
2. `financial_movements_loading_error`
3. `financial_movements_no_expenses_today`
4. `financial_movements_empty_summary`
5. `financial_movements_movement_singular`
6. `financial_movements_movement_plural`
7. `financial_movements_average_label`
8. `financial_movements_last_movement_label`
9. `financial_movements_no_expenses`
10. `financial_movements_low_expenses`
11. `financial_movements_moderate_expenses`
12. `financial_movements_high_expenses`
13. `financial_movements_navigation_error`
14. `financial_movements_daily_summary_retry_error`
15. `financial_movements_chart_type_label`
16. `financial_movements_chart_pie`
17. `financial_movements_chart_bars`
18. `financial_movements_chart_horizontal_bars`
19. `financial_movements_expense_ranking`
20. `financial_movements_category_distribution`
21. `financial_movements_daily_evolution`
22. `financial_movements_trend_average`
23. `financial_movements_trend_maximum`
24. `financial_movements_trend_minimum`
25. `financial_movements_quick_period`
26. `financial_movements_period_today`
27. `financial_movements_period_yesterday`
28. `financial_movements_period_this_week`
29. `financial_movements_period_last_week`
30. `financial_movements_period_this_month`
31. `financial_movements_period_last_month`
32. `financial_movements_period_this_year`
33. `financial_movements_category_label`
34. `financial_movements_all_categories`
35. `financial_movements_custom_date_range`
36. `financial_movements_start_date_label`
37. `financial_movements_end_date_label`
38. `financial_movements_amount_range_label`
39. `financial_movements_min_amount_label`
40. `financial_movements_max_amount_label`
41. `financial_movements_advanced_search`
42. `financial_movements_description_label`
43. `financial_movements_reference_label`
44. `financial_movements_notes_label`
45. `financial_movements_user_label`
46. `financial_movements_smart_suggestions`
47. `financial_movements_saved_presets`
48. `financial_movements_no_custom_presets`
49. `financial_movements_delete_preset_title`
50. `financial_movements_delete_preset_confirm`
51. `financial_movements_save_filters_title`
52. `financial_movements_preset_name_label`
53. `financial_movements_preset_description_label`
54. `financial_movements_quick_filters`
55. `financial_movements_period_comparison_title`
56. `financial_movements_main_period_label`
57. `financial_movements_comparison_period_label`
58. `financial_movements_suggested_comparison_periods`
59. `financial_movements_period_previous`
60. `financial_movements_period_previous_month`
61. `financial_movements_period_previous_year`
62. `financial_movements_period_previous_quarter`
63. `financial_movements_compare_periods_button`
64. `financial_movements_comparing`
65. `financial_movements_swap_periods_tooltip`
66. `financial_movements_comparison_results_title`
67. `financial_movements_close_comparison_tooltip`
68. `financial_movements_period_1_label`
69. `financial_movements_period_2_label`
70. `financial_movements_general_statistics`
71. `financial_movements_total_amount_label`
72. `financial_movements_movement_count_label`
73. `financial_movements_average_amount_label`
74. `financial_movements_category_comparison_title`
75. `financial_movements_no_category_data`
76. `financial_movements_select_period_placeholder`
77. `financial_movements_average_per_movement`
78. `financial_movements_daily_average`
79. `financial_movements_weekly_summary_title`
80. `financial_movements_no_expenses_this_week`
81. `financial_movements_average_per_day_label`
82. `financial_movements_this_week_label`
83. `financial_movements_reports_navigation_error`
84. `financial_movements_weekly_summary_retry_error`

### Common/Reusable Keys (7 unique keys)
1. `common_loading`
2. `common_retry`
3. `common_edit`
4. `common_delete`
5. `common_select`
6. `common_apply`
7. `common_close`
8. `common_cancel`
9. `common_save`

---

## Implementation Notes

1. **Priority**: High - These strings are user-facing and critical for localization
2. **Scope**: All 8 widget files need updates
3. **Pattern**: Use `.tr` extension for GetX translation (already used in some places)
4. **Testing**: Verify all strings render correctly in French, English, and Spanish
5. **Consistency**: Ensure new keys follow the existing naming convention
6. **Reusability**: Common keys should be used across all modules for consistency

---

## Next Steps

1. Add all suggested translation keys to:
   - `fr_translations.dart` (French)
   - `en_translations.dart` (English)
   - `es_translations.dart` (Spanish)

2. Replace hardcoded strings in widgets with `.tr` calls:
   ```dart
   // Before
   Text('Dépenses du jour')
   
   // After
   Text('financial_movements_daily_expenses_title'.tr)
   ```

3. Test all widgets in all supported languages

4. Verify no hardcoded strings remain using grep search

