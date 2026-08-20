import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_message.dart';
import '../../data/models/ticket_category_model.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('DASHBOARD')),
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
          data: (remainingById) => _DashboardContent(
            categories: categories,
            remainingById: remainingById,
            formatNumber: _formatNumber,
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
    required this.formatNumber,
  });

  final List<TicketCategoryModel> categories;
  final Map<String, int> remainingById;
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
