# Supabase Integration - Setup & Verification Guide

## ✅ Implementation Complete

Anda telah berhasil mengintegrasikan Supabase sebagai backend pusat dengan struktur offline-first yang terjaga. Berikut adalah panduan lengkap untuk setup awal dan verifikasi.

---

## 📋 Daftar Checklist Setup

### Phase 1: Backend Schema (Supabase SQL Editor)
- [ ] Login ke Supabase Dashboard: https://app.supabase.com/
- [ ] Navigate ke "SQL Editor"
- [ ] Copy seluruh isi file `docs/SUPABASE_SCHEMA.sql`
- [ ] Buka tab baru di SQL Editor
- [ ] Paste dan jalankan **semua CREATE TABLE** dulu (urutan: 1-4)
- [ ] Tunggu hingga selesai tanpa error
- [ ] Jalankan **CREATE INDEX** statements
- [ ] Verifikasi di "Table Editor" bahwa 4 table sudah terbuat

### Phase 2: Flutter Dependencies
- [ ] Run `flutter pub get` untuk download `connectivity_plus`
- [ ] Run `flutter pub run build_runner build` (sudah dilakukan, verify build output)
- [ ] Run `flutter analyze` untuk validate kode (should show 0 errors)

### Phase 3: Network Configuration (Android)

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Ensure kedua permission ada di manifest. Jika tidak, tambahkan di dalam tag `<manifest>`.

### Phase 4: App Launch & Verification

```bash
# Start app di device/emulator
flutter run

# Atau jika ada multiple devices:
flutter run -d <device_id>
```

---

## 🔍 Verification Checklist

### Test 1: Sync Status Indicator Visible
- [ ] Buka app dan navigate ke "Kasir" tab
- [ ] Lihat AppBar (top bar)
- [ ] Cari icon cloud + text di sebelah Printer & Settings button
- [ ] Indicator harus menunjukkan salah satu:
  - ☁️ "Tersinkron" (hijau) - semua record sudah sync
  - ⚠️ "X belum sync" (oranye) - ada pending records
  - 🔄 "Sedang sync..." (oranye dengan loading) - sedang sinkronisasi

### Test 2: Create Transaction & Verify Local Save
1. **Buat transaksi di Kasir:**
   - Pilih beberapa kategori tiket
   - Klik tombol pembayaran
   - Pilih metode pembayaran
   - Tekan "Bayar"

2. **Verifikasi di local database:**
   - Buka "Riwayat" tab
   - Transaksi harus langsung terlihat
   - isSynced akan false di local database (pending)
   - **Catatan:** Ini normal! Offline-first memastikan transaksi tersimpan lokal dulu

### Test 3: Sync Trigger (Online Mode)
**Requirement:** Device harus connected ke internet (WiFi atau data)

1. **Buka Kasir > AppBar > Click sync indicator**
   - Jika ada pending records dan online, harusnya sync dimulai otomatis
   - Atau klik indicator untuk lihat dialog status detail

2. **Verifikasi sync completed:**
   - Indicator akan berubah menjadi "Tersinkron" (hijau)
   - Atau buka "Riwayat" dan lihat transaksi

3. **Check di Supabase Dashboard:**
   - Login: https://app.supabase.com/
   - Select project Motocross
   - Go to "Table Editor"
   - Open table `transactions`
   - Verifikasi rows muncul dengan data transaksi
   - Check column `is_synced` = true untuk record yang sudah sync

### Test 4: Offline Mode Behavior
**Requirement:** Simulate offline dengan matikan WiFi/data

1. **Matikan internet connection**
2. **Buat transaksi di Kasir**
3. **Verifikasi:**
   - Transaksi tetap tersimpan lokal
   - Indicator menunjukkan "X belum sync" (oranye)
   - App tetap berfungsi normal (BLOCKING SYNC BEHAVIOR PREVENTED)

4. **Nyalakan internet kembali**
5. **Verifikasi sync trigger:**
   - Dalam ~30 detik, sync harusnya otomatis terjadi
   - Atau klik manual sync di indicator
   - Indicator berubah ke "Tersinkron"
   - Supabase Dashboard menunjukkan data synced

