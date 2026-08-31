import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/shared/responsive_padding.dart';
import 'package:stok_anandam/features/shared/responsive_table.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';

import 'api/laporan_marketing_api.dart';
import 'repositories/laporan_marketing_repository.dart';
import 'models/marketing_report_models.dart';

// ---------------------------------------------------------------------------
// Konstanta warna untuk chart & kartu (High-Contrast Enterprise Palette).
// ---------------------------------------------------------------------------
const Color _cOmset = Color(0xFFE53935); // Merah / Vivid Red
const Color _cHpp = Color(0xFF0284C7); // Sky / Vivid Blue
const Color _cLaba = Color(0xFFF59E0B); // Kuning / Amber Yellow
const Color _cMargin = Color(0xFF10B981); // Emerald Green

const List<Color> _accentPalette = [
  _cOmset,
  _cHpp,
  _cMargin,
  Color(0xFFD97706),
  Color(0xFFEC4899),
];

/// Format angka bulat dengan pemisah ribuan titik (gaya Indonesia).
String _thousands(double v) {
  final rounded = v.round();
  final negative = rounded < 0;
  final s = rounded.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final remaining = s.length - 1 - i;
    if (remaining > 0 && remaining % 3 == 0) buf.write('.');
  }
  return (negative ? '-' : '') + buf.toString();
}

class _DayPoint {
  _DayPoint(this.date);
  final String date;
  String label = '';
  double omset = 0;
  double hpp = 0;
  double laba = 0;
  double get marginPct => hpp <= 0 ? 0 : (laba / hpp) * 100;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Konversi MarketingTimeline (dari backend timeline endpoint) ke List<_DayPoint>.
/// Jauh lebih ringan daripada _buildPoints karena tidak perlu parse baris nota satu-satu.
List<_DayPoint> _buildPointsFromTimeline(
    String period, DateTime date, MarketingTimeline tl) {
  final year = date.year;
  final month = date.month;
  final now = DateTime.now();
  final map = <String, _DayPoint>{};

  // Pre-fill slot kosong agar chart rapi
  void ensure(String key, String label) =>
      map.putIfAbsent(key, () => _DayPoint(key)..label = label);

  if (period == 'YEAR') {
    final endYear = now.year < 2026 ? 2026 : now.year;
    for (var y = 2016; y <= endYear; y++) {
      ensure(y.toString(), y.toString());
    }
  } else if (period == 'MONTH') {
    final maxMonth = (year == now.year) ? now.month : 12;
    for (var m = 1; m <= maxMonth; m++) {
      final key = '$year-${_two(m)}';
      ensure(key, _monthShort(key));
    }
  } else if (period == 'WEEK') {
    final dim = DateTime(year, month + 1, 0).day;
    final nWeeks = ((dim - 1) ~/ 7) + 1;
    for (var w = 1; w <= nWeeks; w++) {
      final start = (w - 1) * 7 + 1;
      final end = (start + 6 <= dim) ? start + 6 : dim;
      ensure('$year-${_two(month)}-W$w', '$start-$end');
    }
  } else {
    final dim = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= dim; d++) {
      final key = '$year-${_two(month)}-${_two(d)}';
      ensure(key, _shortDate(key));
    }
  }

  // Isi titik dari data timeline backend
  for (final pt in tl.points) {
    final key = pt.key;
    if (key.isEmpty) continue;

    String mappedKey;
    if (period == 'WEEK' && key.length >= 10) {
      final dayInt = int.tryParse(key.substring(8, 10));
      if (dayInt == null) continue;
      final w = ((dayInt - 1) ~/ 7) + 1;
      mappedKey = '${key.substring(0, 7)}-W$w';
    } else {
      mappedKey = key;
    }

    final p = map.putIfAbsent(mappedKey, () {
      String lbl = pt.label.isNotEmpty ? pt.label : mappedKey;
      return _DayPoint(mappedKey)..label = lbl;
    });
    p.omset += pt.omset;
    p.hpp += pt.totalHpp;
    p.laba += pt.labaKotor;
  }

  return map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// 'yyyy-MM' -> nama bulan pendek (contoh: 'Agu').
String _monthShort(String ym) {
  try {
    final m = int.parse(ym.substring(5, 7));
    return (m >= 1 && m <= 12) ? _monthNames[m - 1] : ym;
  } catch (_) {
    return ym;
  }
}

/// 'yyyy-MM-dd' -> '13/08'.
String _shortDate(String ymd) {
  try {
    final d = DateTime.parse(ymd);
    return '${d.day}/${d.month}';
  } catch (_) {
    return ymd;
  }
}

/// Membungkus chart agar bisa di-scroll horizontal bila jumlah titik banyak,
/// sehingga tiap bar/titik punya ruang dan label tidak bertumpuk.
class _HScrollChart extends StatelessWidget {
  const _HScrollChart({required this.count, required this.child});

  final int count;
  final Widget child;

  /// Lebar ruang minimal per titik (bar + jarak agar label terbaca).
  static const double _minSpacing = 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final avail = c.maxWidth.isFinite ? c.maxWidth : 1.0;
        final height = c.maxHeight.isFinite ? c.maxHeight : 280.0;
        final scrollable = count > 1 && (count * _minSpacing) > avail;
        final contentW = scrollable ? count * _minSpacing.toDouble() : avail;

        final chart = SizedBox(
          width: contentW,
          height: height,
          child: child,
        );

        if (!scrollable) return chart;

        return Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chart,
            ),
            // Petunjuk visual bahwa masih ada data di kanan.
            IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  ),
                  margin: const EdgeInsets.only(right: 4, bottom: 26),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swipe_right, size: 14, color: Colors.grey),
                      SizedBox(width: 2),
                      Text('geser',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Hitung interval agar maksimal [maxLabels] label muncul di sumbu X.
/// Mencegah label menumpuk saat data banyak (mis. 14 hari dalam sebulan).
int _xInterval(int count, {int maxLabels = 7}) {
  if (count <= maxLabels) return 1;
  return (count / maxLabels).ceil();
}

/// Custom FlDotCirclePainter yang juga menggambar label angka langsung di atas/bawah titik
class _FlDotLabelPainter extends FlDotCirclePainter {
  _FlDotLabelPainter({
    required super.color,
    super.radius = 4,
    super.strokeColor = Colors.white,
    super.strokeWidth = 1.5,
    required this.isAbove,
  });

  final bool isAbove;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    super.draw(canvas, spot, offsetInCanvas);

    if (spot.y == 0) return;

    final label = _shortRp(spot.y);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final yOffset = isAbove
        ? offsetInCanvas.dy - radius - strokeWidth - tp.height - 2
        : offsetInCanvas.dy + radius + strokeWidth + 2;

    tp.paint(
      canvas,
      Offset(offsetInCanvas.dx - tp.width / 2, yOffset),
    );
  }

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is! _FlDotLabelPainter || b is! _FlDotLabelPainter) {
      return b;
    }
    return _FlDotLabelPainter(
      color: Color.lerp(a.color, b.color, t)!,
      radius: radius,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      isAbove: b.isAbove,
    );
  }
}

/// Custom dot painter dengan label angka di ATAS titik (misal untuk garis Omset).
FlDotPainter _dotPainterLabelAbove(
    FlSpot spot, double pct, LineChartBarData bar, int idx) {
  return _FlDotLabelPainter(
    color: bar.color ?? Colors.teal,
    isAbove: true,
  );
}

