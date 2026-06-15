import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/features/servis/models/transaksi_servis.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';

/// Dialog konfirmasi + input data saat admin mengubah status transaksi servis.
/// Beberapa status memerlukan data tambahan (biaya, garansi, dll).
class UpdateStatusDialog extends StatefulWidget {
  final String targetStatus;
  final TransaksiServis? transaksi;

  const UpdateStatusDialog({
    super.key,
    required this.targetStatus,
    this.transaksi,
  });

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _biayaFinalCtrl = TextEditingController();
  final _estimasiBiayaCtrl = TextEditingController();
  final _pengambilNamaCtrl = TextEditingController();
  final _durasiGaransiCtrl = TextEditingController();
  final _modalSparepartCtrl = TextEditingController();
  final _ketTindakanCtrl = TextEditingController();
  final _kondisiServisCtrl = TextEditingController();
  final _modelSeriBaruCtrl = TextEditingController();
  final DateTime _tglDitangani = DateTime.now();
  late DateTime _tglJatuhTempo;
  String _statusBayar = 'BELUM_LUNAS';

  bool get _needsBiaya => widget.targetStatus == 'BISA_DIAMBIL';

  bool get _showsServiceFields =>
      widget.targetStatus != 'SUDAH_DIAMBIL' &&
      widget.targetStatus != 'BATAL' &&
      !widget.targetStatus.startsWith('KLAIM');

  bool get _needsTeknisi => widget.targetStatus == 'SEDANG_DIKERJAKAN';

  bool get _needsEstimasiBiaya => widget.targetStatus == 'SEDANG_DIKERJAKAN';

  bool get _needsPengambil => widget.targetStatus == 'SUDAH_DIAMBIL';

  @override
  void initState() {
    super.initState();
    // Initialize tglJatuhTempo from existing transaksi data, or calculate default
    _tglJatuhTempo = DateTime.now().add(const Duration(days: 14));
    final t = widget.transaksi;
    if (t != null) {
      _kondisiServisCtrl.text = t.kondisiServis ?? '';
      _ketTindakanCtrl.text = t.ketTindakan ?? '';
      _durasiGaransiCtrl.text = t.durasiGaransi ?? '';
      _biayaFinalCtrl.text = _formatNumberForInput(t.biayaFinal);
      _modalSparepartCtrl.text = _formatNumberForInput(t.modalSparepart);
      _estimasiBiayaCtrl.text = _formatNumberForInput(t.estimasiBiaya);
      _pengambilNamaCtrl.text = t.pengambilNama ?? '';
      _statusBayar =
          t.statusBayar?.isNotEmpty == true ? t.statusBayar! : 'BELUM_LUNAS';
      // Try to restore tglJatuhTempo from existing data
      if (t.tglJatuhTempo != null && t.tglJatuhTempo!.isNotEmpty) {
        final parsed = DateTime.tryParse(t.tglJatuhTempo!);
        if (parsed != null) _tglJatuhTempo = parsed;
      }
    }
  }