### Test 5: Multiple Transactions Sync
1. **Offline:** Buat 5 transaksi dengan internet mati
2. **Indicator:** Harusnya menunjukkan "5 belum sync"
3. **Online:** Nyalakan internet
4. **Verifikasi:** Semua 5 transaksi sync ke Supabase
5. **Supabase:** Lihat di Table Editor, semua 5 rows ada

### Test 6: Void Transaction Sync
1. **Di Riwayat:** Buka transaksi
2. **Klik void:** Catat alasan void
3. **Online mode:**
   - Original transaction update (void flag) ter-sync
   - Check Supabase: column `is_voided` = true, `voided_at` terisi
4. **Offline mode:**
   - Void tetap disimpan lokal
   - Sync saat online

---

## 📊 Supabase Data Inspection

### Check Synced Transactions
```sql
-- Di Supabase SQL Editor, verify struktur dan data
SELECT id, local_number, total, is_synced, created_at 
FROM transactions 
ORDER BY created_at DESC 
LIMIT 10;
```

### Check Sync Status Across All Tables
```sql
SELECT 
  'transactions' as table_name, COUNT(*) as total_records,
  COUNT(CASE WHEN is_synced = true THEN 1 END) as synced,
  COUNT(CASE WHEN is_synced = false THEN 1 END) as pending
FROM transactions
UNION ALL
SELECT 
  'transaction_items', COUNT(*), 
  COUNT(CASE WHEN is_synced = true THEN 1 END),
  COUNT(CASE WHEN is_synced = false THEN 1 END)
FROM transaction_items
UNION ALL
SELECT 
  'shift_reconciliations', COUNT(*), 
  COUNT(CASE WHEN is_synced = true THEN 1 END),
  COUNT(CASE WHEN is_synced = false THEN 1 END)
FROM shift_reconciliations;
```

---

## 🛠️ Troubleshooting

### Issue 1: Sync Status Indicator Not Showing
**Symptoms:** AppBar tidak menampilkan sync indicator

**Debug Steps:**
1. Verify `sync_status_indicator.dart` imported di `kasir_screen.dart` dan `riwayat_screen.dart`
2. Run `flutter analyze` - pastikan 0 errors
3. Hot reload or full restart: `flutter run`
4. Check Flutter console untuk error messages

**Solution:**
```bash
# Full clean build
flutter clean
flutter pub get
flutter run
```

### Issue 2: Sync Not Triggering Automatically
**Symptoms:** Pending records ada tapi tidak auto-sync saat online

**Debug Steps:**
1. **Check connectivity:**
   ```bash
   # Di Flutter console, trigger sync manually:
   # Click pada sync indicator > "Sync Sekarang" button
   ```
2. **Verify Supabase credentials:**
   - Buka `lib/main.dart`
   - Check URL dan anonKey (lines 20-24)
   - Verifikasi sama dengan project Supabase

3. **Check network permission Android:**
   - `android/app/src/main/AndroidManifest.xml`
   - Pastikan `INTERNET` dan `ACCESS_NETWORK_STATE` permission ada

**Solution:**
```dart
// Di main.dart, verify Supabase init
await Supabase.initialize(
  url: 'https://qwgkqgniqmkbqoktkkwq.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // Full key
);
```

### Issue 3: Data Not Appearing in Supabase
**Symptoms:** Sync indicator shows "Tersinkron" tapi Supabase Table Editor kosong

**Debug Steps:**
1. **Check isSynced column:**
   - Di SQLite lokal: all records harus isSynced = false (pending)
   - Saat sync: berubah menjadi isSynced = true

2. **Verify table creation:**
   - Supabase Dashboard > Table Editor
   - Pastikan 4 table ada: transactions, transaction_items, ticket_categories, shift_reconciliations
   - Lihat column `is_synced` ada di setiap table

3. **Check Supabase logs:**
   - Dashboard > Logs > Postgres
   - Lihat apakah ada error INSERT saat sync

**Solution:**
```bash
# Re-run SQL schema creation
# 1. Copy docs/SUPABASE_SCHEMA.sql
# 2. Paste di Supabase SQL Editor
# 3. Run semua CREATE TABLE statements
```

