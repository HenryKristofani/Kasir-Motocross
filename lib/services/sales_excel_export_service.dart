import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/local/database.dart';
import '../data/models/ticket_category_model.dart';
import '../providers/database_provider.dart';

class SalesExcelExportService {
  Future<File> export({
    required RekapDateFilter filter,
    required List<Transaction> transactions,
    required List<TransactionItem> items,
    required List<TicketCategoryModel> categories,
  }) async {
    final bounds = _resolveBounds(filter);
    final filteredTransactions =
        transactions
            .where(
              (transaction) =>
                  (bounds.$1 == null ||
                      !transaction.createdAt.isBefore(bounds.$1!)) &&
                  (bounds.$2 == null ||
                      transaction.createdAt.isBefore(bounds.$2!)),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final transactionIds = filteredTransactions.map((item) => item.id).toSet();
    final filteredItems = items
        .where((item) => transactionIds.contains(item.transactionId))
        .toList();
    final categoryById = {
      for (final category in categories) category.id: category,
    };

    final workbook = Excel.createExcel();
    final summary = workbook['Ringkasan'];
    final daily = workbook['Rekap Harian'];
    final byTicket = workbook['Rekap Per Tiket'];
    final dailyByTicket = workbook['Harian x Tiket'];
    final details = workbook['Detail Transaksi'];
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }
    workbook.setDefaultSheet('Ringkasan');

    _append(summary, ['REKAP PENJUALAN TIKET MOTOCROSS']);
    _append(summary, ['Periode', _periodLabel(filter)]);
    _append(summary, [
      'Dibuat',
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    ]);
    _append(summary, []);

    final activeTransactions = filteredTransactions
        .where((item) => !item.isVoided)
        .toList();
    final activeIds = activeTransactions.map((item) => item.id).toSet();
    final activeItems = filteredItems
        .where((item) => activeIds.contains(item.transactionId))
        .toList();
    final soldByCategoryId = <String, int>{};
    final quotaUsageByCategoryId = <String, int>{};
    final nominalByCategoryId = <String, int>{};
    final ticketTransactionIds = <String, Set<String>>{};
    final dailyTotals = <String, _SalesAggregate>{};
    final dailyTicketTotals = <String, _SalesAggregate>{};
    for (final item in activeItems) {
      final category = categoryById[item.categoryId];
      if (category == null) continue;

      soldByCategoryId[item.categoryId] =
          (soldByCategoryId[item.categoryId] ?? 0) + item.qty;
      quotaUsageByCategoryId[item.categoryId] =
          (quotaUsageByCategoryId[item.categoryId] ?? 0) + item.qty;
      nominalByCategoryId[item.categoryId] =
          (nominalByCategoryId[item.categoryId] ?? 0) + item.subtotal;
      ticketTransactionIds
          .putIfAbsent(item.categoryId, () => <String>{})
          .add(item.transactionId);

      final transaction = activeTransactions.firstWhere(
        (candidate) => candidate.id == item.transactionId,
      );
      final dateKey = _dateKey(transaction.createdAt);
      _addAggregate(
        dailyTotals,
        dateKey,
        item.qty,
        item.subtotal,
        item.transactionId,
        paymentMethod: transaction.paymentMethod,
      );
      _addAggregate(
        dailyTicketTotals,
        '$dateKey|${item.categoryId}',
        item.qty,
        item.subtotal,
        item.transactionId,
      );

      if (category.isBundling) {
        for (final dayCategory in categories.where(
          (candidate) =>
              candidate.name == category.name &&
              (candidate.dayType == 'day1' || candidate.dayType == 'day2'),
        )) {
          quotaUsageByCategoryId[dayCategory.id] =
              (quotaUsageByCategoryId[dayCategory.id] ?? 0) + item.qty;
          soldByCategoryId[dayCategory.id] =
              (soldByCategoryId[dayCategory.id] ?? 0) + item.qty;
        }
      }
    }
    final totalQty = activeItems.fold<int>(0, (sum, item) => sum + item.qty);
    final totalNominal = activeItems.fold<int>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final totalTransactions = activeTransactions.length;
    final voidedTransactions = filteredTransactions
        .where((item) => item.isVoided)
        .length;
    final totalCapacity = categories
        .where((category) => !category.isBundling && category.quota != null)
        .fold<int>(0, (sum, category) => sum + (category.quota ?? 0));
    final totalRemaining = categories
        .where((category) => !category.isBundling && category.quota != null)
        .fold<int>(0, (sum, category) {
          final sold = quotaUsageByCategoryId[category.id] ?? 0;
          return sum + ((category.quota ?? 0) - sold).clamp(0, 1 << 31);
        });

    _append(summary, ['Indikator', 'Nilai']);
    _append(summary, ['Transaksi aktif', totalTransactions]);
    _append(summary, ['Transaksi dibatalkan', voidedTransactions]);
    _append(summary, ['Tiket terjual', totalQty]);
    _append(summary, ['Total penjualan', totalNominal]);
    _append(summary, ['Total kapasitas tiket', totalCapacity]);
    _append(summary, ['Sisa tiket', totalRemaining]);

    _append(daily, [
      'Tanggal',
      'Transaksi Aktif',
      'Transaksi Dibatalkan',
      'Tiket Terjual',
      'Total Penjualan',
      'Tunai',
      'QRIS',
      'Metode Lain',
    ]);
    final allDateKeys = <String>{
      ...dailyTotals.keys,
      ...filteredTransactions.map(
        (transaction) => _dateKey(transaction.createdAt),
      ),
    }.toList()..sort();
    for (final dateKey in allDateKeys) {
      final dateTransactions = filteredTransactions.where(
        (transaction) => _dateKey(transaction.createdAt) == dateKey,
      );
      final aggregate = dailyTotals[dateKey] ?? _SalesAggregate();
      final voidedCount = dateTransactions
          .where((item) => item.isVoided)
          .length;
      final activeCount = dateTransactions
          .where((item) => !item.isVoided)
          .length;
      _append(daily, [
        dateKey,
        activeCount,
        voidedCount,
        aggregate.qty,
        aggregate.subtotal,
        aggregate.paymentTotals['tunai'] ?? 0,
        aggregate.paymentTotals['qris'] ?? 0,
        aggregate.paymentTotals.entries
            .where((entry) => entry.key != 'tunai' && entry.key != 'qris')
            .fold<int>(0, (sum, entry) => sum + entry.value),
      ]);
    }

    _append(byTicket, [
      'ID Tiket',
      'Nama Tiket',
      'Hari / Paket',
      'Harga Dasar',
      'Kuota',
      'Terjual Langsung',
      'Terpakai Untuk Kuota',
      'Sisa Kuota',
      'Jumlah Transaksi',
      'Total Nominal',
    ]);
    for (final category in categories) {
      final quota = category.quota;
      final quotaUsed = quotaUsageByCategoryId[category.id] ?? 0;
      _append(byTicket, [
        category.id,
        category.name,
        _dayLabel(category.dayType),
        category.price,
        quota ?? '',
        soldByCategoryId[category.id] ?? 0,
        category.isBundling ? '' : quotaUsed,
        quota == null ? '' : (quota - quotaUsed).clamp(0, 1 << 31),
        ticketTransactionIds[category.id]?.length ?? 0,
        nominalByCategoryId[category.id] ?? 0,
      ]);
    }

    _append(dailyByTicket, [
      'Tanggal',
      'ID Tiket',
      'Nama Tiket',
      'Hari / Paket',
      'Jumlah Transaksi',
      'Qty Terjual',
      'Total Nominal',
    ]);
    final dailyTicketEntries = dailyTicketTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in dailyTicketEntries) {
      final separator = entry.key.indexOf('|');
      final dateKey = entry.key.substring(0, separator);
      final categoryId = entry.key.substring(separator + 1);
      final category = categoryById[categoryId];
      _append(dailyByTicket, [
        dateKey,
        categoryId,
        category?.name ?? categoryId,
        _dayLabel(category?.dayType),
        entry.value.transactionIds.length,
        entry.value.qty,
        entry.value.subtotal,
      ]);
    }

