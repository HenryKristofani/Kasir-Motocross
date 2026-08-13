import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';

// Helper function untuk menghitung sisa kuota per kategori
Future<Map<String, int>> calculateSisaKuotaPerKategori(
  AppDatabase db,
  List<TicketCategoryModel> kategoris,
) async {
  final result = <String, int>{};
  
  for (final kat in kategoris) {
    if (kat.quota != null) {
      // Hitung total qty terjual untuk kategori ini
      final query = db.select(db.transactionItems)
        ..where((t) => t.categoryId.equals(kat.id));
      final items = await query.get();
      final totalTerjual = items.fold<int>(0, (sum, item) => sum + item.qty);
      
      // Sisa kuota = quota - total terjual
      final sisa = kat.quota! - totalTerjual;
      result[kat.id] = sisa > 0 ? sisa : 0;
    }
  }
  
  return result;
}
