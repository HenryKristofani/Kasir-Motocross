import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_message.dart';
import '../../core/widgets/pos_date_picker.dart';
import '../../data/models/ticket_category_model.dart';
import '../../data/models/rekap_penjualan_model.dart';
import '../../providers/database_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatNumber(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(kategoriTiketStreamProvider);
    final quotaAsync = ref.watch(sisaKuotaPerKategoriProvider);
    final salesAsync = ref.watch(rekapPenjualanProvider);
    final secondDaySalesAsync = ref.watch(rekapPenjualanHariKeduaProvider);
    final filter = ref.watch(rekapDateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        actions: [
          PopupMenuButton<RekapPeriodType>(
            tooltip: 'Filter data dashboard',
            onSelected: (periodType) async {
              final notifier = ref.read(rekapDateFilterProvider.notifier);
              final current = ref.read(rekapDateFilterProvider);
              if (periodType == RekapPeriodType.tanggalTertentu) {
                final selected = await showPosDatePicker(
                  context: context,
                  initialDate: current.selectedDate,
                  helpText: 'Pilih tanggal dashboard',
                );
                if (selected == null) return;
                final date = DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                );
                notifier.state = current.copyWith(
                  periodType: RekapPeriodType.tanggalTertentu,
                  selectedDate: date,
                  clearRange: true,
                );
                return;
              }
              if (periodType == RekapPeriodType.hariIni) {
                final now = DateTime.now();
                notifier.state = current.copyWith(
                  periodType: RekapPeriodType.hariIni,
                  selectedDate: DateTime(now.year, now.month, now.day),
                  clearRange: true,
                );
                return;
              }
              notifier.state = current.copyWith(
                periodType: RekapPeriodType.semuaWaktu,
                clearRange: true,
              );
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: RekapPeriodType.hariIni,
                checked: filter.periodType == RekapPeriodType.hariIni,
                child: const Text('Hari Ini'),
              ),
              CheckedPopupMenuItem(
                value: RekapPeriodType.tanggalTertentu,
                checked: filter.periodType == RekapPeriodType.tanggalTertentu,
                child: const Text('Pilih Hari'),
              ),
              CheckedPopupMenuItem(
                value: RekapPeriodType.semuaWaktu,
                checked: filter.periodType == RekapPeriodType.semuaWaktu,
                child: const Text('Semua Waktu'),
              ),
            ],
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.refresh(kategoriTiketStreamProvider),
        ),
        data: (categories) => quotaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            error: error,
            onRetry: () => ref.refresh(sisaKuotaPerKategoriProvider),
          ),
          data: (remainingById) => secondDaySalesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              error: error,
              onRetry: () => ref.refresh(rekapPenjualanHariKeduaProvider),
            ),
            data: (secondDaySales) => salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () => ref.refresh(rekapPenjualanProvider),
              ),
              data: (sales) => _DashboardContent(
                categories: categories,
                remainingById: remainingById,
                sales: sales,
                secondDaySales: secondDaySales,
                filter: filter,
                formatNumber: _formatNumber,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.categories,
    required this.remainingById,
    required this.sales,
    required this.secondDaySales,
    required this.filter,
    required this.formatNumber,
  });

  final List<TicketCategoryModel> categories;
  final Map<String, int> remainingById;
  final List<RekapPenjualanItem> sales;
  final List<RekapPenjualanItem> secondDaySales;
  final RekapDateFilter filter;
  final String Function(int) formatNumber;

  @override
  Widget build(BuildContext context) {
    final capacityCategories = categories.where(
      (category) => !category.isBundling && category.quota != null,
    );
    final totalCapacity = capacityCategories.fold<int>(
      0,
      (sum, category) => sum + (category.quota ?? 0),
    );
    final totalRemaining = capacityCategories.fold<int>(
      0,
      (sum, category) =>
          sum + (remainingById[category.id] ?? category.quota ?? 0),
    );
    final totalSold = (totalCapacity - totalRemaining).clamp(0, totalCapacity);

    final grouped = <String, List<TicketCategoryModel>>{};
    for (final category in categories) {
      grouped.putIfAbsent(category.name, () => []).add(category);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BrandingBanner(),
        const SizedBox(height: 20),
        _DashboardSalesSummary(
          sales: sales,
          filter: filter,
          formatNumber: formatNumber,
        ),
        const SizedBox(height: 28),
        _SecondDaySalesSection(
          sales: secondDaySales,
          formatNumber: formatNumber,
        ),
        const SizedBox(height: 28),
        Text(
          'Ringkasan Tiket',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 3.2 : 1.45,
              children: [
                _MetricCard(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Total Keseluruhan Tiket',
                  value: formatNumber(totalCapacity),
                  color: AppColors.asphalt,
                ),
                _MetricCard(
                  icon: Icons.shopping_cart_checkout,
                  title: 'Tiket Terjual',
                  value: formatNumber(totalSold),
                  color: AppColors.safetyOrange,
                ),
                _MetricCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Sisa Tiket',
                  value: formatNumber(totalRemaining),
                  color: Colors.teal,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text('Per Kategori', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          final variants = entry.value.where(
            (category) => !category.isBundling && category.quota != null,
          );
          final capacity = variants.fold<int>(
            0,
            (sum, category) => sum + (category.quota ?? 0),
          );
          final remaining = variants.fold<int>(
            0,
            (sum, category) =>
                sum + (remainingById[category.id] ?? category.quota ?? 0),
          );
          final sold = (capacity - remaining).clamp(0, capacity);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryValue(
                          label: 'Total',
                          value: formatNumber(capacity),
                        ),
                      ),
                      Expanded(
                        child: _CategoryValue(
                          label: 'Terjual',
                          value: formatNumber(sold),
                          color: AppColors.safetyOrange,
                        ),
                      ),
                      Expanded(
                        child: _CategoryValue(
                          label: 'Sisa',
                          value: formatNumber(remaining),
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: variants
                        .map(
                          (category) => Chip(
                            label: Text(
                              '${category.dayType == 'day1' ? 'Day 1' : 'Day 2'}: ${formatNumber(remainingById[category.id] ?? category.quota ?? 0)} sisa',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DashboardSalesSummary extends StatelessWidget {
  const _DashboardSalesSummary({
    required this.sales,
    required this.filter,
    required this.formatNumber,
  });

  final List<RekapPenjualanItem> sales;
  final RekapDateFilter filter;
  final String Function(int) formatNumber;

  String _periodLabel() {
    if (filter.periodType == RekapPeriodType.hariIni) return 'Hari Ini';
    if (filter.periodType == RekapPeriodType.semuaWaktu) return 'Semua Waktu';
    return DateFormat('dd MMM yyyy', 'id_ID').format(filter.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final total = sales.fold<int>(0, (sum, item) => sum + item.totalQty);
    final free = sales.fold<int>(0, (sum, item) => sum + item.freeQty);
    final paid = sales.fold<int>(0, (sum, item) => sum + item.paidQty);
    final nominal = sales.fold<int>(0, (sum, item) => sum + item.totalSubtotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penjualan: ${_periodLabel()}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              icon: Icons.confirmation_number_outlined,
              title: 'Keseluruhan Tiket Keluar',
              value: formatNumber(total),
              color: AppColors.asphalt,
            ),
            _MetricCard(
              icon: Icons.card_giftcard_outlined,
              title: 'Tiket Gratis Keluar',
              value: formatNumber(free),
              color: Colors.teal,
            ),
            _MetricCard(
              icon: Icons.point_of_sale,
              title: 'Tiket Dibeli Keluar',
              value: formatNumber(paid),
              color: AppColors.safetyOrange,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Nominal tiket dibeli: Rp${formatNumber(nominal)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'BREAKDOWN TIKET KELUAR PER KATEGORI',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (sales.isEmpty)
          const Text('Tidak ada tiket keluar pada periode ini.')
        else
          _SalesBreakdownTable(sales: sales, formatNumber: formatNumber),
      ],
    );
  }
}

class _SecondDaySalesSection extends StatelessWidget {
  const _SecondDaySalesSection({
    required this.sales,
    required this.formatNumber,
  });

  static const int operationalQuota = 4950;

  final List<RekapPenjualanItem> sales;
  final String Function(int) formatNumber;

  String _dayLabel(String dayType) => switch (dayType) {
    'day1' => 'Day 1',
    'day2' => 'Day 2',
    'bundling' => 'Bundling 2 Hari',
    _ => dayType,
  };

  @override
  Widget build(BuildContext context) {
    final rows =
        <({String ticketName, String status, int qty, int subtotal})>[];

    for (final item in sales) {
      final ticketName = '${item.kategoriName} - ${_dayLabel(item.dayType)}';
      if (item.paidQty > 0) {
        rows.add((
          ticketName: ticketName,
          status: 'BERBAYAR',
          qty: item.paidQty,
          subtotal: item.paidSubtotal,
        ));
      }
      if (item.freeQty > 0) {
        rows.add((
          ticketName: ticketName,
          status: 'GRATIS',
          qty: item.freeQty,
          subtotal: item.freeSubtotal,
        ));
      }
    }

    final totalSold = rows.fold<int>(0, (sum, row) => sum + row.qty);
    final totalSubtotal = rows.fold<int>(0, (sum, row) => sum + row.subtotal);
    final remaining = (operationalQuota - totalSold).clamp(0, operationalQuota);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATISTIK 23 AGUSTUS 2026 (HARI KEDUA)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              icon: Icons.confirmation_number_outlined,
              title: 'Kuota Hari Kedua',
              value: formatNumber(operationalQuota),
              color: AppColors.asphalt,
            ),
            _MetricCard(
              icon: Icons.shopping_cart_checkout,
              title: 'Total Tiket Keluar',
              value: formatNumber(totalSold),
              color: AppColors.safetyOrange,
            ),
            _MetricCard(
              icon: Icons.inventory_2_outlined,
              title: 'Sisa Kuota Hari Kedua',
              value: formatNumber(remaining),
              color: Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gratis dan berbayar sama-sama mengurangi kuota 4.950. '
          'Total nominal berbayar: Rp${formatNumber(totalSubtotal)}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada tiket keluar pada 23 Agustus 2026.'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(AppColors.asphalt),
                    columns: const [
                      DataColumn(label: Text('Nama Tiket Lengkap')),
                      DataColumn(label: Text('Status Tiket')),
                      DataColumn(label: Text('Jumlah Tiket')),
                      DataColumn(label: Text('Total Nominal (Rp)')),
                    ],
                    rows: [
                      ...rows.map(
                        (row) => DataRow(
                          color: WidgetStatePropertyAll(
                            row.status == 'GRATIS'
                                ? Colors.teal.withValues(alpha: 0.08)
                                : null,
                          ),
                          cells: [
                            DataCell(Text(row.ticketName)),
                            DataCell(
                              Text(
                                row.status,
                                style: TextStyle(
                                  color: row.status == 'GRATIS'
                                      ? Colors.teal[800]
                                      : AppColors.safetyOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(Text(formatNumber(row.qty))),
                            DataCell(Text('Rp ${formatNumber(row.subtotal)}')),
                          ],
                        ),
                      ),
                      DataRow(
                        color: const WidgetStatePropertyAll(Color(0xFFE8E8E8)),
                        cells: [
                          const DataCell(
                            Text(
                              'TOTAL',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const DataCell(SizedBox.shrink()),
                          DataCell(
                            Text(
                              formatNumber(totalSold),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              'Rp ${formatNumber(totalSubtotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _SalesBreakdownTable extends StatelessWidget {
  const _SalesBreakdownTable({required this.sales, required this.formatNumber});

  final List<RekapPenjualanItem> sales;
  final String Function(int) formatNumber;

  String _dayLabel(String dayType) => switch (dayType) {
    'day1' => 'Day 1',
    'day2' => 'Day 2',
    'bundling' => 'Bundling 2 Hari',
    _ => dayType,
  };

  @override
  Widget build(BuildContext context) {
    final rows =
        <
          ({
            String category,
            String dayType,
            String status,
            int qty,
            int subtotal,
          })
        >[];

    final groupedSales = [...sales]
      ..sort((a, b) {
        final byCategory = a.kategoriName.toLowerCase().compareTo(
          b.kategoriName.toLowerCase(),
        );
        if (byCategory != 0) return byCategory;

        const dayOrder = {'day1': 0, 'day2': 1, 'bundling': 2};
        final byDay = (dayOrder[a.dayType] ?? 99).compareTo(
          dayOrder[b.dayType] ?? 99,
        );
        if (byDay != 0) return byDay;

        return 0;
      });

    for (final item in groupedSales) {
      if (item.paidQty > 0) {
        rows.add((
          category: item.kategoriName,
          dayType: item.dayType,
          status: 'BERBAYAR',
          qty: item.paidQty,
          subtotal: item.paidSubtotal,
        ));
      }
      if (item.freeQty > 0) {
        rows.add((
          category: item.kategoriName,
          dayType: item.dayType,
          status: 'GRATIS',
          qty: item.freeQty,
          subtotal: item.freeSubtotal,
        ));
      }
      if (item.totalQty == 0) {
        rows.add((
          category: item.kategoriName,
          dayType: item.dayType,
          status: 'BELUM ADA',
          qty: 0,
          subtotal: 0,
        ));
      }
    }

    final totalQty = rows.fold<int>(0, (sum, row) => sum + row.qty);
    final totalSubtotal = rows.fold<int>(0, (sum, row) => sum + row.subtotal);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(AppColors.asphalt),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Text('Nama Tiket Lengkap')),
            DataColumn(label: Text('Tipe Hari')),
            DataColumn(label: Text('Status Tiket')),
            DataColumn(label: Text('Jumlah Tiket')),
            DataColumn(label: Text('Total Nominal (Rp)')),
          ],
          rows: [
            ...rows.map(
              (row) => DataRow(
                color: WidgetStatePropertyAll(
                  row.status == 'GRATIS'
                      ? Colors.teal.withValues(alpha: 0.08)
                      : row.status == 'BELUM ADA'
                      ? Colors.grey.withValues(alpha: 0.08)
                      : null,
                ),
                cells: [
                  DataCell(Text('${row.category} - ${_dayLabel(row.dayType)}')),
                  DataCell(Text(row.dayType)),
                  DataCell(
                    Text(
                      row.status,
                      style: TextStyle(
                        color: row.status == 'GRATIS'
                            ? Colors.teal[800]
                            : row.status == 'BELUM ADA'
                            ? Colors.grey[700]
                            : AppColors.safetyOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(Text(formatNumber(row.qty))),
                  DataCell(Text('Rp ${formatNumber(row.subtotal)}')),
                ],
              ),
            ),
            DataRow(
              color: const WidgetStatePropertyAll(Color(0xFFE8E8E8)),
              cells: [
                const DataCell(
                  Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const DataCell(SizedBox.shrink()),
                const DataCell(SizedBox.shrink()),
                DataCell(
                  Text(
                    formatNumber(totalQty),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(
                  Text(
                    'Rp ${formatNumber(totalSubtotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.asphalt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.22,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.sports_motorsports),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POS MOTOCROSS',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ticket sales and race-day operations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.sports_motorsports,
                  size: 42,
                  color: AppColors.safetyOrange.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryValue extends StatelessWidget {
  const _CategoryValue({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(appErrorMessage(error), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
