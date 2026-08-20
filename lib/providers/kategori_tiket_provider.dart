import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/ticket_category_model.dart';

class KategoriTiketNotifier
    extends StateNotifier<AsyncValue<List<TicketCategoryModel>>> {
  KategoriTiketNotifier(this.client) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  final SupabaseClient client;

  Future<void> _loadCategories() async {
    try {
      final rows = await client
          .from('ticket_categories')
          .select()
          .order('name')
          .order('day_type');
      final categories = rows
          .map(
            (row) => TicketCategoryModel(
              id: row['id'] as String,
              name: row['name'] as String,
              dayType: row['day_type'] as String? ?? 'day1',
              price: (row['price'] as num).toInt(),
              quota: (row['quota'] as num?)?.toInt(),
            ),
          )
          .toList();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
      await client.from('ticket_categories').insert({
        'id': id,
        'name': name,
        'day_type': dayType,
        'price': price,
        'quota': quota,
      });
      await _loadCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
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
      final updatedRows = await client
          .from('ticket_categories')
          .update({
            'name': name,
            'day_type': dayType,
            'price': price,
            'quota': quota,
          })
          .eq('id', id)
          .select('id');
      if (updatedRows.isEmpty) {
        throw StateError(
          'Tiket tidak diperbarui. Periksa ID tiket dan izin UPDATE Supabase (RLS).',
        );
      }
      await _loadCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteKategori(String id) async {
    try {
      await client.from('ticket_categories').delete().eq('id', id);
      await _loadCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final kategoriTiketNotifierProvider =
    StateNotifierProvider<
      KategoriTiketNotifier,
      AsyncValue<List<TicketCategoryModel>>
    >((ref) {
      return KategoriTiketNotifier(Supabase.instance.client);
    });
