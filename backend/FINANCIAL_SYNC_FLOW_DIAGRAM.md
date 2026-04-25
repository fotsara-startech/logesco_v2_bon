# Financial Movements Sync Flow Diagram

## Before Fix (Broken)

```
User Creates Expense
    ↓
POST /api/v1/financial-movements
    ↓
FinancialMovementService.createMovement()
    ├─ Create financial_movement ✅
    ├─ Update cash_session.soldeAttendu ✅
    ├─ Update cash_register.soldeActuel ✅
    └─ Create cash_movement ✅
    ↓
Response sent to client ✅
    ↓
Sync Middleware intercepts response
    ├─ Enqueues financial_movement ❌ (marked skip: true)
    └─ Does NOT enqueue cash_session ❌ (not in response)
    └─ Does NOT enqueue cash_register ❌ (not in response)
    ↓
Sync Queue is EMPTY ❌
    ↓
Neon is NOT updated ❌
    ↓
Other users DON'T see updated balance ❌
```

## After Fix (Working)

```
User Creates Expense
    ↓
POST /api/v1/financial-movements
    ↓
FinancialMovementService.createMovement()
    ├─ Create financial_movement ✅
    ├─ Update cash_session.soldeAttendu ✅
    │  └─ Enqueue cash_sessions UPDATE ✅ (NEW)
    ├─ Update cash_register.soldeActuel ✅
    │  └─ Enqueue cash_registers UPDATE ✅ (NEW)
    └─ Create cash_movement ✅
    ↓
Response sent to client ✅
    ↓
Sync Middleware intercepts response
    ├─ Enqueues financial_movement ❌ (marked skip: true - intentional)
    └─ Does NOT enqueue cash_session ✅ (already enqueued in service)
    └─ Does NOT enqueue cash_register ✅ (already enqueued in service)
    ↓
Sync Queue has 2 items ✅
    ├─ cash_sessions UPDATE
    └─ cash_registers UPDATE
    ↓
Sync Cycle (every 30 seconds)
    ├─ Reads queue items
    ├─ Sends to Neon
    └─ Marks as synced
    ↓
Neon is UPDATED ✅
    ├─ cash_sessions.solde_attendu reduced
    └─ cash_registers.solde_actuel reduced
    ↓
Other users pull from Neon
    ├─ Get updated cash_sessions
    ├─ Get updated cash_registers
    └─ See updated balance ✅
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         LOCAL (SQLite)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User Creates Expense                                           │
│         ↓                                                       │
│  FinancialMovementService                                       │
│    ├─ Create financial_movement                                │
│    ├─ Update cash_session.soldeAttendu                         │
│    │  └─ Enqueue: cash_sessions UPDATE                         │
│    ├─ Update cash_register.soldeActuel                         │
│    │  └─ Enqueue: cash_registers UPDATE                        │
│    └─ Create cash_movement                                     │
│         ↓                                                       │
│  sync_queue table                                               │
│    ├─ [1] cash_sessions UPDATE (synced=0)                      │
│    └─ [2] cash_registers UPDATE (synced=0)                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
                    Sync Cycle (30s)
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                      NEON (PostgreSQL)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  cash_sessions                                                  │
│    ├─ id: 52                                                   │
│    ├─ solde_attendu: 185778 (UPDATED) ✅                       │
│    └─ ...                                                      │
│                                                                 │
│  cash_registers                                                │
│    ├─ id: 7                                                    │
│    ├─ solde_actuel: 185778 (UPDATED) ✅                        │
│    └─ ...                                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
                    Other Users Pull
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    OTHER USER (SQLite)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Sync Pull from Neon                                            │
│    ├─ Get updated cash_sessions                                │
│    ├─ Get updated cash_registers                               │
│    └─ Update local database                                    │
│         ↓                                                       │
│  User sees updated balance ✅                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Sequence Diagram

```
User          App          Backend         SyncService      Neon
 │             │              │                 │            │
 ├─Create───────→              │                 │            │
 │  Expense     │              │                 │            │
 │             │              │                 │            │
 │             ├─POST /api/v1/financial-movements            │
 │             │              │                 │            │
 │             │    FinancialMovementService    │            │
 │             │    ├─Create financial_movement│            │
 │             │    ├─Update cash_session      │            │
 │             │    │  └─Enqueue UPDATE ──────→│            │
 │             │    ├─Update cash_register     │            │
 │             │    │  └─Enqueue UPDATE ──────→│            │
 │             │    └─Create cash_movement    │            │
 │             │              │                 │            │
 │             │←─Response────│                 │            │
 │             │              │                 │            │
 │             │              │    Sync Cycle (30s)          │
 │             │              │    ├─Read queue ────────────→│
 │             │              │    ├─Send updates           │
 │             │              │    └─Mark synced ←──────────│
 │             │              │                 │            │
 │             │              │                 │    Neon Updated
 │             │              │                 │    ✅ cash_sessions
 │             │              │                 │    ✅ cash_registers
 │             │              │                 │            │
 │             │    Pull from Neon             │            │
 │             ├─────────────────────────────────────────────→│
 │             │←─Updated data ────────────────────────────────│
 │             │              │                 │            │
 │←─Updated────│              │                 │            │
 │  Balance    │              │                 │            │
 │             │              │                 │            │
```

## Key Points

1. **Before Fix**: Cash updates happened in service but weren't enqueued
2. **After Fix**: Cash updates are enqueued immediately after modification
3. **Sync Cycle**: Picks up queue items every 30 seconds
4. **Neon Update**: Happens within 30 seconds of expense creation
5. **Other Users**: See updated balance after pulling from Neon

## What's NOT Synced (Intentional)

```
financial_movements (Internal)
    ├─ Not synced to Neon
    ├─ Each user calculates locally
    └─ Derived from cash_session data

cash_movements (Internal)
    ├─ Not synced to Neon
    ├─ Internal tracking only
    └─ Not user-facing
```

## What IS Synced (Now Working)

```
cash_sessions (User-Facing)
    ├─ Synced to Neon ✅
    ├─ Other users see updated balance
    └─ Source of truth for cash

cash_registers (User-Facing)
    ├─ Synced to Neon ✅
    ├─ Other users see updated register balance
    └─ Tracks register state
```

---

**Status**: ✅ Fix Complete

The financial movements sync is now working correctly. Cash balance updates are properly enqueued and synced to Neon.
