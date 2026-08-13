import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';

// Helper function untuk menghitung sisa kuota per kategori
// EXCLUDE transaksi yang di-void (isVoided = true)
Future<Map<String, int>> calculateSisaKuotaPerKategori(
  AppDatabase db,
  List<TicketCategoryModel> kategoris,
) async {
  final result = <String, int>{};
  
  for (final kat in kategoris) {
    if (kat.quota != null) {
      // Hitung total qty terjual untuk kategori ini (HANYA dari transaksi yang TIDAK di-void)
      // Step 1: Get all active (non-voided) transaction IDs
      final activeTransactions = await (db.select(db.transactions)
        ..where((t) => t.isVoided.equals(false)))
        .get();
      final activeTransactionIds = activeTransactions.map((t) => t.id).toList();
      
      // Step 2: Query items for this category
      final items = await (db.select(db.transactionItems)
        ..where((i) => i.categoryId.equals(kat.id)))
        .get();
      
      // Step 3: Filter items to only those from active transactions
      final activeItems = items.where((item) => activeTransactionIds.contains(item.transactionId)).toList();
      final totalTerjual = activeItems.fold<int>(0, (sum, item) => sum + item.qty);
      
      // Sisa kuota = quota - total terjual (hanya dari transaksi aktif)
      final sisa = kat.quota! - totalTerjual;
      result[kat.id] = sisa > 0 ? sisa : 0;
    }
  }
  
  return result;
}
