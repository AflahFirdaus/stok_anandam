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
        return 'Data sudah terdaftar. Periksa kembali nama atau nomor yang dimasukkan.';
      case 422:
        return 'Data tidak valid. Periksa isian form.';
      case 429:
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 500:
      case 502:
      case 503:
        return 'Server sedang gangguan. Coba lagi beberapa saat.';
      default:
        return null;
    }
  }

  /// Ekstrak pesan dari response body backend (support field `message`, `error`, `errors`).
  static String? _extractBackendMessage(dynamic data) {
    if (data is! Map) return null;
    // Coba field 'message' terlebih dahulu
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
    // Coba field 'error'
    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) return error;
    // Coba field 'errors' (bisa berupa List atau Map)
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first?.toString();
    }
    if (errors is Map && errors.isNotEmpty) {
      return errors.values.first?.toString();
    }
    return null;
  }

  /// Dari DioException: prioritaskan pesan dari backend, lalu status code, baru tipe (timeout, connection).
  static String userMessageFromDio(DioException e, {String? actionContext}) {
    // 1. Coba ambil pesan dari body response backend
    try {
      final backendMsg = _extractBackendMessage(e.response?.data);
      if (backendMsg != null && backendMsg.isNotEmpty) {
        return _sanitizeBackendMessage(backendMsg);
      }
    } catch (_) {}

    // 2. Fallback ke status code
    final status = e.response?.statusCode;

    // Pesan khusus berdasarkan konteks aksi
    if (status == 409 && actionContext != null) {
      return actionContext;
    }
    if (status == 401) {
      return 'Sesi habis atau belum login. Silakan login kembali.';
    }

    final fromStatus = messageFromStatusCode(status);
    if (fromStatus != null && fromStatus.isNotEmpty) return fromStatus;

    // 3. Fallback ke tipe koneksi
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet.';
      case DioExceptionType.badResponse:
        return 'Server mengembalikan error. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan tidak terduga. Coba lagi.';
    }
  }

  /// Membersihkan pesan teknis dari backend agar lebih ramah pengguna.
  static String _sanitizeBackendMessage(String msg) {
    // Hilangkan prefix teknis umum dari Spring Boot
    if (msg.startsWith('could not execute statement')) {
      return 'Gagal menyimpan data. Periksa kembali isian Anda.';
    }
    if (msg.contains('ConstraintViolationException') ||
        msg.contains('Duplicate entry') ||
        msg.contains('duplicate key') ||
        msg.contains('unique constraint')) {
      return 'Data sudah terdaftar. Periksa nama atau nomor yang dimasukkan.';
    }
    if (msg.contains('NullPointerException') || msg.contains('NPE')) {
      return 'Terjadi kesalahan pada server. Coba lagi atau hubungi admin.';
    }
    return msg;
  }

  /// Dari exception umum — deteksi DioException, lalu fallback ke pesan generik.
  ///
  /// [actionContext]: pesan konteks jika terjadi 409 (duplikat), mis:
  ///   "Pelanggan dengan nama atau nomor ini sudah terdaftar."
  static String userMessageFromException(
    Object e, {
    String fallback = 'Terjadi kesalahan. Coba lagi.',
    String? actionContext,
  }) {
    if (e is DioException) return userMessageFromDio(e, actionContext: actionContext);
    // Jika exception adalah String (throw 'pesan')
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      final inner = str.replaceFirst('Exception: ', '');
      if (inner.isNotEmpty && !_isTechnicalMessage(inner)) return inner;
    }
    if (!_isTechnicalMessage(str)) return str;
    return fallback;
  }

  /// Cek apakah pesan bersifat teknis (tidak layak ditampilkan ke user).
  static bool _isTechnicalMessage(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('stacktrace') ||
        lower.contains('at com.') ||
        lower.contains('at java.') ||
        lower.contains('exception') ||
        lower.contains('null pointer') ||
        lower.contains('caused by') ||
        RegExp(r'\d{3}').hasMatch(msg) && lower.contains('error');
  }
}
