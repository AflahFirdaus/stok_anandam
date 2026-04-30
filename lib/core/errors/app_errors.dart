import 'package:dio/dio.dart';

/// Pemetaan error (status code / exception) ke pesan yang ramah pengguna.
/// Jangan tampilkan stack trace atau pesan teknis ke user.
class AppErrors {
  AppErrors._();

  /// Pesan untuk status HTTP. Return null jika ingin fallback umum.
  static String? messageFromStatusCode(int? status) {
    if (status == null) return null;
    switch (status) {
      case 400:
        return 'Permintaan tidak valid. Periksa data lalu coba lagi.';
      case 401:
        return 'Sesi habis atau belum login. Silakan login kembali.';
      case 403:
        return 'Akses ditolak. Hubungi admin jika Anda seharusnya punya akses.';
      case 404:
        return 'Data tidak ditemukan.';
      case 409:
        return 'Data bentrok (sudah ada). Periksa lalu coba lagi.';
      case 422:
        return 'Data tidak valid. Periksa isian form.';
      case 429:
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 500:
      case 502:
      case 503:
        return 'Server sibuk atau gangguan. Coba lagi beberapa saat.';
      default:
        return null;
    }
  }

  /// Dari DioException: prioritaskan pesan dari backend, lalu status code, baru tipe (timeout, connection).
  static String userMessageFromDio(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    final status = e.response?.statusCode;
    final fromStatus = messageFromStatusCode(status);
    if (fromStatus != null && fromStatus.isNotEmpty) return fromStatus;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung. Periksa koneksi internet.';
      case DioExceptionType.badResponse:
        return 'Server mengembalikan error. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  /// Dari exception umum (bukan Dio).
  static String userMessageFromException(Object e, [String fallback = 'Terjadi kesalahan. Coba lagi.']) {
    if (e is DioException) return userMessageFromDio(e);
    return fallback;
  }
}
