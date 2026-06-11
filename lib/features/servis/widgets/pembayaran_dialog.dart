import 'package:flutter/material.dart';
import 'package:stok_anandam/features/servis/widgets/update_status_dialog.dart';

class PembayaranDialog extends StatefulWidget {
  final String? statusBayarSaatIni;
  final double? biayaFinal;
  final double? dp;
  final String? noServis;

  const PembayaranDialog({
    super.key,
    this.statusBayarSaatIni,
    this.biayaFinal,
    this.dp,
    this.noServis,
  });

  @override
  State<PembayaranDialog> createState() => _PembayaranDialogState();
}

class _PembayaranDialogState extends State<PembayaranDialog> {
  final _formKey = GlobalKey<FormState>();
  final _catatanCtrl = TextEditingController();
  String _statusBayar = 'LUNAS';
  String _metodePembayaran = 'CASH';
  final _jumlahBayarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusBayar = widget.statusBayarSaatIni?.isNotEmpty == true
        ? widget.statusBayarSaatIni!
        : 'BELUM_LUNAS';
    // Set default jumlah bayar ke biaya final
    if (widget.biayaFinal != null && widget.biayaFinal! > 0) {
      _jumlahBayarCtrl.text = _formatNumber(widget.biayaFinal!);
    }
  }

  String _formatNumber(double value) {
    String numStr = value.toInt().toString();
    final chars = numStr.split('').toList();
    String formatted = '';
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += chars[i];
    }
    return formatted;
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _jumlahBayarCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final jumlahBayar = _jumlahBayarCtrl.text.isNotEmpty
        ? double.tryParse(
            _jumlahBayarCtrl.text.replaceAll('.', '').replaceAll(',', ''))
        : null;

    // Validasi: jika status LUNAS tapi jumlah bayar < biaya final
    final biayaFinal = widget.biayaFinal ?? 0;
    if (_statusBayar == 'LUNAS' && jumlahBayar != null && biayaFinal > 0 && jumlahBayar < biayaFinal) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Peringatan Pembayaran'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jumlah dibayar: Rp ${_formatNumber(jumlahBayar)}'),
              Text('Biaya Final: Rp ${_formatNumber(biayaFinal)}'),
              const SizedBox(height: 12),
              const Text(
                'Jumlah yang dibayarkan lebih kecil dari biaya final. Apakah Anda yakin ingin menandai sebagai LUNAS?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Kembali'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => Navigator.of(ctx).pop(true),
              label: const Text('Yakin, Lanjutkan'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) {
          Navigator.of(context).pop({
            'statusBayar': _statusBayar,
            'metodePembayaran': _metodePembayaran,
            'jumlahBayar': jumlahBayar,
            'catatan': _catatanCtrl.text.trim(),
          });
        }
      });
      return;
    }

    Navigator.of(context).pop({
      'statusBayar': _statusBayar,
      'metodePembayaran': _metodePembayaran,
      'jumlahBayar': jumlahBayar,
      'catatan': _catatanCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.payments_rounded, color: Colors.green.shade700),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Pembayaran', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info tagihan
              if (widget.noServis != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No. Servis: ${widget.noServis}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (widget.biayaFinal != null)
                        Text('Biaya Final: Rp ${_formatNumber(widget.biayaFinal!)}'),
                      if (widget.dp != null && widget.dp! > 0)
                        Text('DP: Rp ${_formatNumber(widget.dp!)}'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Status Bayar
              DropdownButtonFormField<String>(
                initialValue: _statusBayar,
                decoration: const InputDecoration(
                  labelText: 'Status Bayar',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'LUNAS', child: Text('Lunas')),
                  DropdownMenuItem(
                      value: 'BELUM_LUNAS', child: Text('Belum Lunas')),
                  DropdownMenuItem(value: 'PIUTANG', child: Text('Piutang')),
                ],
                onChanged: (v) => setState(() => _statusBayar = v!),
              ),
              const SizedBox(height: 12),

              // Metode Pembayaran
              DropdownButtonFormField<String>(
                initialValue: _metodePembayaran,
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'TRANSFER', child: Text('Transfer')),
                  DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                ],
                onChanged: (v) => setState(() => _metodePembayaran = v!),
              ),
              const SizedBox(height: 12),

              // Jumlah Bayar
              TextFormField(
                controller: _jumlahBayarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Dibayar',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixText: 'Rp ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandSeparatorFormatter()],
              ),
              const SizedBox(height: 12),

              // Catatan
              TextFormField(
                controller: _catatanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: Pembayaran via QRIS',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          label: const Text('Simpan Pembayaran'),
        ),
      ],
    );
  }
}

