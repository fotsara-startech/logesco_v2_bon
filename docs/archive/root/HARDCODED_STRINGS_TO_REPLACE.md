# Hardcoded Strings to Replace with Translations

## Customer Statement PDF Service
**File:** `logesco_v2/lib/features/customers/services/statement_pdf_service.dart`

### Strings to Replace

| Line | Current Hardcoded String | Replace With | Translation Key |
|------|--------------------------|--------------|-----------------|
| ~182 | `'RELEVÉ DE COMPTE CLIENT'` | `'statement_title_customer'.tr` | statement_title_customer |
| ~190 | `'Date: ${_formatDateForPDF(DateTime.now())}'` | `'statement_generated_date'.trParams({'date': _formatDateForPDF(DateTime.now())})` | statement_generated_date |
| ~212 | `'CLIENT'` | `'statement_client_label'.tr` | statement_client_label |
| ~250 | `'SOLDE DU COMPTE'` | `'statement_balance_label'.tr` | statement_balance_label |
| ~265 | `'Montant dû'` | `'statement_balance_due'.tr` | statement_balance_due |
| ~267 | `'Crédit disponible'` | `'statement_credit_available'.tr` | statement_credit_available |
| ~280 | `'HISTORIQUE DES TRANSACTIONS (${transactions.length})'` | `'statement_transactions_history'.trParams({'count': transactions.length.toString()})` | statement_transactions_history |
| ~290 | `'Aucune transaction enregistrée'` | `'statement_no_transactions'.tr` | statement_no_transactions |
| ~305 | `'Date'` (table header) | `'statement_table_date'.tr` | statement_table_date |
| ~306 | `'Description'` (table header) | `'statement_table_description'.tr` | statement_table_description |
| ~307 | `'Montant'` (table header) | `'statement_table_amount'.tr` | statement_table_amount |
| ~308 | `'Solde'` (table header) | `'statement_table_balance'.tr` | statement_table_balance |
| ~340 | `'Document généré automatiquement le ${_formatDateForPDF(DateTime.now())}'` | `'statement_generated_on'.trParams({'date': _formatDateForPDF(DateTime.now())})` | statement_generated_on |
| ~137 | `'Tél: ${entreprise!['telephone']}'` | `'statement_phone_label'.tr + ': ${entreprise!['telephone']}'` | statement_phone_label |
| ~143 | `'Email: ${client['email']}'` | `'statement_email_label'.tr + ': ${client['email']}'` | statement_email_label |
| ~148 | `'NUI/RCCM: ${entreprise!['nuiRccm']}'` | `'statement_nui_rccm_label'.tr + ': ${entreprise!['nuiRccm']}'` | statement_nui_rccm_label |

## Supplier Statement PDF Service
**File:** `logesco_v2/lib/features/suppliers/services/supplier_statement_pdf_service.dart`

### Strings to Replace

| Current Hardcoded String | Replace With | Translation Key |
|--------------------------|--------------|-----------------|
| `'RELEVÉ DE COMPTE FOURNISSEUR'` | `'statement_title_supplier'.tr` | statement_title_supplier |
| `'Date: ${_formatDateForPDF(DateTime.now())}'` | `'statement_generated_date'.trParams({'date': _formatDateForPDF(DateTime.now())})` | statement_generated_date |
| `'FOURNISSEUR'` | `'statement_supplier_label'.tr` | statement_supplier_label |
| `'SOLDE DU COMPTE'` | `'statement_balance_label'.tr` | statement_balance_label |
| `'Montant dû'` | `'statement_balance_due'.tr` | statement_balance_due |
| `'Solde équilibré'` | `'statement_balanced'.tr` | statement_balanced |
| `'HISTORIQUE DES TRANSACTIONS'` | `'statement_transactions_history'.trParams({'count': transactions.length.toString()})` | statement_transactions_history |
| `'Date'` (table header) | `'statement_table_date'.tr` | statement_table_date |
| `'Type'` (table header) | `'statement_table_type'.tr` | statement_table_type |
| `'Description'` (table header) | `'statement_table_description'.tr` | statement_table_description |
| `'Montant'` (table header) | `'statement_table_amount'.tr` | statement_table_amount |
| `'Solde'` (table header) | `'statement_table_balance'.tr` | statement_table_balance |
| `'Tél: ${fournisseur['telephone']}'` | `'statement_phone_label'.tr + ': ${fournisseur['telephone']}'` | statement_phone_label |
| `'Email: ${fournisseur['email']}'` | `'statement_email_label'.tr + ': ${fournisseur['email']}'` | statement_email_label |
| `'NUI/RCCM: ${entreprise['nuiRccm']}'` | `'statement_nui_rccm_label'.tr + ': ${entreprise['nuiRccm']}'` | statement_nui_rccm_label |

## Implementation Pattern

### Pattern 1: Simple String
```dart
// Before
pw.Text('RELEVÉ DE COMPTE CLIENT', ...)

// After
pw.Text('statement_title_customer'.tr, ...)
```

### Pattern 2: String with Parameter
```dart
// Before
pw.Text('Date: ${_formatDateForPDF(DateTime.now())}', ...)

// After
pw.Text('statement_generated_date'.trParams({'date': _formatDateForPDF(DateTime.now())}), ...)
```

### Pattern 3: String Concatenation
```dart
// Before
pw.Text('Tél: ${entreprise!['telephone']}', ...)

// After
pw.Text('statement_phone_label'.tr + ': ${entreprise!['telephone']}', ...)
```

## Required Import

Add this import to both PDF service files:
```dart
import 'package:get/get.dart';
```

## Verification Checklist

After replacing all strings:

- [ ] All `pw.Text()` calls use `.tr` for translatable strings
- [ ] All dynamic values use `.trParams()` with proper parameter names
- [ ] No hardcoded French/English strings remain in PDF generation
- [ ] Import statement includes `package:get/get.dart`
- [ ] Code compiles without errors
- [ ] PDFs generate correctly in all three languages

## Total Strings to Replace

- **Customer Statement PDF:** 16 strings
- **Supplier Statement PDF:** 15 strings
- **Total:** 31 hardcoded strings

## Status

📋 **READY FOR REPLACEMENT** - All translation keys are in place and this guide shows exactly what needs to be replaced.
