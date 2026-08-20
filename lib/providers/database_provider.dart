import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import '../data/models/rekap_penjualan_model.dart';
import '../core/constants/payment_constants.dart';
import '../services/supabase_ticket_service.dart';

enum RekapPeriodType { hariIni, tanggalTertentu, rentangTanggal, semuaWaktu }

class RekapDateFilter {
  const RekapDateFilter({
    required this.periodType,
    required this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
  });

  factory RekapDateFilter.hariIni() {
    final today = DateTime.now();
    return RekapDateFilter(
      periodType: RekapPeriodType.hariIni,
      selectedDate: DateTime(today.year, today.month, today.day),
    );
  }

  final RekapPeriodType periodType;
  final DateTime selectedDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  RekapDateFilter copyWith({
    RekapPeriodType? periodType,
    DateTime? selectedDate,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool clearRange = false,
  }) {
    return RekapDateFilter(
      periodType: periodType ?? this.periodType,
      selectedDate: selectedDate ?? this.selectedDate,
      rangeStart: clearRange ? null : (rangeStart ?? this.rangeStart),
      rangeEnd: clearRange ? null : (rangeEnd ?? this.rangeEnd),
    );
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final supabaseTicketServiceProvider = Provider<SupabaseTicketService>((ref) {
  return SupabaseTicketService(client: Supabase.instance.client);
});

// Stream semua transaksi, urut dari terbaru
final transactionsStreamProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      return Supabase.instance.client
          .from('transactions')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map(
            (rows) => rows
                .map(
                  (row) => Transaction(
                    id: row['id'] as String,
                    localNumber: row['local_number'] as String,
                    deviceId: row['device_id'] as String,
                    picName: row['pic_name'] as String?,
                    total: (row['total'] as num).toInt(),
                    paymentMethod: row['payment_method'] as String,
                    isSynced: true,
                    createdAt: DateTime.parse(
                      row['created_at'] as String,
                    ).toLocal(),
                    isVoided: row['is_voided'] as bool? ?? false,
                    voidReason: row['void_reason'] as String?,
                    voidedAt: row['voided_at'] == null
                        ? null
                        : DateTime.parse(row['voided_at'] as String).toLocal(),
                  ),
                )
                .toList(),
          );
    });

// Tanggal aktif yang sedang dipilih di halaman Riwayat
final selectedRiwayatDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// Transaksi yang difilter per hari untuk halaman Riwayat
final filteredTransactionsByDateProvider = Provider.autoDispose
    .family<List<Transaction>, DateTime>((ref, selectedDate) {
      final allTransactions =
          ref.watch(transactionsStreamProvider).valueOrNull ??
          const <Transaction>[];
      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final filtered = allTransactions.where((transaction) {
        final createdAt = transaction.createdAt;
        return createdAt.isAfter(
              startOfDay.subtract(const Duration(microseconds: 1)),
            ) &&
            createdAt.isBefore(endOfDay);
      }).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });

// Stream semua kategori tiket dari database lokal, urut berdasarkan nama
final kategoriTiketStreamProvider =
    StreamProvider.autoDispose<List<TicketCategoryModel>>((ref) {
      return ref.watch(supabaseTicketServiceProvider).watchCategories();
    });

class TransactionDetailItem {
  const TransactionDetailItem({
    required this.categoryId,
    required this.categoryName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
    required this.priceOption,
  });

  final String categoryId;
  final String categoryName;
  final int qty;
  final int unitPrice;
  final int subtotal;
  final String priceOption;
}

// Stream semua transaction items (untuk menghitung sisa kuota)
final transactionItemsStreamProvider =
    StreamProvider.autoDispose<List<TransactionItem>>((ref) {
      return Supabase.instance.client
          .from('transaction_items')
          .stream(primaryKey: ['id'])
          .map(
            (rows) => rows
                .map(
                  (row) => TransactionItem(
                    id: row['id'] as String,
                    transactionId: row['transaction_id'] as String,
                    categoryId: row['category_id'] as String,
                    qty: (row['qty'] as num).toInt(),
                    subtotal: (row['subtotal'] as num).toInt(),
                    priceOption: row['price_option'] as String? ?? 'full',
                    isSynced: true,
                  ),
                )
                .toList(),
          );
    });

// Query join transaction_items dengan ticket_categories per transaksi
final transactionDetailItemsProvider = FutureProvider.autoDispose
    .family<List<TransactionDetailItem>, String>((ref, transactionId) async {
      final client = Supabase.instance.client;
      final items = await client
          .from('transaction_items')
          .select()
          .eq('transaction_id', transactionId);
      final categories = await client.from('ticket_categories').select();
      final categoryMap = {
        for (final category in categories) category['id'] as String: category,
      };

      return items.map((row) {
        final category = categoryMap[row['category_id'] as String];
        final categoryModel = category == null
            ? null
            : TicketCategoryModel(
                id: category['id'] as String,
                name: category['name'] as String,
                dayType: category['day_type'] as String? ?? 'day1',
                price: (category['price'] as num).toInt(),
                quota: (category['quota'] as num?)?.toInt(),
              );
        final qty = (row['qty'] as num).toInt();
        final subtotal = (row['subtotal'] as num).toInt();
        final unitPrice = qty > 0 ? subtotal ~/ qty : 0;

        return TransactionDetailItem(
          categoryId: row['category_id'] as String,
          categoryName: categoryModel?.displayName ?? 'Kategori tidak tersedia',
          qty: qty,
          unitPrice: unitPrice,
          subtotal: subtotal,
          priceOption: row['price_option'] as String? ?? 'full',
        );
      }).toList();
    });

