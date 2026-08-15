import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import '../data/models/rekap_penjualan_model.dart';
import '../core/constants/payment_constants.dart';
import 'kuota_helper.dart';
import 'package:drift/drift.dart';

enum PeriodFilter { hariIni, semuaWaktu }

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Stream semua transaksi, urut dari terbaru
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

// Tanggal aktif yang sedang dipilih di halaman Riwayat
final selectedRiwayatDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Transaksi yang difilter per hari untuk halaman Riwayat
final filteredTransactionsByDateProvider = Provider.family<List<Transaction>, DateTime>((ref, selectedDate) {
  final allTransactions = ref.watch(transactionsStreamProvider).valueOrNull ?? const <Transaction>[];
  final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final filtered = allTransactions.where((transaction) {
    final createdAt = transaction.createdAt;
    return createdAt.isAfter(startOfDay.subtract(const Duration(microseconds: 1))) &&
        createdAt.isBefore(endOfDay);
  }).toList();

  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered;
});

// Stream semua kategori tiket dari database lokal, urut berdasarkan nama
final kategoriTiketStreamProvider = StreamProvider<List<TicketCategoryModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.ticketCategories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch()
      .map((rows) => rows.map((row) => TicketCategoryModel(
            id: row.id,
            name: row.name,
            price: row.price,
            quota: row.quota,
          )).toList());
});

class TransactionDetailItem {
  const TransactionDetailItem({
    required this.categoryId,
    required this.categoryName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  final String categoryId;
  final String categoryName;
  final int qty;
  final int unitPrice;
  final int subtotal;
}

// Stream semua transaction items (untuk menghitung sisa kuota)
final transactionItemsStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.transactionItems).watch();
});

// Query join transaction_items dengan ticket_categories per transaksi
final transactionDetailItemsProvider = FutureProvider.family<List<TransactionDetailItem>, String>((ref, transactionId) async {
  final db = ref.watch(databaseProvider);
  ref.watch(transactionItemsStreamProvider);
  ref.watch(kategoriTiketStreamProvider);

  final items = await (db.select(db.transactionItems)
        ..where((item) => item.transactionId.equals(transactionId)))
      .get();

  final categories = await db.select(db.ticketCategories).get();
  final categoryMap = {for (final category in categories) category.id: category};

  return items.map((item) {
    final category = categoryMap[item.categoryId];
    final unitPrice = category?.price ?? 0;

    return TransactionDetailItem(
      categoryId: item.categoryId,
      categoryName: category?.name ?? 'Kategori tidak tersedia',
      qty: item.qty,
      unitPrice: unitPrice,
      subtotal: item.subtotal,
    );
  }).toList();
});

// Computed provider untuk sisa kuota per kategori
// Otomatis di-recompute ketika kategoris atau transactionItems berubah
final sisaKuotaPerKategoriProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final kategoris = await ref.watch(kategoriTiketStreamProvider.future);
  ref.watch(transactionItemsStreamProvider); // Trigger recompute ketika transaction items berubah
  ref.watch(transactionsStreamProvider); // Trigger recompute ketika transaksi di-void (isVoided berubah)
  
  return calculateSisaKuotaPerKategori(db, kategoris);
});

// Provider untuk filter periode rekap penjualan
final rekapPeriodFilterProvider = StateProvider<PeriodFilter>((ref) => PeriodFilter.hariIni);

// Provider untuk rekap penjualan per kategori dengan filter periode
// EXCLUDE transaksi yang di-void (isVoided = true)
final rekapPenjualanProvider = FutureProvider<List<RekapPenjualanItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final periodFilter = ref.watch(rekapPeriodFilterProvider);
  ref.watch(transactionsStreamProvider); // Trigger update saat transaksi berubah
  ref.watch(transactionItemsStreamProvider); // Trigger update saat items berubah
  
  // Hitung periode filter
  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
  
  // Query transaction berdasarkan filter periode dan BUKAN voided
  final query = db.select(db.transactions);
  final List<Transaction> transactions;
  
  if (periodFilter == PeriodFilter.hariIni) {
    transactions = await (query
          ..where((t) => 
            t.createdAt.isBiggerOrEqualValue(startOfDay) & 
            t.createdAt.isSmallerThanValue(endOfDay) &
            t.isVoided.equals(false)))
        .get();
  } else {
    transactions = await (query..where((t) => t.isVoided.equals(false))).get();
  }
  
  // Ambil transaction IDs untuk filter items
  final transactionIds = transactions.map((t) => t.id).toList();
  
  if (transactionIds.isEmpty) {
    return [];
  }
  
  // Query semua transaction items dari transaksi yang sesuai filter
  final items = await db.select(db.transactionItems).get();
  final filteredItems = items.where((item) => transactionIds.contains(item.transactionId)).toList();
  
  // Group by categoryId dan aggregate
  final aggregated = <String, (int qty, int subtotal)>{};
  for (final item in filteredItems) {
    final existing = aggregated[item.categoryId] ?? (0, 0);
    aggregated[item.categoryId] = (existing.$1 + item.qty, existing.$2 + item.subtotal);
  }
  
  // Get kategori names
  final kategoris = await (db.select(db.ticketCategories)).get();
  final kategoriMap = {for (final kat in kategoris) kat.id: kat.name};
  
  // Build result dan sort by total subtotal (descending)
  final result = aggregated.entries
      .map((e) => RekapPenjualanItem(
            kategoriId: e.key,
            kategoriName: kategoriMap[e.key] ?? e.key,
            totalQty: e.value.$1,
            totalSubtotal: e.value.$2,
          ))
      .toList();
  
  result.sort((a, b) => b.totalSubtotal.compareTo(a.totalSubtotal));
  
  return result;
});

