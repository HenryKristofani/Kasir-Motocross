import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ticket_category_model.dart';

enum CartPriceOption { full, half, free, manual }

extension CartPriceOptionLabel on CartPriceOption {
  String get value => switch (this) {
    CartPriceOption.full => 'full',
    CartPriceOption.half => 'half',
    CartPriceOption.free => 'free',
    CartPriceOption.manual => 'manual',
  };

  String get label => switch (this) {
    CartPriceOption.full => '100%',
    CartPriceOption.half => '50%',
    CartPriceOption.free => 'Free',
    CartPriceOption.manual => 'Manual',
  };
}

class CartItemEntry {
  const CartItemEntry({
    required this.id,
    required this.categoryId,
    this.option = CartPriceOption.full,
    this.manualPrice,
  });

  final String id;
  final String categoryId;
  final CartPriceOption option;
  final int? manualPrice;

  CartItemEntry copyWith({CartPriceOption? option, int? manualPrice}) =>
      CartItemEntry(
        id: id,
        categoryId: categoryId,
        option: option ?? this.option,
        manualPrice: manualPrice ?? this.manualPrice,
      );
}

// key: category id, value: individual ticket entries
class CartNotifier extends StateNotifier<Map<String, List<CartItemEntry>>> {
  CartNotifier() : super({});

  void increment(String categoryId) {
    final entries = [...(state[categoryId] ?? const <CartItemEntry>[])];
    entries.add(
      CartItemEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}-${entries.length}',
        categoryId: categoryId,
      ),
    );
    state = {...state, categoryId: entries};
  }

  void decrement(String categoryId) {
    final entries = [...(state[categoryId] ?? const <CartItemEntry>[])];
    if (entries.length <= 1) {
      final newState = {...state}..remove(categoryId);
      state = newState;
    } else {
      entries.removeLast();
      state = {...state, categoryId: entries};
    }
  }

  void remove(String categoryId) {
    final newState = {...state}..remove(categoryId);
    state = newState;
  }

  void clear() {
    state = {};
  }

  void setOption(
    String categoryId,
    String entryId,
    CartPriceOption option, {
    int? manualPrice,
  }) {
    final entries = state[categoryId];
    if (entries == null) return;
    state = {
      ...state,
      categoryId: [
        for (final entry in entries)
          entry.id == entryId
              ? entry.copyWith(option: option, manualPrice: manualPrice)
              : entry,
      ],
    };
  }

  int quantity(String categoryId) => state[categoryId]?.length ?? 0;

  int itemPrice(
    TicketCategoryModel category,
    CartPriceOption option, {
    int? manualPrice,
  }) {
    return switch (option) {
      CartPriceOption.full => category.price,
      CartPriceOption.half => category.price ~/ 2,
      CartPriceOption.free => 0,
      CartPriceOption.manual => manualPrice ?? 0,
    };
  }

  int total(List<TicketCategoryModel> categories) {
    int sum = 0;
    state.forEach((catId, entries) {
      final category = categories.firstWhere((c) => c.id == catId);
      for (final entry in entries) {
        sum += itemPrice(category, entry.option);
      }
    });
    return sum;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, Map<String, List<CartItemEntry>>>((
      ref,
    ) {
      return CartNotifier();
    });
