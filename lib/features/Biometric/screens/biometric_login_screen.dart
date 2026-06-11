import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';
import '../api/biometric_api.dart';
import '../repositories/biometric_repository.dart';
import '../services/biometric_crypto_service.dart';
import 'biometric_register_screen.dart';

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen> {
  final _localAuth = LocalAuthentication();
  String? _deviceId;
  bool _isLoading = false;
  bool _isChecking = true;
  bool _hasBiometricKeys = false;
  bool _canCheckBiometrics = false;
  String? _errorMessage;

  late final BiometricRepository _repository;

  @override
  void initState() {
    super.initState();
    final dio = getIt<Dio>();
    final storage = const FlutterSecureStorage();
    _repository = BiometricRepository(
      BiometricApi(dio),
      BiometricCryptoService(storage),
    );
    _initDevice();
  }

  Future<void> _initDevice() async {
    try {
      // Check biometric availability
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      // Get device ID
      String deviceId;
      try {
        final deviceInfo = DeviceInfoPlugin();
        try {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } catch (_) {
          try {
            final iosInfo = await deviceInfo.iosInfo;
            deviceId = iosInfo.identifierForVendor ?? 'ios-fallback';
          } catch (_) {
            deviceId = 'device-fallback';
          }
        }
      } catch (_) {
        deviceId = 'device-fallback';
      }

      final hasKeys = await _repository.isBiometricAvailable(deviceId);

      setState(() {
        _deviceId = deviceId;
        _canCheckBiometrics = canCheckBiometrics || isDeviceSupported;
        _hasBiometricKeys = hasKeys;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMessage = 'Gagal inisialisasi: $e';
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_deviceId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Authenticate with fingerprint/face ID
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint untuk login',
      );

      if (!authenticated) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Autentikasi biometric gagal';
        });
        return;
      }

      // Perform biometric login to server
      final token = await _repository.loginWithBiometric(_deviceId!);

      // Save token
      await getIt<TokenStorage>().setTokens(accessToken: token);

      // Load user data
      try {
        await getIt<CurrentUserStore>().loadFromApi().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
                '[BiometricLogin] User info load timeout, proceeding anyway');
            return;
          },
        );
      } catch (e) {
        debugPrint('[BiometricLogin] User info load error: $e');
      }

      // Navigate to dashboard
      if (mounted) {
        final userRole =
            getIt<CurrentUserStore>().userRole?.toUpperCase();

        if (userRole == 'TEKNISI' || userRole == 'DELIVERY') {
          context.go(AppRoutes.pengiriman);
        } else if (userRole != null && userRole.contains('NOTA')) {
          context.go(AppRoutes.memo);
        } else if (userRole == 'GUDANG' ||
            (userRole != null && userRole.startsWith('MARKETING'))) {
          context.go(AppRoutes.stok);
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      bool unregistered = false;
      if (e is DioException) {
        final response = e.response;
        if (response?.statusCode == 401) {
          final data = response?.data;
          final message = data is Map ? data['message']?.toString() : '';
          if (message != null && message.contains('Device not registered')) {
            unregistered = true;
          }
        }
      }

      if (unregistered && _deviceId != null) {
        try {
          await _repository.deleteBiometricKeys(_deviceId!);
          setState(() {
            _hasBiometricKeys = false;
          });
        } catch (_) {}
      }

      setState(() {
        _isLoading = false;
        _errorMessage = unregistered
            ? 'Perangkat ini belum terdaftar di server. Silakan klik "Daftarkan Biometric" di bawah.'
            : 'Gagal login biometric: $e';
      });
    }
  }

  Future<void> _navigateToRegister() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BiometricRegisterScreen(),
      ),
    );

    if (result == true) {
      // Refresh state after registration
      _initDevice();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo / title
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Movva ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Color.fromARGB(223, 9, 5, 89),
                        ),
                      ),
                      TextSpan(
                        text: 'by Anandam.id',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Color.fromARGB(255, 53, 205, 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                if (_isChecking)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memeriksa perangkat...'),
                    ],
                  )
                else ...[
                  // Fingerprint icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 56,
                      color: _hasBiometricKeys
                          ? Colors.blue.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _hasBiometricKeys
                        ? 'Login Biometric'
                        : 'Biometric Belum Terdaftar',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _hasBiometricKeys
                        ? 'Gunakan fingerprint atau face ID untuk login cepat'
                        : 'Daftarkan biometric perangkat Anda terlebih dahulu',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Biometric login button
                  if (_hasBiometricKeys && _canCheckBiometrics)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleBiometricLogin,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.fingerprint),
                        label: Text(
                          _isLoading
                              ? 'Memverifikasi...'
                              : 'LOGIN DENGAN BIOMETRIC',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  if (!_canCheckBiometrics && _hasBiometricKeys)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Perangkat tidak mendukung biometric',
                              style: TextStyle(
                                  color: Colors.orange.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Register button
                  if (!_hasBiometricKeys)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToRegister,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          'DAFTARKAN BIOMETRIC',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Back to normal login
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(
                      'Login dengan password',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}