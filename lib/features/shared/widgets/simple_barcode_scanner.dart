import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SimpleBarcodeScanner extends StatefulWidget {
  final String title;
  const SimpleBarcodeScanner({super.key, this.title = 'Scan Barcode / Resi'});

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  MobileScannerController? controller;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && !Platform.isWindows) {
      controller = MobileScannerController(
        formats: const [BarcodeFormat.all],
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      setState(() => _isProcessing = true);
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = !kIsWeb && !Platform.isWindows;

    if (!isMobile) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('Fitur scan kamera hanya tersedia di perangkat mobile.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
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
          MobileScanner(
            controller: controller!,
            onDetect: _onDetect,
          ),
          // Overlay
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Posisikan Barcode / Resi di dalam kotak',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
