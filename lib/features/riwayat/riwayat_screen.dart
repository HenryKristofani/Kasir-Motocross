import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pos_date_picker.dart';
import '../../core/constants/payment_constants.dart';
import '../../data/models/ticket_category_model.dart';
import '../../providers/database_provider.dart';
import '../../data/local/database.dart';
import '../../services/printer/printer_service.dart';
import '../shift/rekonsiliasi_screen.dart';

class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final selected = await showPosDatePicker(
      context: context,
      initialDate: currentDate,
      helpText: 'Pilih tanggal riwayat',
    );

    if (selected != null && context.mounted) {
      ref.read(selectedRiwayatDateProvider.notifier).state = selected;
    }
  }

  Future<void> _reprintTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final client = Supabase.instance.client;
    final itemRows = await client
        .from('transaction_items')
        .select()
        .eq('transaction_id', transaction.id);
    final categories = await client.from('ticket_categories').select();
    final items = itemRows
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
        .toList();
    final categoryMap = {
      for (final item in categories)
        item['id'] as String: TicketCategoryModel(
          id: item['id'] as String,
          name: item['name'] as String,
          dayType: item['day_type'] as String? ?? 'day1',
          price: (item['price'] as num).toInt(),
          quota: (item['quota'] as num?)?.toInt(),
        ),
    };

    final result = await PrinterService.instance.reprintTransaction(
      transaction: transaction,
      items: items,
      categories: categoryMap,
    );

    if (!context.mounted) return;

    final message = result == PosPrintResult.success
        ? 'Struk berhasil dicetak ulang.'
        : 'Gagal mencetak ulang struk.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result == PosPrintResult.success
            ? AppColors.safetyOrange
            : Colors.red,
      ),
    );
  }

  Future<void> _showTransactionDetailSheet(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final detailItems =
                ref
                    .watch(transactionDetailItemsProvider(transaction.id))
                    .valueOrNull ??
                const <TransactionDetailItem>[];
            final total = detailItems.fold<int>(
              0,
              (sum, item) => sum + item.subtotal,
            );

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
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
                            Icons.receipt_long,
                            color: AppColors.safetyOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detail Transaksi',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          if (transaction.isVoided)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DIBATALKAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (transaction.isVoided)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pembatalan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (transaction.voidReason != null &&
                                        transaction.voidReason!.isNotEmpty)
                                      Text('Alasan: ${transaction.voidReason}'),
                                    if (transaction.voidedAt != null)
                                      Text(
                                        'Waktu: ${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(transaction.voidedAt!)}',
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Nomor Nota',
                              transaction.localNumber,
                            ),
                            _buildDetailRow(
                              'Tanggal',
                              DateFormat(
                                'dd MMM yyyy',
                                'id_ID',
                              ).format(transaction.createdAt),
                            ),
                            _buildDetailRow(
                              'Jam',
                              DateFormat(
                                'HH:mm:ss',
                                'id_ID',
                              ).format(transaction.createdAt),
                            ),
                            _buildDetailRow(
                              'Metode Pembayaran',
                              PaymentConstants.getDisplayName(
                                transaction.paymentMethod,
                              ),
                            ),
                            if (transaction.picName != null &&
                                transaction.picName!.isNotEmpty)
                              _buildDetailRow('PIC', transaction.picName!),
                            if (transaction.paymentMethod ==
                                PaymentConstants.tunai) ...[
                              _buildDetailRow(
                                'Uang Masuk',
                                'Data tidak tersimpan pada transaksi',
                              ),
                              _buildDetailRow(
                                'Kembalian',
                                'Data tidak tersimpan pada transaksi',
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              'Rincian Item',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            if (detailItems.isEmpty)
                              const Text('Tidak ada item transaksi.')
                            else
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: detailItems.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = detailItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.categoryName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.qty} x ${_formatRupiah(item.unitPrice)} (${_priceOptionLabel(item.priceOption)})',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: AppColors.asphalt
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(item.subtotal),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: AppColors.safetyOrange,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: AppColors.trackWhite,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.asphalt.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: !transaction.isVoided
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await _reprintTransaction(
                                    context,
                                    ref,
                                    transaction,
                                  );
                                },
                                icon: const Icon(Icons.print),
                                label: const Text('Reprint'),
                              ),
                            )
                          : const SizedBox.shrink(),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: AppColors.asphalt.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _priceOptionLabel(String option) {
    return switch (option) {
      'half' => '50%',
      'free' => 'Free',
      'manual' => 'Manual',
      _ => '100%',
    };
  }

  void _showVoidDialog(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final canSubmit = reasonController.text.trim().isNotEmpty;

          return AlertDialog(
            title: const Text('Batalkan Transaksi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor: ${transaction.localNumber}'),
                Text('Total: ${_formatRupiah(transaction.total)}'),
                const SizedBox(height: 16),
                const Text('Alasan Pembatalan:'),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan alasan pembatalan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: canSubmit
                    ? () async {
                        await Supabase.instance.client
                            .from('transactions')
                            .update({
                              'is_voided': true,
                              'void_reason': reasonController.text.trim(),
                              'voided_at': DateTime.now().toIso8601String(),
                            })
                            .eq('id', transaction.id)
                            .eq('is_voided', false);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil dibatalkan'),
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetyOrange,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text('Batalkan Transaksi'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedRiwayatDateProvider);
    final transactionItems = ref.watch(transactionItemsStreamProvider);
    final filteredTransactions = ref.watch(
      filteredTransactionsByDateProvider(selectedDate),
    );

    final itemTotalsByTransactionId = transactionItems.maybeWhen(
      data: (items) {
        final totals = <String, int>{};
        for (final item in items) {
          totals[item.transactionId] =
              (totals[item.transactionId] ?? 0) + item.subtotal;
        }
        return totals;
      },
      orElse: () => const <String, int>{},
    );

    int displayedTotal(Transaction transaction) {
      return itemTotalsByTransactionId[transaction.id] ?? transaction.total;
    }

    final activeTransactions = filteredTransactions
        .where((t) => !t.isVoided)
        .toList();
    final totalTanggal = activeTransactions.fold<int>(
      0,
      (sum, t) => sum + displayedTotal(t),
    );
    final voidedCount = filteredTransactions.length - activeTransactions.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                ref.read(selectedRiwayatDateProvider.notifier).state =
                    selectedDate.subtract(const Duration(days: 1));
              },
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Hari sebelumnya',
            ),
            Flexible(
              child: Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate),
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(selectedRiwayatDateProvider.notifier).state =
                    selectedDate.add(const Duration(days: 1));
              },
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Hari berikutnya',
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              tooltip: 'Pilih tanggal',
              onPressed: () => _pickDate(context, ref, selectedDate),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.calculate),
              tooltip: 'Rekonsiliasi Kas',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RekonsiliasiScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: filteredTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: AppColors.asphalt.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi pada tanggal ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.charcoal.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.asphalt.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.asphalt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activeTransactions.length} transaksi aktif',
                        style: TextStyle(
                          color: AppColors.trackWhite.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_formatRupiah(totalTanggal)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.safetyOrange,
                        ),
                      ),
                      if (voidedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$voidedCount transaksi dibatalkan',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final t = filteredTransactions[index];
                      final isVoided = t.isVoided;

                      return Container(
                        key: ValueKey(t.id),
                        color: isVoided ? Colors.grey[100] : Colors.transparent,
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () =>
                                  _showTransactionDetailSheet(context, ref, t),
                              leading: Icon(
                                Icons.receipt_long,
                                color: isVoided ? Colors.grey[400] : null,
                              ),
                              title: Text(
                                t.localNumber,
                                style: TextStyle(
                                  decoration: isVoided
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isVoided ? Colors.grey[600] : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat(
                                          'HH:mm:ss',
                                          'id_ID',
                                        ).format(t.createdAt),
                                        style: TextStyle(
                                          color: isVoided
                                              ? Colors.grey[500]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.dirtTan.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          PaymentConstants.getDisplayName(
                                            t.paymentMethod,
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.dirtTan,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isVoided && t.voidedAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Dibatalkan: ${DateFormat('HH:mm', 'id_ID').format(t.voidedAt!)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (isVoided &&
                                      (t.voidReason?.isNotEmpty ?? false))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Alasan: ${t.voidReason}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 140,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isVoided)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[400],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'DIBATALKAN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _formatRupiah(displayedTotal(t)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: isVoided
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isVoided
                                            ? Colors.grey[500]
                                            : null,
                                      ),
                                    ),
                                    if (!isVoided)
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'void') {
                                            _showVoidDialog(context, ref, t);
                                          } else if (value == 'reprint') {
                                            _reprintTransaction(
                                              context,
                                              ref,
                                              t,
                                            );
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'reprint',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.print,
                                                  color: AppColors.safetyOrange,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text('Reprint'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'void',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text('Batalkan'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: isVoided
                                  ? Colors.grey[300]
                                  : Colors.grey[200],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
