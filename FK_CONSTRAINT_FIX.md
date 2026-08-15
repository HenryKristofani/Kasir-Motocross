# 🔐 Foreign Key Constraint Fix - Transaction Items 409 Error

## 📋 Problem Diagnosis

**Error Reported:**
```
transaction_items → 409 CONFLICT foreign key constraint category_id_fkey
```

**Root Causes Identified:**

### 1. **Missing Category Dependencies**
- `transaction_items` mencoba refer ke `category_id` yang TIDAK ada di tabel remote `ticket_categories`
- Kemungkinan: Kategori gagal sync ke Supabase karena error `quota NOT NULL` sebelumnya
- Kategori mungkin sudah tercatat `isSynced: true` padahal sebenarnya tidak ada di remote

### 2. **No FK Validation Before Insert**
- Sync langsung coba insert items tanpa verifikasi parent records ada di Supabase
- Tidak ada pengecekan kategori & transaksi exist sebelum insert item

### 3. **Wrong Sync Dependency Order**
- Sebelumnya sync order tidak ketat → items bisa coba sync sebelum parents berhasil
- Transaction items = child dari:
  - `transaction_id` → transactions table (parent 1)
  - `category_id` → ticket_categories table (parent 2)

### 4. **No Force Re-sync Mechanism**
- Kategori yang sudah `isSynced: true` tidak bisa di-retry
- Jika 1 kategori gagal tapi tercatat success, tidak ada cara reset ulang

---

## ✅ Solutions Implemented

### 1. **Strict Dependency Order Enforcement**

**New Sync Sequence (KETAT):**

```dart
STEP 1: _syncTicketCategories()
        ↓ (MUST succeed - if fail, stop chain)
        
STEP 2: _syncTransactions()
        ↓ (parent of items)
        
STEP 3: _verifyAndSyncTransactionItems()  // NEW!
        ├─ Cek: Apakah semua categories ada di remote?
        ├─ Cek: Apakah semua parent transactions ada di remote?
        └─ Hanya sync items jika BOTH parents verified
        
STEP 4: _syncShiftReconciliations()
        (independent, proceed regardless)
```

### 2. **FK Validation Before Insert**

**New Method: `_verifyAndSyncTransactionItems()`**

```dart
// Query Supabase untuk daftar semua categories & transactions
final remoteCategories = await _supabase
    .from('ticket_categories')
    .select('id')
    .then((data) => (data as List).map((row) => row['id'] as String).toSet());

final remoteTransactions = await _supabase
    .from('transactions')
    .select('id')
    .then((data) => (data as List).map((row) => row['id'] as String).toSet());

// Per-item validation
for (final item in unsynced) {
  if (!remoteCategories.contains(item.categoryId)) {
    // Skip! Category tidak ada di remote
    developer.log('[SyncService] ⚠️ Skipping item: category not found in Supabase');
    continue;
  }
  
  if (!remoteTransactions.contains(item.transactionId)) {
    // Skip! Transaction tidak ada di remote
    developer.log('[SyncService] ⚠️ Skipping item: transaction not found in Supabase');
    continue;
  }
  
  // Safe to insert
  await _supabase.from('transaction_items').insert({...});
}
```

**Benefit:**
- ✅ Tidak ada 409 FK errors lagi
- ✅ Items yang orphan di-skip, tidak throw error
- ✅ Log detail kenapa item di-skip (debugging)

### 3. **Critical Parent Error Handling**

**Categories = Critical Parent (RETHROW ON FAILURE)**

```dart
Future<void> _syncTicketCategories() async {
  try {
    // ... sync semua categories
    
    if (successCount == 0) {
      throw Exception('ALL categories failed to sync. Check schema.');
    }
    
  } catch (e) {
    _lastError = 'Error in _syncTicketCategories: $e';
    rethrow; // ⚠️ CRITICAL: Stop entire chain!
  }
}
```

**Transactions = Parent (RETHROW ON FAILURE)**

```dart
Future<void> _syncTransactions() async {
  // ... per-record try-catch (continue on individual failure)
  
  catch (e) {
    _lastError = 'Error in _syncTransactions: $e';
    rethrow; // ⚠️ Stop chain: items need transaction IDs
  }
}
```

**Items = Child (NO RETHROW)**

```dart
Future<void> _verifyAndSyncTransactionItems() async {
  // ... attempt sync
  
  catch (e) {
    developer.log('[SyncService] Error verifying/syncing items: $e');
    // ✅ NO rethrow - reconciliations should still proceed
  }
}
```

### 4. **Force Re-sync All Categories**

**New Public Method:**