/// Custom dot painter dengan label angka di BAWAH titik (misal untuk garis HPP/Margin).
FlDotPainter _dotPainterLabelBelow(
    FlSpot spot, double pct, LineChartBarData bar, int idx) {
  return _FlDotLabelPainter(
    color: bar.color ?? Colors.teal,
    isAbove: false,
  );
}

/// Satuan ringkas: 1,25jt / 300rb / 900.
String _shortRp(double v) {
  final a = v.abs();
  final sign = v < 0 ? '-' : '';
  if (a >= 1e9) {
    return '$sign${(v / 1e9).toStringAsFixed(1)}M';
  }
  if (a >= 1e6) {
    return '$sign${(v / 1e6).toStringAsFixed(1).replaceAll('.0', '')}jt';
  }
  if (a >= 1e3) {
    return '$sign${(v / 1e3).toStringAsFixed(0)}rb';
  }
  return sign + _thousands(v);
}

/// Halaman laporan detail omzet & margin kotor per marketing.
class LaporanMarketingPage extends StatefulWidget {
  const LaporanMarketingPage({super.key});

  @override
  State<LaporanMarketingPage> createState() => _LaporanMarketingPageState();
}

class _LaporanMarketingPageState extends State<LaporanMarketingPage> {
  late final LaporanMarketingRepository _repo;

  String _period = 'DAY';
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String _viewMode =
      'visual'; // 'visual' (Grafik & Analisis) | 'table' (Ringkasan Tabel Saja)
  bool _loading = true;
  String? _error;
  MarketingSalesSummary? _summary;

  // Marketing yang sedang dipilih (bisa satu, beberapa, atau Semua).
  List<String> _selectedCodes = const [];
  // Status mode bandingkan (menampilkan 2 marketing berdampingan).
  bool _compare = false;
  bool _useAggregate =
      true; // default: Gabungkan (wajib milih marketing dulu baru muncul datanya)

  /// Tanggal acuan yang dikirim ke API.
  /// - YEAR  -> Januari tahun terpilih (acuan tahun saja; backend pakai rentang penuh).
  /// - MONTH -> tanggal AKHIR periode: today utk tahun berjalan (data Jan–bulan ini),
  ///            atau 31 Desember utk tahun lampau (data Jan–Des).
  /// - WEEK  & DAY -> tanggal 1 bulan terpilih (drill-down Minggu/Hari).
  DateTime get _date {
    if (_period == 'MONTH') {
      final now = DateTime.now();
      return _year == now.year
          ? DateTime(now.year, now.month, now.day)
          : DateTime(_year, 12, 31);
    }
    if (_period == 'WEEK' || _period == 'DAY') {
      return DateTime(_year, _month, 1);
    }
    // YEAR
    return DateTime(_year, 1, 1);
  }

