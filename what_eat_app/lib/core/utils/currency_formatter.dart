class CurrencyFormatter {
  /// Format số tiền thành chuỗi VNĐ
  /// Ví dụ: 50000 -> "50.000 đ"
  static String formatVND(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} đ';
  }

  /// Format số tiền thành chuỗi ngắn gọn
  /// Ví dụ: 50000 -> "50k", 1000000 -> "1M"
  static String formatCompact(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toString();
  }
}