  String _formatNumberForInput(double? value) {
    if (value == null) return '';
    String numStr = '';
    if (value == value.roundToDouble()) {
      numStr = value.toInt().toString();
    } else {
      numStr = value.toString();
    }
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String fractionalPart = parts.length > 1 ? ',${parts[1]}' : '';

    final chars = integerPart.split('').toList();
    String formatted = '';
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += chars[i];
    }
    return formatted + fractionalPart;
  }

  @override
  void dispose() {
    _biayaFinalCtrl.dispose();
    _estimasiBiayaCtrl.dispose();
    _modalSparepartCtrl.dispose();
    _pengambilNamaCtrl.dispose();
    _durasiGaransiCtrl.dispose();
    _ketTindakanCtrl.dispose();
    _kondisiServisCtrl.dispose();
    _modelSeriBaruCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final biaya = _biayaFinalCtrl.text.isNotEmpty
        ? double.tryParse(
            _biayaFinalCtrl.text.replaceAll('.', '').replaceAll(',', ''))
        : null;
    final modalSparepart = _modalSparepartCtrl.text.isNotEmpty
        ? double.tryParse(
            _modalSparepartCtrl.text.replaceAll('.', '').replaceAll(',', ''))
        : null;
    final estimasiBiaya = _estimasiBiayaCtrl.text.isNotEmpty
        ? double.tryParse(
            _estimasiBiayaCtrl.text.replaceAll('.', '').replaceAll(',', ''))
        : null;

    // Format tglJatuhTempo - calculated from durasiGaransi for BISA_DIAMBIL,
    // or from DatePicker for SUDAH_DIAMBIL
    String? tglJatuhTempoFormatted;
    if (_needsBiaya && _durasiGaransiCtrl.text.trim().isNotEmpty) {
      tglJatuhTempoFormatted =
          _calculateTglJatuhTempo(_durasiGaransiCtrl.text.trim());
    } else if (_needsPengambil) {
      // Use the DatePicker value for SUDAH_DIAMBIL
      tglJatuhTempoFormatted = DateFormat('yyyy-MM-dd').format(_tglJatuhTempo);
    }

    // Format tglAmbil for SUDAH_DIAMBIL
    String? tglAmbil;
    if (_needsPengambil) {
      tglAmbil = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    // Format tglDitangani as date-only string for backend
    String? tglDitanganiFormatted;
    if (_needsTeknisi) {
      tglDitanganiFormatted = DateFormat('yyyy-MM-dd').format(_tglDitangani);
    }

    // Ambil data user yang sedang login untuk teknisi otomatis
    final userStore = getIt<CurrentUserStore>();
    final teknisiId = userStore.userId;
    final teknisiNama = userStore.displayName;

    final Map<String, dynamic> resultPayload = {
      if (_showsServiceFields) 'ketTindakan': _ketTindakanCtrl.text.trim(),
      if (_showsServiceFields) 'kondisiServis': _kondisiServisCtrl.text.trim(),
      if (_needsTeknisi && teknisiId != null) 'teknisiId': teknisiId,
      if (_needsTeknisi) 'namaTeknisi': teknisiNama,
      if (_needsTeknisi && tglDitanganiFormatted != null)
        'tglDitangani': tglDitanganiFormatted,
      if (_needsTeknisi && tglDitanganiFormatted != null)
        'tanggalDitangani': tglDitanganiFormatted,
      if (_needsBiaya) 'biayaFinal': biaya,
      if (_needsBiaya) 'modalSparepart': modalSparepart,
      if (_needsEstimasiBiaya) 'estimasiBiaya': estimasiBiaya,
      if (_needsPengambil && _pengambilNamaCtrl.text.isNotEmpty)
        'pengambilNama': _pengambilNamaCtrl.text.trim(),
      if (_needsBiaya) 'durasiGaransi': _durasiGaransiCtrl.text.trim(),
      if (_needsBiaya) 'statusBayar': _statusBayar,
      if (tglJatuhTempoFormatted != null)
        'tglJatuhTempo': tglJatuhTempoFormatted,
      if (tglAmbil != null) 'tglAmbil': tglAmbil,
      if (widget.targetStatus == 'KLAIM_SUDAH_DIAMBIL' &&
          _modelSeriBaruCtrl.text.isNotEmpty)
        'modelSeriBaru': _modelSeriBaruCtrl.text.trim(),
    };

    debugPrint('===== UpdateStatusDialog SUBMIT =====');
    debugPrint('targetStatus: ${widget.targetStatus}');
    debugPrint('teknisiId: $teknisiId (nama: $teknisiNama)');
    debugPrint('Payload: $resultPayload');
    debugPrint('======================================');

    Navigator.of(context).pop(resultPayload);
  }

  /// Calculate tglJatuhTempo from durasiGaransi string.
  /// Supports formats: "14", "14 Hari", "1 bulan", "30 hari", etc.
  String _calculateTglJatuhTempo(String durasi) {
    final now = DateTime.now();
    final lower = durasi.toLowerCase().trim();

    // Try to parse as "N bulan" format
    if (lower.contains('bulan')) {
      final nums = RegExp(r'(\d+)')
          .allMatches(lower)
          .map((m) => m.group(1)!)
          .where((s) => s.isNotEmpty)
          .toList();
      if (nums.isNotEmpty) {
        final months = int.tryParse(nums[0]) ?? 1;
        return DateFormat('yyyy-MM-dd').format(
          DateTime(now.year, now.month + months, now.day),
        );
      }
    }

    // Try to parse as "N tahun" format
    if (lower.contains('tahun') || lower.contains('thn')) {
      final nums = RegExp(r'(\d+)')
          .allMatches(lower)
          .map((m) => m.group(1)!)
          .where((s) => s.isNotEmpty)
          .toList();
      if (nums.isNotEmpty) {
        final years = int.tryParse(nums[0]) ?? 1;
        return DateFormat('yyyy-MM-dd').format(
          DateTime(now.year + years, now.month, now.day),
        );
      }
    }

    // Default: parse as number of days (e.g., "14", "14 Hari", "30 hari")
    final nums = RegExp(r'(\d+)')
        .allMatches(lower)
        .map((m) => m.group(1)!)
        .where((s) => s.isNotEmpty)
        .toList();
    if (nums.isNotEmpty) {
      final days = int.tryParse(nums[0]) ?? 14;
      return DateFormat('yyyy-MM-dd').format(
        now.add(Duration(days: days)),
      );
    }

    // Fallback: 14 days from now
    return DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 14)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.targetStatus.replaceAll('_', ' ');
    final isBatal = widget.targetStatus == 'BATAL';
    final userStore = getIt<CurrentUserStore>();
    final teknisiNama = userStore.displayName;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isBatal ? Icons.warning_rounded : Icons.update_rounded,
            color: isBatal ? Colors.red : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text('Ubah ke: $label', style: const TextStyle(fontSize: 16)),
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
              if (widget.targetStatus == 'KLAIM_SUDAH_DIAMBIL') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modelSeriBaruCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Seri Baru (Jika Ganti Unit)',
                    hintText: 'Isi jika distributor mengganti dengan unit baru',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],

              if (_showsServiceFields) ...[
                if (_needsTeknisi) ...[
                  const SizedBox(height: 12),
                  // Tampilkan informasi teknisi otomatis dari user yang login
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.build_rounded,
                              size: 20, color: Colors.indigo.shade700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teknisi yang mengerjakan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.indigo.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                teknisiNama,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle,
                            size: 18, color: Colors.indigo.shade300),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue:
                        DateFormat('dd MMM yyyy').format(_tglDitangani),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Ditangani',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.event_available_rounded),
                    ),
                  ),
                  if (_needsEstimasiBiaya) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _estimasiBiayaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Estimasi Biaya',
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
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kondisiServisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi Servis',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ketTindakanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan Tindakan',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
              ],

              // Field khusus untuk BISA_DIAMBIL
              if (_needsBiaya) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durasiGaransiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Durasi Garansi',
                    hintText: 'Contoh: 1 bulan / 30 hari',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _biayaFinalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Biaya Final',
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
                TextFormField(
                  controller: _modalSparepartCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modal Sparepart (opsional)',
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
              ],

              // Field nama pengambil hanya untuk SUDAH_DIAMBIL
              if (_needsPengambil) ...[
                _LastServiceSnapshot(transaksi: widget.transaksi),
                const SizedBox(height: 12),
                // Date picker for tglJatuhTempo (Batas Garansi)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _tglJatuhTempo,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                      helpText: 'Pilih Tanggal Jatuh Tempo Garansi',
                    );
                    if (picked != null) {
                      setState(() {
                        _tglJatuhTempo = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Jatuh Tempo Garansi',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.event_available_rounded),
                      suffixIcon: Icon(Icons.edit_calendar_rounded),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_tglJatuhTempo),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pengambilNamaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pengambil Barang',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pengambil wajib diisi';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isBatal ? Colors.red : null,
            foregroundColor: isBatal ? Colors.white : null,
          ),
          onPressed: _submit,
          child: Text('Konfirmasi $label'),
        ),
      ],
    );
  }
}

