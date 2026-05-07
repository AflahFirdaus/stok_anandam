import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/data/repositories/memo_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'dart:developer' as dev;
import 'package:stok_anandam/features/memo/utils/memo_auth_utils.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // Mobile Controller (Conditional)
  MobileScannerController? controller;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _isFlashOn = false;

  // Windows Buffer
  final FocusNode _focusNode = FocusNode();
  String _scanBuffer = "";
  DateTime _lastKeyPress = DateTime.now();

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (!_isWindows) {
      // Configuration for mobile_scanner 6.x
      controller = MobileScannerController(
        formats: const [BarcodeFormat.all],
        detectionSpeed: DetectionSpeed.normal,
        autoStart: true,
      );
    } else {
      // Ensure focus for scanner detection
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

  // Handle Input from 2D Scanner (HID Keyboard mode)
  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();

      // If delay between keys is too long, it might be manual typing?
      if (now.difference(_lastKeyPress).inMilliseconds > 1000) {
        _scanBuffer = "";
      }
      _lastKeyPress = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scanBuffer.isNotEmpty) {
          dev.log('[Scanner] Windows HID Scan: $_scanBuffer', name: 'Scanner');
          _processMemoId(_scanBuffer.trim());
          _scanBuffer = "";
        }
      } else {
        // Collect visible characters
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

    dev.log('[Scanner] Mobile Detected: $code', name: 'Scanner');
    await _processMemoId(code);
  }

  Future<void> _processMemoId(String memoId) async {
    if (_isProcessing) return;
    if (!mounted) return;
    
    setState(() => _isProcessing = true);

    try {
      dev.log('[Scanner] Fetching detail for ID: $memoId', name: 'Scanner');
      final detail = await getIt<MemoRepository>().getMemoDetail(memoId);

      if (detail == null) {
        dev.log('[Scanner] Memo not found: $memoId', name: 'Scanner');
        _showError("Memo tidak ditemukan.");
        return;
      }

      final userRole = getIt<CurrentUserStore>().userRole;
      
      if (!mounted) return;

      MemoAuthUtils.guardAccess(
        context,
        role: userRole,
        status: detail.statusAkhir,
        onGranted: () {
          dev.log('[Scanner] Navigation success to: $memoId', name: 'Scanner');
          context.pushReplacementNamed(AppRoutes.memoDetail,
              pathParameters: {'id': memoId});
        },
      );
    } catch (e) {
      dev.log('[Scanner] Error processing ID: $e', name: 'Scanner', error: e);
      _showError(
          "Gagal memproses QR Code: ${AppErrors.userMessageFromException(e)}");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  bool _isAuthorized(String? role, MemoStatus? status) {
    return MemoAuthUtils.canAccessMemo(role, status);
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
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
        appBar: AppBar(title: const Text('Scan QR Memo (Windows)')),
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleHardwareKey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hub_rounded,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 32),
                Text(
                  "SIAP MENERIMA SCAN",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Silakan arahkan scanner 2D Anda ke QR Code Memo",
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
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
        title: const Text('Scan QR Memo'),
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
                dev.log('[Scanner] Error: ${error.errorCode}', name: 'Scanner', error: error);
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
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                // Corner Borders
                Positioned(
                  top: 0, left: 0,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        left: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 4),
                        left: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
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
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Posisikan QR / Barcode di dalam kotak',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
