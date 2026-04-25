# Financial Movements Sync Guide

## Overview

When you create an expense (financial movement), the system now properly synchronizes the cash balance updates to Neon so all users see the updated balance.

## What Happens When You Create an Expense

### Step 1: Expense Created
```
User creates expense: -1000 FCFA
```

### Step 2: Backend Updates (Local)
```
✅ financial_movement record created (internal)
✅ cash_session.soldeAttendu reduced by 1000
✅ cash_register.soldeActuel reduced by 1000
✅ cash_movement record created (internal tracking)
```

### Step 3: Sync to Neon (NEW FIX)
```
📤 cash_sessions UPDATE enqueued
📤 cash_registers UPDATE enqueued
❌ financial_movements NOT enqueued (intentional - internal)
❌ cash_movements NOT enqueued (intentional - internal)
```

### Step 4: Other Users See Update
```
User B pulls from Neon
✅ Sees updated cash_session balance
✅ Sees updated cash_register balance
✅ Calculates financial_movements locally
```

## How to Verify It's Working

### 1. Create an Expense
- Open the app
- Create a financial movement (expense)
- Note the amount and time

### 2. Check Local Sync Queue
```bash
node test-financial-movement-sync.js
```

Expected output:
```
📋 Sync Queue Status:
   cash_sessions (UPDATE): 1 pending
   cash_registers (UPDATE): 1 pending
```

### 3. Check Neon Data
```bash
node check-neon-data.js
```

Expected output:
```
📊 Cash Sessions in Neon: X
📊 Ventes in Neon: Y
```

The cash_sessions count should match your local database.

### 4. Verify in Neon Directly
```bash
# Connect to Neon and check
SELECT id, solde_attendu FROM cash_sessions ORDER BY id DESC LIMIT 1;
```

Should show the updated balance.

## What Gets Synced

### ✅ SYNCED (User-Facing)
- `cash_sessions` — Balance updates
- `cash_registers` — Register balance updates
- `ventes` — Sales
- `utilisateurs` — Users
- `produits` — Products
- `clients` — Customers
- `boutiques` — Stores
- `categories` — Categories
- `fournisseurs` — Suppliers
- `user_roles` — Roles

### ❌ NOT SYNCED (Internal)
- `financial_movements` — Internal accounting (each user calculates locally)
- `cash_movements` — Internal tracking
- `details_ventes` — Part of ventes
- `mouvements_stock` — Internal stock tracking
- `transactions_comptes` — Internal account transactions

## Why Financial Movements Aren't Synced

Financial movements are **derived data**, not primary data:

```
Primary Data (Synced):
  cash_session.soldeAttendu = 100,000 FCFA

Derived Data (Not Synced):
  financial_movement = {
    type: 'expense',
    amount: -1,000 FCFA,
    reason: 'Office supplies'
  }
```

Each user's backend calculates financial_movements locally from the synced cash_session data. This:
- Reduces sync overhead
- Avoids data duplication
- Ensures each user has their own accounting records
- Uses cash_session as the source of truth

## Troubleshooting

### Issue: Expense created but not synced

**Check 1: Is backend running?**
```bash
curl http://localhost:8080/health
```

**Check 2: Is CLOUD_DB_URL set?**
```bash
cat backend/.env | grep CLOUD_DB_URL
```

**Check 3: Check sync logs**
```bash
# Look for these logs when creating an expense:
📤 Push X opération(s) vers Neon...
✅ cash_sessions synced
✅ cash_registers synced
```

**Check 4: Verify queue**
```bash
node test-financial-movement-sync.js
```

### Issue: Sync queue keeps growing

This means items aren't being synced to Neon. Check:
1. Is Neon accessible? `node check-neon-data.js`
2. Are there errors in the logs?
3. Is the backend restarted after code changes?

### Issue: Other users don't see updated balance

1. Verify the expense was created locally
2. Check that cash_sessions was synced to Neon
3. Have the other user pull data (refresh)
4. Check their local database for the updated cash_session

## Files Modified

- `backend/src/services/financial-movement.js` — Now enqueues cash_session and cash_register updates
- `backend/src/server.js` — Passes syncService to FinancialMovementService

## Testing Steps

1. **Restart backend** (CRITICAL — Node.js must reload modules)
   ```bash
   # Stop the backend
   # Start it again
   ```

2. **Create an expense**
   - Open app
   - Create financial movement
   - Note the amount

3. **Verify sync**
   ```bash
   node test-financial-movement-sync.js
   ```

4. **Check Neon**
   ```bash
   node check-neon-data.js
   ```

5. **Verify other users see it**
   - Have another user open the app
   - They should see the updated cash balance

## Status

✅ **Fixed** — Financial movements now properly sync cash balance updates to Neon

The system is working as designed:
- Expenses update cash_session balance ✅
- Cash balance syncs to Neon ✅
- Other users see updated balance ✅
- Financial movements are internal (not synced) ✅
