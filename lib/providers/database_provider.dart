import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import 'kuota_helper.dart';
import 'package:drift/drift.dart';

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