  static const List<({String value, String label, IconData icon})> _periods = [
    (value: 'DAY', label: 'Hari', icon: Icons.today_rounded),
    (value: 'WEEK', label: 'Minggu', icon: Icons.date_range_rounded),
    (value: 'MONTH', label: 'Bulan', icon: Icons.calendar_month_rounded),
    (value: 'YEAR', label: 'Tahun', icon: Icons.calendar_today_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _repo = LaporanMarketingRepository(
      LaporanMarketingApi(getIt<Dio>()),
      getIt<ApiNewEndpoints>(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Lightweight: ambil seluruh rentang dalam SATU request (startDate/endDate),
      // backend mengembalikan semua marketing sekaligus. Tidak perlu loop
      // per-bulan/per-hari/per-marketing sehingga server tidak kebanjiran request.
      final range = _reportRange();
      final summary = await _repo.getOverview(
        period: _period,
        startDate: range.start,
        endDate: range.end,
        empCodes: null,
      );
      if (mounted) {
        setState(() {
          _summary = summary;
          _syncSelections(summary);
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('LaporanMarketing load error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Rentang tanggal (inklusi start..end) untuk seluruh periode yang dipilih.
  ///  - YEAR  -> 2016 s/d akhir tahun berjalan (tren 10 tahun).
  ///  - MONTH -> Januari s/d bulan berjalan (atau Des utk tahun lampau).
  ///  - WEEK/DAY -> seluruh hari di bulan terpilih.
  ({DateTime start, DateTime end}) _reportRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'YEAR':
        return (start: DateTime(2016, 1, 1), end: DateTime(now.year, 12, 31));
      case 'MONTH':
        final end = (_year == now.year)
            ? DateTime(now.year, now.month, now.day)
            : DateTime(_year, 12, 31);
        return (start: DateTime(_year, 1, 1), end: end);
      case 'WEEK':
      case 'DAY':
      default:
        final dim = DateTime(_year, _month + 1, 0).day;
        return (
          start: DateTime(_year, _month, 1),
          end: DateTime(_year, _month, dim),
        );
    }
  }

  /// Pastikan seleksi marketing selalu valid terhadap daftar yang tersedia.
  void _syncSelections(MarketingSalesSummary s) {
    final codes = s.content
        .map((r) => r.empCode)
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (codes.isEmpty) {
      _selectedCodes = const [];
      return;
    }
    if (_useAggregate) {
      _selectedCodes = _selectedCodes.where((c) => codes.contains(c)).toList();
    } else {
      if (_selectedCodes.isEmpty) {
        _selectedCodes = [codes.first];
      }
      _selectedCodes = _selectedCodes.where((c) => codes.contains(c)).toList();
      if (_selectedCodes.isEmpty) {
        _selectedCodes = [codes.first];
      }
    }
  }

  void _onYearChanged(int value) {
    if (_year == value) return;
    setState(() => _year = value);
    _load();
  }

  void _onMonthChanged(int value) {
    if (_month == value) return;
    setState(() => _month = value);
    _load();
  }

  /// Nama bulan lengkap (Januari, Februari, ... Desember).
  static const List<String> _fullMonthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<int> _availableYears() {
    final current = DateTime.now().year;
    // Rentang data laporan 2016 s/d tahun berjalan (mengikuti tren 10 tahun).
    return [for (var y = current; y >= 2016; y--) y];
  }

  /// Dropdown generik berbingkai agar senada dengan tombol filter lainnya.
  Widget _buildFilterDropdown<T>({
    required BuildContext context,
    required T selected,
    required IconData icon,
    required List<T> values,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selected,
              isDense: true,
              borderRadius: BorderRadius.circular(AppRadius.card),
              dropdownColor: theme.colorScheme.surface,
              items: [
                for (final v in values)
                  DropdownMenuItem(value: v, child: Text(labelOf(v))),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown(BuildContext context) {
    return _buildFilterDropdown<int>(
      context: context,
      selected: _year,
      icon: Icons.calendar_today_rounded,
      values: _availableYears(),
      labelOf: (y) => y.toString(),
      onChanged: _onYearChanged,
    );
  }

  Widget _buildMonthDropdown(BuildContext context) {
    return _buildFilterDropdown<int>(
      context: context,
      selected: _month,
      icon: Icons.calendar_month_rounded,
      values: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      labelOf: (m) => _fullMonthNames[m - 1],
      onChanged: _onMonthChanged,
    );
  }

  void _onPeriodChanged(String value) {
    if (_period == value) return;
    setState(() => _period = value);
    _load();
  }

  void _toggleCompare() {
    final s = _summary;
    if (s == null || s.content.length < 2) return;
    setState(() {
      _compare = !_compare;
      if (_compare) {
        final codes = s.content
            .map((r) => r.empCode)
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .toList();
        final first = _selectedCodes.isEmpty ? codes[0] : _selectedCodes[0];
        final second = codes.firstWhere(
            (c) => c != first && !_selectedCodes.contains(c),
            orElse: () =>
                codes.firstWhere((c) => c != first, orElse: () => first));
        _selectedCodes = [first, second];
      } else {
        _selectedCodes = _selectedCodes.sublist(0, 1);
      }
    });
  }

  void _removeSlot(int index) {
    if (index <= 0) return;
    setState(() {
      _selectedCodes = _selectedCodes.sublist(0, 1);
      _compare = false;
    });
  }

  void _toggleAggregate() {
    setState(() {
      _useAggregate = !_useAggregate;
      if (_useAggregate) {
        _compare = false;
        // Mode gabungan: defaultnya BELUM memilih marketing (wajib pilih dulu)
        _selectedCodes = const [];
      } else {
        // Kembali ke mode Bandingkan: default 1 marketing saja
        final s = _summary;
        if (s != null && s.content.isNotEmpty) {
          final first = s.content.first.empCode;
          _selectedCodes =
              (first != null && first.trim().isNotEmpty) ? [first] : const [];
        } else {
          _selectedCodes = const [];
        }
        _compare = false;
      }
    });
  }

  /// Multi-select picker (pilih beberapa / Semua marketing).
  Future<void> _openMultiPicker() async {
    final s = _summary;
    if (s == null) return;
    final all = <MarketingSalesRow>[
      for (final r in s.content)
        if (r.empCode != null && r.empCode!.trim().isNotEmpty) r,
    ]..sort((a, b) => (a.empName ?? a.empCode ?? '')
        .toLowerCase()
        .compareTo((b.empName ?? b.empCode ?? '').toLowerCase()));
    if (all.isEmpty) return;

    final initial = <String>{..._selectedCodes};

    final chosen = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final sel = Set<String>.from(initial);
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = all.where((r) {
              if (query.isEmpty) return true;
              final name = (r.empName ?? '').toLowerCase();
              final code = (r.empCode ?? '').toLowerCase();
              return name.contains(query) || code.contains(query);
            }).toList();

            void toggleAll(bool? v) {
              setSheetState(() {
                if (v == true) {
                  sel
                    ..clear()
                    ..addAll(all.map((r) => r.empCode!));
                } else {
                  sel.clear();
                }
              });
            }

            void toggleOne(bool? v, String code) {
              setSheetState(() {
                if (v == true) {
                  sel.add(code);
                } else {
                  sel.remove(code);
                }
              });
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 4, AppSpacing.lg, AppSpacing.sm),
                      child: Text('Pilih Marketing',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 4),
                      child: TextField(
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau kode marketing...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                        onChanged: (val) => setSheetState(
                            () => query = val.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1),
                    CheckboxListTile(
                      value: sel.length == all.length && all.isNotEmpty,
                      onChanged: toggleAll,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: theme.colorScheme.primary,
                      title: const Text('Semua Marketing',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Ceklis semua ${all.length} marketing'),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Text(
                                  'Marketing "$query" tidak ditemukan',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final r = filtered[i];
                                return CheckboxListTile(
                                  value: sel.contains(r.empCode),
                                  onChanged: (v) => toggleOne(v, r.empCode!),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: theme.colorScheme.primary,
                                  title: Text(r.empName ?? '—'),
                                  subtitle: Text(r.empCode ?? ''),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: FilledButton.icon(
                        onPressed:
                            sel.isEmpty ? null : () => Navigator.pop(ctx, sel),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(sel.isEmpty
                            ? 'Pilih minimal 1'
                            : 'Terapkan (${sel.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen == null || !mounted || chosen.isEmpty) return;
    setState(() {
      _selectedCodes = chosen.toList();
      _useAggregate = true;
      _compare = false;
    });
  }

  Future<void> _openPicker(int index) async {
    final s = _summary;
    if (s == null) return;
    final taken = <String>{
      for (var i = 0; i < _selectedCodes.length; i++)
        if (i != index) _selectedCodes[i],
    };
    final options = s.content.where((r) {
      final c = r.empCode;
      return c != null && c.trim().isNotEmpty && !taken.contains(c);
    }).toList()
      ..sort((a, b) => (a.empName ?? a.empCode ?? '')
          .toLowerCase()
          .compareTo((b.empName ?? b.empCode ?? '').toLowerCase()));
    if (options.isEmpty) return;

    final chosen = await showModalBottomSheet<MarketingSalesRow>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = options.where((r) {
              if (query.isEmpty) return true;
              final name = (r.empName ?? '').toLowerCase();
              final code = (r.empCode ?? '').toLowerCase();
              return name.contains(query) || code.contains(query);
            }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 4, AppSpacing.lg, AppSpacing.sm),
                      child: Text('Pilih Marketing',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 4),
                      child: TextField(
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau kode marketing...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                        onChanged: (val) => setSheetState(
                            () => query = val.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Text(
                                  'Marketing "$query" tidak ditemukan',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final r = filtered[i];
                                final selected =
                                    _selectedCodes[index] == r.empCode;
                                return ListTile(
                                  leading: Icon(Icons.person_rounded,
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant),
                                  title: Text(r.empName ?? '—'),
                                  subtitle: Text(r.empCode ?? ''),
                                  trailing: selected
                                      ? Icon(Icons.check_circle_rounded,
                                          color: theme.colorScheme.primary)
                                      : Icon(Icons.chevron_right_rounded,
                                          color: theme
                                              .colorScheme.onSurfaceVariant),
                                  onTap: () => Navigator.of(ctx).pop(r),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen == null || chosen.empCode == null || !mounted) return;
    setState(() {
      final list = [..._selectedCodes];
      list[index] = chosen.empCode!;
      _selectedCodes = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: AppRoutes.laporanOmset,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      onNavigate: (route) => context.go(route),
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      title: 'Laporan Omset Marketing',
      child: Padding(
        padding: ResponsivePadding.all(context),
        child: LayoutBuilder(
          builder: (context, c) {
            final isMobile = c.maxWidth < 640;
            final filterBar = _buildFilterBar(context);
            final body = _buildBody(context, shrinkWrap: isMobile);
            if (isMobile) {
              // Filter ikut scroll bersama konten — lebih banyak ruang visualisasi
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    filterBar,
                    const SizedBox(height: AppSpacing.lg),
                    body,
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                filterBar,
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------- FILTER BAR (ENTERPRISE TWO-SIDED LAYOUT) -------------------------
  Widget _buildFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 960;
    final isMedium = width >= 640;

    // 1. Grup Kontrol Waktu & Kalender (Sisi Kiri)
    final timeControlGroup = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Selector Periode (Hari, Minggu, Bulan, Tahun)
        SegmentedButton<String>(
          segments: [
            for (final p in _periods)
              ButtonSegment(
                value: p.value,
                label: Text(p.label),
                icon: isMedium ? Icon(p.icon, size: 16) : null,
              ),
          ],
          selected: {_period},
          onSelectionChanged: (s) => _onPeriodChanged(s.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),

        // Dropdown Tahun — utk Bulan/Minggu/Hari.
        // (Tahunan tidak butuh dropdown: chart langsung menampilkan tren 2016-2026)
        if (_period != 'YEAR') _buildYearDropdown(context),

        // Dropdown Bulan — utk Minggu & Hari (perlu bulan spesifik).
        // (Bulanan memakai dropdown Tahun saja; isi chart = bulan di tahun tsb.)
        if (_period == 'WEEK' || _period == 'DAY') _buildMonthDropdown(context),

        // Tombol Refresh
        IconButton.filledTonal(
          onPressed: _loading ? null : _load,
          icon: Icon(_loading ? Icons.hourglass_top : Icons.refresh_rounded,
              size: 18),
          tooltip: 'Muat ulang data',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    // 2. Grup Kontrol Mode Tampilan & Info Badge (Sisi Kanan)
    final viewControlGroup = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
      children: [
        if (_summary != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_rounded,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  _labelRange(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // Switcher Mode Tampilan: Grafik vs Ringkasan Tabel
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'visual',
              label: Text(isMedium ? 'Grafik & Analisis' : 'Grafik'),
              icon: const Icon(Icons.analytics_rounded, size: 16),
            ),
            ButtonSegment(
              value: 'table',
              label: Text(isMedium ? 'Ringkasan Tabel' : 'Tabel'),
              icon: const Icon(Icons.table_chart_rounded, size: 16),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (s) => setState(() => _viewMode = s.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                timeControlGroup,
                viewControlGroup,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                timeControlGroup,
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                viewControlGroup,
              ],
            ),
    );
  }

  // ------------------------- BODY -------------------------
  Widget _buildBody(BuildContext context, {bool shrinkWrap = false}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final s = _summary;
    if (s == null || s.content.isEmpty) {
      return const _EmptyView();
    }
    final sel = _useAggregate ? _aggForSelection(s) : s;
    if (_viewMode == 'table') {
      return _buildTableOnlyReport(context, sel, shrinkWrap: shrinkWrap);
    }
    return _buildReport(context, sel, shrinkWrap: shrinkWrap);
  }

  /// Ringkasan yang diagregasikan (dijumlahkan) sesuai marketing yang dipilih.
  MarketingSalesSummary _aggForSelection(MarketingSalesSummary s) {
    final sel = _selectedCodes.toSet();
    final rows = s.content.where((r) {
      final c = r.empCode;
      return c != null && sel.contains(c);
    }).toList();
    var qty = 0.0, omset = 0.0, hpp = 0.0, laba = 0.0;
    for (final r in rows) {
      qty += r.qty;
      omset += r.omset;
      hpp += r.totalHpp;
      laba += r.labaKotor;
    }
    final margin = hpp <= 0 ? 0.0 : (laba / hpp) * 100;
    return MarketingSalesSummary(
      period: s.period,
      rangeStart: s.rangeStart,
      rangeEnd: s.rangeEnd,
      content: rows,
      totalQty: qty,
      totalOmset: omset,
      totalHpp: hpp,
      totalLabaKotor: laba,
      marginPct: margin,
    );
  }

  // ------------------------- MODE 2: RINGKASAN TABEL SAJA -------------------------
  Widget _buildTableOnlyReport(BuildContext context, MarketingSalesSummary s,
      {bool shrinkWrap = false}) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        // Baris 1: Kartu ringkasan 2x2
        _buildSummaryCards(context, s),
        const SizedBox(height: AppSpacing.xl),

        // Baris 2: Container Card Tabel Ringkasan Seluruh Marketing
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.25),
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Performa Seluruh Marketing',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total ${s.content.length} marketing aktif pada periode ${_labelRange()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabel Data Responsif
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ResponsiveDataTable(
                  minColumnWidth: 120,
                  maxColumnWidth: 240,
                  headingRowColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  columns: [
                    buildDataColumn('Marketing',
                        alignment: Alignment.centerLeft),
                    buildDataColumn('Total Omset',
                        alignment: Alignment.centerRight),
                    buildDataColumn('Total HPP',
                        alignment: Alignment.centerRight),
                    buildDataColumn('Total Margin Kotor',
                        alignment: Alignment.centerRight),
                    buildDataColumn('Total Margin',
                        alignment: Alignment.centerRight),
                  ],
                  rows: [
                    // Baris Data per Marketing
                    for (var i = 0; i < s.content.length; i++) ...[
                      DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      _accentPalette[i % _accentPalette.length]
                                          .withValues(alpha: 0.15),
                                  child: Text(
                                    (s.content[i].empName?.isNotEmpty == true
                                            ? s.content[i].empName![0]
                                            : 'M')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _accentPalette[
                                          i % _accentPalette.length],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.content[i].empName ?? '—',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        s.content[i].empCode ?? '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _rp(s.content[i].omset),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _cOmset,
                              ),
                            ),
                          )),
                          DataCell(Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _rp(s.content[i].totalHpp),
                              style:
                                  const TextStyle(fontSize: 12, color: _cHpp),
                            ),
                          )),
                          DataCell(Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _rp(s.content[i].labaKotor),
                              style:
                                  const TextStyle(fontSize: 12, color: _cLaba),
                            ),
                          )),
                          DataCell(Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_rp(s.content[i].labaKotor)} (${s.content[i].marginPct.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _cMargin,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],

                    // Baris Footer: TOTAL KESELURUHAN
                    DataRow(
                      color: WidgetStateProperty.all(theme
                          .colorScheme.primaryContainer
                          .withValues(alpha: 0.35)),
                      cells: [
                        DataCell(Text(
                          'TOTAL KESELURUHAN',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        DataCell(Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _rp(s.totalOmset),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _cOmset,
                            ),
                          ),
                        )),
                        DataCell(Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _rp(s.totalHpp),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _cHpp,
                            ),
                          ),
                        )),
                        DataCell(Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _rp(s.totalLabaKotor),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _cLaba,
                            ),
                          ),
                        )),
                        DataCell(Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_rp(s.totalLabaKotor)} (${s.marginPct.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _cMargin,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------- MODE 1: GRAFIK & ANALISIS -------------------------
  Widget _buildReport(BuildContext context, MarketingSalesSummary s,
      {bool shrinkWrap = false}) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        // Baris 1 & 2: kartu ringkasan 2x2.
        _buildSummaryCards(context, s),
        const SizedBox(height: AppSpacing.xl),
        Text('Pilih Marketing',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        _buildMarketingSelector(context, s),
        const SizedBox(height: AppSpacing.xl),
        // Seksi detail: SATU laporan gabungan dari seluruh marketing terpilih.
        _buildMarketingSections(context, s),
      ],
    );
  }

  /// Susun seksi detail marketing.
  ///
  /// - Mode Gabungan (_useAggregate): SATU laporan agregat dari semua
  ///   marketing yang dipilih lewat multi-select / "Semua".
  /// - Mode Bandingkan (_compare): 2 seksi berdampingan (kanan-kiri).
  /// - Default (1 marketing): satu seksi full-width.
  Widget _buildMarketingSections(
      BuildContext context, MarketingSalesSummary s) {
    final codes = List<String>.from(_selectedCodes);

    if (_useAggregate) {
      if (codes.isEmpty) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.md),
              Text('Pilih Marketing Terlebih Dahulu',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Silakan pilih satu, beberapa, atau semua marketing untuk menampilkan grafik dan data laporan gabungan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _openMultiPicker,
                icon: const Icon(Icons.checklist_rounded),
                label: const Text('Pilih Marketing'),
              ),
            ],
          ),
        );
      }

      final namesAll = codes
          .map((c) => _empNameOf(s, c))
          .where((n) => n.isNotEmpty)
          .toList();
      final isAll = s.content.isNotEmpty && codes.length >= (_summary?.content.length ?? 0);
      final title = isAll
          ? 'Gabungan Semua Marketing (${codes.length} Marketing)'
          : namesAll.length <= 1
              ? namesAll.firstOrNull ?? 'Marketing'
              : namesAll.length <= 5
                  ? 'Gabungan dari ${namesAll.join(', ')}'
                  : 'Gabungan ${namesAll.sublist(0, 5).join(', ')}, dan ${namesAll.length - 5} lainnya';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MarketingSection(
            key: ValueKey('$_period|$_iso(_date)|aggr|${codes.join(',')}'),
            repo: _repo,
            period: _period,
            date: _date,
            empCodes: codes,
            title: title,
            accent: _accentPalette[0],
          ),
        ],
      );
    }

    final slots = codes.length;

    Widget section(int i) => _MarketingSection(
          key: ValueKey('$_period|$_iso(_date)|compare=$_compare|${codes[i]}'),
          repo: _repo,
          period: _period,
          date: _date,
          empCodes: [codes[i]],
          title: _empNameOf(s, codes[i]),
          accent: _accentPalette[i % _accentPalette.length],
        );

    if (!_compare || slots < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < slots; i++) section(i)],
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        const gap = AppSpacing.xl;
        if (c.maxWidth >= 720) {
          final w = (c.maxWidth - gap * (slots - 1)) / slots;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < slots; i++)
                SizedBox(width: w, child: section(i)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (var i = 0; i < slots; i++) section(i)],
        );
      },
    );
  }

  String _empNameOf(MarketingSalesSummary s, String code) {
    for (final r in s.content) {
      if (r.empCode == code) return r.empName ?? code;
    }
    return code;
  }

  // ------------------------- RINGKASAN 2x2 -------------------------
  Widget _buildSummaryCards(BuildContext context, MarketingSalesSummary s) {
    final items = <(String, String, Color)>[
      ('Total Omset', _rp(s.totalOmset), _cOmset),
      ('Total HPP', _rp(s.totalHpp), _cHpp),
      ('Total Margin Kotor', _rp(s.totalLabaKotor), _cLaba),
      ('Presentase Margin %', (_pct(s.marginPct)), _cMargin),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = AppSpacing.md;
        const cols = 2;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                    width: cardW,
                    child: _SummaryCard(
                        title: items[0].$1,
                        value: items[0].$2,
                        color: items[0].$3)),
                const SizedBox(width: gap),
                SizedBox(
                    width: cardW,
                    child: _SummaryCard(
                        title: items[1].$1,
                        value: items[1].$2,
                        color: items[1].$3)),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                SizedBox(
                    width: cardW,
                    child: _SummaryCard(
                        title: items[2].$1,
                        value: items[2].$2,
                        color: items[2].$3)),
                const SizedBox(width: gap),
                SizedBox(
                    width: cardW,
                    child: _SummaryCard(
                        title: items[3].$1,
                        value: items[3].$2,
                        color: items[3].$3)),
              ],
            ),
          ],
        );
      },
    );
  }

// ------------------------- PEMILIH MARKETING (COMPARE) -------------------------
  Widget _buildMarketingSelector(
      BuildContext context, MarketingSalesSummary s) {
    final theme = Theme.of(context);
    final canCompare = s.content.length >= 2;

    // ---- Tombol segmen: Gabungan vs Bandingkan ----
    Widget modeToggle() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: !_useAggregate ? _toggleAggregate : null,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _useAggregate
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text('Gabungan',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: _useAggregate
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _useAggregate ? _toggleAggregate : null,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !_useAggregate
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text('Bandingkan',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: !_useAggregate
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }

    if (_useAggregate) {
      final codes = _selectedCodes;
      final Widget pickerCard;
      if (codes.isEmpty) {
        pickerCard = InkWell(
          onTap: _openMultiPicker,
          borderRadius: BorderRadius.circular(AppRadius.card + 2),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card + 2),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.group_add_rounded,
                      size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Marketing',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Belum ada marketing dipilih — Klik untuk memilih',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.checklist_rounded, color: theme.colorScheme.primary),
              ],
            ),
          ),
        );
      } else {
        final names = codes
            .map((c) => _empNameOf(s, c))
            .where((n) => n.isNotEmpty)
            .toList();
        final all = s.content.length;
        final isAll = all > 0 && codes.length >= all;
        final subtitle = isAll
            ? 'Seluruh $all marketing digabung'
            : names.take(3).join(', ') +
                (names.length > 3 ? ', +${names.length - 3} lainnya' : '');
        pickerCard = _MarketingPickerCard(
          empCode: '',
          empName: subtitle,
          index: 0,
          accent: _accentPalette[0],
          onTap: _openMultiPicker,
          onRemove: () => setState(() => _selectedCodes = const []),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          modeToggle(),
          const SizedBox(height: AppSpacing.md),
          pickerCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        modeToggle(),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 720;
            const gap = AppSpacing.md;
            final slots = _selectedCodes.length;

            Widget card(int i) => _MarketingPickerCard(
                  empCode: _selectedCodes[i],
                  empName: _empNameOf(s, _selectedCodes[i]),
                  index: i,
                  accent: _accentPalette[i % _accentPalette.length],
                  onTap: () => _openPicker(i),
                  onRemove: i > 0 ? () => _removeSlot(i) : null,
                );

            Widget compareButton() => InkWell(
                  onTap: canCompare ? _toggleCompare : null,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _compare
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: _compare
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.compare_arrows_rounded,
                            size: 18,
                            color: canCompare
                                ? (_compare
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant)
                                : theme.colorScheme.outline),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _compare ? 'Tutup' : 'Bandingkan',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: canCompare
                                ? (_compare
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant)
                                : theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

            // Lebar card: 1 slot -> setengah (agar tombol compare muat di samping),
            // beberapa slot -> dibagi rata sekelas.
            double slotW() {
              if (!isWide) return c.maxWidth;
              if (slots <= 1) return (c.maxWidth - gap) / 2;
              return (c.maxWidth - gap * (slots - 1)) / slots;
            }

            Widget cards() {
              if (isWide) {
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < slots; i++)
                      SizedBox(width: slotW(), child: card(i)),
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < slots; i++) ...[
                    if (i > 0) const SizedBox(height: gap),
                    SizedBox(width: double.infinity, child: card(i)),
                  ],
                ],
              );
            }

            // Layar lebar dgn 1 slot: taruh tombol compare di sisi kanan card.
            if (isWide && slots <= 1) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: slotW(), child: card(0)),
                  const SizedBox(width: gap),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: compareButton(),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cards(),
                const SizedBox(height: AppSpacing.md),
                compareButton(),
              ],
            );
          },
        ),
      ],
    );
  }

  // ------------------------- LABEL & FORMAT -------------------------
  String _labelRange() {
    switch (_period) {
      case 'YEAR':
        final endYear = DateTime.now().year < 2026 ? 2026 : DateTime.now().year;
        return 'Tahun 2016 — $endYear';
      case 'MONTH':
        return 'Bulanan $_year';
      case 'WEEK':
      case 'DAY':
      default:
        return '${_fullMonthNames[_month - 1]} $_year';
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _rp(double v) => 'Rp ${_thousands(v)}';
  String _pct(double v) => '${v.toStringAsFixed(2)}%';
}

/// Kartu pemilih marketing (satu dari slot perbandingan).
class _MarketingPickerCard extends StatelessWidget {
  const _MarketingPickerCard({
    required this.empCode,
    required this.empName,
    required this.index,
    required this.accent,
    required this.onTap,
    this.onRemove,
  });

  final String empCode;
  final String empName;
  final int index;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(Icons.person_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketing ${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      empCode,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onRemove,
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                  tooltip: 'Hapus dari perbandingan',
                ),
              Icon(Icons.expand_more_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seksi ringkasan + chart + detail, bisa untuk satu atau gabungan marketing.
class _MarketingSection extends StatefulWidget {
  const _MarketingSection({
    super.key,
    required this.repo,
    required this.period,
    required this.date,
    required this.empCodes,
    required this.title,
    required this.accent,
  });

  final LaporanMarketingRepository repo;
  final String period;
  final DateTime date;

  /// Kode marketing yang ditampilkan (1 atau lebih utk agregat).
  final List<String> empCodes;

  /// Judul seksi (nama marketing utk satu orang, atau "Gabungan N Marketing").
  final String title;
  final Color accent;

  @override
  State<_MarketingSection> createState() => _MarketingSectionState();
}

class _MarketingSectionState extends State<_MarketingSection> {
  // ====== Chart (dimuat instan via timeline endpoint) ======
  bool _loading = true;
  String? _error;
  MarketingTimeline? _timeline;
  List<_DayPoint> _points = const [];

  // ====== Detail Nota & Barang (lazy — dimuat ketika accordion dibuka) ======
  bool _detailLoading = false;
  String? _detailError;
  bool _detailLoaded = false;
  MarketingNotaDetail? _nota;
  MarketingItemDetail? _item;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void didUpdateWidget(covariant _MarketingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period ||
        widget.date != oldWidget.date ||
        !_sameCodes(widget.empCodes, oldWidget.empCodes)) {
      _detailLoaded = false;
      _nota = null;
      _item = null;
      _loadTimeline();
    }
  }

  bool _sameCodes(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (final x in a) {
      if (!b.contains(x)) return false;
    }
    return true;
  }

  /// Rentang tanggal (inklusi start..end) utk seksi ini, mengikuti periode.
  ///  - YEAR  -> 2016 s/d akhir tahun berjalan.
  ///  - MONTH -> Januari s/d bulan berjalan (atau Des utk tahun lampau).
  ///  - WEEK/DAY -> seluruh hari di bulan terpilih.
  ({DateTime start, DateTime end}) _sectionRange() {
    final p = widget.period;
    final now = DateTime.now();
    final y = widget.date.year;
    final m = widget.date.month;
    switch (p) {
      case 'YEAR':
        return (start: DateTime(2016, 1, 1), end: DateTime(now.year, 12, 31));
      case 'MONTH':
        final end = (y == now.year)
            ? DateTime(now.year, now.month, now.day)
            : DateTime(y, 12, 31);
        return (start: DateTime(y, 1, 1), end: end);
      case 'WEEK':
      case 'DAY':
      default:
        final dim = DateTime(y, m + 1, 0).day;
        return (start: DateTime(y, m, 1), end: DateTime(y, m, dim));
    }
  }

  // Kode marketing efektif: null jika semua marketing.
  String? get _effectiveEmpCode {
    final isAll = widget.empCodes.isEmpty ||
        widget.title.startsWith('Gabungan Semua Marketing');
    if (isAll) return null;
    if (widget.empCodes.length == 1) return widget.empCodes.first;
    return widget.empCodes.join(',');
  }

  /// ⚡ Muat titik chart secara instan dari endpoint timeline agregat.
  /// Hanya mengirim/menerima N baris (misal 11 titik untuk rentang 10 tahun).
  Future<void> _loadTimeline() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final range = _sectionRange();
      final tl = await widget.repo.getTimeline(
        period: widget.period,
        startDate: range.start,
        endDate: range.end,
        empCode: _effectiveEmpCode,
      );
      if (!mounted) return;
      setState(() {
        _timeline = tl;
        _points = _buildPointsFromTimeline(widget.period, widget.date, tl);
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('MarketingSection timeline error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// 🔄 Lazy: Muat detail nota & barang hanya ketika accordion dibuka.
  Future<void> _loadDetail() async {
    if (_detailLoaded || _detailLoading) return;
    setState(() {
      _detailLoading = true;
      _detailError = null;
    });
    try {
      final range = _sectionRange();
      final isAll = widget.empCodes.isEmpty ||
          widget.title.startsWith('Gabungan Semua Marketing');

      MarketingNotaDetail nota;
      MarketingItemDetail item;

      if (isAll) {
        final res = await Future.wait([
          widget.repo.getNotas(
              period: widget.period,
              startDate: range.start,
              endDate: range.end,
              empCode: null),
          widget.repo.getItems(
              period: widget.period,
              startDate: range.start,
              endDate: range.end,
              empCode: null),
        ]);
        nota = res[0] as MarketingNotaDetail;
        item = res[1] as MarketingItemDetail;
      } else {
        // Untuk satu/beberapa marketing — fetch per kode lalu gabungkan.
        var tQty = 0.0, tOmset = 0.0, tHpp = 0.0, tLaba = 0.0;
        final mergedNota = <MarketingNotaRow>[];
        final mergedItem = <MarketingItemRow>[];

        final tasks = widget.empCodes.map((code) async {
          return await Future.wait([
            widget.repo.getNotas(
                period: widget.period,
                startDate: range.start,
                endDate: range.end,
                empCode: code),
            widget.repo.getItems(
                period: widget.period,
                startDate: range.start,
                endDate: range.end,
                empCode: code),
          ]);
        });

        final allResults = await Future.wait(tasks);
        for (final results in allResults) {
          final n = results[0] as MarketingNotaDetail;
          final it = results[1] as MarketingItemDetail;
          mergedNota.addAll(n.content);
          mergedItem.addAll(it.content);
          tQty += n.totalQty;
          tOmset += n.totalOmset;
          tHpp += n.totalHpp;
          tLaba += n.totalLabaKotor;
        }
        final margin = tHpp <= 0 ? 0.0 : (tLaba / tHpp) * 100;
        nota = MarketingNotaDetail(
          empCode: widget.empCodes.join(','),
          empName: widget.title,
          period: widget.period,
          content: mergedNota,
          totalQty: tQty,
          totalOmset: tOmset,
          totalHpp: tHpp,
          totalLabaKotor: tLaba,
          marginPct: margin,
        );
        item = MarketingItemDetail(
          empCode: widget.empCodes.join(','),
          empName: widget.title,
          period: widget.period,
          content: mergedItem,
          totalQty: tQty,
          totalOmset: tOmset,
          totalHpp: tHpp,
          totalLabaKotor: tLaba,
          marginPct: margin,
        );
      }

      if (!mounted) return;
      setState(() {
        _nota = nota;
        _item = item;
        _detailLoaded = true;
        _detailLoading = false;
      });
    } catch (e, st) {
      debugPrint('MarketingSection detail error: $e\n$st');
      if (mounted) {
        setState(() {
          _detailError = e.toString();
          _detailLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(color: widget.accent.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: widget.accent),
          if (_loading)
            const SizedBox(
                height: 240, child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 32, color: theme.colorScheme.error),
                  const SizedBox(height: 8),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loadTimeline,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _buildLoaded(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildLoaded(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.accent.withValues(alpha: 0.14),
              child: Icon(Icons.person_rounded, size: 20, color: widget.accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    widget.empCodes.length > 1
                        ? '${widget.empCodes.length} marketing aktif'
                        : widget.empCodes.join(', '),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Kartu ringkasan metrik langsung dari timeline (sudah tersedia).
        if (_timeline != null) _buildMetricWrapFromTimeline(theme, _timeline!),
        const SizedBox(height: AppSpacing.xl),
        _buildCharts(theme),
        const SizedBox(height: AppSpacing.xl),
        // Detail marketing bisa disembunyikan lewat dropdown (expand/collapse).
        // Data detail baru dimuat KETIKA accordion dibuka (lazy loading).
        ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          leading: Icon(Icons.receipt_long_rounded,
              size: 20, color: theme.colorScheme.primary),
          title: Text('Detail Marketing',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          onExpansionChanged: (expanded) {
            if (expanded) _loadDetail();
          },
          children: [
            const SizedBox(height: AppSpacing.md),
            if (_detailLoading)
              const SizedBox(
                  height: 80, child: Center(child: CircularProgressIndicator()))
            else if (_detailError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gagal memuat detail: $_detailError',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        _detailLoaded = false;
                        _loadDetail();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    )
                  ],
                ),
              )
            else if (_nota == null && _item == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text('Belum ada data detail pada periode ini',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              )
            else
              DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: EdgeInsets.symmetric(vertical: 8),
                        tabs: [
                          Tab(text: 'Per Nota'),
                          Tab(text: 'Per Barang'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 440,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: TabBarView(
                          children: [
                            _NotaTabView(data: _nota),
                            _ItemTabView(data: _item),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Kartu ringkasan metrik dari data timeline (instan, tanpa perlu detail nota).
  Widget _buildMetricWrapFromTimeline(ThemeData theme, MarketingTimeline tl) {
    final items = <(String, String)>[
      ('Omset', _rpM(tl.totalOmset)),
      ('HPP', _rpM(tl.totalHpp)),
      ('Margin Kotor', _rpM(tl.totalLabaKotor)),
      ('Presentase Margin %', ' ${_pctM(tl.marginPct)}'),
    ];
    const colors = [_cOmset, _cHpp, _cLaba, _cMargin];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = AppSpacing.md;
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 2);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: w,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors[i % colors.length].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                        color:
                            colors[i % colors.length].withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].$1,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: double.infinity),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            items[i].$2,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colors[i % colors.length],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCharts(ThemeData theme) {
    return _ChartCard(
      title: 'Omset, HPP & Margin',
      legend: const [
        ('Omset', _cOmset),
        ('HPP', _cHpp),
        ('Margin', _cMargin),
      ],
      child: SizedBox(
        height: 420,
        child: _buildOmsetHppChart(theme, _points),
      ),
    );
  }

  String _rpM(double v) => 'Rp ${_thousands(v)}';
  String _pctM(double v) => '${v.toStringAsFixed(2)}%';

// --- Chart 1: Omset (garis) & HPP (batang) ---
  Widget _buildOmsetHppChart(ThemeData theme, List<_DayPoint> pts) {
    if (pts.isEmpty) {
      return const _ChartEmpty();
    }
    final labels = pts.map((p) => p.label).toList();
    var maxVal = 1.0;
    for (final p in pts) {
      if (p.omset > maxVal) maxVal = p.omset;
      if (p.hpp > maxVal) maxVal = p.hpp;
    }
    final maxY = maxVal * 1.15;
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    final hasMany = pts.length > 1;

    // leftSize lebih besar agar label seperti "250jt" tidak terpotong.
    const leftSize = 54.0;
    const bottomSize = 28.0;

    // Interval X hanya dipakai utk label nilai pada TITIK (dot), bukan label
    // bawah — label bawah ditampilkan lengkap untuk seluruh titik.
    final xIntervalVal = _xInterval(pts.length);

    Widget xTitle(double v, TitleMeta m) {
      final i = v.round();
      // Pastikan v bernilai bulat persis, abaikan pecahan desimal dari engine fl_chart
      if ((v - i).abs() > 0.01) return const SizedBox.shrink();
      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
      // Tampilkan SEMUA label bawah (lengkap & urut, mis. 1/8, 2/8, 3/8, ...).
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          labels[i],
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      );
    }

    Widget leftTitle(double v, TitleMeta m) {
      if (v == m.min) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          _shortRp(v),
          textAlign: TextAlign.right,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      );
    }

    // Omset (merah), HPP (biru), & margin antara Omset-HPP diarsir hijau.
    const omsetColor = _cOmset; // merah
    const hppColor = _cHpp; // biru
    return _HScrollChart(
      count: pts.length,
      child: LineChart(
        LineChartData(
          // Matikan clipData & beri margin horizontal agar titik & label di ujung kiri-kanan tidak menempel pada garis tepi chart
          clipData: const FlClipData.none(),
          lineBarsData: [
            // Garis Omset — kuning (di atas), label di atas titik
            LineChartBarData(
              spots: [
                for (var i = 0; i < pts.length; i++)
                  FlSpot(i.toDouble(), pts[i].omset),
              ],
              color: omsetColor,
              barWidth: 2.5,
              isCurved: true,
              curveSmoothness: 0.15,
              preventCurveOverShooting: true,
              dotData: const FlDotData(
                  show: true, getDotPainter: _dotPainterLabelAbove),
              showingIndicators: [
                for (var i = 0; i < pts.length; i += xIntervalVal) i,
              ],
            ),
            // Garis HPP — merah (di bawah), label di bawah titik
            LineChartBarData(
              spots: [
                for (var i = 0; i < pts.length; i++)
                  FlSpot(i.toDouble(), pts[i].hpp),
              ],
              color: hppColor,
              barWidth: 2.5,
              isCurved: true,
              curveSmoothness: 0.15,
              preventCurveOverShooting: true,
              dotData: const FlDotData(
                  show: true, getDotPainter: _dotPainterLabelBelow),
            ),
          ],
          betweenBarsData: [
            // Area margin (hijau transparan) di antara garis Omset dan HPP
            BetweenBarsData(
              fromIndex: 0,
              toIndex: 1,
              color: const Color(0x3344B84B),
            ),
          ],
          minY: 0,
          maxY: maxY,
          minX: -0.4,
          maxX: hasMany ? pts.length - 0.6 : 1.4,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: gridColor, strokeWidth: 1, dashArray: const [4, 4]),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: gridColor, width: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: leftSize,
                getTitlesWidget: leftTitle,
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1.0,
                reservedSize: bottomSize,
                getTitlesWidget: xTitle,
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipColor: (_) => const Color(0x701E272E),
              getTooltipItems: (spots) {
                if (spots.isEmpty) return [];
                final idx = spots.first.spotIndex;
                final p = idx >= 0 && idx < pts.length ? pts[idx] : null;
                return List.generate(spots.length, (i) {
                  if (p == null) return null;
                  final laba = p.omset - p.hpp;
                  if (i == 0) {
                    // Item pertama: header tanggal + Omset
                    return LineTooltipItem(
                      '📅 ${p.label}\nOmset  : ${_rpM(p.omset)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  }
                  // Item kedua: HPP (merah) + Margin (hijau) via children
                  return LineTooltipItem(
                    'HPP    : ${_rpM(p.hpp)}',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text:
                            '\nMargin : ${_rpM(laba)} (${p.marginPct.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  // --- Chart 2: Omset & Margin Kotor (dua garis dlm SATU chart) ---
  // Keduanya memakai satuan Rupiah (margin kotor sudah berupa angka nominal,
  // bukan %). Disusun pada satu sumbu Y yang sama sehingga garis omset otomatis
  // berada di atas dan garis margin kotor di bawah — tidak saling tabrakan,
  // mengikuti pola chart "Omset & HPP".
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.legend = const [],
  });

  final String title;
  final Widget child;

  /// Legend items: list of (label, color). Tampil sebagai chip kecil di header.
  final List<(String, Color)> legend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // Padding: 16 di semua sisi kecuali bawah 12 (chart punya dot yang butuh napas)
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title di kiri, legend chips di kanan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (legend.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    for (final (label, color) in legend)
                      _LegendChip(label: label, color: color),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// Chip kecil untuk legend chart — bulat kecil berwarna + teks label.
class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text('Belum ada data untuk digambar',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Belum ada data penjualan pada periode ini',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Gagal memuat data',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

// ------------------------- TAB: PER NOTA -------------------------
class _NotaTabView extends StatefulWidget {
  const _NotaTabView({this.data});

  final MarketingNotaDetail? data;

  @override
  State<_NotaTabView> createState() => _NotaTabViewState();
}

class _NotaTabViewState extends State<_NotaTabView> {
  int _page = 0;
  static const int _pageSize = 50;

  static String _rp(double v) => 'Rp ${_thousands(v)}';
  static String _num(double v) => _thousands(v);
  static String _pct(double v) => '${v.toStringAsFixed(2)}%';

  @override
  void didUpdateWidget(covariant _NotaTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final theme = Theme.of(context);
    if (d == null || d.content.isEmpty) {
      return const Center(child: Text('Tidak ada nota pada periode ini'));
    }

    final totalItems = d.content.length;
    final maxPage = ((totalItems - 1) ~/ _pageSize);
    if (_page > maxPage) _page = maxPage;
    final start = _page * _pageSize;
    final end =
        (start + _pageSize > totalItems) ? totalItems : (start + _pageSize);
    final pagedContent = d.content.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 560;
              if (isWide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ResponsiveDataTable(
                    minColumnWidth: 110,
                    maxColumnWidth: 180,
                    headingRowColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.4),
                    columns: [
                      buildDataColumn('No. Nota',
                          alignment: Alignment.centerLeft),
                      buildDataColumn('Tanggal', alignment: Alignment.center),
                      buildDataColumn('Pelanggan',
                          alignment: Alignment.centerLeft),
                      buildDataColumn('Qty', alignment: Alignment.centerRight),
                      buildDataColumn('Omset',
                          alignment: Alignment.centerRight),
                      buildDataColumn('Laba', alignment: Alignment.centerRight),
                    ],
                    rows: [
                      for (final r in pagedContent)
                        DataRow(cells: [
                          DataCell(Text(r.docNo ?? '—',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Text(r.docDate ?? '—',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Text(r.parName ?? '—',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_num(r.qty),
                                  style: const TextStyle(fontSize: 12)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_rp(r.omset),
                                  style: const TextStyle(fontSize: 12)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_rp(r.labaKotor),
                                  style: const TextStyle(fontSize: 12)))),
                        ]),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: pagedContent.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final r = pagedContent[i];
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.docNo ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(r.docDate ?? '',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(r.parName ?? '—',
                              softWrap: true,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Text('Qty: ${_num(r.qty)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Omset: ${_rp(r.omset)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Laba: ${_rp(r.labaKotor)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Margin: ${_pct(r.marginPct)}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _PaginationBar(
          currentPage: _page,
          totalItems: totalItems,
          pageSize: _pageSize,
          onPageChanged: (newPage) => setState(() => _page = newPage),
        ),
      ],
    );
  }
}

// ------------------------- TAB: PER BARANG -------------------------
class _ItemTabView extends StatefulWidget {
  const _ItemTabView({this.data});

  final MarketingItemDetail? data;

  @override
  State<_ItemTabView> createState() => _ItemTabViewState();
}

class _ItemTabViewState extends State<_ItemTabView> {
  int _page = 0;
  static const int _pageSize = 50;

  static String _rp(double v) => 'Rp ${_thousands(v)}';
  static String _num(double v) => _thousands(v);
  static String _pct(double v) => '${v.toStringAsFixed(2)}%';

  @override
  void didUpdateWidget(covariant _ItemTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final theme = Theme.of(context);
    if (d == null || d.content.isEmpty) {
      return const Center(child: Text('Tidak ada barang pada periode ini'));
    }

    final totalItems = d.content.length;
    final maxPage = ((totalItems - 1) ~/ _pageSize);
    if (_page > maxPage) _page = maxPage;
    final start = _page * _pageSize;
    final end =
        (start + _pageSize > totalItems) ? totalItems : (start + _pageSize);
    final pagedContent = d.content.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 560;
              if (isWide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ResponsiveDataTable(
                    minColumnWidth: 110,
                    maxColumnWidth: 180,
                    headingRowColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.4),
                    columns: [
                      buildDataColumn('Kode', alignment: Alignment.centerLeft),
                      buildDataColumn('Nama Barang',
                          alignment: Alignment.centerLeft),
                      buildDataColumn('Kategori',
                          alignment: Alignment.centerLeft),
                      buildDataColumn('Qty', alignment: Alignment.centerRight),
                      buildDataColumn('Omset',
                          alignment: Alignment.centerRight),
                      buildDataColumn('Laba', alignment: Alignment.centerRight),
                      buildDataColumn('Margin',
                          alignment: Alignment.centerRight),
                    ],
                    rows: [
                      for (final r in pagedContent)
                        DataRow(cells: [
                          DataCell(Text(r.iteCode ?? '—',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Text(r.itemName ?? '—',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Text(r.depName ?? r.depCode ?? '—',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_num(r.qty),
                                  style: const TextStyle(fontSize: 12)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_rp(r.omset),
                                  style: const TextStyle(fontSize: 12)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_rp(r.labaKotor),
                                  style: const TextStyle(fontSize: 12)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_pct(r.marginPct),
                                  style: const TextStyle(fontSize: 12)))),
                        ]),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: pagedContent.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final r = pagedContent[i];
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.itemName ?? '—',
                              softWrap: true,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                              '${r.iteCode ?? ''} · ${r.depName ?? r.depCode ?? ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Text('Qty: ${_num(r.qty)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Omset: ${_rp(r.omset)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Laba: ${_rp(r.labaKotor)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Margin: ${_pct(r.marginPct)}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _PaginationBar(
          currentPage: _page,
          totalItems: totalItems,
          pageSize: _pageSize,
          onPageChanged: (newPage) => setState(() => _page = newPage),
        ),
      ],
    );
  }
}

// ------------------------- PAGINATION BAR -------------------------
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= pageSize) return const SizedBox.shrink();

    final totalPages = (totalItems / pageSize).ceil();
    final startItem = currentPage * pageSize + 1;
    final endItem = (currentPage + 1) * pageSize > totalItems
        ? totalItems
        : (currentPage + 1) * pageSize;
    final theme = Theme.of(context);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan $startItem–$endItem dari $totalItems data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                tooltip: 'Halaman Sebelumnya',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                tooltip: 'Halaman Berikutnya',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
