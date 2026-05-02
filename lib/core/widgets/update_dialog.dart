import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../services/app_update_service.dart';

/// Dialog elegan untuk menampilkan info update dan progress download menggunakan ota_update.
class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;
  final AppUpdateService service;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.service,
  });

  /// Tampilkan dialog update. Jika forceUpdate, dialog tidak bisa di-dismiss.
  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.isForceUpdate,
      builder: (_) => UpdateDialog(
        info: info,
        service: AppUpdateService(),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;
  StreamSubscription? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });

    try {
      _subscription = widget.service.downloadAndInstall(widget.info).listen(
        (OtaEvent event) {
          if (!mounted) return;
          
          setState(() {
            if (event.status == OtaStatus.DOWNLOADING) {
              final val = int.tryParse(event.value ?? '0') ?? 0;
              _progress = val / 100.0;
            } else if (event.status == OtaStatus.INSTALLING) {
              _progress = 1.0;
              if (!widget.info.isForceUpdate) {
                Navigator.of(context).pop();
              }
            } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
              _downloading = false;
              _error = 'Izin penyimpanan ditolak.';
            } else if (event.status == OtaStatus.INTERNAL_ERROR || 
                       event.status == OtaStatus.DOWNLOAD_ERROR) {
              _downloading = false;
              _error = 'Gagal mengunduh: ${event.value}';
            }
          });
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _downloading = false;
              _error = 'Terjadi kesalahan: $e';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Gagal memulai unduhan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !widget.info.isForceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.system_update,
                  color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Pembaruan Tersedia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                children: [
                  const TextSpan(text: 'Versi terbaru '),
                  TextSpan(
                    text: widget.info.versionName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  const TextSpan(text: ' sudah tersedia.'),
                ],
              ),
            ),
            if (widget.info.releaseNotes != null &&
                widget.info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catatan Rilis:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Text(widget.info.releaseNotes!,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
            if (widget.info.isForceUpdate) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembaruan ini wajib diinstal untuk melanjutkan.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_downloading) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Mengunduh... ${(_progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          if (!widget.info.isForceUpdate && !_downloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti Saja'),
            ),
          if (!_downloading)
            ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Update Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }
}
