import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import 'database_provider.dart';
import 'package:drift/drift.dart' as drift;

// Provider untuk inisialisasi seed data kategori tiket
final initKategoriTiketProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);

  // Cek apakah sudah ada data kategori
  final existingCount = await (db.select(db.ticketCategories)).get().then((rows) => rows.length);

  if (existingCount == 0) {
    // Seed data awal
    final seedCategories = [
      const TicketCategoryModel(id: 'cat-1', name: 'MX1', price: 50000),
      const TicketCategoryModel(id: 'cat-2', name: 'MX2', price: 50000),
      const TicketCategoryModel(id: 'cat-3', name: 'Open Class', price: 35000),
      const TicketCategoryModel(id: 'cat-4', name: 'Penonton', price: 20000),
    ];

    for (final cat in seedCategories) {
      await db.into(db.ticketCategories).insert(
            TicketCategoriesCompanion.insert(
              id: cat.id,
              name: cat.name,
              price: cat.price,
              quota: const drift.Value.absent(),
            ),
          );
    }
  }
});
