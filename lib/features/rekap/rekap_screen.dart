import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pos_date_picker.dart';
import '../../core/utils/error_message.dart';
import '../../providers/database_provider.dart';

class RekapScreen extends ConsumerWidget {
  const RekapScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatTanggal(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  String _getPeriodLabel(RekapDateFilter filter) {
    switch (filter.periodType) {
      case RekapPeriodType.hariIni:
        return 'Hari Ini';
      case RekapPeriodType.tanggalTertentu:
        return _formatTanggal(filter.selectedDate);
      case RekapPeriodType.rentangTanggal:
        if (filter.rangeStart == null || filter.rangeEnd == null) {
          return 'Rentang Tanggal';
        }
        return '${_formatTanggal(filter.rangeStart!)} - ${_formatTanggal(filter.rangeEnd!)}';
      case RekapPeriodType.semuaWaktu:
        return 'Semua Waktu';
    }
  }

  Future<void> _pickTanggalTertentu(
    BuildContext context,
    WidgetRef ref,
    RekapDateFilter currentFilter,
  ) async {
    final selected = await showPosDatePicker(
      context: context,
      initialDate: currentFilter.selectedDate,
      helpText: 'Pilih tanggal rekap',
    );

    if (selected == null || !context.mounted) return;

    final normalized = _startOfDay(selected);
    final nextType = _isToday(normalized)
        ? RekapPeriodType.hariIni
        : RekapPeriodType.tanggalTertentu;

    ref.read(rekapDateFilterProvider.notifier).state = currentFilter.copyWith(
      periodType: nextType,
      selectedDate: normalized,
      clearRange: true,
    );
  }

  Future<void> _pickRentangTanggal(
    BuildContext context,
    WidgetRef ref,
    RekapDateFilter currentFilter,
  ) async {
    final fallback = _startOfDay(currentFilter.selectedDate);
    final initialRange = DateTimeRange(
      start: _startOfDay(currentFilter.rangeStart ?? fallback),
      end: _startOfDay(currentFilter.rangeEnd ?? fallback),
    );

    final selectedRange = await showPosDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      helpText: 'Pilih rentang tanggal rekap',
    );

    if (selectedRange == null || !context.mounted) return;

    ref.read(rekapDateFilterProvider.notifier).state = currentFilter.copyWith(
      periodType: RekapPeriodType.rentangTanggal,
      selectedDate: _startOfDay(selectedRange.start),
      rangeStart: _startOfDay(selectedRange.start),
      rangeEnd: _startOfDay(selectedRange.end),
    );
  }

  void _geserTanggal(
    WidgetRef ref,
    RekapDateFilter currentFilter,
    int dayOffset,
  ) {
    final shiftedDate = _startOfDay(
      currentFilter.selectedDate.add(Duration(days: dayOffset)),
    );
    final nextType = _isToday(shiftedDate)
        ? RekapPeriodType.hariIni
        : RekapPeriodType.tanggalTertentu;

    ref.read(rekapDateFilterProvider.notifier).state = currentFilter.copyWith(
      periodType: nextType,
      selectedDate: shiftedDate,
      clearRange: true,
    );
  }

