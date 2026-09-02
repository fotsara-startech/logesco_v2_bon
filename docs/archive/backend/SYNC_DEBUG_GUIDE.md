# Sync Service Debugging Guide

## Current Issues & Solutions

### Issue 1: `column "nom_caisse" does not exist`

**Root Cause**: The cash-sessions route returns `nomCaisse` (calculated field from `caisse.nom`), but PostgreSQL schema only has `caisse_id`.

**Solution**: The middleware now filters this out via `allowedColumns`. Only these fields are synced:
- `id`, `caisse_id`, `utilisateur_id`, `boutique_id`, `solde_ouverture`, `solde_fermeture`, `date_ouverture`, `date_fermeture`, `is_active`, `metadata`, `solde_attendu`, `ecart`

**Verification**:
```bash
# Enable debug logging
export DEBUG_SYNC=1
npm start

# Look for: 🔍 Sync cash_sessions: {...}
# Should NOT contain: nomCaisse, nomUtilisateur
```

---

### Issue 2: `null value in column "numero_vente"`

**Root Cause**: The `numeroVente` field is null when synced to PostgreSQL.

**Possible Causes**:
1. `generateSaleNumber()` returns null
2. `numeroVente` is not being passed to `vente.create()`
3. Response data doesn't include `numeroVente`

**Debugging Steps**:

1. Check if `numeroVente` is generated:
```javascript
// In sales.js, add logging
const numeroVente = await generateSaleNumber(prisma);
console.log('Generated numeroVente:', numeroVente);
```

2. Check if it's in the response:
```bash
export DEBUG_SYNC=1
npm start

# Look for: 🔍 Sync ventes: {...}
# Should contain: numeroVente: "VTE-20260425-..."
```

3. Check the sync_queue directly:
```sql
SELECT data FROM sync_queue WHERE table_name = 'ventes' LIMIT 1;
-- Should show: {"id":298,"numeroVente":"VTE-...","clientId":null,...}
```

---

### Issue 3: Foreign Key Constraint Violations

**Error**: `insert or update on table "ventes" violates foreign key constraint "ventes_session_id_fkey"`

**Root Cause**: `cash_sessions` not synced before `ventes`.

**Solution**: The sync service respects this order:
```
1. user_roles
2. utilisateurs
3. boutiques
4. categories
5. produits
6. cash_registers
7. cash_sessions  ← Must sync before ventes
8. clients
9. fournisseurs
10. ventes        ← Depends on cash_sessions
```

**Verification**:
```sql
-- Check if cash_sessions exists in Neon
SELECT COUNT(*) FROM cash_sessions;

-- Check if ventes references valid session_id
SELECT v.id, v.session_id, cs.id 
FROM ventes v 
LEFT JOIN cash_sessions cs ON v.session_id = cs.id 
WHERE cs.id IS NULL LIMIT 5;
```

---

## Debugging Workflow

### Step 1: Enable Debug Logging

```bash
export DEBUG_SYNC=1
npm start
```

This will show:
- `🔍 Sync [table]: {...}` — What's being enqueued
- `📤 Push X opération(s) vers Neon...` — Push attempt
- `⚠️  Erreur push item X: ...` — Errors

### Step 2: Check Local Queue

```sql
-- SQLite (local)
SELECT id, table_name, operation, synced, error, data 
FROM sync_queue 
WHERE synced = 0 
LIMIT 5;
```

Look for:
- `synced = 0` → Pending
- `error IS NOT NULL` → Failed
- `data` → What's being sent

### Step 3: Verify Field Mapping

```sql
-- Check what's in the queue
SELECT json_extract(data, '$.nomCaisse') as nom_caisse_field
FROM sync_queue 
WHERE table_name = 'cash_sessions' 
LIMIT 1;

-- Should be NULL (field filtered out)
```

### Step 4: Check Neon Data

```sql
-- PostgreSQL (Neon)
SELECT * FROM cash_sessions LIMIT 1;
SELECT * FROM ventes LIMIT 1;

-- Check for NULL values
SELECT id, numero_vente FROM ventes WHERE numero_vente IS NULL;
```

