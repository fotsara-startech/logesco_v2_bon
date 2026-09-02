# Sync Service Test Guide

## Prerequisites

1. Backend running locally with SQLite
2. Neon PostgreSQL database configured in `.env` as `CLOUD_DB_URL`
3. Flutter app connected to local backend

## Test Scenario 1: Basic Sync (Online)

### Steps
1. Start backend: `npm start`
2. Check logs for: `☁️  Connexion Neon établie — mode hybride actif`
3. In Flutter app, create a new sale
4. Check backend logs for:
   ```
   📤 Push 1 opération(s) vers Neon...
   ✅ (no errors)
   ```
5. Wait 30 seconds (sync cycle)
6. Query Neon to verify sale exists:
   ```sql
   SELECT * FROM ventes WHERE numero_vente = 'XXXX';
   ```

### Expected Result
✅ Sale appears in Neon within 30 seconds  
✅ No "column does not exist" errors  
✅ All fields properly mapped (camelCase → snake_case)

---

## Test Scenario 2: Offline Mode

### Steps
1. Backend running with Neon configured
2. **Disconnect internet** (or block Neon connection)
3. Check logs for: `⚠️  Neon inaccessible — mode offline-fallback`
4. Create a sale in Flutter app
5. Check backend logs for:
   ```
   📤 Push 1 opération(s) vers Neon...
   ⚠️  Neon inaccessible — mode offline-fallback
   ```
6. Sale is queued in `sync_queue` table (SQLite)
7. **Reconnect internet**
8. Wait 30 seconds for sync cycle
9. Check logs for:
   ```
   ☁️  Connexion Neon établie — mode hybride actif
   📤 Push 1 opération(s) vers Neon...
   ✅ (synced)
   ```

### Expected Result
✅ Sale queued locally when offline  
✅ Sale synced to Neon when connection restored  
✅ No data loss

---

## Test Scenario 3: Multi-User Sync

### Steps
1. **User A**: Create a sale on backend A
2. **User B**: Check if sale appears in their local database within 30 seconds
3. **User B**: Create a sale on backend B
4. **User A**: Check if sale appears in their local database within 30 seconds

### Expected Result
✅ Both users see each other's sales within 30 seconds  
✅ Bidirectional sync works correctly

---

## Test Scenario 4: Field Filtering

### Steps
1. Create a sale with all fields
2. Check `sync_queue` table:
   ```sql
   SELECT data FROM sync_queue WHERE table_name = 'ventes' LIMIT 1;
   ```
3. Verify only allowed columns are present (no `client`, `details`, `nomCaisse`, etc.)

### Expected Result
✅ Only valid PostgreSQL columns in queue  
✅ No extra/calculated fields

---

## Debugging

### Check Sync Queue Status
```sql
-- SQLite (local)
SELECT * FROM sync_queue WHERE synced = 0;
```

### Check Sync Errors
```sql
-- SQLite (local)
SELECT id, table_name, error FROM sync_queue WHERE error IS NOT NULL;
```

### Monitor Sync Cycle
```bash
# Watch backend logs
npm start 2>&1 | grep -E "📤|📥|☁️|⚠️"
```

### Verify Data in Neon
```sql
-- PostgreSQL (Neon)
SELECT COUNT(*) FROM ventes;
SELECT COUNT(*) FROM cash_sessions;
SELECT COUNT(*) FROM utilisateurs;
```

---

## Common Issues & Solutions

### Issue: "column does not exist"
**Cause**: Field not in `allowedColumns` array  
**Solution**: Check `sync-middleware.js` and add missing column to the route's `allowedColumns`

### Issue: Foreign key constraint violations
**Cause**: Parent table not synced before child table  
**Solution**: Check `_pushLocalToCloud()` ordering in `sync-service.js`

### Issue: Sync not happening
**Cause**: `CLOUD_DB_URL` not set or Neon unreachable  
**Solution**: 
- Check `.env` file has valid `CLOUD_DB_URL`
- Test Neon connection: `psql $CLOUD_DB_URL -c "SELECT 1"`

### Issue: Offline mode not working
**Cause**: `sync_queue` table not created  
**Solution**: Restart backend to trigger `_createLocalTables()`

---

## Performance Notes

- **Sync cycle**: 30 seconds (configurable in `initialize()`)
- **Queue batch size**: 100 operations per cycle
- **Queue cleanup**: Removes synced entries older than 7 days
- **Connection pool**: Max 3 connections to Neon

## Monitoring

Check sync status via API:
```bash
curl http://localhost:8080/api/v1/sync/status
```

Response:
```json
{
  "cloudEnabled": true,
  "cloudAvailable": true,
  "mode": "hybrid"
}
```
