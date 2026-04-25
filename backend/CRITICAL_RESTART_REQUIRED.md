# ⚠️ CRITICAL: Backend Restart Required

## The Problem

The backend process is still running the **OLD CODE**. The middleware changes are in the files, but Node.js has cached the old version in memory.

## The Solution

You MUST completely stop and restart the backend:

### Step 1: Stop the Backend

**In the terminal where backend is running:**
```
Press Ctrl+C
```

Wait for it to fully stop. You should see:
```
^C
(process exits)
```

### Step 2: Clear Node Cache (Important!)

```bash
# Windows PowerShell
Remove-Item -Recurse -Force node_modules\.cache -ErrorAction SilentlyContinue

# Or just delete the cache folder manually
```

### Step 3: Restart the Backend

```bash
npm start
```

You should see:
```
=== LOGESCO Backend démarrage 2026-04-25T12:XX:XX.XXXZ ===
...
☁️  Connexion Neon établie — mode hybride actif
✅ SyncService démarré
```

## Why This Matters

Node.js caches modules in memory. When you modify a file, the running process doesn't automatically reload it. You must:

1. **Stop** the process (Ctrl+C)
2. **Wait** for it to fully exit
3. **Restart** with `npm start`

## Verification

After restart, create a sale and check logs for:

```
📤 Push X opération(s) vers Neon...
```

**Should NOT see**:
- `column "nom_caisse" does not exist`
- `column "client" does not exist`

**Should see**:
- ✅ (no errors)

## If Still Having Issues

1. **Verify the middleware file was updated**:
   ```bash
   grep -n "allowedColumns" backend/src/middleware/sync-middleware.js
   ```
   Should show multiple matches

2. **Check the sync service file**:
   ```bash
   grep -n "_toSnakeCase" backend/src/services/sync-service.js
   ```
   Should show the function definition

3. **Enable debug logging**:
   ```bash
   $env:DEBUG_SYNC=1
   npm start
   ```

4. **Create a test sale** and look for:
   ```
   🔍 Sync ventes: {...}
   ```

## Common Mistakes

❌ **Don't do this**:
- Just refresh the browser (doesn't restart backend)
- Just save the file (doesn't reload Node.js)
- Run `npm start` while old process is still running (will fail on port)

✅ **Do this**:
- Press Ctrl+C to stop backend
- Wait for process to exit completely
- Run `npm start` to restart

## Timeline

- **Immediately after restart**: Middleware loads new code
- **First sale after restart**: Field filtering works
- **Within 30 seconds**: Sale appears in Neon without errors

---

**Status**: Files are updated ✅  
**Action Required**: Restart backend ⚠️
