# Complete Sync Architecture — SQLite ↔ Neon

## Overview

The sync system enables bidirectional synchronization between local SQLite databases and a shared Neon PostgreSQL cloud database. This allows multiple users to work offline and automatically sync when connected.

```
┌─────────────────────────────────────────────────────────────┐
│                    NEON CLOUD (PostgreSQL)                  │
│                   (Shared by all users)                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                    ↕ (Bidirectional Sync)
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
   │ User A  │          │ User B  │          │ User C  │
   │ Backend │          │ Backend │          │ Backend │
   │ SQLite  │          │ SQLite  │          │ SQLite  │
   └─────────┘          └─────────┘          └─────────┘
```

## Components

### 1. **Sync Service** (`sync-service.js`)

Core synchronization engine with these responsibilities:

#### Initialization
- Creates local `sync_queue` and `sync_meta` tables
- Checks Neon connectivity
- Performs initial sync if Neon is empty
- Starts 30-second sync cycle

#### Push (Local → Cloud)
- Reads pending operations from `sync_queue`
- Respects foreign key dependencies (user_roles → utilisateurs → boutiques → ... → ventes)
- Converts camelCase → snake_case
- Filters out invalid/calculated fields
- Sends to Neon via parameterized queries
- Marks operations as synced

#### Pull (Cloud → Local)
- Queries Neon for changes since last sync
- Applies changes to local SQLite
- Updates `last_pull` timestamp

#### Cleanup
- Removes synced entries older than 7 days
- Prevents `sync_queue` from growing indefinitely

### 2. **Sync Middleware** (`sync-middleware.js`)

Intercepts API write operations and queues them for sync:

```
API Request (POST/PUT/PATCH/DELETE)
    ↓
Route Handler (creates/updates/deletes in SQLite)
    ↓
Response Interceptor (middleware)
    ↓
Field Filtering (allowedColumns)
    ↓
Enqueue to sync_queue
    ↓
Sync Service picks up in next cycle
```

**Key Feature**: Filters response data to only include columns that exist in PostgreSQL schema.

### 3. **Sync Queue** (Local SQLite Table)

Stores pending operations:

```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY,
  table_name TEXT,           -- 'ventes', 'cash_sessions', etc.
  operation TEXT,            -- 'INSERT', 'UPDATE', 'DELETE'
  record_id TEXT,            -- ID of the record
  data TEXT,                 -- JSON of the record
  created_at DATETIME,       -- When operation was created
  synced INTEGER,            -- 0 = pending, 1 = synced
  error TEXT                 -- Error message if failed
)
```

## Data Flow

### Online Scenario (Neon Available)

```
1. User creates sale in Flutter app
   ↓
2. Backend receives POST /api/v1/sales
   ↓
3. Route handler creates record in SQLite
   ↓
4. Middleware intercepts response
   ↓
5. Filters fields (allowedColumns)
   ↓
6. Enqueues to sync_queue
   ↓
7. Sync service picks up (immediately or in next cycle)
   ↓
8. Converts camelCase → snake_case
   ↓
9. Sends to Neon via INSERT ... ON CONFLICT
   ↓
10. Marks as synced in sync_queue
   ↓
11. Other users' backends pull changes in next cycle
   ↓
12. Sale appears in all users' local databases
```

**Timeline**: 0-30 seconds

### Offline Scenario (Neon Unavailable)

```
1. User creates sale in Flutter app
   ↓
2. Backend receives POST /api/v1/sales
   ↓
3. Route handler creates record in SQLite
   ↓
4. Middleware intercepts response
   ↓
5. Enqueues to sync_queue (synced = 0)
   ↓
6. Sync service tries to push but Neon is down
   ↓
7. Operation stays in queue (synced = 0)
   ↓
8. User continues working offline
   ↓
9. Internet restored
   ↓
10. Sync service detects Neon is available
   ↓
11. Pushes all pending operations
   ↓
12. Other users see the sale in next cycle
```

**Timeline**: Immediate locally, synced when internet restored

## Field Mapping

### Middleware Filtering

Each route has `allowedColumns` that match PostgreSQL schema:

