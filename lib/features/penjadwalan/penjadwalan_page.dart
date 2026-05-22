import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/data/repositories/memo_repository.dart';
import 'package:stok_anandam/data/repositories/map_repository.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/features/memo/widgets/status_badge.dart'; // We'll need to move _StatusBadge to a separate file or keep it local.

// Enum untuk membedakan tipe halaman
enum TipeJadwal { kirim, teknisi }

class PenjadwalanPage extends StatefulWidget {
  final String memoId;
  final MemoDetail memo; // Data memo dari halaman sebelumnya
  final TipeJadwal tipe;

  const PenjadwalanPage({
    super.key,
    required this.memoId,
    required this.memo,
    required this.tipe,
  });

  @override
  State<PenjadwalanPage> createState() => _PenjadwalanPageState();
}

class _PenjadwalanPageState extends State<PenjadwalanPage> {
  // 1. Tambahkan Form Key untuk validasi form kosong
  final _formKey = GlobalKey<FormState>();

  final _tanggalController = TextEditingController();
  final _estimasiWaktuController = TextEditingController();
  final _alamatController = TextEditingController();
  final _alamatMapsController = TextEditingController();
  final _catatanController = TextEditingController();
  final _kodeposController = TextEditingController();
  int? _selectedKodeposId;
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedDesa;
  bool _isLoading = false;
  List<Map<String, dynamic>> _kodeposResults = [];
  bool _isSearchingKodepos = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    final typeStr = widget.tipe == TipeJadwal.kirim ? "PENGIRIMAN" : "TEKNISI";
    final existing = widget.memo.penjadwalanHistory
        .where((j) => j.tipeTugas == typeStr)
        .toList();