// Provider khusus untuk data rekap hari ini saja (untuk rekonsiliasi kas)
final rekapPenjualanHariIniProvider = FutureProvider<List<RekapPenjualanItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(transactionsStreamProvider); // Trigger update saat transaksi berubah
  ref.watch(transactionItemsStreamProvider); // Trigger update saat items berubah
  
  // Hitung periode hari ini
  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
  
  // Query transaction hari ini yang TIDAK di-void
  final transactions = await (db.select(db.transactions)
        ..where((t) => 
          t.createdAt.isBiggerOrEqualValue(startOfDay) & 
          t.createdAt.isSmallerThanValue(endOfDay) &
          t.isVoided.equals(false)))
      .get();
  
  // Ambil transaction IDs
  final transactionIds = transactions.map((t) => t.id).toList();
  
  if (transactionIds.isEmpty) {
    return [];
  }
  
  // Query semua transaction items
  final items = await db.select(db.transactionItems).get();
  final filteredItems = items.where((item) => transactionIds.contains(item.transactionId)).toList();
  
  // Group by categoryId dan aggregate
  final aggregated = <String, (int qty, int subtotal)>{};
  for (final item in filteredItems) {
    final existing = aggregated[item.categoryId] ?? (0, 0);
    aggregated[item.categoryId] = (existing.$1 + item.qty, existing.$2 + item.subtotal);
  }
  
  // Get kategori names
  final kategoris = await (db.select(db.ticketCategories)).get();
  final kategoriMap = {for (final kat in kategoris) kat.id: kat.name};
  
  // Build result dan sort by total subtotal (descending)
  final result = aggregated.entries
      .map((e) => RekapPenjualanItem(
            kategoriId: e.key,
            kategoriName: kategoriMap[e.key] ?? e.key,
            totalQty: e.value.$1,
            totalSubtotal: e.value.$2,
          ))
      .toList();
  
  result.sort((a, b) => b.totalSubtotal.compareTo(a.totalSubtotal));
  
  return result;
});

// Provider untuk total sistem tunai hari ini (untuk rekonsiliasi kas)
final totalSistemTunaiHariIniProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(transactionsStreamProvider); // Trigger update saat transaksi berubah
  
  // Hitung periode hari ini
  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
  
  // Query transaction hari ini yang TIDAK di-void dan payment method = "tunai"
  final transactions = await (db.select(db.transactions)
        ..where((t) => 
          t.createdAt.isBiggerOrEqualValue(startOfDay) & 
          t.createdAt.isSmallerThanValue(endOfDay) &
          t.isVoided.equals(false) &
          t.paymentMethod.equals(PaymentConstants.tunai)))
      .get();
  
  // Jumlahkan total
  int total = 0;
  for (final transaction in transactions) {
    total += transaction.total;
  }
  
  return total;
});

// Provider untuk total keseluruhan hari ini (semua metode pembayaran)
// Ini hanya untuk info ringkasan, tidak digunakan untuk selisih tunai.
final totalKeseluruhanHariIniProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(transactionsStreamProvider); // Trigger update saat transaksi berubah

  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

  final transactions = await (db.select(db.transactions)
        ..where((t) =>
          t.createdAt.isBiggerOrEqualValue(startOfDay) &
          t.createdAt.isSmallerThanValue(endOfDay) &
          t.isVoided.equals(false)))
      .get();

  int total = 0;
  for (final transaction in transactions) {
    total += transaction.total;
  }

  return total;
});

// Stream semua shift reconciliations, urut dari terbaru
final shiftReconciliationsStreamProvider = StreamProvider<List<ShiftReconciliation>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.shiftReconciliations)
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
      .watch();
});