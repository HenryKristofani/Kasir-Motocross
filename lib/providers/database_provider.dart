import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import '../data/models/rekap_penjualan_model.dart';
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

// Stream semua transaction items (untuk menghitung sisa kuota)
final transactionItemsStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.transactionItems).watch();
});

// Computed provider untuk sisa kuota per kategori
// Otomatis di-recompute ketika kategoris atau transactionItems berubah
final sisaKuotaPerKategoriProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final kategoris = await ref.watch(kategoriTiketStreamProvider.future);
  final _ = ref.watch(transactionItemsStreamProvider); // Trigger recompute ketika transaction items berubah
  
  return calculateSisaKuotaPerKategori(db, kategoris);
});

// Provider untuk filter periode rekap penjualan
final rekapPeriodFilterProvider = StateProvider<PeriodFilter>((ref) => PeriodFilter.hariIni);

// Provider untuk rekap penjualan per kategori dengan filter periode
final rekapPenjualanProvider = FutureProvider<List<RekapPenjualanItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final periodFilter = ref.watch(rekapPeriodFilterProvider);
  final _ = ref.watch(transactionsStreamProvider); // Trigger update saat transaksi berubah
  final __ = ref.watch(transactionItemsStreamProvider); // Trigger update saat items berubah
  
  // Hitung periode filter
  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
  
  // Query transaction berdasarkan filter periode
  final query = db.select(db.transactions);
  final List<Transaction> transactions;
  
  if (periodFilter == PeriodFilter.hariIni) {
    transactions = await (query..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay) & t.createdAt.isSmallerThanValue(endOfDay))).get();
  } else {
    transactions = await query.get();
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