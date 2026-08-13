/// Payment method constants untuk memastikan konsistensi di seluruh aplikasi
class PaymentConstants {
  // Nilai-nilai paymentMethod yang valid
  static const String tunai = 'tunai';
  static const String qris = 'qris';
  static const String kartu = 'kartu';
  
  // List semua metode pembayaran yang valid
  static const List<String> validMethods = [tunai, qris, kartu];
  
  // Display names untuk UI
  static const Map<String, String> displayNames = {
    tunai: 'Tunai',
    qris: 'QRIS',
    kartu: 'Kartu',
  };
  
  /// Get display name untuk payment method
  static String getDisplayName(String method) {
    return displayNames[method] ?? method;
  }
}
