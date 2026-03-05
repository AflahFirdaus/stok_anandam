import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan token JWT untuk request API yang butuh Bearer auth.
class TokenStorage extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';

  final SharedPreferences _prefs;
  String? _token;
  String? _refreshToken;

  TokenStorage(this._prefs) {
    _token = _prefs.getString(_tokenKey);
    _refreshToken = _prefs.getString(_refreshKey);
  }

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Future<void> setToken(String? value) async {
    _token = value;
    if (value != null) {
      await _prefs.setString(_tokenKey, value);
    } else {
      await _prefs.remove(_tokenKey);
    }
    notifyListeners();
  }

  Future<void> setRefreshToken(String? value) async {
    _refreshToken = value;
    if (value != null) {
      await _prefs.setString(_refreshKey, value);
    } else {
      await _prefs.remove(_refreshKey);
    }
    notifyListeners();
  }

  /// Menyimpan kedua token (dari login atau refresh).
  Future<void> setTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      _token = accessToken;
      await _prefs.setString(_tokenKey, accessToken);
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _prefs.setString(_refreshKey, refreshToken);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshKey);
    notifyListeners();
  }
}