  Widget _buildFilterInfoCard(
    BuildContext context,
    WidgetRef ref,
    RekapDateFilter filter,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.trackWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.asphalt.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Periode Rekap',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.asphalt.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          if (filter.periodType == RekapPeriodType.hariIni ||
              filter.periodType == RekapPeriodType.tanggalTertentu)
            Row(
              children: [
                IconButton(
                  onPressed: () => _geserTanggal(ref, filter, -1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Hari sebelumnya',
                ),
                Expanded(
                  child: Text(
                    _formatTanggal(filter.selectedDate),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _geserTanggal(ref, filter, 1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Hari berikutnya',
                ),
                IconButton(
                  onPressed: () => _pickTanggalTertentu(context, ref, filter),
                  icon: const Icon(Icons.calendar_today_outlined),
                  tooltip: 'Pilih tanggal',
                ),
              ],
            )
          else if (filter.periodType == RekapPeriodType.rentangTanggal)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getPeriodLabel(filter),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _pickRentangTanggal(context, ref, filter),
                  icon: const Icon(Icons.date_range_outlined),
                  tooltip: 'Pilih rentang tanggal',
                ),
              ],
            )
          else
            Text(
              'Menampilkan seluruh data penjualan.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(rekapDateFilterProvider);
    final rekapAsync = ref.watch(rekapPenjualanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REKAP PENJUALAN'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PopupMenuButton<RekapPeriodType>(
              onSelected: (periodType) {
                final today = _startOfDay(DateTime.now());
                final current = ref.read(rekapDateFilterProvider);

                if (periodType == RekapPeriodType.rentangTanggal) {
                  final start = _startOfDay(
                    current.rangeStart ?? current.selectedDate,
                  );
                  final end = _startOfDay(
                    current.rangeEnd ?? current.selectedDate,
                  );
                  ref.read(rekapDateFilterProvider.notifier).state = current
                      .copyWith(
                        periodType: periodType,
                        rangeStart: start,
                        rangeEnd: end,
                      );
                  return;
                }

                if (periodType == RekapPeriodType.hariIni) {
                  ref.read(rekapDateFilterProvider.notifier).state = current
                      .copyWith(
                        periodType: periodType,
                        selectedDate: today,
                        clearRange: true,
                      );
                  return;
                }

                ref.read(rekapDateFilterProvider.notifier).state = current
                    .copyWith(
                      periodType: periodType,
                      clearRange: periodType != RekapPeriodType.semuaWaktu,
                    );
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: RekapPeriodType.hariIni,
                  checked: selectedFilter.periodType == RekapPeriodType.hariIni,
                  child: const Text('Hari Ini'),
                ),
                CheckedPopupMenuItem(
                  value: RekapPeriodType.tanggalTertentu,
                  checked:
                      selectedFilter.periodType ==
                      RekapPeriodType.tanggalTertentu,
                  child: const Text('Tanggal Tertentu'),
                ),
                CheckedPopupMenuItem(
                  value: RekapPeriodType.rentangTanggal,
                  checked:
                      selectedFilter.periodType ==
                      RekapPeriodType.rentangTanggal,
                  child: const Text('Rentang Tanggal'),
                ),
                CheckedPopupMenuItem(
                  value: RekapPeriodType.semuaWaktu,
                  checked:
                      selectedFilter.periodType == RekapPeriodType.semuaWaktu,
                  child: const Text('Semua Waktu'),
                ),
              ],
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 4),
                    Text(
                      _getPeriodLabel(selectedFilter),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterInfoCard(context, ref, selectedFilter),
          Expanded(
            child: rekapAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(appErrorMessage(err), textAlign: TextAlign.center),
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
                        Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: AppColors.asphalt.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada penjualan untuk periode ini',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                // Hitung total
                final totalQty = rekapList.fold<int>(
                  0,
                  (sum, item) => sum + item.totalQty,
                );
                final totalNominal = rekapList.fold<int>(
                  0,
                  (sum, item) => sum + item.totalSubtotal,
                );

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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.trackWhite.withValues(
                                    alpha: 0.7,
                                  ),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppColors.trackWhite,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total Tiket',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.trackWhite
                                                .withValues(alpha: 0.7),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppColors.safetyOrange,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Grand Total',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.trackWhite
                                                .withValues(alpha: 0.7),
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
                      final percentOfTotal = totalNominal > 0
                          ? (item.totalSubtotal / totalNominal)
                          : 0.0;

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
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.kategoriName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Stats
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Terjual',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.totalQty} pcs',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Nominal',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatRupiah(item.totalSubtotal),
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
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress bar - proporsi kontribusi
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Kontribusi',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        Text(
                                          '${(percentOfTotal * 100).toStringAsFixed(1)}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
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
                                        value: percentOfTotal,
                                        minHeight: 8,
                                        backgroundColor: AppColors.asphalt
                                            .withValues(alpha: 0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.safetyOrange.withValues(
                                                alpha: 0.8,
                                              ),
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
          ),
        ],
      ),
    );
  }
}
