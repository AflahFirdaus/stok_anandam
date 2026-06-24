import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/item_categories.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/network/tkdn_categories.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';
import '../layout/dashboard_shell.dart';
import '../shared/modern_filter.dart';
import 'package:stok_anandam/features/presence/mixins/presence_action_mixin.dart';

// ─────────────────────────── Model ───────────────────────────

class _SimulasiResult {
  final double spj;
  final double dpp;
  final double ppn;
  final double pph;
  final double bersih;
  final double pphRate;

  const _SimulasiResult({
    required this.spj,
    required this.dpp,
    required this.ppn,
    required this.pph,
    required this.bersih,
    required this.pphRate,
  });
}

enum _ItemSource { stok, tkdn }

class _SimItem {
  final String nama;
  final String? spesifikasi;
  final String? kategori;
  final double? modal;
  final _ItemSource source;

  const _SimItem({
    required this.nama,
    this.spesifikasi,
    this.kategori,
    this.modal,
    required this.source,
  });
}

// ─────────────────────────── Page ───────────────────────────

class SimulasiPage extends StatelessWidget {
  const SimulasiPage({super.key});

  @override
  Widget build(BuildContext context) => const _SimulasiContent();
}

class _SimulasiContent extends StatefulWidget {
  const _SimulasiContent();

  @override
  State<_SimulasiContent> createState() => _SimulasiContentState();
}

class _SimulasiContentState extends State<_SimulasiContent> with PresenceActionMixin {
  // ── Form state ──
  final _spjController = TextEditingController();
  final _spjFocus = FocusNode();
  bool _adaPpn = true;
  double _pphRate = 0.5;

  // ── Result ──
  _SimulasiResult? _result;

  // ── Kategori multi-select ──
  List<String> _selectedCategories = [];

  // ── Items list ──
  bool _loadingItems = false;
  List<_SimItem> _items = [];
  String? _itemsError;

  // ── Stok kategori (spesifik subkategori sesuai request)
  static const List<String> _stokCategories = [
    '2ND',
    'ACS',
    'ADP',
    'AL',
    'ATK',
    'BAT',
    'BRKT',
    'CARTD',
    'CCTV',
    'CLR',
    'CS',
    'DRW',
    'FAN',
    'FP',
    'GMC',
    'HDEX2',
    'HDIN2',
    'HDIN3',
    'HEL',
    'HPTB',
    'KAS',
    'KB',
    'KBL',
    'KBM',
    'LCD',
    'MB',
    'MC',
    'MDM',
    'MJ',
    'MM',
    'MS',
    'NB',
    'NWK',
    'PCAIO',
    'PCBU',
    'PCMN',
    'PCSVR',
    'PJT',
    'PP',
    'PRINT',
    'PROC',
    'PSU',
    'RAM',
    'RCK',
    'SCAN',
    'SCR',
    'SOFT',
    'SP',
    'SSD',
    'SSDEX',
    'STAB',
    'TINTA',
    'TP',
    'TPOD',
    'UFD',
    'UPS',
    'VGA'
  ];

  // ── TKDN kategori
  static const List<String> _tkdnCategories = TkdnCategories.all;

  // ── Combined Kategori Helper & Lists ──
  static String _getCategoryDisplayName(String compoundCode) {
    final parts = compoundCode.split(':');
    if (parts.length != 2) return compoundCode;
    final source = parts[0];
    final code = parts[1];

    if (source == 'stok') {
      final name = ItemCategories.getDisplayName(code);
      return '[STOK] $name';
    } else {
      final name = TkdnCategories.getDisplayName(code);
      return '[TKDN] $name';
    }
  }

  static final List<String> _combinedCategories = (() {
    final list = <String>[];
    for (final c in _stokCategories) {
      list.add('stok:$c');
    }
    for (final c in _tkdnCategories) {
      list.add('tkdn:$c');
    }
    list.sort((a, b) {
      final nameA = _getCategoryDisplayName(a).toLowerCase();
      final nameB = _getCategoryDisplayName(b).toLowerCase();
      return nameA.compareTo(nameB);
    });
    return list;
  })();

