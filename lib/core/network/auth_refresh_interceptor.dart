import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import '../routing/app_router.dart';
import '../../injection.dart';
import '../../token_storage.dart';

class AuthRefreshInterceptor extends QueuedInterceptor {
  AuthRefreshInterceptor(this._dio);
  final Dio _dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final responseData = err.response?.data;
    final requestOptions = err.requestOptions;
    final path = requestOptions.uri.path;

    final bool isDeactivated = responseData != null &&
        responseData['message'] != null &&
        responseData['message'].toString().contains('dinonaktifkan');

    if (isDeactivated) {
      await _forceLogout(toAccessDenied: true);
      return handler.reject(err);
    }

    // 2. Cek apakah ini Token Expired
    bool isTokenExpired = status == 401 &&
        responseData != null &&
        responseData['message'] == 'Token expired';

    if (!isTokenExpired) {
      if (status == 401) {
        await _forceLogout();
      }
      return handler.next(err);
    }

    // 3. Hindari Loop
    if (path.contains('auth/refresh') || path.contains('auth/login')) {
      await _forceLogout();
      return handler.next(err);
    }

    // 4. Ambil Refresh Token
    final refreshToken = getIt<TokenStorage>().refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _forceLogout();
      return handler.next(err);
    }

    try {
      // Gunakan Dio terpisah tanpa interceptor agar tidak loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ));

      final refreshResponse = await refreshDio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data['data'];
      final newAccess = data['accessToken']?.toString();
      final newRefresh = data['refreshToken']?.toString();

      if (newAccess != null && newAccess.isNotEmpty) {
        await getIt<TokenStorage>().setTokens(
          accessToken: newAccess,
          refreshToken: newRefresh ?? refreshToken,
        );

        final opts = requestOptions.copyWith(
          headers: Map<String, dynamic>.from(requestOptions.headers)
            ..['Authorization'] = 'Bearer $newAccess',
        );

        final response = await _dio.fetch(opts);
        return handler.resolve(response);
      }
    } catch (e) {
      debugPrint('[AuthRefresh] Refresh failed: $e');
      await _forceLogout();
      return handler.reject(err);
    }

    return handler.next(err);
  }

  /// Force logout: invalidasi sesi di backend terlebih dahulu, lalu bersihkan local storage.
  /// Menggunakan Dio terpisah (tanpa interceptor) untuk menghindari loop 401.
  Future<void> _forceLogout({bool toAccessDenied = false}) async {
    // 1. Coba invalidasi sesi di backend (best effort)
    try {
      final token = getIt<TokenStorage>().token;
      final refreshToken = getIt<TokenStorage>().refreshToken;

      if (token != null || refreshToken != null) {
        final logoutDio = Dio(BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ));

        await logoutDio.post('/api/v1/auth/logout', data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
        });
        debugPrint('[AuthRefresh] Backend logout berhasil saat force-logout.');
      }
    } catch (e) {
      // Abaikan error — mungkin token sudah expired, tapi tetap bersihkan local
      debugPrint('[AuthRefresh] Backend logout gagal (expected): $e');
    }

    // 2. Clear local storage
    await getIt<TokenStorage>().clear();
    getIt<CurrentUserStore>().clear();

    // 3. Redirect ke login/access-denied
    appRouter.go(toAccessDenied ? AppRoutes.accessDenied : AppRoutes.login);
  }
}
