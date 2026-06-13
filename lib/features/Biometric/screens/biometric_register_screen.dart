import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:stok_anandam/injection.dart';
import '../api/biometric_api.dart';
import '../repositories/biometric_repository.dart';
import '../services/biometric_crypto_service.dart';

class BiometricRegisterScreen extends StatefulWidget {
  const BiometricRegisterScreen({super.key});

  @override
  State<BiometricRegisterScreen> createState() =>
      _BiometricRegisterScreenState();
}

class _BiometricRegisterScreenState extends State<BiometricRegisterScreen> {
  final _deviceNameController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistered = false;
  String? _deviceId;
  String? _errorMessage;

  late final BiometricRepository _repository;

  @override
  void initState() {
    super.initState();
    final dio = getIt<Dio>();
    const storage = FlutterSecureStorage();
    _repository = BiometricRepository(
      BiometricApi(dio),
      BiometricCryptoService(storage),
    );
    _initDeviceInfo();
  }

  Future<void> _initDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        if (_deviceNameController.text.isEmpty) {
          _deviceNameController.text =
              '${androidInfo.brand} ${androidInfo.model}';
        }
      } catch (_) {
        try {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
          if (_deviceNameController.text.isEmpty) {
            _deviceNameController.text = '${iosInfo.name} (iOS)';
          }
        } catch (_) {
          // Fallback for desktop/web
          deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
          if (_deviceNameController.text.isEmpty) {
            _deviceNameController.text = 'Desktop Device';
          }
        }
      }

      setState(() => _deviceId = deviceId);
    } catch (e) {
      setState(() {
        _deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_deviceId == null) {
      setState(() => _errorMessage = 'Gagal mendapatkan ID perangkat');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.registerBiometric(
        deviceId: _deviceId!,
        deviceName: _deviceNameController.text.isNotEmpty
            ? _deviceNameController.text
            : 'Perangkat Saya',
      );

      setState(() {
        _isRegistered = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric berhasil didaftarkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal mendaftarkan biometric: $e';
      });
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Biometric'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Icon(
              Icons.fingerprint,
              size: 80,
              color: _isRegistered ? Colors.green : Colors.blue.shade400,
            ),
            const SizedBox(height: 16),

            Text(
              _isRegistered
                  ? 'Biometric Terdaftar!'
                  : 'Daftarkan Biometric Perangkat',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _isRegistered
                  ? 'Perangkat Anda siap digunakan untuk login biometric.'
                  : 'Daftarkan fingerprint atau face ID perangkat Anda untuk login cepat tanpa password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Device ID
            if (_deviceId != null) ...[
              _InfoRow(label: 'Device ID', value: _deviceId!),
              const SizedBox(height: 16),
            ],

            // Device Name
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(
                labelText: 'Nama Perangkat',
                hintText: 'Contoh: Xiaomi Redmi Note 12',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 24),

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
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Register button
            if (!_isRegistered)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleRegister,
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
                        ? 'Mendaftarkan...'
                        : 'DAFTARKAN BIOMETRIC',
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

            if (_isRegistered) ...[
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'SELESAI',
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
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}