  @override
  void dispose() {
    _spjController.dispose();
    _spjFocus.dispose();
    super.dispose();
  }

  // ─── Format & Parse Helpers ───

  static String _addThousandSep(String s) {
    final rev = s.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < rev.length; i += 3) {
      chunks.add(rev.substring(i, (i + 3 < rev.length) ? i + 3 : rev.length));
    }
    return chunks.join('.').split('').reversed.join();
  }

  static String _rp(double v) {
    return _addThousandSep(v.round().toString());
  }

  static double _parseRaw(String s) {
    final clean = s.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(clean) ?? 0;
  }

  // ─── Kalkulasi ───

  void _hitung() {
    final spj = _parseRaw(_spjController.text);
    if (spj <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah SPJ yang valid'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    double dpp, ppn, pph, bersih;
    if (_adaPpn) {
      dpp = spj / 1.11;
      ppn = dpp * 0.11;
      pph = dpp * (_pphRate / 100);
      bersih = spj - ppn - pph;
    } else {
      dpp = spj;
      ppn = 0;
      pph = 0;
      bersih = spj;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _result = _SimulasiResult(
        spj: spj,
        dpp: dpp,
        ppn: ppn,
        pph: pph,
        bersih: bersih,
        pphRate: _pphRate,
      );
      _items = [];
      _itemsError = null;
      _selectedCategories = [];
    });
  }

  // ─── Load Items ───

  Future<void> _loadItems() async {
    if (_result == null) return;
    if (_selectedCategories.isEmpty) {
      setState(() => _items = []);
      return;
    }
    setState(() {
      _loadingItems = true;
      _itemsError = null;
    });

    final bersih = _result!.bersih;
    final allItems = <_SimItem>[];

    final selectedStok = _selectedCategories
        .where((c) => c.startsWith('stok:'))
        .map((c) => c.substring(5))
        .toList();
    final selectedTkdn = _selectedCategories
        .where((c) => c.startsWith('tkdn:'))
        .map((c) => c.substring(5))
        .toList();

    try {
      final dio = getIt<MyApiClient>().dio;

      // ── Fetch STOK ──
      if (selectedStok.isNotEmpty) {
        try {
          final resp = await dio.get<Map<String, dynamic>>(
            '/api/v1/stock',
            queryParameters: <String, dynamic>{
              'page': 0,
              'size': 200,
              'sortBy': 'modal',
              'direction': 'asc',
              'categories': selectedStok,
            },
          );
          final data = resp.data;
          if (data != null && isResponseSuccess(data['status'])) {
            final payload = data['data'];
            List<dynamic> raw = [];
            if (payload is List) {
              raw = payload;
            } else if (payload is Map && payload['content'] is List) {
              raw = payload['content'] as List;
            }
            for (final e in raw) {
              if (e is! Map) continue;
              final map = Map<String, dynamic>.from(e);
              final modalVal = map['modal'] ??
                  map['final_pricelist'] ??
                  map['finalPricelist'];
              final modalNum = double.tryParse(
                      modalVal?.toString().replaceAll(RegExp(r'[^\d.]'), '') ??
                          '') ??
                  0;
              if (modalNum <= 0 || modalNum > bersih) continue;
              allItems.add(_SimItem(
                nama: map['itemName']?.toString() ??
                    map['itemCode']?.toString() ??
                    '—',
                spesifikasi:
                    map['spesifikasi']?.toString().trim().isNotEmpty == true
                        ? map['spesifikasi'].toString().trim()
                        : null,
                kategori:
                    map['category']?.toString() ?? map['kategori']?.toString(),
                modal: modalNum,
                source: _ItemSource.stok,
              ));
            }
          }
        } catch (_) {}
      }

      // ── Fetch TKDN ──
      if (selectedTkdn.isNotEmpty) {
        try {
          final resp = await dio.get<Map<String, dynamic>>(
            '/api/v1/tkdn',
            queryParameters: <String, dynamic>{
              'page': 0,
              'size': 200,
              'sortBy': 'kategori',
              'direction': 'asc',
              'isTkdn': true,
              'categories': selectedTkdn,
            },
          );
          final data = resp.data;
          if (data != null && isResponseSuccess(data['status'])) {
            final payload = data['data'];
            List<dynamic> raw = [];
            if (payload is List) {
              raw = payload;
            } else if (payload is Map && payload['content'] is List) {
              raw = payload['content'] as List;
            }
            for (final e in raw) {
              if (e is! Map) continue;
              final map = Map<String, dynamic>.from(e);
              final modalVal = map['modal'];
              final modalNum = double.tryParse(
                      modalVal?.toString().replaceAll(RegExp(r'[^\d.]'), '') ??
                          '') ??
                  0;
              if (modalNum <= 0 || modalNum > bersih) continue;
              allItems.add(_SimItem(
                nama: map['nama']?.toString() ??
                    map['itemName']?.toString() ??
                    '—',
                spesifikasi:
                    map['spesifikasi']?.toString().trim().isNotEmpty == true
                        ? map['spesifikasi'].toString().trim()
                        : null,
                kategori:
                    map['kategori']?.toString() ?? map['category']?.toString(),
                modal: modalNum,
                source: _ItemSource.tkdn,
              ));
            }
          }
        } catch (_) {}
      }

      // Sort by modal asc
      allItems.sort((a, b) => (a.modal ?? 0).compareTo(b.modal ?? 0));

      if (mounted) {
        setState(() {
          _items = allItems;
          _loadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _itemsError = 'Gagal memuat data: $e';
          _loadingItems = false;
        });
      }
    }
  }

  // ─── SPJ Input Formatter ───

  void _onSpjChanged(String raw) {
    final digits = raw.replaceAll('.', '');
    if (digits.isEmpty) return;
    final formatted = _addThousandSep(digits);
    _spjController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    return DashboardShell(
      currentRoute: AppRoutes.simulasi,
      userName: userStore.displayName,
      userRole: userStore.userRole,
      title: 'Simulasi SPJ',
      onNavigate: (route) {
        if (route != AppRoutes.simulasi) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        userStore.clear();
        context.go(AppRoutes.login);
      },
      onScan: () => context.pushNamed(AppRoutes.scanner),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final pad = isMobile ? AppSpacing.lg : AppSpacing.xl;

    return Container(
      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            _buildCalculatorCard(theme),
            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(theme),
              const SizedBox(height: 20),
              _buildCategorySelector(theme),
              if (_selectedCategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildItemList(theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.calculate_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulasi Penghitungan SPJ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hitung Pendapatan bersih dari SPJ & temukan barang yang sesuai',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Calculator Card ───

  Widget _buildCalculatorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── SPJ Input ──
          Text(
            'Jumlah SPJ',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _spjController,
            focusNode: _spjFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onSpjChanged,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade300,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(
                  color: Color(0xFF1A237E),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),

          const SizedBox(height: 20),

          // ── PPN Toggle ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBD0FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: Color(0xFF3949AB),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PPN (11%)?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _buildPpnToggle(),
                  ],
                ),

                // ── PPH Choice ──
                if (_adaPpn) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'PPH (% dari DPP)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPphChip(0.5, '0,5%'),
                      const SizedBox(width: 10),
                      _buildPphChip(1.5, '1,5%'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Hitung Button ──
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _hitung,
              icon: const Icon(Icons.calculate_rounded, size: 20),
              label: const Text(
                'Hitung',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPpnToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _adaPpn = false;
            _result = null;
            _items = [];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: !_adaPpn ? Colors.red.shade600 : Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              border: Border.all(
                color: !_adaPpn ? Colors.red.shade600 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              'Tidak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: !_adaPpn ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _adaPpn = true;
            _result = null;
            _items = [];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _adaPpn ? const Color(0xFF1A237E) : Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(20)),
              border: Border.all(
                color: _adaPpn ? const Color(0xFF1A237E) : Colors.grey.shade300,
              ),
            ),
            child: Text(
              'Ya',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _adaPpn ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPphChip(double rate, String label) {
    final selected = _pphRate == rate;
    return GestureDetector(
      onTap: () => setState(() {
        _pphRate = rate;
        _result = null;
        _items = [];
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? const Color(0xFF1A237E) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // ─── Result Card ───

  Widget _buildResultCard(ThemeData theme) {
    final r = _result!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hasil Simulasi',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final text = 'SPJ: Rp ${_rp(r.spj)}\n'
                      'DPP: Rp ${_rp(r.dpp)}\n'
                      '${_adaPpn ? "PPN (11%): Rp ${_rp(r.ppn)}\nPPH (${r.pphRate}%): Rp ${_rp(r.pph)}\n" : ""}'
                      'Uang Diterima: Rp ${_rp(r.bersih)}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hasil disalin ke clipboard'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 14, color: Colors.black54),
                      SizedBox(width: 4),
                      Text('Salin',
                          style:
                              TextStyle(color: Colors.black87, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Breakdown
          _resultRow('SPJ', r.spj),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12, height: 1),
          ),
          _resultRow('DPP (SPJ ÷ 1,11)', r.dpp),
          if (_adaPpn) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.black12, height: 1),
            ),
            _resultRow('PPN (11% × DPP)', r.ppn, isNegative: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.black12, height: 1),
            ),
            _resultRow('PPH (${r.pphRate}% × DPP)', r.pph, isNegative: true),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.black26, height: 1, thickness: 1),
          ),
          // Bersih highlighted
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diterima Bersih',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_rp(r.bersih)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    double value, {
    bool isNegative = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '${isNegative ? "- " : ""}Rp ${_rp(value)}',
          style: TextStyle(
            color: isNegative ? Colors.red.shade700 : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Category Selector ───

  Widget _buildCategorySelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.category_rounded,
                  size: 18, color: Color(0xFF3949AB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilih Kategori Barang',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              if (_selectedCategories.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategories = [];
                      _items = [];
                    });
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih kategori barang untuk melihat rekomendasi harga modal di bawah harga yang diterima',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          MultiSelectSearchableDropdown<String>(
            hintText: 'Pilih Kategori',
            values: _selectedCategories,
            options: _combinedCategories,
            displayText: _getCategoryDisplayName,
            onChanged: (cats) {
              setState(() {
                _selectedCategories = cats;
              });
              _loadItems();
            },
          ),
        ],
      ),
    );
  }

  // ─── Items List ───

  Widget _buildItemList(ThemeData theme) {
    if (_loadingItems) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Mencari rekomendasi barang...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_itemsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_itemsError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
        ),
      );
    }

    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Tidak ada barang yang sesuai',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba pilih kategori lain atau naikkan jumlah SPJ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.recommend_rounded,
                  size: 18, color: Color(0xFF1A237E)),
              const SizedBox(width: 8),
              Text(
                'Rekomendasi Barang',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_items.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '≤ Rp ${_rp(_result!.bersih)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        ..._items.map((item) => _buildItemCard(theme, item)),
      ],
    );
  }

  Widget _buildItemCard(ThemeData theme, _SimItem item) {
    final isStok = item.source == _ItemSource.stok;
    final labelColor =
        isStok ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final labelBg = isStok ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);
    final labelText = isStok ? 'STOK' : 'TKDN';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: labelColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: labelColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & spec
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.spesifikasi != null &&
                    item.spesifikasi!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.spesifikasi!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.kategori != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.kategori!,
                    style: TextStyle(
                      fontSize: 10,
                      color: labelColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Modal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Modal',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rp ${_rp(item.modal ?? 0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
