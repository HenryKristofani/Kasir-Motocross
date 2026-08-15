import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ticket_category_model.dart';

// key: category id, value: qty
class CartNotifier extends StateNotifier<Map<String, int>> {
  CartNotifier() : super({});

  void increment(String categoryId) {
    state = {...state, categoryId: (state[categoryId] ?? 0) + 1};
  }

  void decrement(String categoryId) {
    final current = state[categoryId] ?? 0;
    if (current <= 1) {
      final newState = {...state}..remove(categoryId);
      state = newState;
    } else {
      state = {...state, categoryId: current - 1};
    }
  }

  void remove(String categoryId) {
    final newState = {...state}..remove(categoryId);
    state = newState;
  }

  void clear() {
    state = {};
  }

  int total(List<TicketCategoryModel> categories) {
    int sum = 0;
    state.forEach((catId, qty) {
      final cat = categories.firstWhere((c) => c.id == catId);
      sum += cat.price * qty;
    });
    return sum;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, int>>((ref) {
  return CartNotifier();
});