import 'package:dio/dio.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/widgets/app_feedback.dart';
import 'package:stok_anandam/injection.dart';

/// Interceptor untuk mendeteksi error 401 (Unauthorized).
/// Jika token expired, auto-logout dan arahkan ke login.
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    final isAuthRequest = path.contains('/api/v1/auth/logout') ||
        path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/me');
    final isBiometricRequest = path.contains('/api/v1/biometric');

    // Handle 401 (Unauthorized/Token Expired)
    if (err.response?.statusCode == 401 &&
        !isAuthRequest &&
        !isBiometricRequest) {
      // Don't auto-logout for /api/v1/auth/me during login flow (let AuthBloc handle it)
      if (!path.contains('/api/v1/auth/me')) {
        getIt<AuthService>().logout();
        AppFeedback.showErrorGlobal(
            'Sesi Anda telah berakhir. Silakan login kembali.');
        // We do NOT call appRouter.go() here.
        // AuthService.logout() clears TokenStorage, which triggers the GoRouter refreshListenable redirect.
      }
    }
    // Handle 403 (Forbidden/Permission Denied)
    else if (err.response?.statusCode == 403 && !isAuthRequest) {
      AppFeedback.showErrorGlobal(
          'Anda tidak memiliki akses untuk tindakan ini.');
    }

    return handler.next(err);
  }
}
