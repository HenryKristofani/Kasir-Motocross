import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/payment_constants.dart';
import '../../providers/database_provider.dart';
import '../../core/utils/error_message.dart';
import 'riwayat_rekonsiliasi_screen.dart';

class RekonsiliasiScreen extends ConsumerStatefulWidget {
  const RekonsiliasiScreen({super.key});

  @override
  ConsumerState<RekonsiliasiScreen> createState() => _RekonsiliasiScreenState();
}

class _RekonsiliasiScreenState extends ConsumerState<RekonsiliasiScreen> {
  final _fisikTunaiController = TextEditingController();
  final _catatanController = TextEditingController();

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  void _showSaveDialog(
    BuildContext context,
    WidgetRef ref,
    int totalSistemTunai,
    int totalFisikTunai,
    int selisih,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Rekonsiliasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Total Sistem (Tunai)', totalSistemTunai),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Fisik (Input)', totalFisikTunai),
            const Divider(height: 24),
            _buildSummaryRow(
              'Selisih',
              selisih,
              textColor: selisih == 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
            if (selisih != 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: ${selisih > 0 ? 'LEBIH' : 'KURANG'} ${_formatRupiah(selisih.abs())}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (_catatanController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _catatanController.text.trim(),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final deviceId = 'device_1'; // TODO: Get real device ID
              final newId = const Uuid().v4();
              await Supabase.instance.client
                  .from('shift_reconciliations')
                  .insert({
                    'id': newId,
                    'device_id': deviceId,
                    'total_sistem_tunai': totalSistemTunai,
                    'total_fisik_tunai': totalFisikTunai,
                    'selisih': selisih,
                    'catatan': _catatanController.text.trim().isEmpty
                        ? null
                        : _catatanController.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                  });

              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rekonsiliasi berhasil disimpan'),
                  ),
                );
                // Reset form
                _fisikTunaiController.clear();
                _catatanController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safetyOrange,
            ),
            child: const Text('Simpan & Tutup Shift'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    int amount, {
    Color? textColor,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          _formatRupiah(amount),
          style: TextStyle(fontWeight: fontWeight, color: textColor),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fisikTunaiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rekapAsync = ref.watch(rekapPenjualanHariIniProvider);
    final totalSistemAsync = ref.watch(totalSistemTunaiHariIniProvider);
    final totalKeseluruhanAsync = ref.watch(totalKeseluruhanHariIniProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REKONSILIASI KAS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RiwayatRekonsiliasiScreen(),
                ),
              );
            },
            tooltip: 'Riwayat Rekonsiliasi',
          ),
        ],
      ),
      body: rekapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text(appErrorMessage(err))),
        data: (rekapList) {
          // Hitung total per metode pembayaran dari transaksi hari ini
          final paymentMethods = <String, int>{};
          final allTransactions = ref.watch(transactionsStreamProvider);
          final itemTotals = ref
              .watch(transactionTotalsFromItemsProvider)
              .maybeWhen(
                data: (value) => value,
                orElse: () => const <String, int>{},
              );

          allTransactions.whenData((transactions) {
            // Filter: hari ini, tidak void
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final endOfDay = startOfDay.add(const Duration(days: 1));

            for (final t in transactions) {
              if (!t.isVoided &&
                  t.createdAt.isAfter(startOfDay) &&
                  t.createdAt.isBefore(endOfDay)) {
                paymentMethods[t.paymentMethod] =
                    (paymentMethods[t.paymentMethod] ?? 0) +
                    (itemTotals[t.id] ?? t.total);
              }
            }
          });

          // Total sistem (tunai) - dari provider yang dedicated
          final totalSistemTunai = totalSistemAsync.maybeWhen(
            data: (value) => value,
            orElse: () => 0,
          );

          // Total keseluruhan hari ini - semua metode pembayaran, info tambahan
          final totalKeseluruhanHariIni = totalKeseluruhanAsync.maybeWhen(
            data: (value) => value,
            orElse: () => 0,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Total Keseluruhan Hari Ini (ringkasan utama, info tambahan)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.trackWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.dirtTan.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Keseluruhan Hari Ini',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(totalKeseluruhanHariIni),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.dirtTan,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Termasuk semua metode pembayaran',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.charcoal.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Breakdown Metode Pembayaran
              Text(
                'Breakdown Metode Pembayaran',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ...paymentMethods.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            PaymentConstants.getDisplayName(e.key),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            _formatRupiah(e.value),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.safetyOrange,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Input Fisik Tunai
              Text(
                'Input Jumlah Uang Tunai Fisik',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fisikTunaiController,
                decoration: InputDecoration(
                  hintText: 'Masukkan jumlah uang tunai fisik...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Catatan (optional)
              Text(
                'Catatan (Opsional)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanController,
                decoration: InputDecoration(
                  hintText: 'Masukkan catatan bila ada selisih...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Selisih Display
              if (_fisikTunaiController.text.isNotEmpty)
                _buildSelisihCard(context, totalSistemTunai),
              const SizedBox(height: 24),

              // Tombol Simpan
              ElevatedButton(
                onPressed: _fisikTunaiController.text.isEmpty
                    ? null
                    : () {
                        final fisikTunai = int.tryParse(
                          _fisikTunaiController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ),
                        );
                        if (fisikTunai == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Input tidak valid')),
                          );
                          return;
                        }
                        final selisih = fisikTunai - totalSistemTunai;
                        _showSaveDialog(
                          context,
                          ref,
                          totalSistemTunai,
                          fisikTunai,
                          selisih,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _fisikTunaiController.text.isEmpty
                      ? Colors.grey[300]
                      : AppColors.safetyOrange,
                ),
                child: const Text(
                  'Lanjut ke Konfirmasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelisihCard(BuildContext context, int totalSistemTunai) {
    final fisikTunai = int.tryParse(
      _fisikTunaiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (fisikTunai == null) return const SizedBox.shrink();

    final selisih = fisikTunai - totalSistemTunai;
    final isSesuai = selisih == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSesuai
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSesuai ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selisih', style: Theme.of(context).textTheme.headlineSmall),
              Text(
                _formatRupiah(selisih.abs()),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isSesuai ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSesuai ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSesuai ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSesuai
                        ? 'SESUAI - Tidak ada selisih'
                        : 'SELISIH - ${selisih > 0 ? 'LEBIH' : 'KURANG'} ${_formatRupiah(selisih.abs())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