    _append(details, [
      'No',
      'Waktu',
      'Nomor Transaksi',
      'PIC',
      'Kategori',
      'Hari',
      'Opsi Harga',
      'Qty',
      'Harga Efektif / Tiket',
      'Subtotal',
      'Metode Pembayaran',
      'Status',
      'Device ID',
    ]);
    var number = 1;
    for (final transaction in filteredTransactions) {
      final transactionItems = filteredItems.where(
        (item) => item.transactionId == transaction.id,
      );
      for (final item in transactionItems) {
        final category = categoryById[item.categoryId];
        _append(details, [
          number++,
          transaction.createdAt,
          transaction.localNumber,
          transaction.picName ?? '',
          category?.name ?? item.categoryId,
          category?.dayType ?? '',
          _optionLabel(item.priceOption),
          item.qty,
          item.qty == 0 ? 0 : item.subtotal ~/ item.qty,
          item.subtotal,
          transaction.paymentMethod,
          transaction.isVoided ? 'Dibatalkan' : 'Aktif',
          transaction.deviceId,
        ]);
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      path.join(directory.path, 'rekap_penjualan_$timestamp.xlsx'),
    );
    final bytes = workbook.encode();
    if (bytes == null) throw StateError('Gagal membuat file Excel.');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _append(Sheet sheet, List<Object?> values) {
    sheet.appendRow(values.map(_cell).toList());
  }

  void _addAggregate(
    Map<String, _SalesAggregate> aggregates,
    String key,
    int qty,
    int subtotal,
    String transactionId, {
    String? paymentMethod,
  }) {
    final aggregate = aggregates.putIfAbsent(key, _SalesAggregate.new);
    aggregate.qty += qty;
    aggregate.subtotal += subtotal;
    aggregate.transactionIds.add(transactionId);
    if (paymentMethod != null) {
      aggregate.paymentTotals[paymentMethod] =
          (aggregate.paymentTotals[paymentMethod] ?? 0) + subtotal;
    }
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _dayLabel(String? dayType) => switch (dayType) {
    'day1' => 'Day 1',
    'day2' => 'Day 2',
    'bundling' => 'Bundling 2 Hari',
    _ => '',
  };

  CellValue _cell(Object? value) {
    if (value is int) return IntCellValue(value);
    if (value is DateTime) return DateTimeCellValue.fromDateTime(value);
    return TextCellValue(value?.toString() ?? '');
  }

  String _optionLabel(String option) => switch (option) {
    'half' => '50%',
    'free' => 'Free',
    'manual' => 'Manual',
    _ => '100%',
  };

  String _periodLabel(RekapDateFilter filter) => switch (filter.periodType) {
    RekapPeriodType.hariIni => 'Hari Ini',
    RekapPeriodType.tanggalTertentu => DateFormat(
      'yyyy-MM-dd',
    ).format(filter.selectedDate),
    RekapPeriodType.rentangTanggal =>
      '${filter.rangeStart} - ${filter.rangeEnd}',
    RekapPeriodType.semuaWaktu => 'Semua Waktu',
  };

  (DateTime?, DateTime?) _resolveBounds(RekapDateFilter filter) {
    DateTime start(DateTime date) => DateTime(date.year, date.month, date.day);
    switch (filter.periodType) {
      case RekapPeriodType.hariIni:
        final value = start(DateTime.now());
        return (value, value.add(const Duration(days: 1)));
      case RekapPeriodType.tanggalTertentu:
        final value = start(filter.selectedDate);
        return (value, value.add(const Duration(days: 1)));
      case RekapPeriodType.rentangTanggal:
        if (filter.rangeStart == null || filter.rangeEnd == null) {
          return (null, null);
        }
        final first = start(filter.rangeStart!);
        final last = start(filter.rangeEnd!);
        final lower = first.isBefore(last) ? first : last;
        final upper = first.isAfter(last) ? first : last;
        return (lower, upper.add(const Duration(days: 1)));
      case RekapPeriodType.semuaWaktu:
        return (null, null);
    }
  }
}

class _SalesAggregate {
  int qty = 0;
  int subtotal = 0;
  final Set<String> transactionIds = <String>{};
  final Map<String, int> paymentTotals = <String, int>{};
}
