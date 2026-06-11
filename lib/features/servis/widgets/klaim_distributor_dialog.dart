import 'package:flutter/material.dart';
import '../models/klaim_distributor.dart';
import '../repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'update_status_dialog.dart';

class KlaimDistributorDialog extends StatefulWidget {
  final String transaksiId;
  const KlaimDistributorDialog({super.key, required this.transaksiId});

  @override
  State<KlaimDistributorDialog> createState() => _KlaimDistributorDialogState();
}

class _KlaimDistributorDialogState extends State<KlaimDistributorDialog> {
  final _formKey = GlobalKey<FormState>();
  final ServisRepository _repository = getIt<ServisRepository>();
  bool _isLoading = false;

  final _namaDistributorCtrl = TextEditingController();
  final _alamatDistributorCtrl = TextEditingController();
  final _resiPengirimanCtrl = TextEditingController();
  final _biayaKlaimCtrl = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Buat instance model
      final cleanedBiaya = _biayaKlaimCtrl.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim();
      final klaim = KlaimDistributor(
        namaDistributor: _namaDistributorCtrl.text.trim(),
        alamatDistributor: _alamatDistributorCtrl.text.trim(),
        resiPengiriman: _resiPengirimanCtrl.text.trim(),
        biayaKlaim: double.tryParse(cleanedBiaya) ?? 0.0,
      );

      // 2. KIRIM SEBAGAI MAP, BUKAN OBJEK MODEL
      await _repository.createKlaimDistributor(
          widget.transaksiId, klaim.toJsonCreate());

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal membuat klaim: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Klaim ke Distributor'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _namaDistributorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Distributor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _alamatDistributorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Distributor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _resiPengirimanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Resi Pengiriman',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _biayaKlaimCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Biaya Klaim',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandSeparatorFormatter()],
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
