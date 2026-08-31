import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/features/servis/repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:developer' as dev;

class ServisScannerPage extends StatefulWidget {
  const ServisScannerPage({super.key});

  @override
  State<ServisScannerPage> createState() => _ServisScannerPageState();
}

class _ServisScannerPageState extends State<ServisScannerPage> {
  MobileScannerController? controller;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  // Windows Buffer for HID Scanner
  final FocusNode _focusNode = FocusNode();
  String _scanBuffer = "";
  DateTime _lastKeyPress = DateTime.now();

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (!_isWindows) {
      controller = MobileScannerController(
        formats: const [BarcodeFormat.all],
        detectionSpeed: DetectionSpeed.normal,
        autoStart: true,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Handle input from 2D Scanner (HID Keyboard mode) on Windows
  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      if (now.difference(_lastKeyPress).inMilliseconds > 1000) {
        _scanBuffer = "";
      }
      _lastKeyPress = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scanBuffer.isNotEmpty) {
          dev.log('[ServisScanner] Windows HID Scan: $_scanBuffer',
              name: 'ServisScanner');
          _processServisId(_scanBuffer.trim());
          _scanBuffer = "";
        }
      } else {
        final char = event.character;
        if (char != null) {
          _scanBuffer += char;
        }
      }
    }
  }

  void _handleCapture(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    dev.log('[ServisScanner] Mobile Detected: $code', name: 'ServisScanner');
    await _processServisId(code);
  }

  Future<void> _processServisId(String servisId) async {
    if (_isProcessing) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      dev.log('[ServisScanner] Fetching detail for ID: $servisId',
          name: 'ServisScanner');
      final repository = getIt<ServisRepository>();
      final transaksi = await repository.getTransaksiById(servisId);

      if (!mounted) return;

      if (transaksi.id == null || transaksi.id!.isEmpty) {
        _showError("Data servis tidak ditemukan.");
        return;
      }

      dev.log('[ServisScanner] Navigation success to: $servisId',
          name: 'ServisScanner');
      // Replace current route with detail page
      context.pushReplacementNamed(AppRoutes.servisDetail,
          pathParameters: {'id': servisId});
    } catch (e) {
      dev.log('[ServisScanner] Error processing ID: $e',
          name: 'ServisScanner', error: e);
      _showError(
          "Gagal memproses QR Code. Pastikan QR Code yang discan adalah Nota Servis yang valid.");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan Gagal'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isWindows) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR Nota Servis (Windows)')),
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleHardwareKey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 32),
                Text(
                  "SIAP MENERIMA SCAN",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Silakan arahkan scanner 2D Anda ke QR Code Nota Servis",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                if (_isProcessing)
                  const CircularProgressIndicator()
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text("Sistem Siap",
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // --- MOBILE UI ---
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Nota Servis'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (controller != null)
            IconButton(
              onPressed: () async {
                await controller!.toggleTorch();
                setState(() => _isFlashOn = !_isFlashOn);
              },
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (controller != null)
            MobileScanner(
              controller: controller!,
              onDetect: _handleCapture,
              fit: BoxFit.cover,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(error.errorCode.name,
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => controller?.start(),
                        child: const Text('Mulai Ulang Kamera'),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Scanner Overlay
          Center(
            child: Stack(
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                // Corner Borders
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        left: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 4),
                        left: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius:
                          BorderRadius.only(bottomLeft: Radius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memproses data...'),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan scan ke QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
