# Fix: Financial Movements Sync Issue

## Problem

When creating a financial movement (expense), the cash_session and cash_register updates were not being synchronized to Neon. The financial_movements table itself is intentionally NOT synced (it's internal), but the cash_session balance update SHOULD be synced so other users see the updated balance.

## Root Cause

The `FinancialMovementService.updateActiveCashRegister()` method was updating:
1. ✅ `cash_session.soldeAttendu` (the expected balance)
2. ✅ `cash_register.soldeActuel` (the register balance)

But these updates were happening inside the service, not through the API route, so the sync middleware never saw them. The middleware only enqueues data when it intercepts the API response.

## Solution

Modified the `FinancialMovementService` to:

1. **Accept syncService in constructor**
   ```javascript
   constructor(prisma, syncService = null) {
     this.prisma = prisma;
     this.syncService = syncService;
   }
   ```

2. **Enqueue cash_session update after modification**
   ```javascript
   // After updating cash_session
   if (this.syncService) {
     const updatedSession = await this.prisma.cashSession.findUnique({
       where: { id: activeSession.id }
     });
     await this.syncService.enqueue('cash_sessions', 'UPDATE', updatedSession);
   }
   ```

3. **Enqueue cash_register update after modification**
   ```javascript
   // After updating cash_register
   if (this.syncService) {
     const updatedCashRegister = await this.prisma.cashRegister.findUnique({
       where: { id: activeSession.caisseId }
     });
     await this.syncService.enqueue('cash_registers', 'UPDATE', updatedCashRegister);
   }
   ```

4. **Updated server.js to pass syncService**
   ```javascript
   this.financialMovementService = new FinancialMovementService(prisma, syncService);
   ```

## What Gets Synced Now

When you create an expense:

1. ✅ **cash_session** is updated and synced
   - `soldeAttendu` is reduced
   - Other users see the updated balance

2. ✅ **cash_register** is updated and synced
   - `soldeActuel` is reduced
   - Other users see the updated register balance

3. ❌ **financial_movement** is NOT synced (intentional)
   - It's internal accounting
   - Other users calculate it locally from cash_session

## Verification

After restarting the backend:

1. Create an expense in the app
2. Check the logs for:
   ```
   📤 Push X opération(s) vers Neon...
   ✅ cash_sessions synced
   ✅ cash_registers synced
   ```

3. Verify in Neon:
   ```bash
   node check-neon-data.js
   ```
   Should show updated cash_sessions and cash_registers

## Files Modified

- `backend/src/services/financial-movement.js` — Added syncService enqueue calls
- `backend/src/server.js` — Pass syncService to FinancialMovementService

## Status

✅ Fixed — Financial movements now properly sync the cash_session and cash_register updates to Neon
