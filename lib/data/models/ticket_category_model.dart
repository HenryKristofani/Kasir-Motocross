class TicketCategoryModel {
  final String id;
  final String name;
  final int price;
  final int? quota;

  const TicketCategoryModel({
    required this.id,
    required this.name,
    required this.price,
    this.quota,
  });
}

// Data dummy sementara, nanti bisa diganti input manual atau dari Supabase
final dummyTicketCategories = [
  const TicketCategoryModel(id: 'cat-1', name: 'MX1', price: 50000),
  const TicketCategoryModel(id: 'cat-2', name: 'MX2', price: 50000),
  const TicketCategoryModel(id: 'cat-3', name: 'Open Class', price: 35000),
  const TicketCategoryModel(id: 'cat-4', name: 'Penonton', price: 20000),
];