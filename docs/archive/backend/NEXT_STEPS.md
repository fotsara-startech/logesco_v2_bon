# Next Steps — Sync Service Testing

## What Was Done

✅ Fixed field mapping issues in sync middleware  
✅ Improved field filtering in sync service  
✅ Added comprehensive documentation  
✅ Created test script to verify fixes  

## What You Need to Do

### Step 1: Restart Backend

The middleware changes require a fresh start:

```bash
# Stop current backend (Ctrl+C)
# Then restart:
npm start
```

You should see:
```
☁️  Connexion Neon établie — mode hybride actif
✅ SyncService démarré
```

### Step 2: Test with a Sale

1. Open Flutter app
2. Create a new sale (any product, any amount)
3. Check backend logs for:

```
🔍 Sync ventes: {...}
📤 Push 1 opération(s) vers Neon...
```

**Expected**: No errors, sale synced within 30 seconds

### Step 3: Verify in Neon

```bash
# Check if sale appears in Neon
psql $CLOUD_DB_URL -c "SELECT id, numero_vente, montant_total FROM ventes ORDER BY id DESC LIMIT 1;"
```

**Expected**: Sale appears with all fields populated

### Step 4: Test Offline Mode (Optional)

1. Disconnect internet (or block Neon connection)
2. Create another sale
3. Check backend logs for: `⚠️  Neon inaccessible — mode offline-fallback`
4. Reconnect internet
5. Wait 30 seconds
6. Check logs for: `📤 Push X opération(s) vers Neon...`
7. Verify sale appears in Neon

## Troubleshooting

### If You See: `column "nom_caisse" does not exist`

**Solution**: Restart backend
```bash
npm start
```

The middleware changes need to be reloaded.

### If You See: `null value in column "numero_vente"`

**Debugging**:
```bash
# Enable debug logging
export DEBUG_SYNC=1
npm start

# Create a sale and check if numeroVente is in the sync data
# Look for: 🔍 Sync ventes: {...}
```

If `numeroVente` is missing, check:
1. `backend/src/utils/transformers.js` — `generateSaleNumber()` function
2. `backend/src/routes/sales.js` — Line 684, verify `numeroVente` is passed to `vente.create()`

### If You See: Foreign Key Constraint Errors

**Debugging**:
```sql
-- Check if cash_sessions exist in Neon
SELECT COUNT(*) FROM cash_sessions;

-- Check sync queue for pending operations
SELECT table_name, COUNT(*) FROM sync_queue WHERE synced = 0 GROUP BY table_name;
```

The sync service should push `cash_sessions` before `ventes`. If not, check the ordering in `_pushLocalToCloud()`.

## Verification Checklist

- [ ] Backend restarted
- [ ] Sale created in Flutter app
- [ ] No "column does not exist" errors in logs
- [ ] Sale appears in Neon within 30 seconds
- [ ] All fields populated (not null)
- [ ] Offline mode works (optional)

## Documentation

For more details, see:
- `SYNC_FIX_SUMMARY.md` — What was fixed
- `SYNC_DEBUG_GUIDE.md` — Debugging procedures
- `SYNC_TEST_GUIDE.md` — Detailed testing scenarios
- `SYNC_ARCHITECTURE_COMPLETE.md` — Full architecture

## Quick Test Script

To verify field filtering is working:
```bash
node test-sync-middleware.js
```

Should show:
```
✅ PASSED: No unwanted fields
```

## Support

If issues persist:

1. **Check logs**: `npm start 2>&1 | grep -E "📤|⚠️|✅"`
2. **Check queue**: `SELECT * FROM sync_queue WHERE synced = 0 LIMIT 5;`
3. **Check Neon**: `SELECT COUNT(*) FROM ventes;`
4. **Enable debug**: `export DEBUG_SYNC=1 && npm start`

## Expected Timeline

- **Immediate**: Field filtering working, no "column does not exist" errors
- **Within 30 seconds**: Sale appears in Neon
- **Offline mode**: Operations queued, synced when connection restored

---

**Status**: Ready for testing ✅

The sync service is now properly filtering fields and should work reliably. Restart the backend and test with a sale to verify.
