import 'package:flutter/foundation.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/injection.dart';

/// User yang sedang login (dari GET /api/v1/auth/me). Di-set setelah login dan di splash.
class CurrentUserStore extends ChangeNotifier {
  AuthMeResult? _me;

  AuthMeResult? get me => _me;
  String get displayName => _me?.displayName ?? 'User';
  String? get userRole => _me?.role;

  /// Load dari API dan simpan. Panggil setelah login dan saat splash (jika ada token).
  Future<void> loadFromApi() async {
    try {
      final api = getIt<ApiNewEndpoints>();
      _me = await api.getMe();
    } catch (_) {
      _me = null;
    }
    notifyListeners();
  }

  void clear() {
    _me = null;
    notifyListeners();
  }
}
