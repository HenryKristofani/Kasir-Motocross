import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';

/// Sync status enum untuk tracking state lebih detail
enum SyncStatus {
  idle, // Not syncing
  syncing, // Currently syncing
  error, // Sync failed
  errorWaitingRetry, // Failed and waiting for retry
}

/// Queue-based one-way sync service: local → Supabase
/// Syncs transactions, transaction_items, ticket_categories, and shift_reconciliations
/// Auto-triggers on connectivity changes (offline→online) dengan retry backoff
/// DEPENDENCY ORDER KETAT:
/// 1. ticket_categories (parent, MUST succeed before proceeding)
/// 2. transactions (parent of transaction_items, checked FK before items sync)
/// 3. transaction_items (only sync if categories & transactions verified present)
/// 4. shift_reconciliations (independent)
class SyncService {
  static final SyncService _instance = SyncService._internal();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  factory SyncService() => _instance;

  SyncService._internal();

  final _connectivity = Connectivity();
  late AppDatabase _db;
  late SupabaseClient _supabase;
  StreamSubscription? _connectivitySub;

  SyncStatus _status = SyncStatus.idle;
  int _pendingCount = 0;
  String _lastError = '';
  DateTime? _lastSyncAttempt;
  DateTime? _lastLocalMutationSyncTrigger;
  int _consecutiveFailures = 0;
  static const int _minSyncDelaySeconds =
      15; // Minimum 15 detik antar sync attempt
  static const int _maxRetryDelaySeconds = 60; // Max 60 detik backoff
  static const int _localMutationSyncThrottleSeconds =
      3; // Max satu trigger local-write per 3s

  // Public getters untuk UI:
  int get pendingCount => _pendingCount;
  bool get isSyncing => _status == SyncStatus.syncing;
  bool get hasError =>
      _status == SyncStatus.error || _status == SyncStatus.errorWaitingRetry;
  String get lastError => _lastError;
  SyncStatus get status => _status;

  /// Initialize sync service dengan database dan Supabase client
  void init(AppDatabase db, SupabaseClient supabase) {
    _db = db;
    _supabase = supabase;
    if (_connectivitySub != null) {
      developer.log(
        '[SyncService] Already initialized; skipped duplicate listener setup',
        name: 'sync',
      );
      return;
    }
    _setupConnectivityListener();
    developer.log('[SyncService] Initialized', name: 'sync');
  }

  /// Force re-sync ALL categories (regardless of isSynced status)
  /// Gunakan ketika ada indikasi kategori tidak berhasil sync ke Supabase
  /// (misal: setelah fix schema)
  Future<void> forceResyncAllCategories() async {
    if (_status == SyncStatus.syncing) {
      developer.log(
        '[SyncService] Already syncing, skip force resync',
        name: 'sync',
      );
      return;
    }

    _lastSyncAttempt = DateTime.now();
    _status = SyncStatus.syncing;
    developer.log(
      '[SyncService] FORCE re-syncing ALL categories...',
      name: 'sync',
    );

    try {
      // Reset ALL categories to isSynced = false dulu
      await (_db.update(
        _db.ticketCategories,
      )).write(const TicketCategoriesCompanion(isSynced: drift.Value(false)));
      developer.log(
        '[SyncService] Reset all categories isSynced to false',
        name: 'sync',
      );

      // Sekarang sync ulang semua
      await _syncTicketCategories();

      _consecutiveFailures = 0;
      _lastError = '';
      _status = SyncStatus.idle;
      developer.log(
        '[SyncService] Force re-sync categories completed successfully',
        name: 'sync',
      );
    } catch (e) {
      _consecutiveFailures++;
      _lastError = e.toString();
      _status = SyncStatus.errorWaitingRetry;
      developer.log(
        '[SyncService] Force re-sync error: $e',
        name: 'sync',
        error: e,
      );
    }
  }

  /// Listen to connectivity changes: ketika online, trigger sync dengan delay
  void _setupConnectivityListener() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final isConnected = !results.contains(ConnectivityResult.none);
      developer.log(
        '[SyncService] Connectivity changed: $isConnected',
        name: 'sync',
      );

