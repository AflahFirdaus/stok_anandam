import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token JWT terenkripsi untuk request API yang butuh Bearer auth.
class TokenStorage extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;
  String? _refreshToken;

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  /// Harus dipanggil saat inisialisasi aplikasi (contoh: di injection.dart)
  Future<void> init() async {
    _token = await _secureStorage.read(key: _tokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshKey);
    notifyListeners();
  }

  Future<void> setToken(String? value) async {
    _token = value;
    if (value != null) {
      await _secureStorage.write(key: _tokenKey, value: value);
    } else {
      await _secureStorage.delete(key: _tokenKey);
    }
    notifyListeners();
  }

  Future<void> setRefreshToken(String? value) async {
    _refreshToken = value;
    if (value != null) {
      await _secureStorage.write(key: _refreshKey, value: value);
    } else {
      await _secureStorage.delete(key: _refreshKey);
    }
    notifyListeners();
  }

  /// Menyimpan kedua token (dari login atau refresh).
  Future<void> setTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      _token = accessToken;
      await _secureStorage.write(key: _tokenKey, value: accessToken);
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _secureStorage.write(key: _refreshKey, value: refreshToken);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshKey);
    notifyListeners();
  }
}
