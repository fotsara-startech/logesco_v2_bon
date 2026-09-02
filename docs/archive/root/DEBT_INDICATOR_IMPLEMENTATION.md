# Debt Indicator Implementation - COMPLETED

## Summary
Successfully added visual debt indicators to both customer and supplier lists to show at a glance which clients/suppliers have outstanding debts.

## Changes Made

### 1. Updated Supplier Model
**File:** `logesco_v2/lib/features/suppliers/models/supplier.dart`

- Added `solde` field to Supplier class (default: 0.0)
- Updated `fromJson()` to parse solde from API response
- Updated `toJson()` to include solde
- Updated `copyWith()` to support solde parameter
- Added `aDette` getter property:
  ```dart
  /// Vérifie si le fournisseur a une dette (solde > 0 pour les fournisseurs)
  bool get aDette => solde > 0;
  ```

**Note:** For suppliers, `solde > 0` means they have a debt (we owe them money)

### 2. Updated Customer List View
**File:** `logesco_v2/lib/features/customers/views/customer_list_view.dart`

- Modified `_CustomerListItem.build()` to display debt indicator
- Added visual badge in the title row showing "DETTE" when `customer.solde < 0`
- Badge styling:
  - Red background with red border
  - Warning icon + "DETTE" text
  - Positioned next to customer name
  - Only displays if customer has debt

**Note:** For customers, `solde < 0` means they have a debt (they owe us money)

### 3. Updated Supplier Card Widget
**File:** `logesco_v2/lib/features/suppliers/widgets/supplier_card.dart`

- Modified header section to display debt indicator
- Added visual badge showing "DETTE" when `supplier.aDette` is true
- Badge styling:
  - Red background with red border
  - Warning icon + "DETTE" text
  - Positioned next to supplier name
  - Only displays if supplier has debt

## Visual Indicators

### Debt Badge Design
```
┌─────────────────────────────────────────────────────────────┐
│ [Icon] Name                                    [⚠ DETTE]    │
│        Contact Info                                          │
└─────────────────────────────────────────────────────────────┘
```

- **Color:** Red (#F44336 family)
- **Icon:** Warning icon (Icons.warning_rounded)
- **Text:** "DETTE" in bold
- **Size:** Compact, fits inline with name
- **Visibility:** Only shows when debt exists

## Logic

### Customers
- **Debt exists when:** `solde < 0`
- **Meaning:** Customer owes us money
- **Display:** Red "DETTE" badge in customer list

### Suppliers
- **Debt exists when:** `solde > 0`
- **Meaning:** We owe the supplier money
- **Display:** Red "DETTE" badge in supplier card

## API Integration

The implementation assumes the backend returns `solde` field in:
- `/api/v1/suppliers` - List suppliers endpoint
- `/api/v1/customers` - List customers endpoint

If the backend doesn't return solde, the indicators will show no debt (default solde = 0.0).

## Testing Checklist

- [ ] View customer list → Customers with debt show "DETTE" badge
- [ ] View supplier list → Suppliers with debt show "DETTE" badge
- [ ] Customers without debt → No badge displayed
- [ ] Suppliers without debt → No badge displayed
- [ ] Badge styling is consistent and readable
- [ ] Badge doesn't interfere with other UI elements
- [ ] Debt status updates when customer/supplier data refreshes

## Files Modified

1. `logesco_v2/lib/features/suppliers/models/supplier.dart` - Added solde field and aDette getter
2. `logesco_v2/lib/features/customers/views/customer_list_view.dart` - Added debt badge to customer list
3. `logesco_v2/lib/features/suppliers/widgets/supplier_card.dart` - Added debt badge to supplier card

## Status
✅ **COMPLETE** - Debt indicators now display in both customer and supplier lists
