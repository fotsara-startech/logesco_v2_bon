# Implementation Guide: Using Statement Translations in PDF Services

## Overview
This guide shows how to integrate the newly added statement translations into the PDF generation services for both customer and supplier account statements.

## Current State
- ✅ All translation keys added to 3 language files (French, English, Spanish)
- ⏳ PDF services still use hardcoded strings
- ⏳ Need to replace hardcoded strings with translation keys

## Implementation Steps

### Step 1: Import Translation System in PDF Services

**File:** `logesco_v2/lib/features/customers/services/statement_pdf_service.dart`

Add import at the top:
```dart
import 'package:get/get.dart';
```

### Step 2: Replace Hardcoded Strings in Customer Statement PDF

**Current hardcoded strings to replace:**

| Current | Translation Key |
|---------|-----------------|
| `'RELEVÉ DE COMPTE CLIENT'` | `'statement_title_customer'.tr` |
| `'Date: ${_formatDateForPDF(DateTime.now())}'` | `'statement_generated_date'.trParams({'date': _formatDateForPDF(DateTime.now())})` |
| `'CLIENT'` | `'statement_client_label'.tr` |
| `'SOLDE DU COMPTE'` | `'statement_balance_label'.tr` |
| `'Montant dû'` | `'statement_balance_due'.tr` |
| `'Crédit disponible'` | `'statement_credit_available'.tr` |
| `'HISTORIQUE DES TRANSACTIONS (${transactions.length})'` | `'statement_transactions_history'.trParams({'count': transactions.length.toString()})` |
| `'Aucune transaction enregistrée'` | `'statement_no_transactions'.tr` |
| `'Date'` (table header) | `'statement_table_date'.tr` |
| `'Description'` (table header) | `'statement_table_description'.tr` |
| `'Montant'` (table header) | `'statement_table_amount'.tr` |
| `'Solde'` (table header) | `'statement_table_balance'.tr` |
| `'Document généré automatiquement le ${_formatDateForPDF(DateTime.now())}'` | `'statement_generated_on'.trParams({'date': _formatDateForPDF(DateTime.now())})` |
| `'Tél: ${entreprise!['telephone']}'` | `'statement_phone_label'.tr + ': ${entreprise!['telephone']}'` |
| `'Email: ${client['email']}'` | `'statement_email_label'.tr + ': ${client['email']}'` |
| `'NUI/RCCM: ${entreprise!['nuiRccm']}'` | `'statement_nui_rccm_label'.tr + ': ${entreprise!['nuiRccm']}'` |

### Step 3: Replace Hardcoded Strings in Supplier Statement PDF

**File:** `logesco_v2/lib/features/suppliers/services/supplier_statement_pdf_service.dart`

Same approach as customer statement, but use:
- `'statement_title_supplier'.tr` instead of `'statement_title_customer'.tr`
- `'statement_supplier_label'.tr` instead of `'statement_client_label'.tr`

### Step 4: Example Implementation

**Before (hardcoded):**
```dart
pw.Text(
  'RELEVÉ DE COMPTE CLIENT',
  style: pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  ),
),
```

**After (with translation):**
```dart
pw.Text(
  'statement_title_customer'.tr,
  style: pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  ),
),
```

**With parameters:**
```dart
pw.Text(
  'statement_generated_date'.trParams({'date': _formatDateForPDF(DateTime.now())}),
  style: const pw.TextStyle(
    fontSize: 9,
    color: PdfColors.white,
  ),
),
```

## Translation Parameter Usage

### Single Parameter
```dart
'statement_generated_date'.trParams({'date': '10/03/2026 14:30'})
// Output: "Date: 10/03/2026 14:30"
```

### Multiple Parameters
```dart
'statement_transactions_history'.trParams({'count': '5'})
// Output: "HISTORIQUE DES TRANSACTIONS (5)"
```

## Testing the Implementation

### Test in French
1. Set app language to French
2. Generate customer statement PDF
3. Verify all text appears in French

### Test in English
1. Set app language to English
2. Generate customer statement PDF
3. Verify all text appears in English

### Test in Spanish
1. Set app language to Spanish
2. Generate customer statement PDF
3. Verify all text appears in Spanish

## Checklist for Implementation

- [ ] Import `package:get/get.dart` in both PDF service files
- [ ] Replace all hardcoded strings in customer statement PDF
- [ ] Replace all hardcoded strings in supplier statement PDF
- [ ] Test customer statement in French
- [ ] Test customer statement in English
- [ ] Test customer statement in Spanish
- [ ] Test supplier statement in French
- [ ] Test supplier statement in English
- [ ] Test supplier statement in Spanish
- [ ] Verify all table headers are translated
- [ ] Verify all labels are translated
- [ ] Verify date formatting works with translations

## Notes

- The `.tr` extension automatically uses the current app language
- Parameters are passed using `.trParams({'key': 'value'})`
- All translation keys are prefixed with `statement_` for easy identification
- The implementation maintains the same PDF layout and formatting

## Status
📋 **READY FOR IMPLEMENTATION** - All translation keys are in place and ready to be integrated into PDF services