```dart
Future<void> forceResyncAllCategories() async {
  // Step 1: Reset semua kategori ke isSynced = false
  await (_db.update(_db.ticketCategories))
      .write(const TicketCategoriesCompanion(isSynced: drift.Value(false)));
  
  // Step 2: Sync ulang semuanya
  await _syncTicketCategories();
}
```

**Kapan Gunakan:**
- Setelah fix Supabase schema (quota NOT NULL)
- Jika curiga kategori tidak berhasil di-sync sebelumnya
- Untuk "force clean sync" dari awal

---

## 📊 Comparison: Before vs After

| Aspect | Before | After |
|--------|--------|-------|
| **Dependency Check** | ❌ Tidak ada | ✅ Verify parents di remote |
| **Order Enforcement** | ⚠️ Urutan tapi loose | ✅ KETAT: rethrow parent failures |
| **FK Validation** | ❌ Direct insert | ✅ Pre-insert verification |
| **Missing Parent Handling** | ❌ 409 error | ✅ Skip dengan log detail |
| **Re-sync Mechanism** | ❌ Tidak ada | ✅ forceResyncAllCategories() |
| **Error Propagation** | ⚠️ Inconsistent | ✅ Parent = rethrow, Child = no-throw |

---

## 🔍 Error Diagnosis Guide

### Scenario 1: "category_id_fkey violation"
```
[SyncService] ✗ Item sync failed: item-123
Error: ... violates foreign key constraint "transaction_items_category_id_fkey"
```

**Diagnosis:** Kategori tidak ada di Supabase
**Check:** Run di Supabase SQL Editor:
```sql
SELECT id, name, is_synced FROM ticket_categories;
-- Apakah kategori yang dipakai ada di sini?
```

**Solution:** 
1. Jika kategori TIDAK ada: `SyncService().forceResyncAllCategories()`
2. Jika kategori ada tapi `is_synced = false`: Tunggu next sync cycle
3. Jika kategori ada tapi tidak di log: Mungkin sudah di-skip oleh validator

### Scenario 2: "transaction_id_fkey violation"
```
[SyncService] ✗ Item sync failed: item-456
Error: ... violates foreign key constraint "transaction_items_transaction_id_fkey"
```

**Diagnosis:** Transaksi tidak ada di Supabase
**Check:** Run di Supabase SQL Editor:
```sql
SELECT id, local_number, is_synced FROM transactions WHERE id = 'txn-id';
-- Apakah transaksi dengan ID ini ada?
```

**Solution:**
1. Jika transaksi TIDAK ada: Cek log apakah transaksi gagal sync
2. Monitor untuk "Transaction sync failed" dalam [SyncService] logs

### Scenario 3: "Item di-skip, tidak error"
```
[SyncService] ⚠️ Skipping item item-789: category category-xyz not found in Supabase
```

**Diagnosis:** NORMAL - Item di-skip karena parent missing
**Expected:** Item akan di-retry saat next sync (jika parent sudah masuk)

**Action:** Pastikan kategori ter-sync:
```sql
SELECT COUNT(*) FROM ticket_categories WHERE id = 'category-xyz';
-- Harus return 1
```

---

## 🚀 Step-by-Step Recovery Guide

### Jika Sudah Terjadi 409 FK Error:

**Step 1: Buka Supabase SQL Editor**
```sql
-- Check data status
SELECT id, name, is_synced FROM ticket_categories LIMIT 10;
SELECT id, local_number, is_synced FROM transactions LIMIT 10;
SELECT id, transaction_id, category_id, is_synced FROM transaction_items LIMIT 10;

-- Lihat ada conflict? Baris mana yang rusak?
```

**Step 2: Identify Missing Parents**
```sql
-- Transaction items tanpa parent transactions
SELECT ti.id, ti.transaction_id 
FROM transaction_items ti
LEFT JOIN transactions t ON ti.transaction_id = t.id
WHERE t.id IS NULL;

-- Transaction items tanpa parent categories
SELECT ti.id, ti.category_id 
FROM transaction_items ti
LEFT JOIN ticket_categories tc ON ti.category_id = tc.id
WHERE tc.id IS NULL;
```

**Step 3: Opsi A - Delete Orphan Items (jika data baru)**
```sql
-- HATI-HATI: Ini menghapus data di remote!
DELETE FROM transaction_items 
WHERE transaction_id NOT IN (SELECT id FROM transactions)
   OR category_id NOT IN (SELECT id FROM ticket_categories);
```

**Step 4: Opsi B - Reset & Force Sync (Recommended)**
```sql
-- Mark semua sebagai belum sync
UPDATE ticket_categories SET is_synced = false;
UPDATE transactions SET is_synced = false;
UPDATE transaction_items SET is_synced = false;
```

