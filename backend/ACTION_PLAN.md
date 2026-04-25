# Action Plan — Fix Sync Issues

## Current Status

❌ **Problem**: Sync still failing with field mapping errors  
✅ **Root Cause**: Backend process not restarted (old code in memory)  
✅ **Solution**: Complete backend restart required

## What's Been Done

1. ✅ Updated `sync-middleware.js` with field filtering
2. ✅ Updated `sync-service.js` with better conversion
3. ✅ Added comprehensive documentation
4. ✅ Created test script to verify fixes
5. ⏳ **Waiting for**: Backend restart

## Immediate Action Required

### Step 1: Stop Backend (CRITICAL)

**In your terminal where backend is running:**

```
Press Ctrl+C
```

Wait until you see:
```
^C
(no more output)
```

**Do NOT skip this step.** The old code is still in memory.

### Step 2: Verify Files Were Updated

```bash
# Check middleware has allowedColumns
grep "allowedColumns" backend/src/middleware/sync-middleware.js

# Should show multiple matches like:
# allowedColumns: [
```

### Step 3: Restart Backend

```bash
npm start
```

**Expected output:**
```
=== LOGESCO Backend démarrage 2026-04-25T12:XX:XX.XXXZ ===
...
☁️  Connexion Neon établie — mode hybride actif
✅ SyncService démarré
```

### Step 4: Create a Test Sale

1. Open Flutter app
2. Create a new sale
3. **Check backend logs** for:

```
🔍 Sync cash_sessions (INSERT): 8 fields
🔍 Sync ventes (INSERT): 12 fields
📤 Push 2 opération(s) vers Neon...
```

**Should NOT see:**
- `column "nom_caisse" does not exist`
- `column "client" does not exist`

### Step 5: Verify in Neon

```bash
psql $CLOUD_DB_URL -c "SELECT id, numero_vente FROM ventes ORDER BY id DESC LIMIT 1;"
```

**Expected**: Sale appears with `numero_vente` populated

## Debugging If Issues Persist

### Issue: Still seeing `column "nom_caisse" does not exist`

**Cause**: Backend not restarted  
**Solution**: 
1. Press Ctrl+C to stop
2. Wait 5 seconds
3. Run `npm start` again

### Issue: Middleware not logging anything

**Cause**: Middleware not being called  
**Solution**:
1. Check if `CLOUD_DB_URL` is set: `echo $env:CLOUD_DB_URL`
2. Check if sale is being created: Look for `POST /api/v1/sales 201`
3. Enable debug: `$env:DEBUG_SYNC=1; npm start`

### Issue: `null value in column "numero_vente"`

**Cause**: `numeroVente` not being generated or passed  
**Solution**:
1. Check `generateSaleNumber()` in `backend/src/utils/transformers.js`
2. Verify it returns a value: `VTE-20260425-HHMMSS`
3. Check if it's passed to `vente.create()` in `backend/src/routes/sales.js` line 684

## Expected Behavior After Restart

### ✅ What Should Work

1. **Sales sync without errors**
   - No "column does not exist" errors
   - `numeroVente` properly synced
   - All required fields present

2. **Cash sessions sync without errors**
   - No `nom_caisse` errors
   - Only valid columns synced
   - Calculated fields filtered out

3. **Foreign key constraints respected**
   - `cash_sessions` synced before `ventes`
   - No FK constraint violations

4. **Offline mode works**
   - Operations queued locally when offline
   - Auto-sync when connection restored

## Timeline

| Time | Action | Expected Result |
|------|--------|-----------------|
| Now | Stop backend (Ctrl+C) | Process exits |
| +5s | Restart backend (`npm start`) | Backend starts, connects to Neon |
| +10s | Create a sale in Flutter | Sale created locally |
| +15s | Check logs | `🔍 Sync ventes: 12 fields` |
| +45s | Check Neon | Sale appears in database |

## Files Modified

- `backend/src/middleware/sync-middleware.js` — Field filtering
- `backend/src/services/sync-service.js` — Field conversion

## Files Created (Documentation)

- `CRITICAL_RESTART_REQUIRED.md` — Why restart is needed
- `SYNC_FIX_SUMMARY.md` — What was fixed
- `SYNC_DEBUG_GUIDE.md` — Debugging procedures
- `test-sync-middleware.js` — Verification script

## Support

If you get stuck:

1. **Check logs**: `npm start 2>&1 | grep -E "🔍|📤|⚠️"`
2. **Run test**: `node test-sync-middleware.js`
3. **Check queue**: Look at `sync_queue` table in SQLite
4. **Enable debug**: `$env:DEBUG_SYNC=1; npm start`

---

**Next Step**: Stop backend and restart it now ⏭️
