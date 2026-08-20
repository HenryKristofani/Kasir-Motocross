import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import '../data/models/rekap_penjualan_model.dart';
import '../core/constants/payment_constants.dart';
import 'kuota_helper.dart';
import 'package:drift/drift.dart';

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

// Stream semua transaksi, urut dari terbaru
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

// Tanggal aktif yang sedang dipilih di halaman Riwayat
final selectedRiwayatDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// Transaksi yang difilter per hari untuk halaman Riwayat
final filteredTransactionsByDateProvider =
    Provider.family<List<Transaction>, DateTime>((ref, selectedDate) {
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
final kategoriTiketStreamProvider = StreamProvider<List<TicketCategoryModel>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.ticketCategories,
  )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch().map(
    (rows) => rows
        .map(
          (row) => TicketCategoryModel(
            id: row.id,
            name: row.name,
            dayType: row.dayType,
            price: row.price,
            quota: row.quota,
          ),
        )
        .toList(),
  );
});

class TransactionDetailItem {
  const TransactionDetailItem({
    required this.categoryId,
    required this.categoryName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  final String categoryId;
  final String categoryName;
  final int qty;
  final int unitPrice;
  final int subtotal;
}

// Stream semua transaction items (untuk menghitung sisa kuota)
final transactionItemsStreamProvider = StreamProvider<List<TransactionItem>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.select(db.transactionItems).watch();
});

// Query join transaction_items dengan ticket_categories per transaksi
final transactionDetailItemsProvider =
    FutureProvider.family<List<TransactionDetailItem>, String>((
      ref,
      transactionId,
    ) async {
      final db = ref.watch(databaseProvider);
      ref.watch(transactionItemsStreamProvider);
      ref.watch(kategoriTiketStreamProvider);

      final items = await (db.select(
        db.transactionItems,
      )..where((item) => item.transactionId.equals(transactionId))).get();

      final categories = await db.select(db.ticketCategories).get();
      final categoryMap = {
        for (final category in categories) category.id: category,
      };

      return items.map((item) {
        final category = categoryMap[item.categoryId];
        final unitPrice = category?.price ?? 0;

        return TransactionDetailItem(
          categoryId: item.categoryId,
          categoryName: category == null
              ? 'Kategori tidak tersedia'
              : TicketCategoryModel(
                  id: category.id,
                  name: category.name,
                  dayType: category.dayType,
                  price: category.price,
                  quota: category.quota,
                ).displayName,
          qty: item.qty,
          unitPrice: unitPrice,
          subtotal: item.subtotal,
        );
      }).toList();
    });

// Computed provider untuk sisa kuota per kategori
// Otomatis di-recompute ketika kategoris atau transactionItems berubah
final sisaKuotaPerKategoriProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final kategoris = await ref.watch(kategoriTiketStreamProvider.future);
  ref.watch(
    transactionItemsStreamProvider,
  ); // Trigger recompute ketika transaction items berubah
  ref.watch(
    transactionsStreamProvider,
  ); // Trigger recompute ketika transaksi di-void (isVoided berubah)

  return calculateSisaKuotaPerKategori(db, kategoris);
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
  AppDatabase db, {
  DateTime? startAt,
  DateTime? endAtExclusive,
}) async {
  final t = db.transactions;
  final ti = db.transactionItems;
  final c = db.ticketCategories;

  final joinedQuery = db.select(ti).join([
    innerJoin(t, t.id.equalsExp(ti.transactionId)),
    leftOuterJoin(c, c.id.equalsExp(ti.categoryId)),
  ]);

  Expression<bool> predicate = t.isVoided.equals(false);
  if (startAt != null) {
    predicate = predicate & t.createdAt.isBiggerOrEqualValue(startAt);
  }
  if (endAtExclusive != null) {
    predicate = predicate & t.createdAt.isSmallerThanValue(endAtExclusive);
  }
  joinedQuery.where(predicate);

  final rows = await joinedQuery.get();
  if (rows.isEmpty) {
    return [];
  }

  final aggregated = <String, ({int qty, int subtotal, String kategoriName})>{};
  for (final row in rows) {
    final item = row.readTable(ti);
    final category = row.readTableOrNull(c);
    final current = aggregated[item.categoryId];

    aggregated[item.categoryId] = (
      qty: (current?.qty ?? 0) + item.qty,
      subtotal: (current?.subtotal ?? 0) + item.subtotal,
      kategoriName: category == null
          ? (current?.kategoriName ?? item.categoryId)
          : TicketCategoryModel(
              id: category.id,
              name: category.name,
              dayType: category.dayType,
              price: category.price,
              quota: category.quota,
            ).displayName,
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
final rekapPenjualanProvider = FutureProvider<List<RekapPenjualanItem>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final dateFilter = ref.watch(rekapDateFilterProvider);
  ref.watch(
    transactionsStreamProvider,
  ); // Trigger update saat transaksi berubah
  ref.watch(
    transactionItemsStreamProvider,
  ); // Trigger update saat items berubah
  ref.watch(
    kategoriTiketStreamProvider,
  ); // Trigger update saat nama kategori berubah

  final bounds = _resolveRekapDateBounds(dateFilter);
  return _loadRekapPenjualanByRange(
    db,
    startAt: bounds.startAt,
    endAtExclusive: bounds.endAtExclusive,
  );
});

// Provider khusus untuk data rekap hari ini saja (untuk rekonsiliasi kas)
final rekapPenjualanHariIniProvider = FutureProvider<List<RekapPenjualanItem>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  ref.watch(
    transactionsStreamProvider,
  ); // Trigger update saat transaksi berubah
  ref.watch(
    transactionItemsStreamProvider,
  ); // Trigger update saat items berubah

  final now = DateTime.now();
  return _loadRekapPenjualanByRange(
    db,
    startAt: _startOfDay(now),
    endAtExclusive: _endExclusiveOfDay(now),
  );
});

// Provider untuk total sistem tunai hari ini (untuk rekonsiliasi kas)
final totalSistemTunaiHariIniProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(
    transactionsStreamProvider,
  ); // Trigger update saat transaksi berubah

  // Hitung periode hari ini
  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

  // Query transaction hari ini yang TIDAK di-void dan payment method = "tunai"
  final transactions =
      await (db.select(db.transactions)..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startOfDay) &
                t.createdAt.isSmallerThanValue(endOfDay) &
                t.isVoided.equals(false) &
                t.paymentMethod.equals(PaymentConstants.tunai),
          ))
          .get();

  // Jumlahkan total
  int total = 0;
  for (final transaction in transactions) {
    total += transaction.total;
  }

  return total;
});

// Provider untuk total keseluruhan hari ini (semua metode pembayaran)
// Ini hanya untuk info ringkasan, tidak digunakan untuk selisih tunai.
final totalKeseluruhanHariIniProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(
    transactionsStreamProvider,
  ); // Trigger update saat transaksi berubah

  final DateTime now = DateTime.now();
  final DateTime startOfDay = DateTime(now.year, now.month, now.day);
  final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

  final transactions =
      await (db.select(db.transactions)..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startOfDay) &
                t.createdAt.isSmallerThanValue(endOfDay) &
                t.isVoided.equals(false),
          ))
          .get();

  int total = 0;
  for (final transaction in transactions) {
    total += transaction.total;
  }

  return total;
});

// Stream semua shift reconciliations, urut dari terbaru
final shiftReconciliationsStreamProvider =
    StreamProvider<List<ShiftReconciliation>>((ref) {
      final db = ref.watch(databaseProvider);
      return (db.select(
        db.shiftReconciliations,
      )..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();
    });