### Issue 4: App Crashes on Startup
**Symptoms:** App crash saat initialize

**Debug Steps:**
1. Check logcat untuk error:
   ```bash
   flutter run -v  # Verbose logging
   ```

2. Common errors:
   - `Undefined name 'databaseProvider'` → Missing import
   - `FormatException` pada Supabase init → Invalid anonKey
   - `connectivity_plus` error → Missing AndroidManifest permission

**Solution:**
```dart
// lib/main.dart - Ensure all imports present:
import 'providers/database_provider.dart';
import 'services/sync/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

---

## 📱 Device Testing Tips

### Emulator Network Simulation
```bash
# Simulate offline in emulator
adb shell setting put global airplane_mode_on 1

# Verify offline
adb shell settings get global airplane_mode_on  # Should return 1

# Go back online
adb shell settings put global airplane_mode_on 0
```

### Physical Device Testing
- Toggle WiFi on/off to simulate connectivity changes
- Use Android Settings > Developer Options > Network Throttling untuk network delay simulation

---

## 🚀 Production Deployment Notes

### Before Going Live

1. **Security:**
   - [ ] Enable RLS (Row Level Security) di Supabase tables untuk restrict user access
   - [ ] Move API keys to environment variables (tidak hardcoded di source)
   - [ ] Setup Supabase Auth jika multi-user

2. **Monitoring:**
   - [ ] Setup Supabase logs monitoring
   - [ ] Verify sync latency acceptable
   - [ ] Plan conflict resolution strategy untuk multi-device

3. **Backup:**
   - [ ] Setup Supabase automated backup
   - [ ] Test recovery procedure

4. **Scale:**
   - [ ] Plan untuk volume data + concurrent devices
   - [ ] Monitor Supabase quota usage

---

## 📚 Architecture Overview

```
LOCAL APP LAYER (Offline-First)
  ├─ SQLite Database (Source of Truth)
  │  └─ All transactions saved immediately
  ├─ Drift ORM (isSynced column tracks sync state)
  └─ Cart Provider (Riverpod state management)

         ↓ ONE-WAY SYNC (No two-way conflict)

SYNC SERVICE LAYER
  ├─ Connectivity Monitor (connectivity_plus)
  ├─ Queue-based Sync (pending records only)
  ├─ Auto-retry on connectivity change
  └─ Non-blocking (sync failures don't block app)

         ↓ ASYNC UPLOAD

CLOUD LAYER (Supabase / PostgreSQL)
  ├─ transactions table (append-only)
  ├─ transaction_items (line items)
  ├─ ticket_categories (reference data)
  └─ shift_reconciliations (daily close)

         ← READ (Future: multi-device sync)
```

### Key Design Decisions

| Aspect | Decision | Why |
|--------|----------|-----|
| Direction | Offline→Cloud only | Simplifies multi-device: single source of truth |
| Failure Mode | Non-blocking | App never blocked by network, local always works |
| Conflict | None (one-way) | Single device = no conflicts, extensible later |
| Retry | Auto on connectivity | User experience: transparent background sync |
| Pending Tracking | isSynced boolean | Simple, efficient, works with Drift |

---

## 🔗 Quick Links

- **Supabase Dashboard:** https://app.supabase.com/
- **Supabase Docs:** https://supabase.com/docs
- **Supabase Flutter Docs:** https://supabase.com/docs/reference/flutter
- **Connectivity Plus:** https://pub.dev/packages/connectivity_plus
- **Drift ORM:** https://drift.simonbinder.eu/

---

## 📞 Support & Debugging

Untuk debugging lebih detail, check:
- `lib/services/sync/sync_service.dart` - Debug logs dengan prefix `[SyncService]`
- Flutter console output saat transaction creation dan sync
- Supabase Dashboard Logs untuk PostgreSQL errors

Log dapat di-enable dengan run app dalam verbose mode:
```bash
flutter run -v
```

Sync logs akan menunjukkan:
```
[SyncService] Initialized
[SyncService] Connectivity changed: true
[SyncService] Starting sync...
[SyncService] Syncing X transactions
[SyncService] ✓ Transaction synced: <id>
[SyncService] Sync completed. Pending: 0
```
