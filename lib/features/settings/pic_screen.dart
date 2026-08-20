import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pic_provider.dart';

class PicScreen extends ConsumerWidget {
  const PicScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah PIC'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama PIC'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(picServiceProvider).add(name);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambah PIC: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pics = ref.watch(picStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('MANAJEMEN PIC')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: pics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Gagal memuat PIC: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada PIC'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final pic = items[index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(pic.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          ref.read(picServiceProvider).delete(pic.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
