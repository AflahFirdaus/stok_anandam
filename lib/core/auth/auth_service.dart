import 'package:dio/dio.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:my_api_client/my_api_client.dart';

class AuthService {
  bool _isLoggingOut = false;

  /// Melakukan logout: Invalidate token di backend, hapus local storage, dan reset state.
  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      // 1. Panggil API Logout di backend (best effort)
      final dio = getIt<MyApiClient>().dio;
      await dio.post('/api/v1/auth/logout');
    } catch (_) {
      // Abaikan error jika gagal panggil API logout (misal karena token sudah expired)
    } finally {
      // 2. Clear local storage
      await getIt<TokenStorage>().clear();
      getIt<CurrentUserStore>().clear();

      // 3. Reset all static filter states
      GlobalStateResetter.resetAll();
      
      _isLoggingOut = false;
    }
  }

  /// Pengecekan session habis secara manual/proaktif jika dibutuhkan.
  /// Biasanya ditangani oleh AuthRefreshInterceptor.
  void handleSessionExpired() {
    logout();
  }
}
