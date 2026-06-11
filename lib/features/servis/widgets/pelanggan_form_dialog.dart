import 'package:flutter/material.dart';
import 'package:stok_anandam/injection.dart';
import '../models/pelanggan_servis.dart';
import '../repositories/servis_repository.dart';

class PelangganFormDialog extends StatefulWidget {
  final PelangganServis? pelanggan;

  const PelangganFormDialog({super.key, this.pelanggan});

  @override
  State<PelangganFormDialog> createState() => _PelangganFormDialogState();
}

// 1. Tambahkan SingleTickerProviderStateMixin untuk Animasi
class _PelangganFormDialogState extends State<PelangganFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ServisRepository _repository = getIt<ServisRepository>();
  final _namaCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  String _kategori = 'User';
  bool _isLoading = false;

  static const _kategoriOptions = ['User', 'Toko'];

  bool get _isEdit => widget.pelanggan != null;

  // --- VARIABEL ANIMASI ---
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final pelanggan = widget.pelanggan;
    if (pelanggan != null) {
      _namaCtrl.text = pelanggan.namaPelanggan ?? '';
      _kategori = pelanggan.kategori ?? 'User';
      _teleponCtrl.text = pelanggan.noTelepon ?? '';
      _waCtrl.text = pelanggan.noWhatsapp ?? '';
      _alamatCtrl.text = pelanggan.alamat ?? '';
    }
    _teleponCtrl.addListener(_autoFillWa);

    // Setup Animasi Meluncur & Pudar (Durasi 400ms untuk kehalusan premium)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Mulai sedikit dari bawah
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    // Jalankan animasi saat dialog dibuka
    _animController.forward();
  }

  void _autoFillWa() {
    final telepon = _teleponCtrl.text.trim();
    if (telepon.isEmpty) return;
    String wa = telepon;
    if (telepon.startsWith('0')) {
      wa = '62${telepon.substring(1)}';
    } else if (!telepon.startsWith('62')) {
      wa = '62$telepon';
    }
    if (_waCtrl.text != wa) {
      _waCtrl.text = wa;
      _waCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _waCtrl.text.length),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose(); // Jangan lupa hapus controller animasi
    _namaCtrl.dispose();
    _teleponCtrl.dispose();
    _waCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final pelanggan = PelangganServis(
        namaPelanggan: _namaCtrl.text.trim(),
        kategori: _kategori,
        noTelepon: _teleponCtrl.text.trim(),
        noWhatsapp: _waCtrl.text.trim(),
        alamat: _alamatCtrl.text.trim(),
      );

      if (_isEdit) {
        await _repository.updatePelangganServis(
            widget.pelanggan!.id!, pelanggan);
      } else {
        await _repository.createPelangganServis(pelanggan);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Pelanggan berhasil diperbarui'
                : 'Pelanggan berhasil ditambahkan'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _modernInputDecoration(
      ThemeData theme, String label, IconData icon,
      {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
      filled: true,
      fillColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Padding yang aman untuk layar sekecil apapun
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),

      // 2. Bungkus dengan Animasi Slide dan Fade
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            // 3. Batasi lebar maksimal untuk Desktop, tapi full width untuk Mobile
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- HEADER ---
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                                _isEdit
                                    ? 'Perbarui detail informasi pelanggan'
                                    : 'Masukkan detail informasi pelanggan baru',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Tutup',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),

                // --- BODY FORM ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _namaCtrl,
                            decoration: _modernInputDecoration(
                                theme, 'Nama Lengkap *', Icons.badge_outlined),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text('Kategori Pelanggan',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              segments: _kategoriOptions
                                  .map((k) => ButtonSegment<String>(
                                      value: k, label: Text(k)))
                                  .toList(),
                              selected: {_kategori},
                              onSelectionChanged: (s) =>
                                  setState(() => _kategori = s.first),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. LayoutBuilder untuk Responsivitas Kolom Telepon & WA
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Jika ruangnya lebih dari 450px, tampilkan sejajar (Desktop/Tablet)
                              if (constraints.maxWidth > 450) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildTeleponField(theme)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildWaField(theme)),
                                  ],
                                );
                              } else {
                                // Jika ruangnya sempit, susun ke bawah (Mobile/Setengah Layar)
                                return Column(
                                  children: [
                                    _buildTeleponField(theme),
                                    const SizedBox(height: 16),
                                    _buildWaField(theme),
                                  ],
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _alamatCtrl,
                            decoration: _modernInputDecoration(
                                    theme,
                                    'Alamat (Opsional)',
                                    Icons.location_on_outlined)
                                .copyWith(alignLabelWithHint: true),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- FOOTER ACTIONS ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                    border: Border(
                        top: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(_isEdit ? 'Update Data' : 'Simpan Data'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeleponField(ThemeData theme) {
    return TextFormField(
      controller: _teleponCtrl,
      decoration: _modernInputDecoration(
          theme, 'No. Telepon *', Icons.phone_outlined,
          hint: '08xx'),
      keyboardType: TextInputType.phone,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
    );
  }

  Widget _buildWaField(ThemeData theme) {
    return TextFormField(
      controller: _waCtrl,
      decoration: _modernInputDecoration(
          theme, 'No. WhatsApp *', Icons.chat_bubble_outline,
          hint: '628xx', helper: 'Otomatis disinkronkan'),
      keyboardType: TextInputType.phone,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
    );
  }
}
