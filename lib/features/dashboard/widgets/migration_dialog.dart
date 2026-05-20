import 'package:flutter/material.dart';
import '../../../injection.dart';
import '../../../data/api_new_endpoints.dart';
import 'package:my_api_client/my_api_client.dart';

/// Menampilkan dialog Sync Migrasi (MyBiz → PostgreSQL).
/// Bisa dipanggil dari halaman mana pun agar tombol Sync Migrasi di header bisa diklik.
void showMigrationDialog(BuildContext context, {VoidCallback? onSuccess}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _MigrationDialog(
      onClose: () => Navigator.of(ctx).pop(),
      onSuccess: () {
        Navigator.of(ctx).pop();
        onSuccess?.call();
      },
    ),
  );
}

class _MigrationDialog extends StatefulWidget {
  const _MigrationDialog({required this.onClose, required this.onSuccess});

  final VoidCallback onClose;
  final VoidCallback onSuccess;

  @override
  State<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<_MigrationDialog> {
  static const _steps = [
    ('TKDN (Spreadsheet)', 1),
    ('Pricelist (Spreadsheet)', 2),
    ('Data Distri (Spreadsheet)', 3),
  ];

  bool _started = false;
  int _current = 0;
  bool _loading = true;
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMigrations());
  }

  Future<void> _runMigrations() async {
    if (_started) return;
    _started = true;
    final api = getIt<ApiNewEndpoints>();

    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() {
        _current = i + 1;
        _error = null;
      });

      try {
        switch (i) {
          case 0:
            await api.startTkdnMigration();
            break;
          case 1:
            await api.startPricelistMigration();
            break;
          case 2:
            await api.startPelangganMigration();
            break;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '${_steps[i].$1}: Gagal. Periksa koneksi lalu coba lagi.';
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSuccess();
    });
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Migrasi'),
      content: SizedBox(
        width: 320,
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text('Gagal',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_error!,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              )
            : _success
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                          'Migrasi selesai. Semua data telah disinkronkan dari MyBiz ke PostgreSQL.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _current >= 1 && _current <= _steps.length
                            ? 'Menjalankan $_current/${_steps.length}: ${_steps[_current - 1].$1}...'
                            : 'Memulai migrasi...',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ),
      ),
      actions: [
        if (_error != null)
          TextButton(
            onPressed: widget.onClose,
            child: const Text('Tutup'),
          ),
        if (_loading && _error == null)
          const TextButton(
            onPressed: null,
            child: Text('Menunggu...'),
          ),
      ],
    );
  }
}