    if (existing.isNotEmpty) {
      final last = existing.last;
      _tanggalController.text = last.tanggalJadwal ?? '';
      _estimasiWaktuController.text = last.estimasiWaktu ?? '';
      _alamatController.text = last.alamatLengkap ?? '';
      _alamatMapsController.text = last.alamatMaps ?? '';
      _catatanController.text = last.catatan ?? '';

      // Construct a descriptive search string: "Kodepos - Desa, Kec"
      if (last.kodePos != null && last.kodePos!.isNotEmpty) {
        _kodeposController.text =
            "${last.kodePos} - ${last.desaKelurahan ?? ''}, ${last.kecamatan ?? ''}"
                .trim();
      } else if (last.desaKelurahan != null && last.desaKelurahan!.isNotEmpty) {
        _kodeposController.text =
            "${last.desaKelurahan}, ${last.kecamatan ?? ''}".trim();
      } else if (last.kecamatan != null || last.kabupatenKota != null) {
        _kodeposController.text =
            "${last.kecamatan ?? ''}, ${last.kabupatenKota ?? ''}".trim();
        if (_kodeposController.text.startsWith(',')) {
          _kodeposController.text = _kodeposController.text.substring(1).trim();
        }
      }

      _selectedKodeposId = last.idKodepos;
      _selectedLat = last.latitude;
      _selectedLon = last.longitude;
      _selectedCity = last.kabupatenKota;
      _selectedDistrict = last.kecamatan;
      _selectedDesa = last.desaKelurahan;
    } else {
      // Fallback: Default to memo's address if this is a first-time schedule
      if (widget.tipe == TipeJadwal.kirim) {
        if (widget.memo.desaKelurahan != null &&
            widget.memo.desaKelurahan!.isNotEmpty) {
          _alamatController.text =
              "${widget.memo.desaKelurahan}, ${widget.memo.kecamatan}, ${widget.memo.kabupatenKota}";

          // Construct a descriptive search string for first-time use too
          if (widget.memo.kodePos != null && widget.memo.kodePos!.isNotEmpty) {
            _kodeposController.text =
                "${widget.memo.kodePos} - ${widget.memo.desaKelurahan}, ${widget.memo.kecamatan ?? ''}"
                    .trim();
          } else {
            _kodeposController.text =
                "${widget.memo.desaKelurahan}, ${widget.memo.kecamatan ?? ''}"
                    .trim();
          }

          // Also populate the state variables from the memo data
          _selectedCity = widget.memo.kabupatenKota;
          _selectedDistrict = widget.memo.kecamatan;
          _selectedDesa = widget.memo.desaKelurahan;
          // Note: Memo model doesn't have Lat/Lon yet, so we leave them null
        }
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 3) {
        setState(() => _kodeposResults = []);
        return;
      }
      setState(() => _isSearchingKodepos = true);
      try {
        final results =
            await getIt<MapRepository>().searchLocationPhoton(query);
        setState(() => _kodeposResults = results);
      } catch (_) {
        setState(() => _kodeposResults = []);
      } finally {
        setState(() => _isSearchingKodepos = false);
      }
    });
  }

  Future<void> _searchByCoordinate() async {
    final input = _alamatMapsController.text.trim();
    if (input.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      double? lat;
      double? lon;

      // 1. Cek format "lat, lon"
      final coordRegExp =
          RegExp(r'([-+]?\d{1,2}(?:\.\d+)?),\s*([-+]?\d{1,3}(?:\.\d+)?)');
      final match = coordRegExp.firstMatch(input);
      if (match != null) {
        lat = double.tryParse(match.group(1)!);
        lon = double.tryParse(match.group(2)!);
      }
      // 2. Cek format URL Google Maps (q=lat,lon)
      else if (input.contains('google.com/maps')) {
        final urlMatch =
            RegExp(r'q=([-+]?\d{1,2}(?:\.\d+)?),([-+]?\d{1,3}(?:\.\d+)?)')
                .firstMatch(input);
        if (urlMatch != null) {
          lat = double.tryParse(urlMatch.group(1)!);
          lon = double.tryParse(urlMatch.group(2)!);
        } else {
          // Cek format /@lat,lon,zoom
          final atMatch =
              RegExp(r'@([-+]?\d{1,2}(?:\.\d+)?),([-+]?\d{1,3}(?:\.\d+)?)')
                  .firstMatch(input);
          if (atMatch != null) {
            lat = double.tryParse(atMatch.group(1)!);
            lon = double.tryParse(atMatch.group(2)!);
          }
        }
      }

      if (lat != null && lon != null) {
        final result =
            await getIt<MapRepository>().reverseGeocodePhoton(lat, lon);
        if (!mounted) return;
        if (result != null) {
          // Tetapkan koordinat sesuai input user agar tidak "snap" ke tengah jalan/wilayah
          result['latitude'] = lat;
          result['longitude'] = lon;
          _onLocationSelected(result);
          messenger.showSnackBar(
            const SnackBar(
                content: Text('Lokasi ditemukan!'),
                backgroundColor: Colors.green),
          );
        } else {
          throw Exception('Lokasi tidak ditemukan untuk koordinat tersebut');
        }
      } else {
        throw Exception(
            'Format koordinat tidak valid. Gunakan format: lat, lon');
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text('Gagal mencari koordinat: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onLocationSelected(Map<String, dynamic> loc) {
    setState(() {
      final pc = loc['postalCode']?.toString() ?? '';
      final city = loc['city']?.toString() ?? '';
      final dist = loc['district']?.toString() ?? '';

      _alamatController.text = loc['fullAddress'] ?? '';

      if (pc.isNotEmpty && pc != '-') {
        _kodeposController.text =
            "$pc - ${dist.isNotEmpty ? dist : city}".trim();
      } else {
        _kodeposController.text = loc['name'] ?? loc['fullAddress'] ?? '';
      }

      if (loc['latitude'] != null && loc['longitude'] != null) {
        _alamatMapsController.text =
            "https://www.google.com/maps?q=${loc['latitude']},${loc['longitude']}";
        _selectedLat = loc['latitude'];
        _selectedLon = loc['longitude'];
      }
      _selectedCity = city;
      _selectedDistrict = dist;
      _selectedDesa =
          loc['village']?.toString() ?? loc['desa']?.toString() ?? '';

      _selectedKodeposId = null;
      _kodeposResults = [];
    });
  }

  // (Pastikan Anda sudah meng-import 'package:dio/dio.dart'; di atas)
  // final _dio = getIt<Dio>(); // Jika pakai GetIt, gunakan ini. Jika tidak, pakai:

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF5A85FA)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _submitJadwal() async {
    // 2. Cek apakah ada field wajib yang belum diisi
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap lengkapi semua field yang wajib diisi!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      // 3. Susun Payload persis seperti yang Spring Boot minta
      final Map<String, dynamic> payload = {
        "tipeTugas": widget.tipe == TipeJadwal.kirim ? "PENGIRIMAN" : "TEKNISI",
        "tanggalJadwal": _tanggalController.text, // format: 15-03-2026
        "estimasiWaktu": _estimasiWaktuController.text,
        "catatan":
            _catatanController.text.isNotEmpty ? _catatanController.text : null,
      };

      if (widget.tipe == TipeJadwal.kirim) {
        payload["idKodepos"] =
            _selectedKodeposId ?? int.tryParse(_kodeposController.text);
        payload["alamatLengkap"] = _alamatController.text;
        payload["alamatMaps"] = _alamatMapsController.text;
        payload["latitude"] = _selectedLat;
        payload["longitude"] = _selectedLon;
        payload["kabupatenKota"] = _selectedCity;
        payload["kecamatan"] = _selectedDistrict;
        payload["desaKelurahan"] = _selectedDesa;
      }

      // 4. Eksekusi request menggunakan MemoRepository
      final memoRepo = getIt<MemoRepository>();
      await memoRepo.createPenjadwalan(widget.memoId, payload);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
            content: Text('Jadwal Berhasil Dibuat!'),
            backgroundColor: Colors.green),
      );
      // Optional: context.read<MemoBloc>().add(LoadMemoDetail(widget.memoId)); // Refresh data detail
      context.pop(true); // Kembali ke halaman detail dengan suksess
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Terjadi kesalahan sistem';
      if (e is DioException && e.response?.data != null) {
        errorMsg = e.response?.data['message'] ??
            e.response?.statusMessage ??
            errorMsg;
      } else {
        errorMsg = e.toString();
      }
      messenger.showSnackBar(
        SnackBar(
            content: Text('Gagal: $errorMsg'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    final role = userStore.userRole;
    final isWarehouse = role == 'GUDANG' || role == 'SPV_GUDANG';
    final isKirim = widget.tipe == TipeJadwal.kirim;
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return DashboardShell(
      currentRoute: AppRoutes.memo,
      onScan: () => context.pushNamed(AppRoutes.scanner),
      userName: userStore.displayName,
      userRole: userStore.userRole,
      title: isKirim ? 'Penjadwalan Kirim' : 'Penjadwalan Teknisi',
      onNavigate: (route) => context.go(route),
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
      child: ListView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        children: [
          // --- HEADER & BACK BUTTON ---
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKirim
                          ? 'Penjadwalan Pengiriman'
                          : 'Penjadwalan Teknisi',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Memo ID: #${widget.memo.id}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- INFO CUSTOMER CARD ---
          _buildInfoPelanggan(theme, isDesktop),
          const SizedBox(height: 24),

          // --- MAIN FORM SECTION ---
          LayoutBuilder(
            builder: (context, constraints) {
              return isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 2,
                            child: _buildFormCard(theme, isKirim, isWarehouse)),
                        const SizedBox(width: 24),
                        Expanded(
                            flex: 1, child: _buildSummaryCard(theme, isKirim)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormCard(theme, isKirim, isWarehouse),
                        const SizedBox(height: 24),
                        _buildSummaryCard(theme, isKirim),
                      ],
                    );
            },
          ),

          const SizedBox(height: 40),

          // --- SUBMIT BUTTON ---
          Center(
            child: SizedBox(
              width: isDesktop ? 300 : double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitJadwal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isKirim
                            ? 'Konfirmasi Penjadwalan Kirim'
                            : 'Konfirmasi Penjadwalan Teknisi',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInfoPelanggan(ThemeData theme, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 16,
        children: [
          _buildInfoItem(theme, Icons.person_outline, 'Pelanggan',
              widget.memo.customerName ?? '-'),
          _buildInfoItem(
              theme,
              Icons.calendar_today_outlined,
              'Tanggal Memo',
              widget.memo.tanggalMemo != null
                  ? "${widget.memo.tanggalMemo!.day.toString().padLeft(2, '0')}-${widget.memo.tanggalMemo!.month.toString().padLeft(2, '0')}-${widget.memo.tanggalMemo!.year}"
                  : '-'),
          _buildInfoItem(theme, Icons.assignment_outlined, 'Tipe Memo',
              widget.memo.memoType ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(ThemeData theme, bool isKirim, bool isWarehouse) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Penjadwalan',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildEnterpriseTextField(
                    label: 'Tanggal Rencana',
                    hint: 'Pilih Tanggal',
                    controller: _tanggalController,
                    readOnly: true,
                    prefixIcon: Icons.calendar_month_outlined,
                    onTap: _pilihTanggal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEnterpriseTextField(
                    label: 'Estimasi Waktu',
                    hint: 'Contoh: Siang / 14:00',
                    controller: _estimasiWaktuController,
                    prefixIcon: Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isKirim) ...[
              _buildEnterpriseTextField(
                label: 'Pencarian Kode Pos / Wilayah',
                hint: isWarehouse
                    ? 'Wilayah ditentukan oleh Marketing'
                    : 'Ketik minimal 3 karakter...',
                controller: _kodeposController,
                prefixIcon: Icons.location_on_outlined,
                onChanged: isWarehouse ? null : _searchLocation,
                readOnly: isWarehouse,
                isRequired: !isWarehouse,
                suffixIconWidget: isWarehouse
                    ? null
                    : (_isSearchingKodepos
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search, size: 20)),
              ),
              if (_kodeposResults.isNotEmpty && !isWarehouse)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8)
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _kodeposResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final kp = _kodeposResults[index];
                      return ListTile(
                        title: Text(kp['name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(kp['fullAddress'] ?? ''),
                        leading: const Icon(Icons.place_outlined),
                        onTap: () => _onLocationSelected(kp),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              _buildEnterpriseTextField(
                label: 'Koordinat Lokasi',
                hint:
                    isWarehouse ? '-' : 'Contoh: -7.96, 112.63 atau link maps',
                controller: _alamatMapsController,
                isRequired: false,
                readOnly: isWarehouse,
                suffixIconWidget: isWarehouse
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.location_searching,
                            color: Colors.blue),
                        onPressed: _searchByCoordinate,
                        tooltip: 'Cari Alamat dari Koordinat',
                      ),
              ),
              const SizedBox(height: 20),
              _buildEnterpriseTextField(
                label: 'Alamat Pengiriman Lengkap',
                hint: 'Isi alamat detail...',
                controller: _alamatController,
                maxLines: 2,
                readOnly: isWarehouse,
                isRequired: !isWarehouse,
              ),
              const SizedBox(height: 20),
            ],
            _buildEnterpriseTextField(
              label: 'Catatan Khusus Penjadwalan',
              hint: 'Tambahkan instruksi jika ada',
              controller: _catatanController,
              maxLines: 3,
              isRequired: false,
              readOnly: isWarehouse,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isKirim) {
    return Column(
      children: [
        // ITEMS LIST
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daftar Item',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...widget.memo.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                              child: Text('${item.qty}x',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.namaBarang ?? '-',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(_formatRupiah(item.hargaSatuan),
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Nilai',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatRupiah(widget.memo.totalHarga),
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                ],
              ),
            ],
          ),
        ),

        if (widget.memo.deskripsi != null &&
            widget.memo.deskripsi!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Deskripsi Memo',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.memo.deskripsi!,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnterpriseTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    IconData? prefixIcon,
    IconData? suffixIcon,
    Widget? suffixIconWidget,
    int maxLines = 1,
    VoidCallback? onTap,
    void Function(String)? onChanged,
    bool isRequired = true,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          maxLines: maxLines,
          onTap: onTap,
          onChanged: onChanged,
          validator: isRequired
              ? (value) => (value == null || value.isEmpty)
                  ? 'Field ini wajib diisi'
                  : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIconWidget ??
                (suffixIcon != null ? Icon(suffixIcon, size: 20) : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  String _formatRupiah(num v) =>
      "Rp. ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
}
