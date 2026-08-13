import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/theme/app_theme.dart';
import '../../providers/database_provider.dart';
import '../../data/local/database.dart';

class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
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
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: transactionsAsync.when(
        data: (allTransactions) {
          // Hitung total HANYA dari transaksi yang tidak di-void
          final activeTransactions = allTransactions.where((t) => !t.isVoided).toList();
          final totalHariIni = activeTransactions.fold<int>(0, (sum, t) => sum + t.total);

          if (allTransactions.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }

          return Column(
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
                      'Total: ${_formatRupiah(totalHariIni)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.safetyOrange,
                      ),
                    ),
                    if (allTransactions.length != activeTransactions.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${allTransactions.length - activeTransactions.length} transaksi dibatalkan',
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
                  itemCount: allTransactions.length,
                  itemBuilder: (context, index) {
                    final t = allTransactions[index];
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
                                Text(
                                  DateFormat('HH:mm:ss').format(t.createdAt),
                                  style: TextStyle(
                                    color: isVoided ? Colors.grey[500] : null,
                                  ),
                                ),
                                if (isVoided && t.voidedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Dibatalkan: ${DateFormat('HH:mm').format(t.voidedAt!)}',
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}