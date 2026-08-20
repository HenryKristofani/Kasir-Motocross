import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/pic_model.dart';

final picStreamProvider = StreamProvider.autoDispose<List<PicModel>>((ref) {
  return Supabase.instance.client
      .from('pic_persons')
      .stream(primaryKey: ['id'])
      .order('name')
      .map(
        (rows) => rows
            .map(
              (row) => PicModel(
                id: row['id'] as String,
                name: row['name'] as String,
              ),
            )
            .toList(),
      );
});

final picServiceProvider = Provider<PicService>((ref) => PicService());

class PicService {
  final _client = Supabase.instance.client;

  Future<void> add(String name) async {
    await _client.from('pic_persons').insert({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name.trim(),
    });
  }

  Future<void> delete(String id) async {
    await _client.from('pic_persons').delete().eq('id', id);
  }
}
