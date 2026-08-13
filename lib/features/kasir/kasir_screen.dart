import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/ticket_category_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/local/database.dart';

class KasirScreen extends ConsumerWidget {
  const KasirScreen({super.key});

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> _bayar(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final db = ref.read(databaseProvider);
    final uuid = const Uuid().v4();
    final total = ref.read(cartProvider.notifier).total(dummyTicketCategories);

    // Simpan transaksi utama
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        id: uuid,
        localNumber: 'A-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: 'device-dev-1', // sementara hardcode, nanti dari settings
        total: total,
        paymentMethod: 'tunai',
        createdAt: DateTime.now(),
      ),
    );

    // Simpan item transaksi
    for (final entry in cart.entries) {
      final cat = dummyTicketCategories.firstWhere((c) => c.id == entry.key);
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
        SnackBar(content: Text('Transaksi tersimpan — Total ${_formatRupiah(total)}'),),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total(dummyTicketCategories);

    return Scaffold(
      appBar: AppBar(title: const Text('Kasir - Tiket Motocross')),
      body: ListView.builder(
        itemCount: dummyTicketCategories.length,
        itemBuilder: (context, index) {
          final cat = dummyTicketCategories[index];
          final qty = cart[cat.id] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_formatRupiah(cat.price)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: qty > 0
                        ? () => ref.read(cartProvider.notifier).decrement(cat.id)
                        : null,
                  ),
                  SizedBox(width: 24, child: Text('$qty', textAlign: TextAlign.center)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => ref.read(cartProvider.notifier).increment(cat.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ${_formatRupiah(total)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: cart.isEmpty ? null : () => _bayar(context, ref),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Bayar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}