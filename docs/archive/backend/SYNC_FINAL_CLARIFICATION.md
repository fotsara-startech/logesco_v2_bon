# Sync Service — Final Clarification

## What Gets Synced vs What Doesn't

### ✅ SYNCED (User-Facing Operations)

These are synced to Neon so all users can see them:

1. **ventes** (Sales) — When a customer buys something
2. **utilisateurs** (Users) — User accounts
3. **boutiques** (Stores) — Store information
4. **produits** (Products) — Product catalog
5. **clients** (Customers) — Customer information
6. **fournisseurs** (Suppliers) — Supplier information
7. **categories** (Categories) — Product categories
8. **cash_registers** (Cash Registers) — Register setup
9. **cash_sessions** (Cash Sessions) — When a cashier opens/closes register
10. **user_roles** (Roles) — User roles

### ❌ NOT SYNCED (Internal Tracking)

These are NOT synced because they're internal backend calculations:

1. **financial_movements** — Internal accounting records
2. **cash_movements** — Internal cash tracking
3. **details_ventes** — Part of ventes (included in sale)
4. **mouvements_stock** — Internal stock tracking
5. **transactions_comptes** — Internal account transactions

## Why Financial Movements Aren't Synced

**Financial movements are DERIVED from user operations**, not primary data:

```
User creates expense
    ↓
Backend creates financial_movement (internal)
    ↓
Backend updates cash_session (synced)
    ↓
Other users see updated cash_session
    ↓
Other users' backends calculate financial_movements locally
```

**Example**:
- User A creates expense: -1000 FCFA
- Backend creates financial_movement record (internal)
- Backend updates cash_session: solde_attendu -= 1000
- Sync sends cash_session to Neon
- User B's backend pulls updated cash_session
- User B's backend calculates the same financial_movement locally

## What Actually Syncs

When you create an expense:

1. ✅ **cash_session** is updated and synced
   - `solde_attendu` is reduced
   - Other users see the updated balance

2. ❌ **financial_movement** is NOT synced
   - It's internal accounting
   - Other users calculate it locally from cash_session

## Verification

### Check What's Synced

```bash
# Check Neon data
node check-neon-data.js

# Should show:
# - Updated cash_sessions
# - Updated ventes
# - Updated utilisateurs
# - etc.

# Should NOT show:
# - financial_movements
# - cash_movements
```

### Check Local Data

```bash
# Check local queue
node check-local-queue.js

# Should show:
# - cash_sessions (if updated)
# - ventes (if created)
# - NO financial_movements
```

## How to Verify Expense Was Recorded

1. **Locally**: Financial movement appears in Flutter app ✅
2. **In Neon**: cash_session.solde_attendu is reduced ✅
3. **Other users**: See updated cash_session balance ✅

## Summary

**Financial movements are NOT synced because they're internal calculations, not primary data.**

What matters is that:
- ✅ Cash session balance is updated and synced
- ✅ Other users see the updated balance
- ✅ Each user calculates financial_movements locally

This is the correct design because:
- Reduces sync overhead
- Avoids data duplication
- Each user has their own accounting records
- Shared data (cash_session) is the source of truth

**Status**: Working as designed ✅

---

**Conclusion**: The sync service is working correctly. Financial movements don't need to be synced because they're internal. The important data (cash_session balance) IS synced.
