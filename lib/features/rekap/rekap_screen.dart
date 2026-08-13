import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/database_provider.dart';

class RekapScreen extends ConsumerWidget {
  const RekapScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  String _getPeriodLabel(PeriodFilter filter) {
    return filter == PeriodFilter.hariIni ? 'Hari Ini' : 'Semua Waktu';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(rekapPeriodFilterProvider);
    final rekapAsync = ref.watch(rekapPenjualanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REKAP PENJUALAN'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PopupMenuButton<PeriodFilter>(
              onSelected: (filter) {
                ref.read(rekapPeriodFilterProvider.notifier).state = filter;
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: PeriodFilter.hariIni,
                  checked: selectedPeriod == PeriodFilter.hariIni,
                  child: const Text('Hari Ini'),
                ),
                CheckedPopupMenuItem(
                  value: PeriodFilter.semuaWaktu,
                  checked: selectedPeriod == PeriodFilter.semuaWaktu,
                  child: const Text('Semua Waktu'),
                ),
              ],
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 4),
                    Text(_getPeriodLabel(selectedPeriod)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: rekapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(rekapPenjualanProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (rekapList) {
          if (rekapList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 64, color: AppColors.asphalt.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada penjualan ${_getPeriodLabel(selectedPeriod).toLowerCase()}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          // Hitung total
          final totalQty = rekapList.fold<int>(0, (sum, item) => sum + item.totalQty);
          final totalNominal = rekapList.fold<int>(0, (sum, item) => sum + item.totalSubtotal);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Total summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.asphalt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Penjualan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.trackWhite.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$totalQty pcs',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppColors.trackWhite,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Tiket',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.trackWhite.withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatRupiah(totalNominal),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppColors.safetyOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Grand Total',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.trackWhite.withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Detail per kategori
              Text(
                'Detail Per Kategori',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ...rekapList.asMap().entries.map((e) {
                final index = e.key;
                final item = e.value;
                final percentOfTotal = totalNominal > 0 ? (item.totalSubtotal / totalNominal) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kategori name dan ranking
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? AppColors.safetyOrange
                                      : index == 1
                                          ? AppColors.dirtTan
                                          : AppColors.charcoal,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.kategoriName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Terjual',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.totalQty} pcs',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Nominal',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatRupiah(item.totalSubtotal),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.safetyOrange,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Progress bar - proporsi kontribusi
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kontribusi',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${(percentOfTotal * 100).toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.safetyOrange,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentOfTotal.toDouble(),
                                  minHeight: 8,
                                  backgroundColor: AppColors.asphalt.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.safetyOrange.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
