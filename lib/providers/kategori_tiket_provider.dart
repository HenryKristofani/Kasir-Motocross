import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import '../services/sync/sync_service.dart';
import 'database_provider.dart';

// Notifier untuk operasi CRUD kategori tiket
class KategoriTiketNotifier
    extends StateNotifier<AsyncValue<List<TicketCategoryModel>>> {
  final AppDatabase db;

  KategoriTiketNotifier(this.db) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await (db.select(
        db.ticketCategories,
      )..orderBy([(c) => drift.OrderingTerm.asc(c.name)])).get();
      final categories = rows
          .map(
            (row) => TicketCategoryModel(
              id: row.id,
              name: row.name,
              dayType: row.dayType,
              price: row.price,
              quota: row.quota,
            ),
          )
          .toList();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addKategori({
    required String name,
    required String dayType,
    required int price,
    int? quota,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await db
          .into(db.ticketCategories)
          .insert(
            TicketCategoriesCompanion.insert(
              id: id,
              name: name,
              dayType: drift.Value(dayType),
              price: price,
              quota: drift.Value(quota),
              isSynced: const drift.Value(false),
            ),
          );
      Future.microtask(() => SyncService().triggerLocalMutationSync());
      await _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateKategori({
    required String id,
    required String name,
    required String dayType,
    required int price,
    int? quota,
  }) async {
    try {
      await (db.update(
        db.ticketCategories,
      )..where((c) => c.id.equals(id))).write(
        TicketCategoriesCompanion(
          name: drift.Value(name),
          dayType: drift.Value(dayType),
          price: drift.Value(price),
          quota: drift.Value(quota),
          isSynced: const drift.Value(false),
        ),
      );
      Future.microtask(() => SyncService().triggerLocalMutationSync());
      await _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteKategori(String id) async {
    try {
      await (db.delete(
        db.ticketCategories,
      )..where((c) => c.id.equals(id))).go();
      await _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final kategoriTiketNotifierProvider =
    StateNotifierProvider<
      KategoriTiketNotifier,
      AsyncValue<List<TicketCategoryModel>>
    >((ref) {
      final db = ref.watch(databaseProvider);
      return KategoriTiketNotifier(db);
    });
