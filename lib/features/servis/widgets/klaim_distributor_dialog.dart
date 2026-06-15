import 'package:flutter/material.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:stok_anandam/core/widgets/app_feedback.dart';
import '../models/klaim_distributor.dart';
import '../repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'update_status_dialog.dart';

class KlaimDistributorDialog extends StatefulWidget {
  final String transaksiId;
  final KlaimDistributor? existingKlaim; // Jika tidak null, mode edit
  const KlaimDistributorDialog(
      {super.key, required this.transaksiId, this.existingKlaim});

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

  @override
  void initState() {
    super.initState();
    // Pre-populate jika mode edit
    final k = widget.existingKlaim;
    if (k != null) {
      _namaDistributorCtrl.text = k.namaDistributor ?? '';
      _alamatDistributorCtrl.text = k.alamatDistributor ?? '';
      _resiPengirimanCtrl.text = k.resiPengiriman ?? '';
      if (k.biayaKlaim != null && k.biayaKlaim! > 0) {
        _biayaKlaimCtrl.text = k.biayaKlaim!.toStringAsFixed(0);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cleanedBiaya =
          _biayaKlaimCtrl.text.replaceAll('.', '').replaceAll(',', '').trim();
      final data = <String, dynamic>{
        'namaDistributor': _namaDistributorCtrl.text.trim(),
        'alamatDistributor': _alamatDistributorCtrl.text.trim(),
        'biayaKlaim': double.tryParse(cleanedBiaya) ?? 0.0,
      };

      // 2. Mode: CREATE atau UPDATE
      if (widget.existingKlaim?.id != null) {
        await _repository.updateKlaimDistributor(
            widget.existingKlaim!.id!, data);
      } else {
        await _repository.createKlaimDistributor(widget.transaksiId, data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrors.userMessageFromException(
          e,
          fallback: 'Gagal menyimpan data klaim. Coba lagi.',
        ));
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
          Icon(Icons.local_shipping_rounded,
              color: Theme.of(context).colorScheme.primary),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _alamatDistributorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Distributor (opsional)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _resiPengirimanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Resi Pengiriman',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _biayaKlaimCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Biaya Klaim',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        prefixText: 'Rp ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