// Computed provider untuk sisa kuota per kategori
// Otomatis di-recompute ketika kategoris atau transactionItems berubah
final sisaKuotaPerKategoriProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final kategoris = await ref.watch(kategoriTiketStreamProvider.future);
      final transactions = await ref.watch(transactionsStreamProvider.future);
      final items = await ref.watch(transactionItemsStreamProvider.future);
      final activeIds = transactions
          .where((transaction) => !transaction.isVoided)
          .map((transaction) => transaction.id)
          .toSet();
      final categoriesById = {
        for (final category in kategoris) category.id: category,
      };
      final soldByCategory = <String, int>{};

      for (final item in items) {
        if (!activeIds.contains(item.transactionId)) continue;
        final categoryId = item.categoryId;
        final qty = item.qty;
        soldByCategory[categoryId] = (soldByCategory[categoryId] ?? 0) + qty;
        final category = categoriesById[categoryId];
        if (category?.isBundling == true) {
          for (final day in kategoris.where(
            (candidate) =>
                candidate.name == category!.name &&
                (candidate.dayType == 'day1' || candidate.dayType == 'day2'),
          )) {
            soldByCategory[day.id] = (soldByCategory[day.id] ?? 0) + qty;
          }
        }
      }

      final day1 = <String, TicketCategoryModel>{};
      final day2 = <String, TicketCategoryModel>{};
      for (final category in kategoris) {
        if (category.dayType == 'day1') day1[category.name] = category;
        if (category.dayType == 'day2') day2[category.name] = category;
      }

      final result = <String, int>{};
      for (final category in kategoris) {
        if (category.isBundling) {
          final firstDay = day1[category.name];
          final secondDay = day2[category.name];
          if (firstDay != null && secondDay != null) {
            result[category.id] = [
              (firstDay.quota ?? 0) - (soldByCategory[firstDay.id] ?? 0),
              (secondDay.quota ?? 0) - (soldByCategory[secondDay.id] ?? 0),
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
    });

// State filter periode rekap: hari ini, tanggal tertentu, rentang tanggal, semua waktu.
final rekapDateFilterProvider = StateProvider<RekapDateFilter>(
  (ref) => RekapDateFilter.hariIni(),
);

DateTime _startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _endExclusiveOfDay(DateTime date) =>
    _startOfDay(date).add(const Duration(days: 1));

({DateTime? startAt, DateTime? endAtExclusive}) _resolveRekapDateBounds(
  RekapDateFilter filter,
) {
  switch (filter.periodType) {
    case RekapPeriodType.hariIni:
      final today = _startOfDay(DateTime.now());
      return (
        startAt: today,
        endAtExclusive: today.add(const Duration(days: 1)),
      );
    case RekapPeriodType.tanggalTertentu:
      final selected = _startOfDay(filter.selectedDate);
      return (
        startAt: selected,
        endAtExclusive: selected.add(const Duration(days: 1)),
      );
    case RekapPeriodType.rentangTanggal:
      if (filter.rangeStart == null || filter.rangeEnd == null) {
        final fallback = _startOfDay(DateTime.now());
        return (
          startAt: fallback,
          endAtExclusive: fallback.add(const Duration(days: 1)),
        );
      }

      final start = _startOfDay(filter.rangeStart!);
      final end = _startOfDay(filter.rangeEnd!);
      final lower = start.isBefore(end) ? start : end;
      final upper = start.isAfter(end) ? start : end;
      return (
        startAt: lower,
        endAtExclusive: upper.add(const Duration(days: 1)),
      );
    case RekapPeriodType.semuaWaktu:
      return (startAt: null, endAtExclusive: null);
  }
}

Future<List<RekapPenjualanItem>> _loadRekapPenjualanByRange(
  List<Transaction> transactions,
  List<TransactionItem> items,
  List<TicketCategoryModel> categories, {
  DateTime? startAt,
  DateTime? endAtExclusive,
}) async {
  final transactionIds = transactions
      .where(
        (transaction) =>
            !transaction.isVoided &&
            (startAt == null || !transaction.createdAt.isBefore(startAt)) &&
            (endAtExclusive == null ||
                transaction.createdAt.isBefore(endAtExclusive)),
      )
      .map((transaction) => transaction.id)
      .toSet();
  if (transactionIds.isEmpty) return [];

  if (items.isEmpty) {
    return [];
  }
  final categoryMap = {
    for (final category in categories) category.id: category,
  };

  final aggregated = <String, ({int qty, int subtotal, String kategoriName})>{};
  for (final item in items) {
    final transactionId = item.transactionId;
    if (!transactionIds.contains(transactionId)) continue;
    final categoryId = item.categoryId;
    final category = categoryMap[categoryId];
    final current = aggregated[categoryId];

    aggregated[categoryId] = (
      qty: (current?.qty ?? 0) + item.qty,
      subtotal: (current?.subtotal ?? 0) + item.subtotal,
      kategoriName:
          category?.displayName ?? (current?.kategoriName ?? categoryId),
    );
  }

  final result = aggregated.entries
      .map(
        (entry) => RekapPenjualanItem(
          kategoriId: entry.key,
          kategoriName: entry.value.kategoriName,
          totalQty: entry.value.qty,
          totalSubtotal: entry.value.subtotal,
        ),
      )
      .toList();

  result.sort((a, b) => b.totalSubtotal.compareTo(a.totalSubtotal));
  return result;
}

// Provider untuk rekap penjualan per kategori dengan filter periode fleksibel.
// EXCLUDE transaksi yang di-void (isVoided = true).
final rekapPenjualanProvider =
    FutureProvider.autoDispose<List<RekapPenjualanItem>>((ref) async {
      final dateFilter = ref.watch(rekapDateFilterProvider);
      final transactions = await ref.watch(transactionsStreamProvider.future);
      final items = await ref.watch(transactionItemsStreamProvider.future);
      final categories = await ref.watch(kategoriTiketStreamProvider.future);

      final bounds = _resolveRekapDateBounds(dateFilter);
      return _loadRekapPenjualanByRange(
        transactions,
        items,
        categories,
        startAt: bounds.startAt,
        endAtExclusive: bounds.endAtExclusive,
      );
    });

// Provider khusus untuk data rekap hari ini saja (untuk rekonsiliasi kas)
final rekapPenjualanHariIniProvider =
    FutureProvider.autoDispose<List<RekapPenjualanItem>>((ref) async {
      final transactions = await ref.watch(transactionsStreamProvider.future);
      final items = await ref.watch(transactionItemsStreamProvider.future);
      final categories = await ref.watch(kategoriTiketStreamProvider.future);

      final now = DateTime.now();
      return _loadRekapPenjualanByRange(
        transactions,
        items,
        categories,
        startAt: _startOfDay(now),
        endAtExclusive: _endExclusiveOfDay(now),
      );
    });

final transactionTotalsFromItemsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final items = await ref.watch(transactionItemsStreamProvider.future);
      final totals = <String, int>{};
      for (final item in items) {
        totals[item.transactionId] =
            (totals[item.transactionId] ?? 0) + item.subtotal;
      }
      return totals;
    });

