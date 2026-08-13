import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
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