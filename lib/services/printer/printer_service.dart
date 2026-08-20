import 'dart:async';

import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/payment_constants.dart';
import '../../data/local/database.dart';
import '../../data/models/ticket_category_model.dart';

class PrinterService {
  PrinterService._();

  static final instance = PrinterService._();

  static const String _selectedPrinterNameKey =
      'selected_bluetooth_printer_name';
  static const String _selectedPrinterAddressKey =
      'selected_bluetooth_printer_address';

  final PrinterBluetoothManager _manager = PrinterBluetoothManager();

  String _formatRupiah(int amount) {
    final isNegative = amount < 0;
    final absolute = amount.abs();
    final formatted = absolute.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '${isNegative ? '-' : ''}Rp$formatted';
  }

  Future<List<PrinterBluetooth>> discoverPrinters({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final List<PrinterBluetooth> foundDevices = [];
    final subscription = _manager.scanResults.listen((devices) {
      foundDevices
        ..clear()
        ..addAll(devices);
    });

    try {
      _manager.startScan(timeout);
      await Future<void>.delayed(timeout + const Duration(seconds: 1));
      _manager.stopScan();
      return foundDevices;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> saveSelectedPrinter(PrinterBluetooth printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectedPrinterNameKey,
      printer.name ?? 'Printer Bluetooth',
    );
    await prefs.setString(_selectedPrinterAddressKey, printer.address ?? '');
  }

  Future<void> clearSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedPrinterNameKey);
    await prefs.remove(_selectedPrinterAddressKey);
  }

  Future<PrinterBluetooth?> getStoredPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_selectedPrinterNameKey);
    final address = prefs.getString(_selectedPrinterAddressKey);

    if (name == null || address == null || address.isEmpty) {
      return null;
    }

    final printers = await discoverPrinters(
      timeout: const Duration(seconds: 4),
    );
    for (final printer in printers) {
      if ((printer.address ?? '').toLowerCase() == address.toLowerCase()) {
        return printer;
      }
      if ((printer.name ?? '').toLowerCase() == name.toLowerCase() &&
          (printer.address ?? '').isNotEmpty) {
        return printer;
      }
    }

    return null;
  }

  Future<PosPrintResult> printTransaction({
    required Transaction transaction,
    required List<TransactionItem> items,
    required Map<String, TicketCategoryModel> categories,
    required String paymentMethod,
    int? uangMasuk,
    int? uangKembali,
  }) async {
    final selectedPrinter = await getStoredPrinter();
    if (selectedPrinter == null) {
      return PosPrintResult.printerNotSelected;
    }

    _manager.selectPrinter(selectedPrinter);

    final profile = await CapabilityProfile.load();
    final bytes = _buildReceiptBytes(
      transaction: transaction,
      items: items,
      categories: categories,
      paymentMethod: paymentMethod,
      uangMasuk: uangMasuk,
      uangKembali: uangKembali,
      profile: profile,
    );

    if (bytes.isEmpty) {
      return PosPrintResult.ticketEmpty;
    }

    return _manager.printTicket(
      bytes,
      chunkSizeBytes: 20,
      queueSleepTimeMs: 20,
    );
  }

  Future<PosPrintResult> reprintTransaction({
    required Transaction transaction,
    required List<TransactionItem> items,
    required Map<String, TicketCategoryModel> categories,
  }) async {
    return printTransaction(
      transaction: transaction,
      items: items,
      categories: categories,
      paymentMethod: transaction.paymentMethod,
      uangMasuk: null,
      uangKembali: null,
    );
  }

  List<int> _buildReceiptBytes({
    required Transaction transaction,
    required List<TransactionItem> items,
    required Map<String, TicketCategoryModel> categories,
    required String paymentMethod,
    int? uangMasuk,
    int? uangKembali,
    required CapabilityProfile profile,
  }) {
    final generator = Generator(PaperSize.mm58, profile);
    var buffer = <int>[];

    buffer += generator.text(
      'MOTOCROSS TICKET',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
      linesAfter: 1,
    );
    buffer += generator.text(
      'Sirkuit Motocross',
      styles: PosStyles(align: PosAlign.center),
      linesAfter: 1,
    );
    buffer += generator.hr();
    buffer += generator.row([
      PosColumn(text: 'Nota', width: 3),
      PosColumn(text: transaction.localNumber, width: 9),
    ]);
    buffer += generator.row([
      PosColumn(text: 'Tgl', width: 3),
      PosColumn(
        text: DateFormat('dd MMM yyyy', 'id_ID').format(transaction.createdAt),
        width: 9,
      ),
    ]);
    buffer += generator.row([
      PosColumn(text: 'Jam', width: 3),
      PosColumn(
        text: DateFormat('HH:mm:ss', 'id_ID').format(transaction.createdAt),
        width: 9,
      ),
    ]);
    buffer += generator.hr();
    buffer += generator.row([
      PosColumn(
        text: 'Qty',
        width: 2,
        styles: PosStyles(align: PosAlign.center),
      ),
      PosColumn(text: 'Jenis', width: 5),
      PosColumn(
        text: 'Nominal',
        width: 5,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);

    for (final item in items) {
      final category = categories[item.categoryId];
      final itemName = category?.displayName ?? 'Tiket';
      final itemSubtotal = item.subtotal;

      buffer += generator.row([
        PosColumn(
          text: '${item.qty}',
          width: 2,
          styles: PosStyles(align: PosAlign.center),
        ),
        PosColumn(text: itemName, width: 5),
        PosColumn(
          text: _formatRupiah(itemSubtotal),
          width: 5,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    buffer += generator.hr();
    buffer += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: PosStyles(bold: true)),
      PosColumn(
        text: _formatRupiah(transaction.total),
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    buffer += generator.row([
      PosColumn(text: 'Bayar', width: 5),
      PosColumn(
        text: PaymentConstants.getDisplayName(paymentMethod),
        width: 7,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);

    if (paymentMethod == PaymentConstants.tunai) {
      if (uangMasuk != null) {
        buffer += generator.row([
          PosColumn(text: 'Uang Masuk', width: 6),
          PosColumn(
            text: _formatRupiah(uangMasuk),
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      if (uangKembali != null) {
        buffer += generator.row([
          PosColumn(text: 'Kembali', width: 6),
          PosColumn(
            text: _formatRupiah(uangKembali),
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }

    buffer += generator.feed(2);
    buffer += generator.text(
      'Terima kasih telah membeli tiket',
      styles: PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    );
    buffer += generator.cut();
    return buffer;
  }
}
