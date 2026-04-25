# Changes Summary — Financial Movements Sync Fix

## Problem Statement

When creating a financial movement (expense), the cash_session and cash_register balance updates were not being synchronized to Neon. This meant:
- ❌ Other users didn't see the updated cash balance
- ❌ The sync queue showed no entries for these updates
- ❌ Neon data was out of sync with local data

## Root Cause Analysis

The `FinancialMovementService.updateActiveCashRegister()` method was:
1. Updating `cash_session.soldeAttendu` in the database
2. Updating `cash_register.soldeActuel` in the database

But these updates happened **inside the service**, not through the API route. The sync middleware only intercepts API responses, so it never saw these updates and never enqueued them.

## Solution Implemented

### Change 1: Update FinancialMovementService Constructor

**File**: `backend/src/services/financial-movement.js`

**Before**:
```javascript
class FinancialMovementService {
  constructor(prisma) {
    this.prisma = prisma;
  }
}
```

**After**:
```javascript
class FinancialMovementService {
  constructor(prisma, syncService = null) {
    this.prisma = prisma;
    this.syncService = syncService;
  }
}
```

**Why**: The service now has access to syncService to enqueue updates.

### Change 2: Enqueue Cash Session Update

**File**: `backend/src/services/financial-movement.js` in `updateActiveCashRegister()`

**Before**:
```javascript
// Mettre à jour le soldeAttendu de la session (même si négatif)
await this.prisma.cashSession.update({
  where: { id: activeSession.id },
  data: {
    soldeAttendu: newSoldeAttendu
  }
});
```

**After**:
```javascript
// Mettre à jour le soldeAttendu de la session (même si négatif)
await this.prisma.cashSession.update({
  where: { id: activeSession.id },
  data: {
    soldeAttendu: newSoldeAttendu
  }
});

// Enqueue la mise à jour de la session pour sync
if (this.syncService) {
  const updatedSession = await this.prisma.cashSession.findUnique({
    where: { id: activeSession.id }
  });
  await this.syncService.enqueue('cash_sessions', 'UPDATE', updatedSession);
}
```

**Why**: After updating the cash_session, we enqueue it so the sync service picks it up and sends it to Neon.

### Change 3: Enqueue Cash Register Update

**File**: `backend/src/services/financial-movement.js` in `updateActiveCashRegister()`

**Before**:
```javascript
// Mettre à jour le solde de la caisse (réduire, même si négatif)
await this.prisma.cashRegister.update({
  where: { id: activeSession.caisseId },
  data: {
    soldeActuel: {
      decrement: parseFloat(montant)
    }
  }
});

console.log(`✅ Caisse ${activeSession.caisse.nom} mise à jour: -${montant} FCFA (solde réduit)`);
```

**After**:
```javascript
// Mettre à jour le solde de la caisse (réduire, même si négatif)
await this.prisma.cashRegister.update({
  where: { id: activeSession.caisseId },
  data: {
    soldeActuel: {
      decrement: parseFloat(montant)
    }
  }
});

// Enqueue la mise à jour de la caisse pour sync
if (this.syncService) {
  const updatedCashRegister = await this.prisma.cashRegister.findUnique({
    where: { id: activeSession.caisseId }
  });
  await this.syncService.enqueue('cash_registers', 'UPDATE', updatedCashRegister);
}

console.log(`✅ Caisse ${activeSession.caisse.nom} mise à jour: -${montant} FCFA (solde réduit)`);
```

**Why**: After updating the cash_register, we enqueue it so the sync service picks it up and sends it to Neon.

### Change 4: Pass SyncService to FinancialMovementService

**File**: `backend/src/server.js`

**Before**:
```javascript
// Services pour les mouvements financiers
this.financialMovementService = new FinancialMovementService(prisma);
```

**After**:
```javascript
// Services pour les mouvements financiers
this.financialMovementService = new FinancialMovementService(prisma, syncService);
```

**Why**: The FinancialMovementService now receives syncService so it can enqueue updates.

## Impact

### What Now Gets Synced

When you create an expense:

1. ✅ **cash_sessions** UPDATE is enqueued
   - `soldeAttendu` is reduced
   - Synced to Neon within 30 seconds
   - Other users see updated balance

2. ✅ **cash_registers** UPDATE is enqueued
   - `soldeActuel` is reduced
   - Synced to Neon within 30 seconds
   - Other users see updated register balance

3. ❌ **financial_movements** is NOT synced (intentional)
   - It's internal accounting
   - Each user calculates it locally from cash_session

### Verification

After restarting the backend and creating an expense, you should see:

```
📤 Push X opération(s) vers Neon...
✅ cash_sessions synced
✅ cash_registers synced
```

And in Neon:
```bash
node check-neon-data.js
# Should show updated cash_sessions
```

## Files Modified

1. `backend/src/services/financial-movement.js`
   - Added syncService parameter to constructor
   - Added enqueue calls for cash_session update
   - Added enqueue calls for cash_register update

2. `backend/src/server.js`
   - Pass syncService to FinancialMovementService constructor

## Testing

1. **Restart backend** (CRITICAL)
2. **Create an expense** in the app
3. **Check logs** for sync messages
4. **Verify Neon** with `node check-neon-data.js`
5. **Test multi-user** — have another user see the updated balance

## Status

✅ **Complete** — Financial movements now properly sync cash balance updates to Neon

## Notes

- The fix is backward compatible (syncService is optional)
- If syncService is not provided, the service still works (just doesn't sync)
- The 30-second sync cycle means updates appear in Neon within 30 seconds
- Financial movements themselves are NOT synced (by design) — only the cash balance
