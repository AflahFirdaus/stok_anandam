import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/repositories/map_repository.dart';
import 'package:stok_anandam/injection.dart';
import 'dart:async';

class CreateRequestDeliveryPage extends StatefulWidget {
  const CreateRequestDeliveryPage({super.key});

  @override
  State<CreateRequestDeliveryPage> createState() => _CreateRequestDeliveryPageState();
}

class _CreateRequestDeliveryPageState extends State<CreateRequestDeliveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _kodeposController = TextEditingController();
  final _alamatController = TextEditingController();
  final _alamatMapsController = TextEditingController();
  final _catatanController = TextEditingController();

  bool _isUrgen = false;
  bool _isLoading = false;
  bool _isSearchingKodepos = false;
  List<Map<String, dynamic>> _kodeposResults = [];
  double? _selectedLat;
  double? _selectedLon;
  Timer? _debounce;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _kodeposController.dispose();
    _alamatController.dispose();
    _alamatMapsController.dispose();
    _catatanController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchKodepos(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 3) {
        setState(() => _kodeposResults = []);
        return;
      }
      setState(() => _isSearchingKodepos = true);
      try {
        final results = await getIt<MapRepository>().searchLocationPhoton(query);
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

      final coordRegExp = RegExp(r'([-+]?\d{1,2}(?:\.\d+)?),\s*([-+]?\d{1,3}(?:\.\d+)?)');
      final match = coordRegExp.firstMatch(input);
      if (match != null) {
        lat = double.tryParse(match.group(1)!);
        lon = double.tryParse(match.group(2)!);
      } else if (input.contains('google.com/maps')) {
        final urlMatch = RegExp(r'q=([-+]?\d{1,2}(?:\.\d+)?),([-+]?\d{1,3}(?:\.\d+)?)').firstMatch(input);
        if (urlMatch != null) {
          lat = double.tryParse(urlMatch.group(1)!);
          lon = double.tryParse(urlMatch.group(2)!);
        } else {
          final atMatch = RegExp(r'@([-+]?\d{1,2}(?:\.\d+)?),([-+]?\d{1,3}(?:\.\d+)?)').firstMatch(input);
          if (atMatch != null) {
            lat = double.tryParse(atMatch.group(1)!);
            lon = double.tryParse(atMatch.group(2)!);
          }
        }
      }

      if (lat != null && lon != null) {
        final result = await getIt<MapRepository>().reverseGeocodePhoton(lat, lon);
        if (result != null) {
          // Tetapkan koordinat sesuai input user agar tidak "snap" ke tengah jalan/wilayah
          result['latitude'] = lat;
          result['longitude'] = lon;
          _onKodeposSelected(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lokasi ditemukan!'), backgroundColor: Colors.green),
          );
        } else {
          throw Exception('Lokasi tidak ditemukan');
        }
      } else {
        throw Exception('Format koordinat tidak valid');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onKodeposSelected(Map<String, dynamic> kp) {
    setState(() {
      final pc = kp['postalCode']?.toString() ?? '';
      final city = kp['city']?.toString() ?? '';
      final dist = kp['district']?.toString() ?? '';

      _alamatController.text = kp['fullAddress'] ?? '';
      
      if (pc.isNotEmpty && pc != '-') {
        _kodeposController.text = "$pc - ${dist.isNotEmpty ? dist : city}".trim();
      } else {
        _kodeposController.text = kp['name'] ?? kp['fullAddress'] ?? '';
      }

      if (kp['latitude'] != null && kp['longitude'] != null) {
        _alamatMapsController.text =
            "https://www.google.com/maps?q=${kp['latitude']},${kp['longitude']}";
        _selectedLat = kp['latitude'];
        _selectedLon = kp['longitude'];
      }
      _kodeposResults = [];
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final payload = {
        "nomorRequest": "REQ-${DateTime.now().millisecondsSinceEpoch}",
        "receiverName": _nameController.text,
        "receiverPhone": _phoneController.text,
        "alamatLengkap": _alamatController.text,
        "alamatMaps": _alamatMapsController.text,
        "kodePos": _kodeposController.text,
        "latitude": _selectedLat,
        "longitude": _selectedLon,
        "keterangan": _catatanController.text,
        "isUrgen": _isUrgen,
      };

      await getIt<ApiNewEndpoints>().createRequestDelivery(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isUrgen
                ? 'Request Urgen Berhasil Dibuat!'
                : 'Request Berhasil Disimpan'),
            backgroundColor: _isUrgen ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
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
      currentRoute: '/request-delivery',
      userName: userStore.displayName,
      userRole: userStore.userRole,
      title: 'Tambah Request Delivery',
      onNavigate: (route) => context.go(route),
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) context.go('/login');
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Tambah Request Baru',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormCard(theme, isDesktop),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isUrgen ? Colors.red : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SIMPAN REQUEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Informasi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Row(
                children: [
                  const Text('Urgen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isUrgen,
                    onChanged: (v) => setState(() => _isUrgen = v),
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          _buildField('Nama Penerima', 'Masukkan nama lengkap', controller: _nameController),
          const SizedBox(height: 16),
          _buildField('Nomor HP', '08xx...', controller: _phoneController, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildField('Pencarian Kode Pos / Wilayah', 'Ketik minimal 3 karakter...', 
            controller: _kodeposController, 
            onChanged: _searchKodepos,
            prefixIcon: Icons.location_on_outlined,
            suffixIcon: _isSearchingKodepos
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search, size: 20)),
          if (_kodeposResults.isNotEmpty) _buildKodeposResults(),
          const SizedBox(height: 16),
          _buildField('Alamat Pengiriman Lengkap', 'Isi alamat detail...', controller: _alamatController, maxLines: 3),
          const SizedBox(height: 16),
          _buildField('Link Google Maps / Koordinat Lokasi', 'Contoh: -7.96, 112.63 atau link maps', 
            controller: _alamatMapsController, 
            isRequired: false,
            suffixIcon: IconButton(
              icon: const Icon(Icons.location_searching, color: Colors.blue),
              onPressed: _searchByCoordinate,
              tooltip: 'Cari Alamat dari Koordinat',
            )),
          const SizedBox(height: 16),
          _buildField('Catatan Tambahan', 'Instruksi khusus...', controller: _catatanController, isRequired: false),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint,
      {TextEditingController? controller,
      bool isRequired = true,
      int maxLines = 1,
      TextInputType? keyboardType,
      IconData? prefixIcon,
      Widget? suffixIcon,
      void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: isRequired ? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildKodeposResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _kodeposResults.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final kp = _kodeposResults[i];
          return ListTile(
            title: Text(kp['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(kp['fullAddress'] ?? ''),
            leading: const Icon(Icons.place_outlined),
            onTap: () => _onKodeposSelected(kp),
          );
        },
      ),
    );
  }
}