**Step 5: Di App - Trigger Force Re-sync**
```dart
// Di provider atau UI button:
final syncService = SyncService();
await syncService.forceResyncAllCategories();
// Tunggu berhasil, lalu:
await syncService.syncPending();
```

**ATAU via UI (Recommended):**
1. Buka app
2. Tap sync indicator di AppBar (cloud icon)
3. Dialog muncul dengan tombol "Force Re-sync Kategori"
4. Klik tombol tersebut
5. Monitor logs: `[SyncService] FORCE re-syncing ALL categories...`

**Step 6: Monitor Logs**
```
[SyncService] FORCE re-syncing ALL categories...
[SyncService] Reset all categories isSynced to false
[SyncService] Syncing N ticket_categories (CRITICAL PARENT)
[SyncService] ✓ Category synced: cat-1
[SyncService] ✓ Category synced: cat-2
[SyncService] Force re-sync categories completed successfully
```

**Step 7: Verify in Supabase**
```sql
-- Semua kategori sudah ada?
SELECT COUNT(*) FROM ticket_categories;
-- Semua dengan is_synced = true?
SELECT COUNT(*) FROM ticket_categories WHERE is_synced = true;
-- Harus sama!
```

---

## 📝 Data Cleanup Checklist

Sebelum force re-sync, pastikan data di Supabase bersih:

```sql
-- ✅ Check 1: Orphan transactions (no category match)
SELECT COUNT(*) FROM transaction_items ti
WHERE ti.category_id NOT IN (SELECT id FROM ticket_categories);

-- ✅ Check 2: Duplicate categories
SELECT name, COUNT(*) as cnt FROM ticket_categories 
GROUP BY name HAVING COUNT(*) > 1;

-- ✅ Check 3: Categories with NULL name (invalid)
SELECT id FROM ticket_categories WHERE name IS NULL;

-- ✅ Check 4: Last sync status
SELECT 'Categories' as table_name, COUNT(*) as total, 
       COUNT(CASE WHEN is_synced THEN 1 END) as synced
FROM ticket_categories
UNION ALL
SELECT 'Transactions', COUNT(*), COUNT(CASE WHEN is_synced THEN 1 END)
FROM transactions
UNION ALL
SELECT 'Items', COUNT(*), COUNT(CASE WHEN is_synced THEN 1 END)
FROM transaction_items;
```

**Jika ada orphan/duplicate/NULL:** Hapus dulu sebelum re-sync.

---

## 🎯 New Code Features

### Public Method: `forceResyncAllCategories()`
```dart
SyncService syncService = SyncService();
await syncService.forceResyncAllCategories();
```
- Resets semua categories ke `isSynced = false`
- Sync ulang dari awal
- Useful setelah schema fix

### Private Method: `_verifyAndSyncTransactionItems()` (NEW)
- Replace lama `_syncTransactionItems()`
- Pre-insert FK validation
- Skip orphan items dengan log detail

### Enhanced Logging
- `[CRITICAL]` prefix untuk parent failures
- `⚠️` untuk skipped items
- Detailed error messages per constraint

---

## ✨ Testing After Fix

### Test 1: Fresh Sync (No Existing Data)
1. App offline → buat kategori + transaksi + item
2. Go online → Tunggu 15s
3. Verify di Supabase: semua ada, `is_synced = true`
4. Check logs: NO "Skipping" messages

### Test 2: Force Re-sync
1. Disable internet
2. Change kategori name (locally)
3. Enable internet
4. Call `SyncService().forceResyncAllCategories()`
5. Verify di Supabase: kategori ter-update

### Test 3: Missing Parent (Error Scenario)
1. Delete 1 kategori dari Supabase (manual)
2. Create transaksi pakai kategori deleted
3. Go online → Sync
4. Check logs: "⚠️ Skipping item: category not found"
5. Verify di Supabase: item NOT ada, OK!

### Test 4: Multiple Failures
1. Simulate Supabase down (kill server)
2. Create multiple kategori + items
3. Try sync → Fail
4. Bring server back → Wait 15-60s
5. Auto-retry → Succeed
6. Verify all in Supabase

---

## 🔮 Future Prevention

1. **Add Category Pre-check**
   - When creating transaction_item, validate category exists locally + remotely
   - Show UI warning if category missing

2. **Sync Status Dashboard**
   - Display: "Pending categories: X, Pending items: Y"
   - Show "Re-sync categories" button

3. **Audit Trail**
   - Log each sync attempt: timestamp, records synced, failures
   - Query past sync history

4. **Automatic Cleanup**
   - Periodic check for orphan items
   - Auto-delete if parents missing for 24h

---

**Status: ✅ FK Constraint Fix Complete**
All 409 errors should resolve after implementing dependency validation.