```javascript
'/sales': {
  table: 'ventes',
  allowedColumns: [
    'id', 'numero_vente', 'client_id', 'vendeur_id', 'session_id',
    'boutique_id', 'date_vente', 'sous_total', 'montant_remise',
    'montant_tva', 'taux_tva', 'montant_total', 'statut',
    'mode_paiement', 'montant_paye', 'montant_restant'
  ]
}
```

**Result**: Only these fields are enqueued. Fields like `client`, `details`, `nomCaisse` are filtered out.

### Sync Service Conversion

The `_toSnakeCase()` method converts camelCase to snake_case:

```javascript
{
  numeroVente: "V001",      →  numero_vente: "V001"
  clientId: 5,              →  client_id: 5
  sessionId: 10,            →  session_id: 10
  montantTotal: 50000       →  montant_total: 50000
}
```

## Foreign Key Ordering

Push operations respect dependencies:

```
1. user_roles
2. utilisateurs
3. boutiques
4. categories
5. produits
6. cash_registers
7. cash_sessions
8. clients
9. fournisseurs
10. ventes (depends on cash_sessions)
```

This prevents "foreign key constraint" errors.

## Modes

### Mode 1: Local Only
- `CLOUD_DB_URL` not set
- No sync, 100% offline
- All data stays in SQLite

### Mode 2: Hybrid (Online)
- `CLOUD_DB_URL` set and Neon available
- Bidirectional sync every 30 seconds
- Neon is source of truth

### Mode 3: Offline Fallback
- `CLOUD_DB_URL` set but Neon unavailable
- Operations queued locally
- Auto-sync when connection restored

## Configuration

### Environment Variables

```bash
# Required for sync
CLOUD_DB_URL=postgresql://user:pass@host/db?sslmode=require

# Optional
SYNC_INTERVAL=30000  # milliseconds (default: 30s)
```

### Sync Cycle

```javascript
// Every 30 seconds:
1. Check Neon connectivity
2. Push pending operations
3. Pull new changes
4. Clean old queue entries
```

## Error Handling

### Push Errors
- Logged to `sync_queue.error` column
- Operation stays in queue (synced = 0)
- Retried in next cycle
- After 7 days, cleaned up

### Pull Errors
- Logged to console
- Non-blocking (doesn't stop sync)
- Retried in next cycle

### Connection Errors
- Automatically detected
- Mode switches to "offline-fallback"
- Retried every 30 seconds

## Performance

| Metric | Value |
|--------|-------|
| Sync cycle | 30 seconds |
| Queue batch size | 100 operations |
| Connection pool | 3 connections |
| Idle timeout | 10 seconds |
| Connection timeout | 5 seconds |
| Queue retention | 7 days |

## Security

- **SSL/TLS**: All Neon connections use SSL
- **Parameterized queries**: Prevents SQL injection
- **Field filtering**: Only allowed columns synced
- **No credentials in queue**: Only data, not auth tokens

## Monitoring

### Check Sync Status
```bash
curl http://localhost:8080/api/v1/sync/status
```

### Monitor Queue
```sql
-- Pending operations
SELECT COUNT(*) FROM sync_queue WHERE synced = 0;

-- Failed operations
SELECT * FROM sync_queue WHERE error IS NOT NULL;

-- Last sync time
SELECT value FROM sync_meta WHERE key = 'last_pull';
```

### View Logs
```bash
npm start 2>&1 | grep -E "📤|📥|☁️|⚠️|✅"
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "column does not exist" | Field not in allowedColumns | Add to sync-middleware.js |
| FK constraint error | Wrong push order | Check _pushLocalToCloud() ordering |
| Sync not happening | CLOUD_DB_URL not set | Check .env file |
| Offline mode not working | sync_queue table missing | Restart backend |
| Data not appearing | Neon unreachable | Check network/firewall |

## Future Enhancements

- [ ] Conflict resolution (last-write-wins vs. merge)
- [ ] Selective sync (sync only certain tables)
- [ ] Compression for large payloads
- [ ] Webhook notifications for real-time sync
- [ ] Audit trail for all synced operations
