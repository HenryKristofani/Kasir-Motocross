import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';

// Helper function untuk menghitung sisa kuota per kategori
// EXCLUDE transaksi yang di-void (isVoided = true)
Future<Map<String, int>> calculateSisaKuotaPerKategori(
  AppDatabase db,
  List<TicketCategoryModel> kategoris,
) async {
  final result = <String, int>{};

  final activeTransactions = await (db.select(
    db.transactions,
  )..where((t) => t.isVoided.equals(false))).get();
  final activeTransactionIds = activeTransactions
      .map((transaction) => transaction.id)
      .toSet();
  final items = await db.select(db.transactionItems).get();
  final soldByCategory = <String, int>{};
  final categoriesById = {
    for (final category in kategoris) category.id: category,
  };

  for (final item in items) {
    if (activeTransactionIds.contains(item.transactionId)) {
      soldByCategory[item.categoryId] =
          (soldByCategory[item.categoryId] ?? 0) + item.qty;
      final category = categoriesById[item.categoryId];
      if (category?.isBundling == true) {
        final day1 = kategoris.where(
          (candidate) =>
              candidate.name == category!.name && candidate.dayType == 'day1',
        );
        final day2 = kategoris.where(
          (candidate) =>
              candidate.name == category!.name && candidate.dayType == 'day2',
        );
        for (final dayCategory in [...day1, ...day2]) {
          soldByCategory[dayCategory.id] =
              (soldByCategory[dayCategory.id] ?? 0) + item.qty;
        }
      }
    }
  }

  final day1ByName = <String, TicketCategoryModel>{};
  final day2ByName = <String, TicketCategoryModel>{};
  for (final category in kategoris) {
    if (category.dayType == 'day1') day1ByName[category.name] = category;
    if (category.dayType == 'day2') day2ByName[category.name] = category;
  }

  for (final category in kategoris) {
    if (category.isBundling) {
      final day1 = day1ByName[category.name];
      final day2 = day2ByName[category.name];
      if (day1 != null && day2 != null) {
        final day1Remaining =
            (day1.quota ?? 0) - (soldByCategory[day1.id] ?? 0);
        final day2Remaining =
            (day2.quota ?? 0) - (soldByCategory[day2.id] ?? 0);
        result[category.id] = [
          day1Remaining,
          day2Remaining,
        ].reduce((a, b) => a < b ? a : b).clamp(0, 1 << 31);
      }
    } else if (category.quota != null) {
      result[category.id] =
          (category.quota! - (soldByCategory[category.id] ?? 0)).clamp(
            0,
            1 << 31,
          );
    }
  }

  return result;
}
