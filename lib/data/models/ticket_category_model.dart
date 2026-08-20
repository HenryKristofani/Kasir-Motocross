class TicketCategoryModel {
  final String id;
  final String name;
  final String dayType;
  final int price;
  final int? quota;

  const TicketCategoryModel({
    required this.id,
    required this.name,
    this.dayType = 'day1',
    required this.price,
    this.quota,
  });

  bool get isBundling => dayType == 'bundling';

  String get displayName {
    switch (dayType) {
      case 'day2':
        return '$name - Day 2';
      case 'bundling':
        return '$name - Bundling 2 Hari';
      default:
        return '$name - Day 1';
    }
  }
}

// Data dummy sementara, nanti bisa diganti input manual atau dari Supabase
final dummyTicketCategories = <TicketCategoryModel>[];
