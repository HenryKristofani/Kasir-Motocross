import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/database_provider.dart';
import '../../core/utils/error_message.dart';

class RiwayatRekonsiliasiScreen extends ConsumerWidget {
  const RiwayatRekonsiliasiScreen({super.key});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
  }

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rekonsiliasiAsync = ref.watch(shiftReconciliationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('RIWAYAT REKONSILIASI')),
      body: rekonsiliasiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(appErrorMessage(err), textAlign: TextAlign.center),
        ),
        data: (reconciliations) {
          if (reconciliations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat rekonsiliasi',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai buat rekonsiliasi kas untuk melihat histori shift',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reconciliations.length,
            itemBuilder: (context, index) {
              final item = reconciliations[index];
              final isSesuai = item.selisih == 0;
              final selisihText = isSesuai
                  ? 'SESUAI'
                  : item.selisih > 0
                  ? 'LEBIH ${_formatRupiah(item.selisih.abs())}'
                  : 'KURANG ${_formatRupiah(item.selisih.abs())}';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tanggal & Jam
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateTime(item.createdAt),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          // Status Selisih Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSesuai
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isSesuai ? Colors.green : Colors.red,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selisihText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSesuai ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Total Sistem
                      _buildDetailRow(
                        context,
                        'Total Sistem (Tunai)',
                        item.totalSistemTunai,
                      ),
                      const SizedBox(height: 12),

                      // Total Fisik
                      _buildDetailRow(
                        context,
                        'Total Fisik',
                        item.totalFisikTunai,
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Divider(color: Colors.grey[300], thickness: 1),
                      const SizedBox(height: 16),

                      // Selisih Detail
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selisih',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _formatRupiah(item.selisih.abs()),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSesuai ? Colors.green : Colors.red,
                                ),
                          ),
                        ],
                      ),

                      // Catatan (jika ada)
                      if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.catatan!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          _formatRupiah(amount),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.safetyOrange,
          ),
        ),
      ],
    );
  }
}
