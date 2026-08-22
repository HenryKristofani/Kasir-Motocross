class RekapPenjualanItem {
  final String kategoriId;
  final String kategoriName;
  final String dayType;
  final int totalQty;
  final int totalSubtotal;
  final int freeQty;
  final int paidQty;
  final int freeSubtotal;
  final int paidSubtotal;

  const RekapPenjualanItem({
    required this.kategoriId,
    required this.kategoriName,
    required this.dayType,
    required this.totalQty,
    required this.totalSubtotal,
    required this.freeQty,
    required this.paidQty,
    required this.freeSubtotal,
    required this.paidSubtotal,
  });
}
