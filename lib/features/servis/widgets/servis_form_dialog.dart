import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pelanggan_servis.dart';
import '../models/klaim_distributor.dart';
import '../repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'update_status_dialog.dart';

class ServisFormDialog extends StatefulWidget {
  const ServisFormDialog({super.key});

  @override
  State<ServisFormDialog> createState() => _ServisFormDialogState();
}

// 1. Tambahkan SingleTickerProviderStateMixin untuk Animasi
class _ServisFormDialogState extends State<ServisFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ServisRepository _repository = getIt<ServisRepository>();
  final ApiNewEndpoints _api = getIt<ApiNewEndpoints>();

  // --- STATE VARIABLES ---
  bool _isLoadingPelanggan = true;
  bool _isLoading = false;
  bool _isCheckingSn = false;

  List<PelangganServis> _pelangganList = [];
  PelangganServis? _selectedPelanggan;

  String _tipeNota = 'SERVIS';

  // --- SN Check State ---
  String? _snCheckResult; // 'found', 'not_found', 'error'
  String? _snCheckDetail;
  List<ItemSerialNumberResponse>? _snBlItems; // BL (SN Masuk + Old Data)
  List<ItemSerialNumberResponse>? _snJlItems; // JL (SN Keluar)

  // --- FORM CONTROLLERS ---
  final _jenisBarangCtrl = TextEditingController();
  final _merekCtrl = TextEditingController();
  final _modelSeriCtrl = TextEditingController();
  final _kelengkapanCtrl = TextEditingController();
  final _kerusakanCtrl = TextEditingController();
  final _dpCtrl = TextEditingController();
  final _estimasiBiayaCtrl = TextEditingController();
  final _snCtrl = TextEditingController();

  // --- KLAIM DISTRIBUTOR CONTROLLERS ---
  final _namaDistributorCtrl = TextEditingController();
  final _alamatDistributorCtrl = TextEditingController();
  final _resiPengirimanCtrl = TextEditingController();
  final _biayaKlaimCtrl = TextEditingController();

  Timer? _snDebounce;

  // --- VARIABEL ANIMASI ---
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPelanggan();

    // Setup Animasi Meluncur & Pudar (400ms untuk kehalusan premium)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    // Jalankan animasi saat dialog dibuka
    _animController.forward();
  }

  Future<void> _loadPelanggan() async {
    try {
      final parsedList = await _repository.getPelangganServis(size: 200);
      if (mounted) {
        setState(() {
          _pelangganList = parsedList.content;
        });
      }
    } catch (e) {
      debugPrint('Gagal load pelanggan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPelanggan = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPelanggan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih Pelanggan terlebih dahulu!')));
      return;
    }

    // Validasi tambahan untuk klaim
    final isKlaim = _tipeNota == 'KLAIM';
    if (isKlaim && _namaDistributorCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama Distributor wajib diisi untuk klaim garansi!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        "pelangganId": _selectedPelanggan!.id,
        "jenisBarang": _jenisBarangCtrl.text.trim(),
        "merek": _merekCtrl.text.trim(),
        "modelSeri": _modelSeriCtrl.text.trim(),
        "kerusakan": _kerusakanCtrl.text.trim(),
        "kelengkapan": _kelengkapanCtrl.text.trim(),
        "dp": double.tryParse(_dpCtrl.text.trim()) ?? 0.0,
        "estimasiBiaya": double.tryParse(_estimasiBiayaCtrl.text.trim()) ?? 0.0,
        "tipeNota": _tipeNota,
      };

      final response = await _repository.createTransaksiServis(payload);

      if (mounted) {
        if (isKlaim) {
          // Langsung buat klaim distributor dengan data dari form
          try {
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
            await _repository.createKlaimDistributor(
                response.id ?? '', klaim.toJsonCreate());
          } catch (e) {
            debugPrint('Gagal membuat klaim: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi klaim berhasil dibuat dengan data distributor.'),
              ),
            );
            Navigator.of(context).pop(response);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Servis berhasil dibuat')),
            );
            Navigator.of(context).pop(response);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Mengecek Serial Number di 3 endpoint: SN Masuk (BL), SN Keluar (JL), dan Old Data Item SN (BL).
  Future<void> _checkSn() async {
    final sn = _snCtrl.text.trim();
    if (sn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Masukkan Serial Number terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isCheckingSn = true;
      _snCheckResult = null;
      _snCheckDetail = null;
      _snBlItems = null;
      _snJlItems = null;
    });

    try {
      final blItems = <ItemSerialNumberResponse>[];
      final jlItems = <ItemSerialNumberResponse>[];

      // 1. Cek di SN Masuk → BL
      final snMasukResponse = await _api.getSnMasuk(sn: sn, size: 10, page: 0);
      if (snMasukResponse['status'] == 200 && snMasukResponse['data'] is List) {
        final list = snMasukResponse['data'] as List;
        blItems.addAll(
          list.map((e) =>
              ItemSerialNumberResponse.fromJson(Map<String, dynamic>.from(e))),
        );
      }

      // 2. Cek di SN Keluar → JL
      final snKeluarResponse =
          await _api.getSnKeluar(sn: sn, size: 10, page: 0);
      if (snKeluarResponse['status'] == 200 &&
          snKeluarResponse['data'] is List) {
        final list = snKeluarResponse['data'] as List;
        jlItems.addAll(
          list.map((e) =>
              ItemSerialNumberResponse.fromJson(Map<String, dynamic>.from(e))),
        );
      }

      // 3. Cek di Old Data Item SN → BL (data lama)
      final oldSnResponse =
          await _api.getOldItemSn(search: sn, size: 10, page: 0);
      if (oldSnResponse['status'] == 200 && oldSnResponse['data'] is List) {
        final list = oldSnResponse['data'] as List;
        blItems.addAll(
          list.map((e) =>
              ItemSerialNumberResponse.fromJson(Map<String, dynamic>.from(e))),
        );
      }

      if (!mounted) return;

      final totalFound = blItems.length + jlItems.length;
      if (totalFound > 0) {
        setState(() {
          _snCheckResult = 'found';
          _snBlItems = blItems;
          _snJlItems = jlItems;
          _snCheckDetail =
              'Ditemukan $totalFound data: ${blItems.length} BL, ${jlItems.length} JL';
        });
      } else {
        setState(() {
          _snCheckResult = 'not_found';
          _snCheckDetail =
              'Serial Number "$sn" tidak ditemukan di data pembelian.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _snCheckResult = 'error';
        _snCheckDetail = 'Gagal mengecek SN: $e';
      });
    } finally {
      if (mounted) setState(() => _isCheckingSn = false);
    }
  }

  void _clearSnCheck() {
    setState(() {
      _snCtrl.clear();
      _snCheckResult = null;
      _snCheckDetail = null;
      _snBlItems = null;
      _snJlItems = null;
    });
  }

  /// Build card item for BL (kiri - biru) or JL (kanan - orange).
  Widget _buildSnItemCard(
    ItemSerialNumberResponse item,
    ThemeData theme, {
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doc ID - value only, copyable
          _snValueRow(
            icon: Icons.copy_rounded,
            iconColor: accentColor,
            value: item.docId,
            theme: theme,
          ),
          const SizedBox(height: 4),
          // User - value only, bold, copyable
          _snValueRow(
            icon: Icons.copy_rounded,
            iconColor: accentColor,
            value: item.user,
            theme: theme,
            boldValue: true,
          ),
          // Tanggal
          if (item.tanggal != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: accentColor.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  _formatDate(item.tanggal!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A row with icon + value (copyable on tap).
  Widget _snValueRow({
    required IconData icon,
    required Color iconColor,
    required String? value,
    required ThemeData theme,
    bool boldValue = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disalin: $value'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Row(
        children: [
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: iconColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  String get _snFoundItemName {
    if (_snBlItems != null && _snBlItems!.isNotEmpty) {
      return _snBlItems!.first.itemName ?? '';
    }
    if (_snJlItems != null && _snJlItems!.isNotEmpty) {
      return _snJlItems!.first.itemName ?? '';
    }
    return '';
  }

  Widget _buildSnCheckResult(ThemeData theme) {
    final isFound = _snCheckResult == 'found';
    final isError = _snCheckResult == 'error';
    final color = isFound
        ? Colors.green
        : isError
            ? Colors.red
            : Colors.orange;
    final icon = isFound
        ? Icons.check_circle_outline
        : isError
            ? Icons.error_outline
            : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFound
                          ? 'SN Ditemukan!'
                          : isError
                              ? 'Gagal Mengecek'
                              : 'SN Tidak Ditemukan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    if (isFound) ...[
                      const SizedBox(height: 4),
                      Text(
                        _snFoundItemName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_snCheckDetail != null) ...[
            const SizedBox(height: 4),
            Text(
              _snCheckDetail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
          // Layout kiri-kanan: BL | JL
          if (isFound) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kolom BL (kiri) - biru
                Expanded(
                  child: _buildSnColumn(
                    title: 'BL (Masuk)',
                    icon: Icons.arrow_downward_rounded,
                    accentColor: Colors.blue.shade700,
                    bgAccentColor: Colors.blue,
                    items: _snBlItems,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                // Kolom JL (kanan) - merah orange
                Expanded(
                  child: _buildSnColumn(
                    title: 'JL (Keluar)',
                    icon: Icons.arrow_upward_rounded,
                    accentColor: Colors.deepOrange.shade700,
                    bgAccentColor: Colors.deepOrange,
                    items: _snJlItems,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSnColumn({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Color bgAccentColor,
    required List<ItemSerialNumberResponse>? items,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header kolom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgAccentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items?.length ?? 0}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (items != null && items.isNotEmpty)
          ...items.take(3).map((item) =>
              _buildSnItemCard(item, theme, accentColor: bgAccentColor))
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tidak ada data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // --- Helper untuk Input Decoration Modern ---
  InputDecoration _modernInputDecoration(
      ThemeData theme, String label, IconData icon,
      {String? hint, String? helper, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
      suffixIcon: suffixIcon,
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
  void dispose() {
    _animController.dispose(); // Hapus controller animasi
    _snDebounce?.cancel();
    _jenisBarangCtrl.dispose();
    _merekCtrl.dispose();
    _modelSeriCtrl.dispose();
    _kelengkapanCtrl.dispose();
    _kerusakanCtrl.dispose();
    _dpCtrl.dispose();
    _estimasiBiayaCtrl.dispose();
    _snCtrl.dispose();
    _namaDistributorCtrl.dispose();
    _alamatDistributorCtrl.dispose();
    _resiPengirimanCtrl.dispose();
    _biayaKlaimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKlaim = _tipeNota == 'KLAIM';
    // Dapatkan lebar layar untuk responsive
    final screenWidth = MediaQuery.of(context).size.width;

    // Tentukan maxWidth dialog berdasarkan lebar layar
    double dialogMaxWidth;
    if (screenWidth > 900) {
      dialogMaxWidth = 720; // Desktop lebar
    } else if (screenWidth > 600) {
      dialogMaxWidth = 640; // Setengah layar / tablet
    } else {
      dialogMaxWidth = screenWidth - 32; // Mobile, hampir full width
    }

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
            constraints: BoxConstraints(
              maxWidth: dialogMaxWidth,
              maxHeight: screenWidth > 900 ? 900 : 800,
            ),
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
                // Header
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
                          color: isKlaim
                              ? Colors.deepOrange.withValues(alpha: 0.15)
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isKlaim
                              ? Icons.local_shipping_rounded
                              : Icons.receipt_long_rounded,
                          color: isKlaim
                              ? Colors.deepOrange
                              : theme.colorScheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKlaim
                                  ? 'Buat Nota Klaim Garansi'
                                  : 'Buat Nota Servis',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              isKlaim
                                  ? 'Isi data barang & distributor untuk klaim garansi'
                                  : 'Isi data barang yang akan diservis',
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

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- PELANGGAN SECTION ---
                          Text('Data Pelanggan',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_isLoadingPelanggan)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            Autocomplete<PelangganServis>(
                              displayStringForOption:
                                  (PelangganServis option) =>
                                      '${option.namaPelanggan} (${option.noTelepon ?? "-"})',
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _pelangganList;
                                }
                                return _pelangganList.where(
                                    (PelangganServis p) {
                                  final query =
                                      textEditingValue.text.toLowerCase();
                                  final nama =
                                      (p.namaPelanggan ?? "").toLowerCase();
                                  final telepon =
                                      (p.noTelepon ?? "").toLowerCase();
                                  return nama.contains(query) ||
                                      telepon.contains(query);
                                });
                              },
                              onSelected: (PelangganServis selection) {
                                setState(() {
                                  _selectedPelanggan = selection;
                                });
                                FocusScope.of(context).unfocus();
                              },
                              fieldViewBuilder: (context,
                                  textEditingController,
                                  focusNode,
                                  onFieldSubmitted) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: _modernInputDecoration(
                                    theme,
                                    'Ketik Nama atau WA Pelanggan...',
                                    Icons.search_rounded,
                                    suffixIcon: _selectedPelanggan != null
                                        ? IconButton(
                                            icon:
                                                const Icon(Icons.clear_rounded),
                                            onPressed: () {
                                              textEditingController.clear();
                                              setState(() {
                                                _selectedPelanggan = null;
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: (value) {
                                    if (_selectedPelanggan != null) {
                                      setState(() {
                                        _selectedPelanggan = null;
                                      });
                                    }
                                  },
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 6.0,
                                    borderRadius: BorderRadius.circular(12),
                                    clipBehavior: Clip.antiAlias,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                          maxHeight: 250, maxWidth: 400),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          final PelangganServis option =
                                              options.elementAt(index);
                                          return ListTile(
                                            title: Text(
                                                option.namaPelanggan ??
                                                    "Tanpa Nama",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle:
                                                Text(option.noTelepon ?? "-"),
                                            onTap: () {
                                              onSelected(option);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_selectedPelanggan != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Kategori: ${_selectedPelanggan!.kategori ?? "-"} | WA: ${_selectedPelanggan!.noTelepon}',
                                style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // --- DATA BARANG SECTION ---
                          Text('Data Barang',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          // --- SERIAL NUMBER CHECK (paling atas di section Data Barang) ---
                          Text('Cek Serial Number',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Cek apakah barang ini benar-benar dibeli di sini',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 3. LayoutBuilder untuk Responsivitas SN Field + Button
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Jika lebar > 500px, tampilkan sejajar (Desktop/Tablet)
                              if (constraints.maxWidth > 500) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _snCtrl,
                                        decoration: _modernInputDecoration(
                                          theme,
                                          'Serial Number',
                                          Icons.qr_code_rounded,
                                          hint: 'Masukkan SN barang...',
                                          suffixIcon:
                                              _snCtrl.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.clear_rounded,
                                                          size: 20),
                                                      onPressed: _clearSnCheck,
                                                    )
                                                  : null,
                                        ),
                                        onChanged: (_) {
                                          if (_snCheckResult != null) {
                                            setState(() {
                                              _snCheckResult = null;
                                              _snCheckDetail = null;
                                              _snBlItems = null;
                                              _snJlItems = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 56,
                                      child: FilledButton.tonal(
                                        onPressed: _isCheckingSn
                                            ? null
                                            : _checkSn,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isCheckingSn
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Text('Cek SN'),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Mobile: susun ke bawah
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _snCtrl,
                                      decoration: _modernInputDecoration(
                                        theme,
                                        'Serial Number',
                                        Icons.qr_code_rounded,
                                        hint: 'Masukkan SN barang...',
                                        suffixIcon:
                                            _snCtrl.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 20),
                                                    onPressed: _clearSnCheck,
                                                  )
                                                : null,
                                      ),
                                      onChanged: (_) {
                                        if (_snCheckResult != null) {
                                          setState(() {
                                            _snCheckResult = null;
                                            _snCheckDetail = null;
                                            _snBlItems = null;
                                            _snJlItems = null;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 48,
                                      child: FilledButton.tonal(
                                        onPressed: _isCheckingSn
                                            ? null
                                            : _checkSn,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isCheckingSn
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Text('Cek SN'),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          if (_snCheckResult != null) ...[
                            const SizedBox(height: 10),
                            _buildSnCheckResult(theme),
                          ],

                          const SizedBox(height: 20),

                          // --- Form fields barang lainnya (Responsive Layout) ---
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 500;
                              return Column(
                                children: [
                                  // Baris 1: Jenis + Merek
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _jenisBarangCtrl,
                                            decoration: _modernInputDecoration(
                                                theme,
                                                'Jenis (Misal: Laptop) *',
                                                Icons.devices_rounded),
                                            validator: (v) =>
                                                v!.isEmpty ? 'Wajib diisi' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _merekCtrl,
                                            decoration: _modernInputDecoration(
                                                theme,
                                                'Merek',
                                                Icons
                                                    .branding_watermark_rounded),
                                          ),
                                        ),
                                      ],
                                  ),
                                  if (!isWide) ...[
                                    TextFormField(
                                      controller: _jenisBarangCtrl,
                                      decoration: _modernInputDecoration(
                                          theme,
                                          'Jenis (Misal: Laptop) *',
                                          Icons.devices_rounded),
                                      validator: (v) =>
                                          v!.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _merekCtrl,
                                      decoration: _modernInputDecoration(
                                          theme,
                                          'Merek',
                                          Icons.branding_watermark_rounded),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  // Model/Seri
                                  TextFormField(
                                    controller: _modelSeriCtrl,
                                    decoration: _modernInputDecoration(
                                        theme,
                                        'Model / Seri *',
                                        Icons.memory_rounded),
                                  ),
                                  const SizedBox(height: 12),
                                  // Kerusakan
                                  TextFormField(
                                    controller: _kerusakanCtrl,
                                    decoration: _modernInputDecoration(
                                        theme,
                                        'Keluhan / Kerusakan *',
                                        Icons.warning_amber_rounded),
                                    maxLines: 2,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Wajib diisi' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  // Kelengkapan
                                  TextFormField(
                                    controller: _kelengkapanCtrl,
                                    decoration: _modernInputDecoration(
                                        theme,
                                        'Kelengkapan (Tas, Charger, dll)',
                                        Icons.backpack_rounded),
                                  ),
                                  const SizedBox(height: 12),
                                  // Baris 2: DP + Estimasi Biaya
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _dpCtrl,
                                            decoration: _modernInputDecoration(
                                                theme,
                                                'DP',
                                                Icons.savings_rounded),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _estimasiBiayaCtrl,
                                            decoration: _modernInputDecoration(
                                                theme,
                                                'Estimasi Biaya',
                                                Icons.payments_rounded),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                  ),
                                  if (!isWide) ...[
                                    TextFormField(
                                      controller: _dpCtrl,
                                      decoration: _modernInputDecoration(
                                          theme, 'DP', Icons.savings_rounded),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _estimasiBiayaCtrl,
                                      decoration: _modernInputDecoration(
                                          theme,
                                          'Estimasi Biaya',
                                          Icons.payments_rounded),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // --- TIPE NOTA SECTION ---
                          Text('Tipe Nota',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  title: const Text('Servis Normal'),
                                  subtitle: const Text(
                                      'Antre pengecekan seperti biasa'),
                                  value: 'SERVIS',
                                  groupValue: _tipeNota,
                                  activeColor: theme.colorScheme.primary,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() => _tipeNota = value!);
                                  },
                                ),
                                Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.4)),
                                RadioListTile<String>(
                                  title: const Text('Klaim Distributor'),
                                  subtitle: const Text(
                                      'Langsung menunggu pengiriman ke distributor'),
                                  value: 'KLAIM',
                                  groupValue: _tipeNota,
                                  activeColor: Colors.deepOrange,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() => _tipeNota = value!);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // --- KLAIM DISTRIBUTOR FIELDS (muncul jika tipe nota = KLAIM) ---
                          if (isKlaim) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.deepOrange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_shipping_rounded,
                                            color: Colors.deepOrange, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Data Klaim Distributor',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.deepOrange)),
                                      ],
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lengkapi data distributor untuk klaim garansi',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _namaDistributorCtrl,
                                    decoration: _modernInputDecoration(
                                      theme,
                                      'Nama Distributor *',
                                      Icons.business_rounded,
                                    ),
                                    validator: (v) {
                                      if (isKlaim &&
                                          (v == null || v.trim().isEmpty)) {
                                        return 'Wajib diisi untuk klaim';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _alamatDistributorCtrl,
                                    decoration: _modernInputDecoration(
                                      theme,
                                      'Alamat Distributor',
                                      Icons.location_on_rounded,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 12),
                                  // Responsive: Resi + Biaya Klaim
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth > 400) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _resiPengirimanCtrl,
                                                decoration:
                                                    _modernInputDecoration(
                                                  theme,
                                                  'Resi Pengiriman',
                                                  Icons.receipt_rounded,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _biayaKlaimCtrl,
                                                decoration:
                                                    _modernInputDecoration(
                                                  theme,
                                                  'Biaya Klaim',
                                                  Icons.money_rounded,
                                                ).copyWith(
                                                  prefixText: 'Rp ',
                                                ),
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                inputFormatters: [
                                                  ThousandSeparatorFormatter()
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            TextFormField(
                                              controller: _resiPengirimanCtrl,
                                              decoration:
                                                  _modernInputDecoration(
                                                theme,
                                                'Resi Pengiriman',
                                                Icons.receipt_rounded,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextFormField(
                                              controller: _biayaKlaimCtrl,
                                              decoration:
                                                  _modernInputDecoration(
                                                theme,
                                                'Biaya Klaim',
                                                Icons.money_rounded,
                                              ).copyWith(
                                                prefixText: 'Rp ',
                                              ),
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                      decimal: true),
                                              inputFormatters: [
                                                ThousandSeparatorFormatter()
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
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
                            : () => Navigator.pop(context),
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
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                            _isLoading ? 'Menyimpan...' : 'Simpan Transaksi'),
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
}