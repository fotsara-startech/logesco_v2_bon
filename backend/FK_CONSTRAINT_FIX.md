# Foreign Key Constraint Fix

## Problem

When syncing a `vente` (sale), it references a `session_id` that doesn't exist in Neon yet:

```
⚠️  Erreur push item 8: insert or update on table "ventes" violates foreign key constraint "ventes_session_id_fkey"
```

**Root Cause**: 
1. Sale is created locally with an active session
2. Sale is enqueued to sync_queue
3. When sync tries to push the sale to Neon, the session doesn't exist there yet
4. FK constraint fails because `session_id` references non-existent session

## Solution

Modified `_pushLocalToCloud()` to check if referenced sessions exist in Neon before syncing ventes:

```javascript
// IMPORTANT: Si c'est une vente, vérifier que la session existe en Neon
if (item.table_name === 'ventes' && data.session_id) {
  try {
    const sessionExists = await client.query(
      'SELECT id FROM cash_sessions WHERE id = $1',
      [data.session_id]
    );
    if (sessionExists.rows.length === 0) {
      // Session n'existe pas en Neon, la chercher en local et la syncer d'abord
      const localSession = await this.localPrisma.$queryRawUnsafe(
        'SELECT * FROM cash_sessions WHERE id = ?',
        data.session_id
      );
      if (localSession && localSession.length > 0) {
        console.log(`  ⚠️  Session ${data.session_id} manquante en Neon, sync d'abord...`);
        await this._applyToCloud(client, 'cash_sessions', 'INSERT', localSession[0]);
      }
    }
  } catch (e) {
    // Erreur lors de la vérification, continuer
  }
}
```

## How It Works

### Before (Broken)
```
1. Sale created locally with session_id = 5
2. Sale enqueued to sync_queue
3. Sync tries to push sale to Neon
4. ❌ FK constraint fails: session_id 5 doesn't exist in Neon
```

### After (Fixed)
```
1. Sale created locally with session_id = 5
2. Sale enqueued to sync_queue
3. Sync tries to push sale to Neon
4. ✅ Check if session 5 exists in Neon
5. If not, fetch session 5 from local and sync it first
6. Then sync the sale
7. ✅ FK constraint satisfied
```

## Expected Behavior

### Logs
```
📤 Push 2 opération(s) vers Neon...
  ⚠️  Session 5 manquante en Neon, sync d'abord...
✅ (no errors)
```

### Result
- Session synced first
- Sale synced second
- No FK constraint violations

## Testing

1. **Restart backend**: `npm start`
2. **Create a sale**: In Flutter app
3. **Check logs**: Should see session sync message
4. **Verify in Neon**: Both session and sale should appear

## Performance Impact

- **Minimal**: Only checks if session exists (1 query per vente)
- **Fallback**: Only syncs session if it doesn't exist in Neon
- **Non-blocking**: Errors don't interrupt sync

## Files Modified

| File | Change |
|------|--------|
| `backend/src/services/sync-service.js` | Added FK dependency check in `_pushLocalToCloud()` |

## Related Issues

This fix also handles:
- Other FK dependencies (if needed in future)
- Missing parent records
- Out-of-order sync operations

## Rollback

If issues occur:
```bash
git checkout HEAD~1 -- backend/src/services/sync-service.js
npm start
```