// Provider untuk total sistem tunai hari ini (untuk rekonsiliasi kas)
final totalSistemTunaiHariIniProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final itemTotals = await ref.watch(transactionTotalsFromItemsProvider.future);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return transactions
      .where(
        (transaction) =>
            !transaction.isVoided &&
            transaction.paymentMethod == PaymentConstants.tunai &&
            !transaction.createdAt.isBefore(start) &&
            transaction.createdAt.isBefore(end),
      )
      .fold<int>(
        0,
        (sum, transaction) =>
            sum + (itemTotals[transaction.id] ?? transaction.total),
      );
});

// Provider untuk total keseluruhan hari ini (semua metode pembayaran)
// Ini hanya untuk info ringkasan, tidak digunakan untuk selisih tunai.
final totalKeseluruhanHariIniProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final itemTotals = await ref.watch(transactionTotalsFromItemsProvider.future);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return transactions
      .where(
        (transaction) =>
            !transaction.isVoided &&
            !transaction.createdAt.isBefore(start) &&
            transaction.createdAt.isBefore(end),
      )
      .fold<int>(
        0,
        (sum, transaction) =>
            sum + (itemTotals[transaction.id] ?? transaction.total),
      );
});

// Stream semua shift reconciliations, urut dari terbaru
final shiftReconciliationsStreamProvider =
    StreamProvider.autoDispose<List<ShiftReconciliation>>((ref) {
      return Supabase.instance.client
          .from('shift_reconciliations')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map(
            (rows) => rows
                .map(
                  (row) => ShiftReconciliation(
                    id: row['id'] as String,
                    deviceId: row['device_id'] as String,
                    totalSistemTunai: (row['total_sistem_tunai'] as num)
                        .toInt(),
                    totalFisikTunai: (row['total_fisik_tunai'] as num).toInt(),
                    selisih: (row['selisih'] as num).toInt(),
                    catatan: row['catatan'] as String?,
                    createdAt: DateTime.parse(
                      row['created_at'] as String,
                    ).toLocal(),
                    isSynced: true,
                  ),
                )
                .toList(),
          );
    });
