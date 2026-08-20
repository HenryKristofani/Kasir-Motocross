import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import 'database_provider.dart';
import 'package:drift/drift.dart' as drift;

const seedTicketCategories = <TicketCategoryModel>[
  TicketCategoryModel(
    id: 'vvip-day1',
    name: 'VVIP',
    dayType: 'day1',
    price: 0,
    quota: 20,
  ),
  TicketCategoryModel(
    id: 'vvip-day2',
    name: 'VVIP',
    dayType: 'day2',
    price: 0,
    quota: 20,
  ),
  TicketCategoryModel(
    id: 'vvip-bundling',
    name: 'VVIP',
    dayType: 'bundling',
    price: 0,
  ),
  TicketCategoryModel(
    id: 'vip-day1',
    name: 'VIP',
    dayType: 'day1',
    price: 0,
    quota: 70,
  ),
  TicketCategoryModel(
    id: 'vip-day2',
    name: 'VIP',
    dayType: 'day2',
    price: 0,
    quota: 70,
  ),
  TicketCategoryModel(
    id: 'vip-bundling',
    name: 'VIP',
    dayType: 'bundling',
    price: 0,
  ),
  TicketCategoryModel(
    id: 'paddock-day1',
    name: 'Paddock',
    dayType: 'day1',
    price: 0,
    quota: 1000,
  ),
  TicketCategoryModel(
    id: 'paddock-day2',
    name: 'Paddock',
    dayType: 'day2',
    price: 0,
    quota: 1500,
  ),
  TicketCategoryModel(
    id: 'paddock-bundling',
    name: 'Paddock',
    dayType: 'bundling',
    price: 0,
  ),
  TicketCategoryModel(
    id: 'paddock-undangan-day1',
    name: 'Paddock Undangan',
    dayType: 'day1',
    price: 0,
    quota: 300,
  ),
  TicketCategoryModel(
    id: 'paddock-undangan-day2',
    name: 'Paddock Undangan',
    dayType: 'day2',
    price: 0,
    quota: 300,
  ),
  TicketCategoryModel(
    id: 'umum-day1',
    name: 'Umum',
    dayType: 'day1',
    price: 0,
    quota: 1000,
  ),
  TicketCategoryModel(
    id: 'umum-day2',
    name: 'Umum',
    dayType: 'day2',
    price: 0,
    quota: 2500,
  ),
  TicketCategoryModel(
    id: 'umum-bundling',
    name: 'Umum',
    dayType: 'bundling',
    price: 0,
  ),
  TicketCategoryModel(
    id: 'crosser-day1',
    name: 'Crosser',
    dayType: 'day1',
    price: 0,
    quota: 150,
  ),
  TicketCategoryModel(
    id: 'crosser-day2',
    name: 'Crosser',
    dayType: 'day2',
    price: 0,
    quota: 150,
  ),
];

Future<void> reseedTicketCategories(AppDatabase db) async {
  await db.transaction(() async {
    await db.delete(db.ticketCategories).go();
    for (final category in seedTicketCategories) {
      await db
          .into(db.ticketCategories)
          .insert(
            TicketCategoriesCompanion.insert(
              id: category.id,
              name: category.name,
              dayType: drift.Value(category.dayType),
              price: category.price,
              quota: drift.Value(category.quota),
              isSynced: const drift.Value(false),
            ),
          );
    }
  });
}

// Provider untuk inisialisasi seed data kategori tiket
final initKategoriTiketProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);

  final existingRows = await db.select(db.ticketCategories).get();
  final existingIds = existingRows.map((row) => row.id).toSet();
  final isLegacySeed =
      existingRows.isNotEmpty &&
      existingRows.every(
        (row) => {'MX1', 'MX2', 'Open Class', 'Penonton'}.contains(row.name),
      );
  if (existingRows.isEmpty || isLegacySeed) {
    await reseedTicketCategories(db);
  } else {
    for (final category in seedTicketCategories) {
      if (existingIds.contains(category.id)) continue;
      await db
          .into(db.ticketCategories)
          .insert(
            TicketCategoriesCompanion.insert(
              id: category.id,
              name: category.name,
              dayType: drift.Value(category.dayType),
              price: category.price,
              quota: drift.Value(category.quota),
              isSynced: const drift.Value(false),
            ),
          );
    }
  }

});
