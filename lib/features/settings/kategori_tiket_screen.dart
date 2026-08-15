import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_category_model.dart';
import '../../providers/kategori_tiket_provider.dart';
import '../../providers/database_provider.dart';

class KategoriTiketScreen extends ConsumerWidget {
  const KategoriTiketScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  void _showKategoriDialog(
    BuildContext context,
    WidgetRef ref, {
    TicketCategoryModel? kategori,
  }) {
    final nameController = TextEditingController(text: kategori?.name ?? '');
    final priceController = TextEditingController(text: kategori?.price.toString() ?? '');
    final quotaController = TextEditingController(text: kategori?.quota?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kategori == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Misal: MX1, Open Class',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  hintText: '50000',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quotaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kuota (opsional)',
                  hintText: 'Kosongkan jika tidak ada batasan',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text) ?? 0;
              final quota = int.tryParse(quotaController.text);

              if (name.isEmpty || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan Harga harus diisi dengan benar')),
                );
                return;
              }

              if (kategori == null) {
                ref.read(kategoriTiketNotifierProvider.notifier).addKategori(
                      name: name,
                      price: price,
                      quota: quota,
                    );
              } else {
                ref.read(kategoriTiketNotifierProvider.notifier).updateKategori(
                      id: kategori.id,
                      name: name,
                      price: price,
                      quota: quota,
                    );
              }

              Navigator.pop(context);
            },
            child: Text(kategori == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, TicketCategoryModel kategori) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin hapus kategori "${kategori.name}"? Ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(kategoriTiketNotifierProvider.notifier).deleteKategori(kategori.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kategoriStream = ref.watch(kategoriTiketStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAJEMEN KATEGORI TIKET'),
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
        data: (kategoriList) => kategoriList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: AppColors.asphalt.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada kategori tiket',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : _buildKategoriList(context, ref, kategoriList),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showKategoriDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build list dengan sisa kuota yang di-watch real-time
  Widget _buildKategoriList(BuildContext context, WidgetRef ref, List<TicketCategoryModel> kategoriList) {
    final sisaKuotaAsync = ref.watch(sisaKuotaPerKategoriProvider);

    return sisaKuotaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (sisaKuotaMap) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: kategoriList.length,
          itemBuilder: (context, index) {
            final kategori = kategoriList[index];
            final sisaKuota = sisaKuotaMap[kategori.id] ?? kategori.quota ?? -1;
            final terjual = kategori.quota != null ? (kategori.quota! - sisaKuota) : 0;

            return Card(
              key: ValueKey(kategori.id),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.safetyOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.safetyOrange,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    kategori.name.substring(0, kategori.name.length >= 2 ? 2 : 1).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.safetyOrange,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                title: Text(
                  kategori.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatRupiah(kategori.price),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.safetyOrange,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (kategori.quota != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.dirtTan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.dirtTan,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Terjual: $terjual / Kuota: ${kategori.quota}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.dirtTan,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => Future.microtask(
                        // ignore: use_build_context_synchronously
                        () => _showKategoriDialog(context, ref, kategori: kategori),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      onTap: () => Future.microtask(
                        // ignore: use_build_context_synchronously
                        () => _showDeleteConfirmDialog(context, ref, kategori),
                      ),
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
}