class _LastServiceSnapshot extends StatelessWidget {
  final TransaksiServis? transaksi;

  const _LastServiceSnapshot({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = transaksi;
    if (t == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data servis terakhir',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _SnapshotRow('Kondisi Servis', t.kondisiServis),
          _SnapshotRow('Keterangan Tindakan', t.ketTindakan),
          _SnapshotRow('Durasi Garansi', t.durasiGaransi),
          _SnapshotRow('Biaya Final', _formatCurrency(t.biayaFinal)),
          _SnapshotRow('Modal Sparepart', _formatCurrency(t.modalSparepart)),
        ],
      ),
    );
  }

  String? _formatCurrency(double? value) {
    if (value == null) return null;
    return NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(value);
  }
}

class _SnapshotRow extends StatelessWidget {
  final String label;
  final String? value;

  const _SnapshotRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanString = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    if (cleanString.isEmpty) return oldValue;

    List<String> parts = cleanString.split(',');
    String integerPart = parts[0];
    if (integerPart.length > 1 && integerPart.startsWith('0')) {
      integerPart = integerPart.replaceFirst(RegExp(r'^0+'), '');
      if (integerPart.isEmpty) {
        integerPart = '0';
      }
    }
    String fractionalPart =
        parts.length > 1 ? ',${parts.sublist(1).join('')}' : '';

    String digits = integerPart;
    final chars = digits.split('').toList();
    String formatted = '';
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += chars[i];
    }

    formatted += fractionalPart;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
