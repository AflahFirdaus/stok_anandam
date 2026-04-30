import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../injection.dart';

class UserSessionService {
  final Dio _dio = getIt<Dio>();

  /// Membersihkan sesi aktif (refresh tokens) untuk user tertentu di backend.
  /// Mencoba beberapa endpoint umum jika tidak ada spesifikasi pasti.
  Future<void> clearUserSessions(Object userId) async {
    final path = '/api/v1/users/$userId/clear-sessions';
    try {
      debugPrint('Calling clear sessions: POST $path');
      final response = await _dio.post(path);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('Success clearing sessions');
        return;
      }
    } on DioException catch (e) {
      String detail = e.message ?? 'Unknown error';
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        detail = body['message'].toString();
      }
      throw Exception('Gagal membersihkan sesi: $detail');
    } catch (e) {
      throw Exception('Gagal membersihkan sesi: $e');
    }
  }
}
