import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_category_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/local/database.dart';
import '../settings/kategori_tiket_screen.dart';

class KasirScreen extends ConsumerWidget {
  const KasirScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> _bayar(BuildContext context, WidgetRef ref, List<TicketCategoryModel> kategoris) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final db = ref.read(databaseProvider);
    final uuid = const Uuid().v4();
    final total = ref.read(cartProvider.notifier).total(kategoris);

    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        id: uuid,
        localNumber: 'A-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: 'device-dev-1',
        total: total,
        paymentMethod: 'tunai',
        createdAt: DateTime.now(),
      ),
    );

    for (final entry in cart.entries) {
      final cat = kategoris.firstWhere((c) => c.id == entry.key);
      await db.into(db.transactionItems).insert(
        TransactionItemsCompanion.insert(
          id: const Uuid().v4(),
          transactionId: uuid,
          categoryId: entry.key,
          qty: entry.value,
          subtotal: (cat.price * entry.value).toInt(),
        ),
      );
    }

    ref.read(cartProvider.notifier).clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi tersimpan — Total ${_formatRupiah(total)}')),
      );
    }
  }

  // Daftar kategori tiket — dipakai di kedua layout (portrait & landscape)
  Widget _buildCategoryList(BuildContext context, WidgetRef ref, Map<String, int> cart, List<TicketCategoryModel> kategoris) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: kategoris.length,
      itemBuilder: (context, index) {
        final cat = kategoris[index];
        final qty = cart[cat.id] ?? 0;
        final selected = qty > 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: selected ? AppColors.safetyOrange.withValues(alpha: 0.06) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? AppColors.safetyOrange : AppColors.asphalt.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
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
                    color: AppColors.asphalt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cat.name.substring(0, cat.name.length >= 2 ? 2 : 1).toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      Text(cat.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(_formatRupiah(cat.price), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove),
                      onPressed: qty > 0 ? () => ref.read(cartProvider.notifier).decrement(cat.id) : null,
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
                      onPressed: () => ref.read(cartProvider.notifier).increment(cat.id),
                      style: IconButton.styleFrom(backgroundColor: AppColors.safetyOrange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Panel ringkasan keranjang untuk mode landscape — dengan scroll untuk item banyak
  Widget _buildCartSummaryPanel(BuildContext context, WidgetRef ref, Map<String, int> cart, int total, List<TicketCategoryModel> kategoris) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.asphalt.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max, // Gunakan ruang penuh untuk panel
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text('Ringkasan', style: Theme.of(context).textTheme.headlineMedium),
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
                      children: cart.entries.map((e) {
                        final cat = kategoris.firstWhere((c) => c.id == e.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text('${cat.name} x${e.value}', style: Theme.of(context).textTheme.bodyLarge)),
                              Text(_formatRupiah(cat.price * e.value), style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                        );
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
                Text(_formatRupiah(total), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.safetyOrange)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.isEmpty ? null : () => _bayar(context, ref, kategoris),
                child: const Text('BAYAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom bar ringkasan untuk mode portrait — minimal height, no scroll
  Widget _buildCartSummaryBottomBar(BuildContext context, WidgetRef ref, Map<String, int> cart, int total, List<TicketCategoryModel> kategoris) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
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
                Text(_formatRupiah(total), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.safetyOrange)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.isEmpty ? null : () => _bayar(context, ref, kategoris),
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
      appBar: AppBar(
        title: const Text('KASIR — TIKET MOTOCROSS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KategoriTiketScreen()),
            ),
          ),
        ],
      ),
      body: kategoriStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
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
                  Icon(Icons.category_outlined, size: 64, color: AppColors.asphalt.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kategori tiket',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KategoriTiketScreen()),
                    ),
                    child: const Text('Tambah Kategori'),
                  ),
                ],
              ),
            );
          }

          final total = ref.read(cartProvider.notifier).total(kategoris);

          return OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                // Landscape: split-view — list kiri, ringkasan panel tetap di kanan dengan scroll
                return Row(
                  children: [
                    Expanded(child: _buildCategoryList(context, ref, cart, kategoris)),
                    _buildCartSummaryPanel(context, ref, cart, total, kategoris),
                  ],
                );
              }

              // Portrait: list penuh + bottom bar ringkasan minimal
              return Column(
                children: [
                  Expanded(child: _buildCategoryList(context, ref, cart, kategoris)),
                  _buildCartSummaryBottomBar(context, ref, cart, total, kategoris),
                ],
              );
            },
          );
        },
      ),
    );
  }
}