      if (isConnected && _status != SyncStatus.syncing) {
        // Cek apakah cukup delay sejak last attempt
        if (_shouldRetry()) {
          await Future.delayed(const Duration(seconds: 1));
          await syncPending();
        }
      }
    });
  }

  /// Check if enough time has passed since last sync attempt
  bool _shouldRetry() {
    if (_lastSyncAttempt == null) return true;

    final secondsSinceLast = DateTime.now()
        .difference(_lastSyncAttempt!)
        .inSeconds;
    final minDelay = _consecutiveFailures == 0
        ? _minSyncDelaySeconds
        : (_minSyncDelaySeconds * (_consecutiveFailures)).clamp(
            0,
            _maxRetryDelaySeconds,
          );

    final shouldRetry = secondsSinceLast >= minDelay;
    if (!shouldRetry) {
      developer.log(
        '[SyncService] Retry delayed. Failures: $_consecutiveFailures, '
        'Wait ${minDelay - secondsSinceLast}s more',
        name: 'sync',
      );
    }
    return shouldRetry;
  }

  /// Trigger sync secara langsung setelah local data berubah.
  /// Metode ini tidak di-await dari UI, jadi tidak mem-block user interaction.
  /// Jika online dan belum melewati backoff/throttle, maka sync langsung dijalankan.
  void triggerLocalMutationSync() {
    Future.microtask(() async {
      if (_status == SyncStatus.syncing) {
        developer.log(
          '[SyncService] Skip local mutation sync: already syncing',
          name: 'sync',
        );
        return;
      }

      final connectivityResults = await _connectivity.checkConnectivity();
      final isOnline = !connectivityResults.contains(ConnectivityResult.none);
      if (!isOnline) {
        developer.log(
          '[SyncService] Skip local mutation sync: offline',
          name: 'sync',
        );
        return;
      }

      final now = DateTime.now();
      if (_lastLocalMutationSyncTrigger != null) {
        final secondsSinceLastTrigger = now
            .difference(_lastLocalMutationSyncTrigger!)
            .inSeconds;
        if (secondsSinceLastTrigger < _localMutationSyncThrottleSeconds) {
          developer.log(
            '[SyncService] Skip local mutation sync: throttled for ${_localMutationSyncThrottleSeconds - secondsSinceLastTrigger} s',
            name: 'sync',
          );
          return;
        }
      }
      _lastLocalMutationSyncTrigger = now;

      final allowImmediate =
          _lastSyncAttempt == null ||
          _consecutiveFailures > 0 ||
          now.difference(_lastSyncAttempt!).inSeconds >= _minSyncDelaySeconds;

      if (!allowImmediate) {
        developer.log(
          '[SyncService] Local mutation sync deferred by retry backoff. Last sync: $_lastSyncAttempt',
          name: 'sync',
        );
        return;
      }

      developer.log(
        '[SyncService] Local mutation sync trigger fired',
        name: 'sync',
      );
      await syncPending();
    });
  }

  static void showSuccessSnackBar(int syncedCount) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      developer.log(
        '[SyncService] SnackBar skipped: no ScaffoldMessenger attached',
        name: 'sync',
      );
      return;
    }

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '✓ $syncedCount transaksi tersinkron ke server',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Main sync function dengan error handling dan retry backoff
  /// DEPENDENCY ORDER KETAT:
  /// 1. Categories MUST succeed before proceeding (critical parent)
  /// 2. Transactions MUST succeed before items (parent FK)
  /// 3. Items ONLY if both parents verified present
  Future<void> syncPending() async {
    if (_status == SyncStatus.syncing) {
      developer.log('[SyncService] Already syncing, skip', name: 'sync');
      return;
    }

    _lastSyncAttempt = DateTime.now();
    _status = SyncStatus.syncing;
    developer.log(
      '[SyncService] Starting sync... (Attempt #${_consecutiveFailures + 1})',
      name: 'sync',
    );

    var syncedThisCycle = 0;

    try {
      // STEP 1: Sync ticket_categories (PARENT - must succeed first)
      // If this fails, rethrow to stop entire chain
      syncedThisCycle += await _syncTicketCategories();

      // STEP 2: Sync transactions (parent of transaction_items)
      syncedThisCycle += await _syncTransactions();

      // STEP 3: Sync transaction_items ONLY if parent tables available
      // Verify categories & transactions exist di Supabase sebelum sync items
      syncedThisCycle += await _verifyAndSyncTransactionItems();

      // STEP 4: Sync shift reconciliations (independent)
      syncedThisCycle += await _syncShiftReconciliations();

      // Update pending count
      await _updatePendingCount();

      _consecutiveFailures = 0;
      _lastError = '';
      _status = SyncStatus.idle;

      if (syncedThisCycle > 0) {
        showSuccessSnackBar(syncedThisCycle);
      }

      developer.log(
        '[SyncService] Sync completed successfully. Pending: $_pendingCount, synced this cycle: $syncedThisCycle',
        name: 'sync',
      );
    } catch (e) {
      _consecutiveFailures++;
      _lastError = e.toString();
      _status = SyncStatus.errorWaitingRetry;

      final retryDelay = (_minSyncDelaySeconds * _consecutiveFailures).clamp(
        0,
        _maxRetryDelaySeconds,
      );
      developer.log(
        '[SyncService] Sync error (failure #$_consecutiveFailures): $e\n'
        'Will retry in ${retryDelay}s',
        name: 'sync',
        error: e,
      );
    }
  }

  /// Sync semua transaksi yang belum ter-sync (isSynced = false)
  Future<int> _syncTransactions() async {
    try {
      final unsynced = await (_db.select(
        _db.transactions,
      )..where((t) => t.isSynced.equals(false))).get();

      if (unsynced.isEmpty) {
        developer.log('[SyncService] No pending transactions', name: 'sync');
        return 0;
      }

      developer.log(
        '[SyncService] Syncing ${unsynced.length} transactions',
        name: 'sync',
      );

      final syncedIds = <String>[];

      for (final txn in unsynced) {
        try {
          await _supabase.from('transactions').insert({
            'id': txn.id,
            'local_number': txn.localNumber,
            'device_id': txn.deviceId,
            'total': txn.total,
            'payment_method': txn.paymentMethod,
            'is_voided': txn.isVoided,
            'void_reason': txn.voidReason,
            'voided_at': txn.voidedAt?.toIso8601String(),
            'created_at': txn.createdAt.toIso8601String(),
          });

          syncedIds.add(txn.id);
          developer.log(
            '[SyncService] ✓ Transaction synced: ${txn.id}',
            name: 'sync',
          );
        } catch (e) {
          _lastError = 'Transaction sync failed for ${txn.id}: $e';
          developer.log(
            '[SyncService] ✗ Transaction sync failed: ${txn.id}\nError: $e',
            name: 'sync',
            error: e,
          );
          if (e.toString().contains('local_number')) {
            developer.log(
              '[SyncService] → Possible local_number type mismatch. Verify schema: ALTER TABLE transactions ALTER COLUMN local_number TYPE TEXT;',
              name: 'sync',
            );
          }
        }
      }

      if (syncedIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.update(
            _db.transactions,
            const TransactionsCompanion(isSynced: drift.Value(true)),
            where: (t) => t.id.isIn(syncedIds),
          );
        });
      }

      return syncedIds.length;
    } catch (e) {
      _lastError = 'Error in _syncTransactions: $e';
      developer.log(
        '[SyncService] Error in _syncTransactions: $e',
        name: 'sync',
        error: e,
      );
      rethrow; // Re-throw untuk stop sync chain - transactions are parent
    }
  }

  /// Verify categories & transactions exist in Supabase sebelum sync items
  /// Ini mencegah FK constraint errors dengan memastikan parent records ada
  Future<int> _verifyAndSyncTransactionItems() async {
    try {
      final unsynced = await (_db.select(
        _db.transactionItems,
      )..where((ti) => ti.isSynced.equals(false))).get();

      if (unsynced.isEmpty) {
        developer.log(
          '[SyncService] No pending transaction_items',
          name: 'sync',
        );
        return 0;
      }

      developer.log(
        '[SyncService] Syncing ${unsynced.length} transaction_items',
        name: 'sync',
      );

      final syncedIds = <String>[];

      // Fetch all categories & transactions di Supabase untuk validasi
      final remoteCategories = await _supabase
          .from('ticket_categories')
          .select('id')
          .then(
            (data) => (data as List).map((row) => row['id'] as String).toSet(),
          );

      final remoteTransactions = await _supabase
          .from('transactions')
          .select('id')
          .then(
            (data) => (data as List).map((row) => row['id'] as String).toSet(),
          );

      developer.log(
        '[SyncService] Verified remote data: ${remoteCategories.length} categories, '
        '${remoteTransactions.length} transactions',
        name: 'sync',
      );

      for (final item in unsynced) {
        if (!remoteCategories.contains(item.categoryId)) {
          developer.log(
            '[SyncService] ⚠️ Skipping item ${item.id}: category ${item.categoryId} not found in Supabase. '
            'Possible causes: category failed to sync previously, or not yet synced.',
            name: 'sync',
          );
          continue;
        }

        if (!remoteTransactions.contains(item.transactionId)) {
          developer.log(
            '[SyncService] ⚠️ Skipping item ${item.id}: transaction ${item.transactionId} not found in Supabase. '
            'Possible causes: transaction failed to sync previously, or not yet synced.',
            name: 'sync',
          );
          continue;
        }

        try {
          await _supabase.from('transaction_items').insert({
            'id': item.id,
            'transaction_id': item.transactionId,
            'category_id': item.categoryId,
            'qty': item.qty,
            'subtotal': item.subtotal,
            'price_option': item.priceOption,
          });

          syncedIds.add(item.id);
          developer.log(
            '[SyncService] ✓ Item synced: ${item.id}',
            name: 'sync',
          );
        } catch (e) {
          _lastError = 'Transaction item sync failed for ${item.id}: $e';
          developer.log(
            '[SyncService] ✗ Item sync failed: ${item.id}\nError: $e',
            name: 'sync',
            error: e,
          );
        }
      }

      if (syncedIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.update(
            _db.transactionItems,
            const TransactionItemsCompanion(isSynced: drift.Value(true)),
            where: (ti) => ti.id.isIn(syncedIds),
          );
        });
      }

      return syncedIds.length;
    } catch (e) {
      _lastError = 'Error in _verifyAndSyncTransactionItems: $e';
      developer.log(
        '[SyncService] Error verifying/syncing items: $e',
        name: 'sync',
        error: e,
      );
      // Don't rethrow - item sync failures shouldn't stop reconciliations
      return 0;
    }
  }

  /// Sync semua kategori tiket yang belum ter-sync
  /// Prioritas pertama karena ticket_categories referenced by transaction_items
  /// CRITICAL: Ini adalah parent table. Jika gagal, seluruh sync chain dihentikan
  Future<int> _syncTicketCategories() async {
    try {
      final unsynced = await (_db.select(
        _db.ticketCategories,
      )..where((c) => c.isSynced.equals(false))).get();

      if (unsynced.isEmpty) {
        developer.log(
          '[SyncService] No pending ticket_categories',
          name: 'sync',
        );
        return 0;
      }

      developer.log(
        '[SyncService] Syncing ${unsynced.length} ticket_categories (CRITICAL PARENT)',
        name: 'sync',
      );

      final syncedIds = <String>[];
      for (final cat in unsynced) {
        final payload = {
          'id': cat.id,
          'name': cat.name,
          'day_type': cat.dayType,
          'price': cat.price,
          'quota': cat.quota,
        };
        try {
          await _supabase.from('ticket_categories').upsert(payload);

          syncedIds.add(cat.id);
          developer.log(
            '[SyncService] ✓ Category synced: ${cat.id}',
            name: 'sync',
          );
        } catch (e) {
          final errorText = e.toString();
          final schemaHint =
              errorText.contains('day_type') ||
                  errorText.contains('schema cache')
              ? ' Supabase belum memiliki kolom day_type. Jalankan migration di docs/SUPABASE_SCHEMA.sql.'
              : errorText.contains('quota')
              ? ' Pastikan kolom quota nullable di Supabase.'
              : '';
          _lastError =
              'Category sync failed for ${cat.id}: $errorText$schemaHint';
          developer.log(
            '[SyncService] ✗ Category sync failed: ${cat.id}\n'
            'Payload: $payload\nError: $errorText$schemaHint',
            name: 'sync',
            error: e,
          );
          if (errorText.contains('quota')) {
            developer.log(
              '[SyncService] → Quota column error. Check Supabase schema: '
              'ALTER TABLE ticket_categories ALTER COLUMN quota DROP NOT NULL;',
              name: 'sync',
            );
          }
        }
      }

      if (syncedIds.isEmpty) {
        throw Exception(
          'ALL ticket_categories failed to sync. Check Supabase schema and permissions.',
        );
      }

      await _db.batch((batch) {
        batch.update(
          _db.ticketCategories,
          const TicketCategoriesCompanion(isSynced: drift.Value(true)),
          where: (c) => c.id.isIn(syncedIds),
        );
      });

      developer.log(
        '[SyncService] Successfully synced ${syncedIds.length}/${unsynced.length} categories',
        name: 'sync',
      );
      return syncedIds.length;
    } catch (e) {
      _lastError = 'Error in _syncTicketCategories: $e';
      developer.log(
        '[SyncService] CRITICAL: Error in _syncTicketCategories: $e',
        name: 'sync',
        error: e,
      );
      rethrow; // CRITICAL: Categories are parent. Stop entire chain.
    }
  }

  /// Sync semua shift reconciliations yang belum ter-sync
  Future<int> _syncShiftReconciliations() async {
    try {
      final unsynced = await (_db.select(
        _db.shiftReconciliations,
      )..where((sr) => sr.isSynced.equals(false))).get();

      if (unsynced.isEmpty) {
        developer.log(
          '[SyncService] No pending shift_reconciliations',
          name: 'sync',
        );
        return 0;
      }

      developer.log(
        '[SyncService] Syncing ${unsynced.length} shift_reconciliations',
        name: 'sync',
      );

      final syncedIds = <String>[];
      for (final recon in unsynced) {
        try {
          await _supabase.from('shift_reconciliations').insert({
            'id': recon.id,
            'device_id': recon.deviceId,
            'total_sistem_tunai': recon.totalSistemTunai,
            'total_fisik_tunai': recon.totalFisikTunai,
            'selisih': recon.selisih,
            'catatan': recon.catatan,
            'created_at': recon.createdAt.toIso8601String(),
          });

          syncedIds.add(recon.id);
          developer.log(
            '[SyncService] ✓ Reconciliation synced: ${recon.id}',
            name: 'sync',
          );
        } catch (e) {
          _lastError = 'Reconciliation sync failed for ${recon.id}: $e';
          developer.log(
            '[SyncService] ✗ Reconciliation sync failed: ${recon.id}\nError: $e',
            name: 'sync',
            error: e,
          );
        }
      }

      if (syncedIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.update(
            _db.shiftReconciliations,
            const ShiftReconciliationsCompanion(isSynced: drift.Value(true)),
            where: (sr) => sr.id.isIn(syncedIds),
          );
        });
      }

      return syncedIds.length;
    } catch (e) {
      _lastError = 'Error in _syncShiftReconciliations: $e';
      developer.log(
        '[SyncService] Error in _syncShiftReconciliations: $e',
        name: 'sync',
        error: e,
      );
      return 0;
    }
  }

  /// Update pending count untuk UI indicator
  Future<void> _updatePendingCount() async {
    try {
      final pendingTxns =
          await (_db.select(_db.transactions)
                ..where((t) => t.isSynced.equals(false)))
              .get()
              .then((rows) => rows.length);
      final pendingItems =
          await (_db.select(_db.transactionItems)
                ..where((ti) => ti.isSynced.equals(false)))
              .get()
              .then((rows) => rows.length);
      final pendingCats =
          await (_db.select(_db.ticketCategories)
                ..where((c) => c.isSynced.equals(false)))
              .get()
              .then((rows) => rows.length);
      final pendingRecons =
          await (_db.select(_db.shiftReconciliations)
                ..where((sr) => sr.isSynced.equals(false)))
              .get()
              .then((rows) => rows.length);

      _pendingCount = pendingTxns + pendingItems + pendingCats + pendingRecons;
    } catch (e) {
      developer.log(
        '[SyncService] Error updating pending count: $e',
        name: 'sync',
        error: e,
      );
    }
  }

  /// Cleanup saat app ditutup
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    developer.log('[SyncService] Disposed', name: 'sync');
  }
}
