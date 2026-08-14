import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/theme/app_theme.dart';
import '../../core/constants/payment_constants.dart';
import '../../providers/database_provider.dart';
import '../../data/local/database.dart';
import '../shift/rekonsiliasi_screen.dart';

class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final selected = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal riwayat',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (selected != null && context.mounted) {
      ref.read(selectedRiwayatDateProvider.notifier).state = selected;
    }
  }

  void _showVoidDialog(BuildContext context, WidgetRef ref, Transaction transaction) {
    final reasonController = TextEditingController();
    final db = ref.read(databaseProvider);

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
                        // Update transaksi dengan void status
                        await db.update(db.transactions).replace(
                          transaction.copyWith(
                            isVoided: true,
                            voidReason: Value(reasonController.text.trim()),
                            voidedAt: Value(DateTime.now()),
                          ),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi berhasil dibatalkan')),
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
    final filteredTransactions = ref.watch(filteredTransactionsByDateProvider(selectedDate));

    final activeTransactions = filteredTransactions.where((t) => !t.isVoided).toList();
    final totalTanggal = activeTransactions.fold<int>(0, (sum, t) => sum + t.total);
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
                        color: isVoided ? Colors.grey[100] : Colors.transparent,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.receipt_long,
                                color: isVoided ? Colors.grey[400] : null,
                              ),
                              title: Text(
                                t.localNumber,
                                style: TextStyle(
                                  decoration: isVoided ? TextDecoration.lineThrough : null,
                                  color: isVoided ? Colors.grey[600] : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('HH:mm:ss', 'id_ID').format(t.createdAt),
                                        style: TextStyle(
                                          color: isVoided ? Colors.grey[500] : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.dirtTan.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          PaymentConstants.getDisplayName(t.paymentMethod),
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
                                  if (isVoided && (t.voidReason?.isNotEmpty ?? false))
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
                                    Text(
                                      _formatRupiah(t.total),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: isVoided ? TextDecoration.lineThrough : null,
                                        color: isVoided ? Colors.grey[500] : null,
                                      ),
                                    ),
                                    if (!isVoided)
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'void') {
                                            _showVoidDialog(context, ref, t);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'void',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.cancel, color: Colors.red),
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
                              color: isVoided ? Colors.grey[300] : Colors.grey[200],
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