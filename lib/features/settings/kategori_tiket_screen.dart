import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_category_model.dart';
import '../../providers/kategori_tiket_provider.dart';
import '../../providers/database_provider.dart';
import '../../core/utils/error_message.dart';
import 'pic_screen.dart';

class KategoriTiketScreen extends ConsumerWidget {
  const KategoriTiketScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  void _showKategoriDialog(
    BuildContext context,
    WidgetRef ref, {
    TicketCategoryModel? kategori,
  }) {
    const parentNames = [
      'VVIP',
      'VIP',
      'Paddock',
      'Paddock Undangan',
      'Umum',
      'Crosser',
    ];
    final nameController = TextEditingController(text: kategori?.name ?? '');
    final priceController = TextEditingController(
      text: kategori?.price.toString() ?? '',
    );
    final quotaController = TextEditingController(
      text: kategori?.quota?.toString() ?? '',
    );
    var selectedName = parentNames.contains(kategori?.name)
        ? kategori!.name
        : parentNames.first;
    var selectedDayType = kategori?.dayType ?? 'day1';
    if (selectedName == 'Crosser') priceController.text = '0';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final isCrosser = selectedName == 'Crosser';
          final isBundling = selectedDayType == 'bundling';
          return AlertDialog(
            title: Text(
              kategori == null ? 'Tambah Varian Tiket' : 'Edit Varian Tiket',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedName,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Induk',
                    ),
                    items: parentNames
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedName = value;
                        nameController.text = value;
                        if (value == 'Crosser') {
                          priceController.text = '0';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDayType,
                    decoration: const InputDecoration(labelText: 'Varian Hari'),
                    items: [
                      const DropdownMenuItem(
                        value: 'day1',
                        child: Text('Day 1'),
                      ),
                      const DropdownMenuItem(
                        value: 'day2',
                        child: Text('Day 2'),
                      ),
                      const DropdownMenuItem(
                        value: 'bundling',
                        child: Text('Bundling 2 Hari'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedDayType = value ?? 'day1'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    enabled: !isCrosser,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                    ),
                  ),
                  if (!isBundling) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: quotaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kuota',
                        hintText: 'Kosongkan jika tanpa batas',
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Kuota bundling mengikuti minimum sisa Day 1 dan Day 2.',
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final price = isCrosser
                      ? 0
                      : (int.tryParse(priceController.text) ?? 0);
                  final quota = isBundling
                      ? null
                      : int.tryParse(quotaController.text);
                  if (!isCrosser && price < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harga tidak valid')),
                    );
                    return;
                  }
                  try {
                    if (kategori == null) {
                      await ref
                          .read(kategoriTiketNotifierProvider.notifier)
                          .addKategori(
                            name: selectedName,
                            dayType: selectedDayType,
                            price: price,
                            quota: quota,
                          );
                    } else {
                      await ref
                          .read(kategoriTiketNotifierProvider.notifier)
                          .updateKategori(
                            id: kategori.id,
                            name: selectedName,
                            dayType: selectedDayType,
                            price: price,
                            quota: quota,
                          );
                    }

                    if (!context.mounted) return;
                    Navigator.pop(dialogContext);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan tiket: $error')),
                    );
                  }
                },
                child: Text(kategori == null ? 'Tambah' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    TicketCategoryModel kategori,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Yakin hapus kategori "${kategori.name}"? Ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(kategoriTiketNotifierProvider.notifier)
                  .deleteKategori(kategori.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Kelola PIC',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PicScreen()),
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
              Text(appErrorMessage(err), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(kategoriTiketStreamProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (kategoriList) {
          final sortedCategories = [...kategoriList]
            ..sort((a, b) {
              final byName = a.name.toLowerCase().compareTo(
                b.name.toLowerCase(),
              );
              if (byName != 0) return byName;

              const dayOrder = {'day1': 0, 'day2': 1, 'bundling': 2};
              return (dayOrder[a.dayType] ?? 99).compareTo(
                dayOrder[b.dayType] ?? 99,
              );
            });

          return sortedCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: AppColors.asphalt.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kategori tiket',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : _buildKategoriList(context, ref, sortedCategories);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showKategoriDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build list dengan sisa kuota yang di-watch real-time
  Widget _buildKategoriList(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategoryModel> kategoriList,
  ) {
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
            final hasQuota = sisaKuotaMap.containsKey(kategori.id);
            final terjual = kategori.isBundling
                ? (() {
                    final relatedDay1 = kategoriList.firstWhere(
                      (item) =>
                          item.name == kategori.name && item.dayType == 'day1',
                      orElse: () => kategori,
                    );
                    final relatedDay2 = kategoriList.firstWhere(
                      (item) =>
                          item.name == kategori.name && item.dayType == 'day2',
                      orElse: () => kategori,
                    );
                    final day1Quota = relatedDay1.quota ?? 0;
                    final day2Quota = relatedDay2.quota ?? 0;
                    final day1Sold =
                        day1Quota - (sisaKuotaMap[relatedDay1.id] ?? day1Quota);
                    final day2Sold =
                        day2Quota - (sisaKuotaMap[relatedDay2.id] ?? day2Quota);
                    final bundleSold = [day1Sold, day2Sold].reduce(
                      (a, b) => a < b ? a : b,
                    );
                    return bundleSold.clamp(0, 1 << 31);
                  })()
                : kategori.quota != null
                ? (kategori.quota! - sisaKuota)
                : null;

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
                    border: Border.all(color: AppColors.safetyOrange, width: 2),
                  ),
                  child: Text(
                    kategori.name
                        .substring(0, kategori.name.length >= 2 ? 2 : 1)
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.safetyOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  kategori.displayName,
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.safetyOrange,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (hasQuota) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dirtTan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.dirtTan,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              kategori.isBundling
                                  ? 'Terjual: $terjual / Sisa efektif: $sisaKuota'
                                  : 'Terjual: $terjual / Kuota: ${kategori.quota}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                  onSelected: (value) {
                    if (!context.mounted) return;
                    if (value == 'edit') {
                      _showKategoriDialog(context, ref, kategori: kategori);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(context, ref, kategori);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
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
