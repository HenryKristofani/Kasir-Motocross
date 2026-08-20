import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/payment_constants.dart';
import '../../data/models/ticket_category_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/local/database.dart';
import '../../services/printer/printer_service.dart';
import '../settings/kategori_tiket_screen.dart';
import '../../core/utils/error_message.dart';
import '../../providers/pic_provider.dart';
import '../settings/pic_screen.dart';

class KasirScreen extends ConsumerWidget {
  const KasirScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Future<void> _setCartPriceOption(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
    CartItemEntry cartItem,
    CartPriceOption option,
  ) async {
    if (option != CartPriceOption.manual) {
      ref
          .read(cartProvider.notifier)
          .setOption(categoryId, cartItem.id, option);
      return;
    }

    final controller = TextEditingController(
      text: cartItem.manualPrice?.toString() ?? '',
    );
    final manualPrice = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Harga Manual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal per tiket',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Gunakan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (manualPrice != null) {
      ref
          .read(cartProvider.notifier)
          .setOption(
            categoryId,
            cartItem.id,
            CartPriceOption.manual,
            manualPrice: manualPrice,
          );
    }
  }

  Future<void> _choosePicThenPayment(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoris,
  ) async {
    final picName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final pics = ref.watch(picStreamProvider);
          return AlertDialog(
            title: const Text('Pilih PIC Transaksi'),
            content: SizedBox(
              width: 320,
              child: pics.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(appErrorMessage(error)),
                data: (items) => items.isEmpty
                    ? const Text(
                        'Belum ada PIC. Tambahkan PIC terlebih dahulu.',
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'PIC'),
                        items: items
                            .map(
                              (pic) => DropdownMenuItem(
                                value: pic.name,
                                child: Text(pic.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null)
                            Navigator.pop(dialogContext, value);
                        },
                      ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    dialogContext,
                    MaterialPageRoute(builder: (_) => const PicScreen()),
                  );
                  ref.invalidate(picStreamProvider);
                },
                child: const Text('Tambah PIC'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      ),
    );

    if (picName != null && context.mounted) {
      _showPaymentMethodDialog(context, ref, kategoris, picName);
    }
  }

  void _showPaymentMethodDialog(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoris,
    String? picName,
  ) {
    debugPrint(
      '=== _showPaymentMethodDialog called with context valid: ${context.mounted}',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pilih Metode Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Pilih metode pembayaran untuk melanjutkan transaksi:',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showCashPaymentDialog(context, ref, kategoris, picName);
            },
            icon: const Icon(Icons.payments),
            label: const Text('Tunai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safetyOrange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showQRISPaymentDialog(context, ref, kategoris, picName);
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('QRIS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dirtTan,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCashPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoris,
    String? picName,
  ) {
    final total = _calculateCartTotal(
      ref.read(cartProvider),
      kategoris,
      ref.read(cartProvider.notifier),
    );
    final uangMasukController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final uangMasuk = int.tryParse(uangMasukController.text) ?? 0;
            final kembalian = uangMasuk - total;
            final isValid = uangMasuk >= total;

            return AlertDialog(
              title: const Text('Pembayaran Tunai'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Total Tagihan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.asphalt.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.asphalt.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.asphalt.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        _formatRupiah(total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.asphalt,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: uangMasukController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Uang Masuk',
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uang Kembali',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.asphalt.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kembalian >= 0
                            ? AppColors.safetyOrange.withValues(alpha: 0.08)
                            : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kembalian >= 0
                              ? AppColors.safetyOrange.withValues(alpha: 0.35)
                              : Colors.red.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _formatRupiah(kembalian),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: kembalian >= 0
                                  ? AppColors.safetyOrange
                                  : Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (!isValid) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Uang masuk belum cukup.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isValid
                      ? () async {
                          Navigator.pop(dialogContext);
                          await _bayar(
                            context,
                            ref,
                            kategoris,
                            PaymentConstants.tunai,
                            uangMasuk: uangMasuk,
                            uangKembali: kembalian,
                            picName: picName,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQRISPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoris,
    String? picName,
  ) {
    final total = _calculateCartTotal(
      ref.read(cartProvider),
      kategoris,
      ref.read(cartProvider.notifier),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pembayaran QRIS'),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Tagihan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.asphalt.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.asphalt,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.asphalt.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/qris.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 220,
                            height: 220,
                            color: AppColors.asphalt.withValues(alpha: 0.04),
                            child: const Center(
                              child: Icon(Icons.qr_code_2_outlined, size: 72),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kode QRIS untuk pembayaran',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.asphalt.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _bayar(
                context,
                ref,
                kategoris,
                PaymentConstants.qris,
                picName: picName,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dirtTan,
              foregroundColor: Colors.white,
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Future<void> _attemptPrintAfterSave({
    required BuildContext context,
    required WidgetRef ref,
    required Transaction transaction,
    required List<TransactionItem> items,
    required List<TicketCategoryModel> kategoris,
    required String paymentMethod,
    int? uangMasuk,
    int? uangKembali,
  }) async {
    final categoryMap = {
      for (final category in kategoris)
        category.id: TicketCategoryModel(
          id: category.id,
          name: category.name,
          dayType: category.dayType,
          price: category.price,
          quota: category.quota,
        ),
    };

    final result = await PrinterService.instance.printTransaction(
      transaction: transaction,
      items: items,
      categories: categoryMap,
      paymentMethod: paymentMethod,
      uangMasuk: uangMasuk,
      uangKembali: uangKembali,
    );

    if (!context.mounted) return;

    if (result == PosPrintResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi tersimpan dan struk berhasil dicetak'),
          backgroundColor: AppColors.safetyOrange,
        ),
      );
      return;
    }

    final message = switch (result) {
      PosPrintResult.printerNotSelected =>
        'Printer belum dipilih. Silakan pilih printer dulu.',
      PosPrintResult.timeout =>
        'Waktu cetak habis. Printer mungkin tidak responsif.',
      PosPrintResult.ticketEmpty => 'Data struk kosong.',
      PosPrintResult.printInProgress =>
        'Printer sedang dipakai, coba sebentar lagi.',
      PosPrintResult.scanInProgress => 'Pemindaian printer sedang berlangsung.',
      _ => 'Gagal mencetak struk. Transaksi tetap tersimpan.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[800],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Coba print lagi',
          onPressed: () async {
            await _attemptPrintAfterSave(
              context: context,
              ref: ref,
              transaction: transaction,
              items: items,
              kategoris: kategoris,
              paymentMethod: paymentMethod,
              uangMasuk: uangMasuk,
              uangKembali: uangKembali,
            );
          },
        ),
      ),
    );
  }

  Future<void> _showPrinterPickerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final devices = await PrinterService.instance.discoverPrinters(
      timeout: const Duration(seconds: 6),
    );

    if (!context.mounted) return;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada printer Bluetooth yang terdeteksi. Pastikan printer telah dipasangkan.',
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Printer'),
          content: SizedBox(
            width: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final printer = devices[index];
                return ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(printer.name ?? 'Printer Bluetooth'),
                  subtitle: Text(printer.address ?? '-'),
                  onTap: () async {
                    await PrinterService.instance.saveSelectedPrinter(printer);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Printer default: ${printer.name ?? 'Bluetooth Printer'}',
                          ),
                          backgroundColor: AppColors.safetyOrange,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bayar(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoris,
    String paymentMethod, {
    int? uangMasuk,
    int? uangKembali,
    String? picName,
  }) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final uuid = const Uuid().v4();
    final total = ref.read(cartProvider.notifier).total(kategoris);
    final now = DateTime.now();

    final items = [
      for (final entry in cart.entries)
        for (final cartItem in entry.value)
          TransactionItem(
            id: const Uuid().v4(),
            transactionId: uuid,
            categoryId: entry.key,
            qty: 1,
            subtotal: ref
                .read(cartProvider.notifier)
                .itemPrice(
                  kategoris.firstWhere((item) => item.id == entry.key),
                  cartItem.option,
                  manualPrice: cartItem.manualPrice,
                ),
            priceOption: cartItem.option.value,
            isSynced: true,
          ),
    ];

    try {
      await ref
          .read(supabaseTicketServiceProvider)
          .createSale(
            transactionId: uuid,
            localNumber: 'A-${now.millisecondsSinceEpoch}',
            deviceId: 'device-dev-1',
            picName: picName,
            total: total,
            paymentMethod: paymentMethod,
            items: items
                .map(
                  (item) => {
                    'id': item.id,
                    'category_id': item.categoryId,
                    'qty': item.qty,
                    'subtotal': item.subtotal,
                    'price_option': item.priceOption,
                  },
                )
                .toList(),
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout ditolak: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    ref.read(cartProvider.notifier).clear();
    final savedTransaction = Transaction(
      id: uuid,
      localNumber: 'A-${now.millisecondsSinceEpoch}',
      deviceId: 'device-dev-1',
      picName: picName,
      total: total,
      paymentMethod: paymentMethod,
      isSynced: false,
      createdAt: now,
      isVoided: false,
      voidReason: null,
      voidedAt: null,
    );

    if (context.mounted) {
      final scaffold = ScaffoldMessenger.maybeOf(context);
      if (scaffold != null) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              'Transaksi tersimpan — Total ${_formatRupiah(total)}',
            ),
          ),
        );
      }
    }

    if (context.mounted) {
      await _attemptPrintAfterSave(
        context: context,
        ref: ref,
        transaction: savedTransaction,
        items: items,
        kategoris: kategoris,
        paymentMethod: paymentMethod,
        uangMasuk: uangMasuk,
        uangKembali: uangKembali,
      );
    }
  }

  int _cartItemCount(Map<String, List<CartItemEntry>> cart) {
    return cart.values.fold<int>(0, (sum, entries) => sum + entries.length);
  }

  int _calculateCartTotal(
    Map<String, List<CartItemEntry>> cart,
    List<TicketCategoryModel> categories,
    CartNotifier notifier,
  ) {
    return cart.entries.fold<int>(0, (total, entry) {
      final category = categories.firstWhere((item) => item.id == entry.key);
      return total +
          entry.value.fold<int>(
            0,
            (subtotal, item) =>
                subtotal +
                notifier.itemPrice(
                  category,
                  item.option,
                  manualPrice: item.manualPrice,
                ),
          );
    });
  }

  void _showCartBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoris,
  ) {
    final pageContext = context;

    void openPaymentDialog() {
      _choosePicThenPayment(pageContext, ref, kategoris);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final cart = ref.watch(cartProvider);
            final total = _calculateCartTotal(
              cart,
              kategoris,
              ref.read(cartProvider.notifier),
            );

            Future<void> continueToPayment() async {
              debugPrint('=== Lanjut ke Pembayaran pressed in cart sheet');
              if (Navigator.of(sheetContext).canPop()) {
                debugPrint('=== Before Navigator.pop() on cart sheet');
                Navigator.of(sheetContext).pop();
                debugPrint('=== After Navigator.pop() on cart sheet');
              }

              await Future<void>.delayed(const Duration(milliseconds: 50));

              debugPrint('=== Before openPaymentDialog call');
              if (pageContext.mounted) {
                openPaymentDialog();
              }
              debugPrint('=== After openPaymentDialog call');
            }

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 6,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.asphalt.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: AppColors.safetyOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Keranjang',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${_cartItemCount(cart)} item',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.asphalt.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (cart.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_shopping_cart_outlined,
                                size: 56,
                                color: AppColors.asphalt.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Keranjang masih kosong',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.asphalt.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _cartItemCount(cart),
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final flatItems = [
                              for (final entry in cart.entries)
                                for (final item in entry.value)
                                  (entry.key, item),
                            ];
                            final (categoryId, cartItem) = flatItems[index];
                            final category = kategoris.firstWhere(
                              (item) => item.id == categoryId,
                            );
                            final subtotal = ref
                                .read(cartProvider.notifier)
                                .itemPrice(
                                  category,
                                  cartItem.option,
                                  manualPrice: cartItem.manualPrice,
                                );

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.displayName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatRupiah(subtotal)} / pcs - ${cartItem.option.label}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.asphalt
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatRupiah(subtotal),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.safetyOrange,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      DropdownButton<CartPriceOption>(
                                        value: cartItem.option,
                                        items: CartPriceOption.values
                                            .map(
                                              (option) => DropdownMenuItem(
                                                value: option,
                                                child: Text(option.label),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (option) {
                                          if (option != null) {
                                            _setCartPriceOption(
                                              context,
                                              ref,
                                              categoryId,
                                              cartItem,
                                              option,
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Kurangi qty',
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .decrement(categoryId),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        color: AppColors.asphalt,
                                      ),
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '1',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Tambah qty',
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .increment(categoryId),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        color: AppColors.safetyOrange,
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus item',
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .remove(categoryId),
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: AppColors.trackWhite,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.asphalt.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _formatRupiah(total),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.safetyOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: cart.isEmpty
                                  ? null
                                  : continueToPayment,
                              child: const Text('Lanjut ke Pembayaran'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Daftar kategori tiket — dipakai di kedua layout (portrait & landscape)
  Widget _buildCategoryList(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<CartItemEntry>> cart,
    List<TicketCategoryModel> kategoris,
    Map<String, int> sisaKuotaMap,
  ) {
    final grouped = <String, List<TicketCategoryModel>>{};
    for (final category in kategoris) {
      grouped.putIfAbsent(category.name, () => []).add(category);
    }
    final rows = <Object>[];
    for (final entry in grouped.entries) {
      rows.add(entry.key);
      rows.addAll(entry.value);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              row,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        }

        final cat = row as TicketCategoryModel;
        final qty = cart[cat.id]?.length ?? 0;
        final selected = qty > 0;
        final sisaKuota = sisaKuotaMap[cat.id];
        final hasQuota = sisaKuotaMap.containsKey(cat.id);
        final isHabis = hasQuota && sisaKuota == 0;

        return Card(
          key: ValueKey(cat.id),
          margin: const EdgeInsets.only(bottom: 10),
          color: isHabis
              ? AppColors.asphalt.withValues(alpha: 0.05)
              : selected
              ? AppColors.safetyOrange.withValues(alpha: 0.06)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHabis
                  ? Colors.grey.withValues(alpha: 0.3)
                  : selected
                  ? AppColors.safetyOrange
                  : AppColors.asphalt.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Opacity(
            opacity: isHabis ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Badge nomor kategori — kesan plat/bib nomor balap
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isHabis ? Colors.grey : AppColors.asphalt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isHabis
                        ? const Text(
                            'X',
                            style: TextStyle(
                              color: AppColors.trackWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          )
                        : Text(
                            cat.name
                                .substring(0, cat.name.length >= 2 ? 2 : 1)
                                .toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.trackWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cat.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            if (isHabis)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'HABIS',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _formatRupiah(cat.price),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (hasQuota && sisaKuota != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.safetyOrange.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.safetyOrange,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Sisa: $sisaKuota',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.safetyOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: qty > 0
                            ? () => ref
                                  .read(cartProvider.notifier)
                                  .decrement(cat.id)
                            : null,
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        // Disable tombol + jika kuota habis atau qty sudah mencapai sisa kuota
                        onPressed:
                            isHabis || (hasQuota && qty >= (sisaKuota ?? 0))
                            ? null
                            : () => ref
                                  .read(cartProvider.notifier)
                                  .increment(cat.id),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              isHabis || (hasQuota && qty >= (sisaKuota ?? 0))
                              ? Colors.grey
                              : AppColors.safetyOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Panel ringkasan keranjang untuk mode landscape — dengan scroll untuk item banyak
  Widget _buildCartSummaryPanel(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<CartItemEntry>> cart,
    int total,
    List<TicketCategoryModel> kategoris,
    Map<String, int> sisaKuotaMap,
  ) {
    final displayedTotal = _calculateCartTotal(
      cart,
      kategoris,
      ref.read(cartProvider.notifier),
    );
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.asphalt.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max, // Gunakan ruang penuh untuk panel
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keep the same callback object used by the main checkout buttons.
            // This avoids a duplicate flow and makes the behavior identical.
            // Header
            Text(
              'Ringkasan',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Divider(height: 0, thickness: 1),
            const SizedBox(height: 12),

            // Daftar item keranjang — scrollable jika banyak
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada tiket dipilih',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      children: cart.entries.expand((e) {
                        final cat = kategoris.firstWhere((c) => c.id == e.key);
                        return e.value.map((cartItem) {
                          final itemTotal = ref
                              .read(cartProvider.notifier)
                              .itemPrice(
                                cat,
                                cartItem.option,
                                manualPrice: cartItem.manualPrice,
                              );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${cat.displayName} (${cartItem.option.label})',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(itemTotal),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          );
                        });
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 0, thickness: 1),
            const SizedBox(height: 12),

            // Total + Tombol Bayar — pinned di bawah (tidak ikut scroll)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  _formatRupiah(displayedTotal),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.safetyOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.isEmpty
                    ? null
                    : () => _choosePicThenPayment(context, ref, kategoris),
                child: const Text('BAYAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom bar ringkasan untuk mode portrait — minimal height, no scroll
  Widget _buildCartSummaryBottomBar(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<CartItemEntry>> cart,
    int total,
    List<TicketCategoryModel> kategoris,
    Map<String, int> sisaKuotaMap,
  ) {
    final displayedTotal = _calculateCartTotal(
      cart,
      kategoris,
      ref.read(cartProvider.notifier),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tetap minimal untuk bottom bar
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total + Tombol Bayar — hanya ini yang ditampilkan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  _formatRupiah(displayedTotal),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.safetyOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.isEmpty
                    ? null
                    : () => _choosePicThenPayment(context, ref, kategoris),
                child: const Text('BAYAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final kategoriStream = ref.watch(kategoriTiketStreamProvider);

    return Scaffold(
      body: kategoriStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(appErrorMessage(err), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(kategoriTiketStreamProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (kategoris) {
          if (kategoris.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: AppColors.asphalt.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kategori tiket',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const KategoriTiketScreen(),
                      ),
                    ),
                    child: const Text('Tambah Kategori'),
                  ),
                ],
              ),
            );
          }

          // Watch sisa kuota per kategori
          final sisaKuotaAsync = ref.watch(sisaKuotaPerKategoriProvider);

          return sisaKuotaAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text(appErrorMessage(err))),
            data: (sisaKuotaMap) {
              final total = ref.read(cartProvider.notifier).total(kategoris);

              return Scaffold(
                appBar: AppBar(
                  title: const Text('KASIR — TIKET MOTOCROSS'),
                  actions: [
                    Builder(
                      builder: (context) {
                        final cartForBadge = ref.watch(cartProvider);
                        final itemCount = _cartItemCount(cartForBadge);

                        return itemCount > 0
                            ? Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.shopping_cart),
                                    tooltip: 'Keranjang',
                                    onPressed: () => _showCartBottomSheet(
                                      context,
                                      ref,
                                      kategoris,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.safetyOrange,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(Icons.shopping_cart),
                                tooltip: 'Keranjang',
                                onPressed: () => _showCartBottomSheet(
                                  context,
                                  ref,
                                  kategoris,
                                ),
                              );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_outlined),
                      tooltip: 'Pilih Printer',
                      onPressed: () => _showPrinterPickerDialog(context, ref),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KategoriTiketScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                body: OrientationBuilder(
                  builder: (context, orientation) {
                    if (orientation == Orientation.landscape) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCategoryList(
                              context,
                              ref,
                              cart,
                              kategoris,
                              sisaKuotaMap,
                            ),
                          ),
                          _buildCartSummaryPanel(
                            context,
                            ref,
                            cart,
                            total,
                            kategoris,
                            sisaKuotaMap,
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: _buildCategoryList(
                            context,
                            ref,
                            cart,
                            kategoris,
                            sisaKuotaMap,
                          ),
                        ),
                        _buildCartSummaryBottomBar(
                          context,
                          ref,
                          cart,
                          total,
                          kategoris,
                          sisaKuotaMap,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
