import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/ticket_category_model.dart';

class SupabaseTicketService {
  SupabaseTicketService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<List<TicketCategoryModel>> watchCategories() {
    return _client
        .from('ticket_categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .order('day_type')
        .map(
          (rows) => rows
              .map(
                (row) => TicketCategoryModel(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  dayType: row['day_type'] as String? ?? 'day1',
                  price: (row['price'] as num).toInt(),
                  quota: (row['quota'] as num?)?.toInt(),
                ),
              )
              .toList(),
        );
  }

  Future<Map<String, dynamic>> createSale({
    required String transactionId,
    required String localNumber,
    required String deviceId,
    required String? picName,
    required String? keterangan,
    required int total,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.rpc(
      'create_ticket_sale',
      params: {
        'p_transaction_id': transactionId,
        'p_local_number': localNumber,
        'p_device_id': deviceId,
        'p_pic_name': picName,
        'p_keterangan': keterangan,
        'p_total': total,
        'p_payment_method': paymentMethod,
        'p_items': items,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }
}
