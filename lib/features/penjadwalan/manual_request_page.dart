import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/repositories/map_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'dart:async';
import 'package:dio/dio.dart';

class ManualRequestPage extends StatefulWidget {
  const ManualRequestPage({super.key});

  @override
  State<ManualRequestPage> createState() => _ManualRequestPageState();
}

class _ManualRequestPageState extends State<ManualRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _marketingController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _estimasiWaktuController = TextEditingController();
  final _kodeposController = TextEditingController();
  final _alamatController = TextEditingController();
  final _alamatMapsController = TextEditingController();
  final _catatanController = TextEditingController();

  bool _isUrgen = false;
  String _tipeTugas = 'KIRIM'; // KIRIM or AMBIL
  int? _selectedKodeposId;
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedMarketing;
  bool _isLoading = false;
  bool _isSearchingKodepos = false;
  List<Map<String, dynamic>> _kodeposResults = [];
  List<UserAccount> _marketingUsers = [];
  bool _isLoadingMarketing = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadMarketingUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _marketingController.dispose();
    _tanggalController.dispose();
    _estimasiWaktuController.dispose();
    _kodeposController.dispose();
    _alamatController.dispose();
    _alamatMapsController.dispose();
    _catatanController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMarketingUsers() async {
    try {
      final allUsers = await getIt<ApiNewEndpoints>().getAllUsers();
      setState(() {
        // Ambil semua user yang rolenya mengandung kata 'MARKETING'
        _marketingUsers = allUsers
            .where((u) => u.role.toUpperCase().contains('MARKETING'))
            .toList();
        _isLoadingMarketing = false;
      });
    } catch (_) {
      setState(() => _isLoadingMarketing = false);
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
        if (result != null) {
          // Tetapkan koordinat sesuai input user agar tidak "snap" ke tengah jalan/wilayah
          result['latitude'] = lat;
          result['longitude'] = lon;
          _onLocationSelected(result);
          ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mencari koordinat: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      _selectedCity = loc['city'];
      _selectedDistrict = loc['district'];
      _selectedKodeposId = null;
      _kodeposResults = [];
    });
  }

  Future<void> _pilihTanggal() async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _toggleUrgen(bool value) async {
    if (value) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Konfirmasi Urgen',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menandai request ini sebagai URGEN?\n\nStatus urgen akan memberikan indikator visual khusus pada tim operasional dan peta monitoring.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ya, Aktifkan'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _isUrgen = true);
      }
    } else {
      setState(() => _isUrgen = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final payload = {
        "userName": _nameController.text,
        "noHp": _phoneController.text,
        "marketingName": _marketingController.text,
        "tanggalJadwal": _tanggalController.text,
        "estimasiWaktu": _estimasiWaktuController.text,
        "idKodepos": _selectedKodeposId,
        "alamatLengkap": _alamatController.text,
        "alamatMaps": _alamatMapsController.text,
        "latitude": _selectedLat,
        "longitude": _selectedLon,
        "kabupatenKota": _selectedCity,
        "kecamatan": _selectedDistrict,
        "catatan": _catatanController.text,
        "tipeTugas": _tipeTugas == 'KIRIM' ? 'PENGIRIMAN' : 'PENGAMBILAN',
        "isUrgen": _isUrgen,
      };

      final dio = getIt<Dio>();
      await dio.post('/api/v1/penjadwalan/manual', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isUrgen
                    ? 'Request Urgen Berhasil Dibuat!'
                    : 'Request Berhasil Disimpan'),
              ],
            ),
            backgroundColor:
                _isUrgen ? Colors.red.shade700 : Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 1100;

    return DashboardShell(
      currentRoute: '/penjadwalan',
      userName: userStore.displayName,
      userRole: userStore.userRole,
      title: 'Request Pengantaran',
      onNavigate: (route) => context.go(route),
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) context.go('/login');
      },
      child: Column(
        children: [
          // --- ELITE HEADER ---
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16, vertical: 24),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: theme.colorScheme.onSurface, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shadowColor: Colors.black12,
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Pengantaran',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Penugasan langsung tanpa memo (Direct Request)',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // URGENT TOGGLE
                _buildUrgentToggle(),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 16, 8, isDesktop ? 32 : 16, 40),
              child: Form(
                key: _formKey,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _isUrgen
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: _isUrgen
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                      width: _isUrgen ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // --- SECTION 1: DATA PELANGGAN ---
                      _buildSection(
                        title: 'Data Pelanggan & Lokasi Dasar',
                        icon: Icons.person_outline_rounded,
                        children: [
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: _buildField('Nama User / Pelanggan',
                                        'Masukkan nama lengkap',
                                        controller: _nameController)),
                                const SizedBox(width: 24),
                                Expanded(
                                    flex: 1,
                                    child: _buildField(
                                        'Nomor HP (WhatsApp)', '08xx...',
                                        controller: _phoneController,
                                        isRequired: false,
                                        keyboardType: TextInputType.phone)),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: _buildField(
                                    'Pencarian Kode Pos / Wilayah',
                                    'Ketik minimal 3 karakter...',
                                    controller: _kodeposController,
                                    onChanged: _searchLocation,
                                    prefixIcon: Icons.location_on_outlined,
                                    suffixIcon: _isSearchingKodepos
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : (_kodeposController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                    Icons.clear_rounded,
                                                    size: 18),
                                                onPressed: () {
                                                  setState(() {
                                                    _kodeposController.clear();
                                                    _kodeposResults = [];
                                                    _selectedKodeposId = null;
                                                  });
                                                },
                                              )
                                            : const Icon(Icons.search,
                                                size: 20)),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildField('Nama User / Pelanggan',
                                    'Masukkan nama lengkap',
                                    controller: _nameController),
                                const SizedBox(height: 20),
                                _buildField('Nomor HP (WhatsApp)', '08xx...',
                                    controller: _phoneController,
                                    isRequired: false,
                                    keyboardType: TextInputType.phone),
                                const SizedBox(height: 20),
                                _buildField('Pencarian Kode Pos / Wilayah',
                                    'Ketik minimal 3 karakter...',
                                    controller: _kodeposController,
                                    onChanged: _searchLocation,
                                    prefixIcon: Icons.location_on_outlined,
                                    suffixIcon: _kodeposController
                                            .text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                                Icons.clear_rounded,
                                                size: 18),
                                            onPressed: () {
                                              setState(() {
                                                _kodeposController.clear();
                                                _kodeposResults = [];
                                                _selectedKodeposId = null;
                                              });
                                            },
                                          )
                                        : const Icon(Icons.search, size: 20)),
                              ],
                            ),
                          if (_kodeposResults.isNotEmpty)
                            _buildKodeposResults(),
                          const SizedBox(height: 20),
                          _buildField('Link Google Maps / Koordinat Lokasi',
                              'Contoh: -7.96, 112.63 atau link maps',
                              controller: _alamatMapsController,
                              isRequired: false,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.location_searching,
                                    color: Colors.blue),
                                onPressed: _searchByCoordinate,
                                tooltip: 'Cari Alamat dari Koordinat',
                              )),
                        ],
                      ),

                      const Divider(height: 1),

                      // --- SECTION 2: DETAIL REQUEST ---
                      _buildSection(
                        title: 'Detail Penugasan',
                        icon: Icons.event_note_rounded,
                        children: [
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildMarketingField()),
                                const SizedBox(width: 24),
                                Expanded(
                                    child: _buildField(
                                        'Tanggal Rencana', 'Pilih Tanggal',
                                        controller: _tanggalController,
                                        readOnly: true,
                                        onTap: _pilihTanggal)),
                                const SizedBox(width: 24),
                                Expanded(
                                    child: _buildField('Estimasi Waktu',
                                        'Contoh: Pagi / 10:00',
                                        controller: _estimasiWaktuController)),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildMarketingField(),
                                const SizedBox(height: 20),
                                _buildField('Tanggal Rencana', 'Pilih Tanggal',
                                    controller: _tanggalController,
                                    readOnly: true,
                                    onTap: _pilihTanggal),
                                const SizedBox(height: 20),
                                _buildField(
                                    'Estimasi Waktu', 'Contoh: Pagi / 10:00',
                                    controller: _estimasiWaktuController),
                              ],
                            ),
                        ],
                      ),

                      const Divider(height: 1),

                      // --- SECTION 3: KONFIGURASI LAYANAN ---
                      _buildSection(
                        title: 'Konfigurasi Layanan',
                        icon: Icons.settings_suggest_outlined,
                        children: [
                          if (isDesktop)
                            Row(
                              children: [
                                Expanded(
                                  child: _SelectionTile(
                                    label: 'Proses Kirim',
                                    subtitle: 'Barang perlu dikirim ke lokasi',
                                    icon: Icons.local_shipping_outlined,
                                    value: _tipeTugas == 'KIRIM',
                                    onChanged: (v) =>
                                        setState(() => _tipeTugas = 'KIRIM'),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _SelectionTile(
                                    label: 'Proses Ambil',
                                    subtitle: 'Pengambilan barang di lokasi',
                                    icon: Icons.inventory_2_outlined,
                                    value: _tipeTugas == 'AMBIL',
                                    onChanged: (v) =>
                                        setState(() => _tipeTugas = 'AMBIL'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _SelectionTile(
                                  label: 'Proses Kirim',
                                  subtitle: 'Barang perlu dikirim',
                                  icon: Icons.local_shipping_outlined,
                                  value: _tipeTugas == 'KIRIM',
                                  onChanged: (v) =>
                                      setState(() => _tipeTugas = 'KIRIM'),
                                ),
                                const SizedBox(height: 16),
                                _SelectionTile(
                                  label: 'Proses Ambil',
                                  subtitle: 'Barang diambil',
                                  icon: Icons.inventory_2_outlined,
                                  value: _tipeTugas == 'AMBIL',
                                  onChanged: (v) =>
                                      setState(() => _tipeTugas = 'AMBIL'),
                                ),
                              ],
                            ),
                        ],
                      ),

                      const Divider(height: 1),

                      // --- SECTION 4: ALAMAT LENGKAP ---
                      _buildSection(
                        title: 'Alamat Pengiriman Lengkap',
                        icon: Icons.location_on_outlined,
                        children: [
                          _buildField('Alamat Pengiriman Lengkap',
                              'Isi alamat detail...',
                              controller: _alamatController, maxLines: 2),
                          const SizedBox(height: 20),
                          _buildField('Catatan Khusus', 'Instruksi tambahan',
                              controller: _catatanController,
                              isRequired: false),
                        ],
                      ),

                      // --- SUBMIT BUTTON ---
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isUrgen
                                  ? Colors.red.shade700
                                  : theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: _isUrgen
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_isUrgen
                                          ? Icons.flash_on_rounded
                                          : Icons.check_circle_rounded),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isUrgen
                                            ? 'KIRIM REQUEST URGEN'
                                            : 'PROSES REQUEST SEKARANG',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentToggle() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isUrgen
            ? Colors.red.withValues(alpha: 0.05)
            : theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _isUrgen
                ? Colors.red.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isUrgen ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            color: _isUrgen ? Colors.red : theme.colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isUrgen ? 'URGEN' : 'NORMAL',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: _isUrgen ? Colors.red : theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 24,
            child: Switch(
              value: _isUrgen,
              onChanged: _toggleUrgen,
              activeThumbColor: Colors.red,
              activeTrackColor: Colors.red.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint, {
    TextEditingController? controller,
    bool isRequired = true,
    bool readOnly = false,
    VoidCallback? onTap,
    void Function(String)? onChanged,
    IconData? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge,
          validator: isRequired
              ? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: Colors.grey)
                : null,
            suffixIcon: suffixIcon ??
                (readOnly
                    ? const Icon(Icons.calendar_today_rounded,
                        size: 18, color: Colors.grey)
                    : null),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketingField() {
    final theme = Theme.of(context);
    return _isLoadingMarketing
        ? const SizedBox(
            height: 50, child: Center(child: CircularProgressIndicator()))
        : LayoutBuilder(
            builder: (context, constraints) => RawAutocomplete<UserAccount>(
              displayStringForOption: (u) => u.nama,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _marketingUsers;
                }
                return _marketingUsers.where((u) =>
                    u.nama
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()) ||
                    (u.employeeCode
                            ?.toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ??
                        false));
              },
              onSelected: (u) {
                _marketingController.text = u.nama;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                // Sync initial value
                if (_marketingController.text.isNotEmpty &&
                    controller.text.isEmpty) {
                  controller.text = _marketingController.text;
                }

                // Sync changes back to main controller
                controller.addListener(() {
                  if (_marketingController.text != controller.text) {
                    _marketingController.text = controller.text;
                  }
                });

                return _buildField(
                  'Marketing Request',
                  'Cari & Pilih marketing...',
                  controller: controller,
                  prefixIcon: Icons.person_search_rounded,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: constraints.maxWidth,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (BuildContext context, int index) {
                          final UserAccount option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      option.nama.isNotEmpty
                                          ? option.nama[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (option.employeeCode != null)
                                          Text(
                                            option.employeeCode!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildKodeposResults() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _kodeposResults.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (ctx, i) {
            final kp = _kodeposResults[i];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(kp['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(kp['fullAddress'] ?? ''),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.place_rounded,
                    color: Colors.blue.shade600, size: 20),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey.shade300),
              onTap: () => _onLocationSelected(kp),
            );
          },
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SelectionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