### Step 5: Monitor Sync Cycle

```bash
# Watch logs in real-time
npm start 2>&1 | grep -E "📤|📥|☁️|⚠️|✅|🔍"
```

---

## Common Debugging Commands

### Check Sync Status
```bash
curl http://localhost:8080/api/v1/sync/status
```

### View Queue Size
```sql
SELECT COUNT(*) as pending FROM sync_queue WHERE synced = 0;
SELECT COUNT(*) as failed FROM sync_queue WHERE error IS NOT NULL;
```

### Clear Failed Queue Entries
```sql
DELETE FROM sync_queue WHERE error IS NOT NULL;
```

### Reset Sync (Dangerous!)
```sql
DELETE FROM sync_queue;
DELETE FROM sync_meta;
```

### Check Last Sync Time
```sql
SELECT value FROM sync_meta WHERE key = 'last_pull';
```

---

## Field Mapping Reference

### ventes (Sales)
| API Response | PostgreSQL | Status |
|---|---|---|
| `id` | `id` | ✓ Synced |
| `numeroVente` | `numero_vente` | ✓ Synced |
| `clientId` | `client_id` | ✓ Synced |
| `vendeurId` | `vendeur_id` | ✓ Synced |
| `sessionId` | `session_id` | ✓ Synced |
| `client` | ❌ FILTERED | Relation |
| `details` | ❌ FILTERED | Relation |

### cash_sessions
| API Response | PostgreSQL | Status |
|---|---|---|
| `id` | `id` | ✓ Synced |
| `caisseId` | `caisse_id` | ✓ Synced |
| `utilisateurId` | `utilisateur_id` | ✓ Synced |
| `nomCaisse` | ❌ FILTERED | Calculated |
| `nomUtilisateur` | ❌ FILTERED | Calculated |

---

## Testing Sync End-to-End

### Test 1: Simple Sale Sync

```bash
# Terminal 1: Start backend with debug
export DEBUG_SYNC=1
npm start

# Terminal 2: Create a sale via API
curl -X POST http://localhost:8080/api/v1/sales \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "details": [{"produitId": 1, "quantite": 1, "prixUnitaire": 5000}],
    "montantVerse": 5000,
    "modeDeTermine": "comptant"
  }'

# Terminal 1: Watch for:
# 1. 🔍 Sync ventes: {...}
# 2. 📤 Push 1 opération(s) vers Neon...
# 3. ✅ (no errors)

# Terminal 3: Check Neon
psql $CLOUD_DB_URL -c "SELECT id, numero_vente FROM ventes ORDER BY id DESC LIMIT 1;"
```

### Test 2: Offline Mode

```bash
# 1. Start backend
npm start

# 2. Block Neon connection (firewall or disconnect internet)

# 3. Create a sale
# → Should queue locally (synced = 0)

# 4. Restore connection

# 5. Wait 30 seconds for sync cycle

# 6. Check Neon
# → Sale should appear
```

---

## Performance Monitoring

### Queue Growth
```sql
SELECT COUNT(*) FROM sync_queue;
-- Should stay < 1000 (cleanup runs every 30s)
```

### Sync Cycle Duration
```bash
# Look for timing in logs
npm start 2>&1 | grep "Push\|Pull"
# Should complete in < 5 seconds
```

### Error Rate
```sql
SELECT 
  COUNT(*) as total,
  SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) as failed,
  ROUND(100.0 * SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate
FROM sync_queue;
```

---

## Troubleshooting Checklist

- [ ] Backend restarted after code changes
- [ ] `CLOUD_DB_URL` set in `.env`
- [ ] Neon connection working: `psql $CLOUD_DB_URL -c "SELECT 1"`
- [ ] `sync_queue` table exists: `SELECT COUNT(*) FROM sync_queue`
- [ ] No pending errors: `SELECT COUNT(*) FROM sync_queue WHERE error IS NOT NULL`
- [ ] Last sync recent: `SELECT value FROM sync_meta WHERE key = 'last_pull'`
- [ ] Sync cycle running: Look for `📤 Push` in logs every 30s
