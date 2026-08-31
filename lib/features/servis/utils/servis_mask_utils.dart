/// Helper utility untuk masking nomor telepon & WhatsApp pada fitur Servis.
/// Menjamin keamanan data pelanggan saat ditampilkan di UI.
library;

/// Masking nomor telepon / WhatsApp menjadi format bertanda bintang (*).
/// Contoh:
/// - '081234567890' -> '0812****7890'
/// - '08123456789'  -> '0812***6789'
/// - '+6281234567890' -> '+6281****7890'
/// - null / kosong  -> '-'
String maskPhoneNumber(String? phone) {
  if (phone == null) return '-';
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return '-';

  if (trimmed.length <= 4) {
    return '*' * trimmed.length;
  }
  if (trimmed.length <= 7) {
    final start = trimmed.substring(0, 2);
    final end = trimmed.substring(trimmed.length - 1);
    final mask = '*' * (trimmed.length - 3);
    return '$start$mask$end';
  }

  // Nomor standar (>= 8 karakter)
  final prefixLen = trimmed.startsWith('+') ? 5 : 4;
  const suffixLen = 4;

  if (trimmed.length <= (prefixLen + suffixLen)) {
    final start = trimmed.substring(0, 2);
    final end = trimmed.substring(trimmed.length - 2);
    return '$start****$end';
  }

  final prefix = trimmed.substring(0, prefixLen);
  final suffix = trimmed.substring(trimmed.length - suffixLen);
  final maskedMiddle = '*' * (trimmed.length - prefixLen - suffixLen).clamp(3, 4);

  return '$prefix$maskedMiddle$suffix';
}
