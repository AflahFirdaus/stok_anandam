import 'package:flutter/foundation.dart';
import '../api/biometric_api.dart';
import '../services/biometric_crypto_service.dart';

class BiometricRepository {
  final BiometricApi _api;
  final BiometricCryptoService _cryptoService;

  BiometricRepository(this._api, this._cryptoService);

  /// Register biometric for the current user (requires JWT token already set in Dio)
  Future<void> registerBiometric({
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      // Generate RSA key pair
      final publicKeyBase64 = await _cryptoService.generateKeyPair(deviceId);

      // Register public key to server
      await _api.register(
        deviceId: deviceId,
        deviceName: deviceName,
        publicKey: publicKeyBase64,
      );

      debugPrint('[BiometricRepository] Biometric registered successfully for device: $deviceId');
    } catch (e) {
      debugPrint('[BiometricRepository] Register biometric error: $e');
      rethrow;
    }
  }

  /// Perform full biometric login flow: challenge -> sign -> verify
  /// Returns JWT token
  Future<String> loginWithBiometric(String deviceId) async {
    try {
      // Check if keys exist
      final hasKeys = await _cryptoService.hasKeys(deviceId);
      if (!hasKeys) {
        throw Exception('Biometric key tidak ditemukan. Silakan daftarkan biometric terlebih dahulu.');
      }

      // Step 1: Get challenge from server
      final challenge = await _api.getChallenge(deviceId);
      debugPrint('[BiometricRepository] Challenge received: ${challenge.substring(0, min(20, challenge.length))}...');

      // Step 2: Sign challenge with private key
      final signature = await _cryptoService.signChallenge(deviceId, challenge);
      debugPrint('[BiometricRepository] Challenge signed successfully');

      // Step 3: Verify signature and get JWT
      final token = await _api.verify(
        deviceId: deviceId,
        challenge: challenge,
        signature: signature,
      );
      debugPrint('[BiometricRepository] Biometric login successful, token received');

      return token;
    } catch (e) {
      debugPrint('[BiometricRepository] Biometric login error: $e');
      rethrow;
    }
  }

  /// Check if biometric is available for a device
  Future<bool> isBiometricAvailable(String deviceId) async {
    return await _cryptoService.hasKeys(deviceId);
  }

  /// Delete biometric keys for a device
  Future<void> deleteBiometricKeys(String deviceId) async {
    await _cryptoService.deleteKeys(deviceId);
  }
}

int min(int a, int b) => a < b ? a : b;