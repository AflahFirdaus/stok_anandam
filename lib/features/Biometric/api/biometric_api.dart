import 'package:dio/dio.dart';

class BiometricApi {
  final Dio _dio;

  BiometricApi(this._dio);

  static const _basePath = '/api/v1/biometric';

  /// Register biometric public key (requires JWT token)
  Future<void> register({
    required String deviceId,
    required String deviceName,
    required String publicKey,
  }) async {
    final response = await _dio.post(
      '$_basePath/register',
      data: {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'publicKey': publicKey,
      },
      options: Options(responseType: ResponseType.plain),
    );

    if (response.statusCode != 200) {
      throw Exception('Register biometric gagal: ${response.data}');
    }
  }

  /// Request challenge for biometric login (public endpoint)
  Future<String> getChallenge(String deviceId) async {
    final response = await _dio.post(
      '$_basePath/challenge',
      data: {
        'deviceId': deviceId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mendapatkan challenge');
    }

    final data = response.data;
    if (data is Map && data['challenge'] != null) {
      return data['challenge'].toString();
    }
    throw Exception('Response challenge tidak valid');
  }

  /// Verify signature and get JWT token (public endpoint)
  Future<String> verify({
    required String deviceId,
    required String challenge,
    required String signature,
  }) async {
    final response = await _dio.post(
      '$_basePath/verify',
      data: {
        'deviceId': deviceId,
        'challenge': challenge,
        'signature': signature,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Verifikasi biometric gagal');
    }

    final data = response.data;
    if (data is Map && data['token'] != null) {
      return data['token'].toString();
    }
    throw Exception('Response verify tidak valid');
  }
}