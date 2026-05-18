import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/core/network/tkdn_categories.dart';
import '../../data/api_new_endpoints.dart';
import '../../injection.dart';
import '../../token_storage.dart';
import '../layout/dashboard_shell.dart';
import '../shared/migration_sync_mixin.dart';
import '../shared/responsive_padding.dart';
import '../shared/item_deck_card.dart';
import '../shared/modern_filter.dart';
import '../shared/detail_row_with_copy.dart';
import '../shared/responsive_deck_grid.dart';

/// State filter TKDN disimpan di sini agar saat pindah ke menu lain lalu balik, filter tetap.
class _TkdnFilterState {
  _TkdnFilterState._();
  static String search = '';
  static List<String> categories = [];
  static bool? isTkdn = true;
  static String? filterProcessor;
  static String? filterRam;
  static String? filterSsd;
  static String? filterHdd;
  static String? filterVga;
  static String? filterLayar;
  static String? filterOs;
  static double? minPrice;
  static double? maxPrice;
  static int page = 0;
  static String sortBy = 'kategori';
  static String direction = 'asc';
  static int size = 50;

  static void reset() {
    search = '';
    categories = [];
    isTkdn = true;
    filterProcessor = null;
    filterRam = null;
    filterSsd = null;
    filterHdd = null;
    filterVga = null;
    filterLayar = null;
    filterOs = null;
    minPrice = null;
    maxPrice = null;
    page = 0;
    sortBy = 'kategori';
    direction = 'asc';
    size = 50; // Increased size for better grouping
  }
}

class TkdnPage extends StatefulWidget {
  const TkdnPage({super.key});

  @override
  State<TkdnPage> createState() => _TkdnPageState();
}

class _TkdnPageState extends State<TkdnPage> {
  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_TkdnFilterState.reset);
  }

  @override
  Widget build(BuildContext context) {
    return const _TkdnContent();
  }
}

class _TkdnContent extends StatefulWidget {
  const _TkdnContent();

  @override
  State<_TkdnContent> createState() => _TkdnContentState();
}

class _TkdnContentState extends State<_TkdnContent> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  List<Tkdn> _items = [];
  int _page = 0;
  int _size = 50;
  int _totalElements = 0;
  int _totalPages = 0;
  List<Tkdn> _filteredItems = []; // List yang sudah difilter modal 0
  String _search = '';
  String _sortBy = 'kategori';
  String _direction = 'asc';
  bool? _isTkdn;
  List<String> _selectedCategories = [];
  List<String> _availableKategori = [];
  // Filter spesifikasi: tiap jenis punya kolom search sendiri (Prosesor, RAM, SSD, dll.) — semuanya AND.
  String? _filterProcessor;
  String? _filterRam;
  String? _filterSsd;
  String? _filterHdd;
  String? _filterVga;
  String? _filterLayar;
  String? _filterOs;
  final _processorSearchController = TextEditingController();
  final _ramSearchController = TextEditingController();
  final _ssdSearchController = TextEditingController();
  final _hddSearchController = TextEditingController();
  final _vgaSearchController = TextEditingController();
  final _layarSearchController = TextEditingController();
  final _osSearchController = TextEditingController();
  double? _minPrice;
  double? _maxPrice;
  double _datasetMinPrice = 0;
  double _datasetMaxPrice = 100000000; // Default placeholder
  String _loadingMessage = 'Memuat data...';

  /// True setelah _loadAllTkdnForSpecFilter selesai; dipakai agar tidak load ulang tiap kali user ubah isian spesifikasi.
  bool _specFilterDataLoaded = false;
  // Cache opsi filter dari seluruh data (kategori tetap dipakai untuk dropdown).
  final Set<String> _allKategori = {};
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  void _restoreFilterState() {
    _search = _TkdnFilterState.search;
    _searchController.text = _search ?? '';
    _selectedCategories = List<String>.from(_TkdnFilterState.categories);
    _isTkdn = _TkdnFilterState.isTkdn;
    _page = _TkdnFilterState.page;
    _sortBy = _TkdnFilterState.sortBy;
    _direction = _TkdnFilterState.direction;
    _size = _TkdnFilterState.size;
    _filterProcessor = _TkdnFilterState.filterProcessor;
    _filterRam = _TkdnFilterState.filterRam;
    _filterSsd = _TkdnFilterState.filterSsd;
    _filterHdd = _TkdnFilterState.filterHdd;
    _filterVga = _TkdnFilterState.filterVga;
    _filterLayar = _TkdnFilterState.filterLayar;
    _filterOs = _TkdnFilterState.filterOs;
    _processorSearchController.text = _filterProcessor ?? '';
    _ramSearchController.text = _filterRam ?? '';
    _ssdSearchController.text = _filterSsd ?? '';
    _hddSearchController.text = _filterHdd ?? '';
    _vgaSearchController.text = _filterVga ?? '';
    _layarSearchController.text = _filterLayar ?? '';
    _osSearchController.text = _filterOs ?? '';
    _minPrice = _TkdnFilterState.minPrice;
    _maxPrice = _TkdnFilterState.maxPrice;
  }

  void _persistFilterState() {
    _TkdnFilterState.search = _search ?? '';
    _TkdnFilterState.categories = List<String>.from(_selectedCategories);
    _TkdnFilterState.isTkdn = _isTkdn;
    _TkdnFilterState.page = _page;
    _TkdnFilterState.sortBy = _sortBy;
    _TkdnFilterState.direction = _direction;
    _TkdnFilterState.size = _size;
    _TkdnFilterState.filterProcessor = _filterProcessor;
    _TkdnFilterState.filterRam = _filterRam;
    _TkdnFilterState.filterSsd = _filterSsd;
    _TkdnFilterState.filterHdd = _filterHdd;
    _TkdnFilterState.filterVga = _filterVga;
    _TkdnFilterState.filterLayar = _filterLayar;
    _TkdnFilterState.filterOs = _filterOs;
    _TkdnFilterState.minPrice = _minPrice;
    _TkdnFilterState.maxPrice = _maxPrice;
  }

  @override
  void initState() {
    super.initState();
    _restoreFilterState();
    _loadAllFilterOptions();
    fetchLastSync();
    if (_hasSpecFilter) {
      _loadAllTkdnForSpecFilter();
    } else {
      _loadTkdn();
    }
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      setState(() {
        _search = _searchController.text;
        _page = 0;
        _persistFilterState();
      });
      _loadTkdn();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _processorSearchController.dispose();
    _ramSearchController.dispose();
    _ssdSearchController.dispose();
    _hddSearchController.dispose();
    _vgaSearchController.dispose();
    _layarSearchController.dispose();
    _osSearchController.dispose();
    super.dispose();
  }

  static List<Tkdn> _parseContent(Object? content) {
    if (content == null) return [];
    if (content is Map) {
      final innerContent = content['content'];
      if (innerContent is List) return _parseContent(innerContent);
    }
    if (content is List) {
      return content
          .map((e) {
            if (e is Tkdn) return e;
            if (e is Map) return Tkdn.fromJson(Map<String, dynamic>.from(e));
            return null;
          })
          .whereType<Tkdn>()
          .toList();
    }
    return [];
  }

  static String _addThousandSeparator(String number) {
    final reversed = number.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks.join('.').split('').reversed.join();
  }

  static String _formatNumber(num value) {
    if (value % 1 != 0) {
      final parts = value.toString().split('.');
      final integerPart = _addThousandSeparator(parts[0]);
      return '$integerPart,${parts[1]}';
    }
    return _addThousandSeparator(value.toInt().toString());
  }

  static String _rp(Object? x) {
    if (x == null) return '—';
    final n = num.tryParse(x.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
    if (n == null) return x.toString();
    final String formatted = _formatNumber(n);
    return ' $formatted';
  }

  static String? _specVal(Object? x) {
    if (x == null) return null;
    final s = x.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Filter items berdasarkan search spesifikasi (client-side): tiap kolom search AND.
  /// Contoh: Prosesor "i5" + RAM "16" + SSD "256" → item harus punya i5 dan 16 dan 256.
  List<Tkdn> _applySpecFilters(List<Tkdn> items) {
    return items.where((t) {
      if (_filterProcessor != null && _filterProcessor!.trim().isNotEmpty) {
        final v = _specVal(t.processor);
        if (v == null ||
            !v.toLowerCase().contains(_filterProcessor!.trim().toLowerCase())) {
          return false;
        }
      }
      if (_filterRam != null && _filterRam!.trim().isNotEmpty) {
        final v = _specVal(t.ram);
        if (v == null ||
            !v.toLowerCase().contains(_filterRam!.trim().toLowerCase())) {
          return false;
        }
      }
      if (_filterSsd != null && _filterSsd!.trim().isNotEmpty) {
        final v = _specVal(t.ssd);
        if (v == null ||
            !v.toLowerCase().contains(_filterSsd!.trim().toLowerCase())) {
          return false;
        }
      }
      if (_filterHdd != null && _filterHdd!.trim().isNotEmpty) {
        final v = _specVal(t.hdd);
        if (v == null ||
            !v.toLowerCase().contains(_filterHdd!.trim().toLowerCase())) {
          return false;
        }
      }
      if (_filterVga != null && _filterVga!.trim().isNotEmpty) {
        final v = _specVal(t.vga);
        if (v == null ||
            !v.toLowerCase().contains(_filterVga!.trim().toLowerCase())) {
          return false;
        }
      }
      if (_filterLayar != null && _filterLayar!.trim().isNotEmpty) {
        final v = _specVal(t.layar);
        if (v == null ||
            !v.toLowerCase().contains(_filterLayar!.trim().toLowerCase())) {
          return false;
        }
      }
      if (_filterOs != null && _filterOs!.trim().isNotEmpty) {
        final v = _specVal(t.os);
        if (v == null ||
            !v.toLowerCase().contains(_filterOs!.trim().toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool get _hasSpecFilter =>
      (_filterProcessor?.trim().isNotEmpty ?? false) ||
      (_filterRam?.trim().isNotEmpty ?? false) ||
      (_filterSsd?.trim().isNotEmpty ?? false) ||
      (_filterHdd?.trim().isNotEmpty ?? false) ||
      (_filterVga?.trim().isNotEmpty ?? false) ||
      (_filterLayar?.trim().isNotEmpty ?? false) ||
      (_filterOs?.trim().isNotEmpty ?? false);

  List<Tkdn> get _displayItems {
    final start = _page * _size;
    if (start >= _filteredItems.length) return [];
    final end = (start + _size < _filteredItems.length)
        ? start + _size
        : _filteredItems.length;
    return _filteredItems.sublist(start, end);
  }

  /// Menghitung kategori apa saja yang tampil di halaman saat ini.
  List<String> get _currentPageCategories {
    final items = _displayItems;
    final cats = <String>{};
    for (final item in items) {
      String cat = (_v(item.kategori) ?? '—').toUpperCase();
      if (cat == '—') cat = 'LAINNYA';
      cats.add(cat);
    }
    
    // Prioritize standard categories
    final standard = TkdnCategories.all;
    final foundStandard = standard.where((s) => cats.contains(s)).toList();
    final foundOthers = cats.where((c) => !standard.contains(c) && c != 'LAINNYA').toList()..sort();
    
    final sorted = [...foundStandard, ...foundOthers];
    if (cats.contains('LAINNYA')) sorted.add('LAINNYA');
    return sorted;
  }

  void _updatePaginationData() {
    // Selalu urutkan _filteredItems berdasarkan kategori (abjad) lalu nama
    _filteredItems.sort((a, b) {
      String catA = (_v(a.kategori) ?? '—').toUpperCase();
      String catB = (_v(b.kategori) ?? '—').toUpperCase();
      if (catA == '—') catA = 'LAINNYA';
      if (catB == '—') catB = 'LAINNYA';
      
      final standard = TkdnCategories.all;
      int idxA = standard.indexOf(catA);
      int idxB = standard.indexOf(catB);
      
      if (idxA != idxB) {
        if (idxA == -1) return 1;
        if (idxB == -1) return -1;
        return idxA.compareTo(idxB);
      }
      
      if (catA != catB) return catA.compareTo(catB);
      return (_v(a.nama) ?? '').compareTo(_v(b.nama) ?? '');
    });

    _totalPages = (_filteredItems.length / _size).ceil();
    if (_totalPages < 1) _totalPages = 1;
    if (_page >= _totalPages) _page = _totalPages - 1;
    if (_page < 0) _page = 0;
  }

  /// Jika ada filter spesifikasi, muat semua halaman lalu filter di client (API tidak punya param spesifikasi).
  static const int _maxPagesForSpecFilter = 50;
  static const int _pageSizeForSpecFilter = 200;

  /// Muat TKDN dengan filter spec via Dio (format response: data = array, paging terpisah).
  Future<void> _loadAllTkdnForSpecFilterViaDio() async {
    final dio = getIt<MyApiClient>().dio;
    final categoriesVal = _selectedCategories;
    final allItems = <Tkdn>[];
    var page = 0;
    var totalPages = 1;

    while (page < totalPages && page < _maxPagesForSpecFilter) {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': _pageSizeForSpecFilter,
        'sortBy': _sortBy,
        'direction': _direction,
        if (_isTkdn != null) 'isTkdn': _isTkdn,
        if (categoriesVal.isNotEmpty) 'categories': categoriesVal,
        if (_search.trim().isNotEmpty) 'search': _search.trim(),
      };
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/tkdn',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data == null || !isResponseSuccess(data['status'])) break;
      final dataPayload = data['data'];
      final paging = data['paging'];
      if (dataPayload is! List) break;
      final items = _parseContent(dataPayload);
      allItems.addAll(items);
      if (paging is Map) {
        final p = Map<String, dynamic>.from(
            paging.map((k, v) => MapEntry(k?.toString() ?? '', v)));
        totalPages = int.tryParse(p['totalPage']?.toString() ?? '1') ?? 1;
      }
      page++;
      if (!mounted) return;
    }

    if (!mounted) return;
    _collectFilterValues(allItems);
    final filtered = _applySpecFilters(allItems);
    setState(() {
      _loading = false;
      _specFilterDataLoaded = true;
      _syncAvailableFiltersFromCache();
      _persistFilterState();
    });
  }

  Future<void> _loadAllTkdnForSpecFilter() async {
    // We can now just use _loadTkdn because it loads everything and filters
    return _loadTkdn();
  }

  void _collectFilterValues(Iterable<Tkdn> items) {
    for (final t in items) {
      final k = t.kategori?.toString().trim();
      if (k != null && k.isNotEmpty) _allKategori.add(k);
    }
  }

  void _syncAvailableFiltersFromCache() {
    final standard = TkdnCategories.all;
    final others = _allKategori
        .where((c) => !standard.contains(c.toUpperCase().trim()))
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
    _availableKategori = [...standard, ...others];
  }

  Future<void> _loadAllFilterOptions() async {
    try {
      final api = getIt<ApiNewEndpoints>();
      final categories = await api.getTkdnCategories();
      if (!mounted) return;
      setState(() {
        _allKategori.clear();
        _allKategori.addAll(categories);
        _syncAvailableFiltersFromCache();
      });
    } catch (_) {
      // Keep using options collected from current page if API fails.
    }
  }

  Future<void> _loadTkdn() async {
    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = 'Memuat data...';
    });

    try {
      final dio = getIt<MyApiClient>().dio;
      final categoriesVal = _selectedCategories;

      final queryParams = <String, dynamic>{
        'page': 0,
        'size': 100, // Ambil per 100 untuk efisiensi
        'sortBy': _sortBy,
        'direction': _direction,
        if (_isTkdn != null) 'isTkdn': _isTkdn,
        if (categoriesVal.isNotEmpty) 'categories': categoriesVal,
        if (_search.trim().isNotEmpty) 'search': _search.trim(),
      };

      // 1. Fetch first page to get total pages
      final response =
          await dio.get('/api/v1/tkdn', queryParameters: queryParams);
      final body = response.data as Map<String, dynamic>;

      if (!isResponseSuccess(body['status'])) {
        throw Exception(body['message'] ?? 'Gagal memuat data.');
      }

      int totalPage = 1;
      final paging = body['paging'];
      if (paging is Map) {
        totalPage = int.tryParse(paging['totalPage']?.toString() ?? '1') ?? 1;
      }

      final allRawData = <dynamic>[];
      final firstPageContent = body['data'];
      if (firstPageContent is List) {
        allRawData.addAll(firstPageContent);
      } else if (firstPageContent is Map && firstPageContent['content'] is List) {
        allRawData.addAll(firstPageContent['content'] as List);
      }

      // 2. Fetch remaining pages in chunks
      if (totalPage > 1) {
        final maxPages = totalPage > 50 ? 50 : totalPage;
        const chunkSize = 5;

        for (int i = 1; i < maxPages; i += chunkSize) {
          final end = (i + chunkSize < maxPages) ? i + chunkSize : maxPages;
          final futures = <Future<Response>>[];

          setState(() {
            _loadingMessage = 'Memuat data... (Halaman $i/$maxPages)';
          });

          for (int p = i; p < end; p++) {
            futures.add(dio.get('/api/v1/tkdn',
                queryParameters: {...queryParams, 'page': p}));
          }

          final responses = await Future.wait(futures);
          for (final r in responses) {
            final b = r.data as Map<String, dynamic>;
            if (isResponseSuccess(b['status'])) {
              final content = b['data'];
              if (content is List) {
                allRawData.addAll(content);
              } else if (content is Map && content['content'] is List) {
                allRawData.addAll(content['content'] as List);
              }
            }
          }

          // Cek abort jika widget unmounted saat loop panjang
          if (!mounted) return;
          
          // Jika tidak ada spec filter, kita bisa stop lebih awal jika sudah cukup banyak data
          // Tapi demi konsistensi client-side sorting/filtering modal 0, kita ambil semua limit 50 hal.
        }
      }

      setState(() {
        _loadingMessage = 'Memproses data...';
      });

      // 3. Process data in background Isolate
      final processed = await compute(_processTkdnData, {
        'rawData': allRawData,
        'filterProcessor': _filterProcessor,
        'filterRam': _filterRam,
        'filterSsd': _filterSsd,
        'filterHdd': _filterHdd,
        'filterVga': _filterVga,
        'filterLayar': _filterLayar,
        'filterOs': _filterOs,
        'minPrice': _minPrice,
        'maxPrice': _maxPrice,
      });

      if (!mounted) return;

      setState(() {
        _items = processed.allItems;
        _filteredItems = processed.filteredItems;
        _datasetMinPrice = processed.datasetMinPrice;
        _datasetMaxPrice = processed.datasetMaxPrice;
        
        _totalElements = _filteredItems.length;
        _updatePaginationData();

        _syncAvailableFiltersFromCache();
        _loading = false;
        _persistFilterState();
      });
    } catch (e) {
      debugPrint('TKDN Load Error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
    }
  }

  void _onSearchSubmitted() {
    _search = _searchController.text;
    setState(() {
      _page = 0;
      _persistFilterState();
    });
    _loadTkdn();
  }

  void _openDetail(Tkdn item) async {
    final id = item.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final api = getIt<TkdnControllerApi>();
      final response = await api.getTkdnDetail(id: id);
      if (!mounted) return;
      Navigator.of(context).pop();
      final detail = response.data?.data;
      if (detail != null) {
        _showDetailSheet(detail);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail: $e')),
      );
    }
  }

  void _showDetailSheet(Tkdn t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                // Nama di baris atas
                                TextSpan(
                                  text: "${_v(t.nama) ?? '—'}\n",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                    height: 1.3,
                                  ),
                                ),
                                // Spesifikasi di baris bawahnya
                                TextSpan(
                                  text: _v(t.spesifikasi) ?? '-',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon:
                              const Icon(Icons.content_copy_rounded, size: 20),
                          onPressed: () {
                            final String namaBarang = _v(t.nama) ?? '—';
                            final String spekBarang = _v(t.spesifikasi) ?? '';
                            final String fullText =
                                "$namaBarang\n$spekBarang".trim();

                            if (namaBarang != '—') {
                              Clipboard.setData(ClipboardData(text: fullText));

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nama & Spesifikasi disalin'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          color: Colors.blue.shade600,
                          tooltip: 'Salin Nama & Spesifikasi',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DetailRowWithCopy(
                        label: 'Master', value: _v(t.nama), labelWidth: 120),
                    const Divider(),
                    if (!_isModalEmpty(t.modal))
                      DetailRowWithCopy(
                          label: 'Modal', value: _rp(t.modal), labelWidth: 120),
                    const Divider(),
                    DetailRowWithCopy(
                        label: 'Dealer', value: _rp(t.dealer), labelWidth: 120),
                    const Divider(),
                    DetailRowWithCopy(
                        label: 'Principal',
                        value: _rp(t.principal),
                        labelWidth: 120),
                    const Divider(),
                    DetailRowWithCopy(
                        label: 'Tayang', value: _rp(t.tayang), labelWidth: 120),
                    const Divider(),
                    DetailRowWithCopy(
                        label: 'Distri', value: _v(t.distri), labelWidth: 120),
                    const Divider(),
                    DetailRowWithCopy(
                        label: 'Sertifikat TKDN',
                        value: _v(t.sertifikatTkd),
                        labelWidth: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isModalEmpty(Object? x) {
    if (x == null) return true;
    final s = x.toString().trim();
    if (s.isEmpty) return true;
    final n = num.tryParse(s.replaceAll(RegExp(r'[^\d.-]'), ''));
    return n == null || n == 0;
  }

  static String? _v(Object? x) {
    if (x == null) return null;
    final s = x.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    return DashboardShell(
      currentRoute: AppRoutes.tkdn,
      onScan: () => context.pushNamed(AppRoutes.scanner),
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: _loadTkdn),
      showHeaderActionInAppBar: true,
      lastSync: lastSyncFormatted,
      onRefresh: _loading ? null : _loadTkdn,
      onNavigate: (route) {
        if (route != AppRoutes.tkdn) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      child: Padding(
        padding: ResponsivePadding.all(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _FiltersSection(
                searchController: _searchController,
                searchFocus: _searchFocus,
                onSearchSubmitted: _onSearchSubmitted,
                sortBy: _sortBy,
                direction: _direction,
                size: _size,
                isTkdn: _isTkdn,
                selectedCategories: _selectedCategories,
                availableKategori: _availableKategori,
                processorController: _processorSearchController,
                ramController: _ramSearchController,
                ssdController: _ssdSearchController,
                hddController: _hddSearchController,
                vgaController: _vgaSearchController,
                layarController: _layarSearchController,
                osController: _osSearchController,
                filterProcessor: _filterProcessor,
                filterRam: _filterRam,
                filterSsd: _filterSsd,
                filterHdd: _filterHdd,
                filterVga: _filterVga,
                filterLayar: _filterLayar,
                filterOs: _filterOs,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                datasetMinPrice: _datasetMinPrice,
                datasetMaxPrice: _datasetMaxPrice,
                onApply: (sortBy, direction, size, isTkdn, categories, proc, ram,
                    ssd, hdd, vga, layar, os, minP, maxP) {
                  setState(() {
                    _sortBy = sortBy;
                    _direction = direction;
                    _size = size;
                    _isTkdn = isTkdn;
                    _selectedCategories = categories;
                    _filterProcessor = proc;
                    _filterRam = ram;
                    _filterSsd = ssd;
                    _filterHdd = hdd;
                    _filterVga = vga;
                    _filterLayar = layar;
                    _filterOs = os;
                    _minPrice = minP;
                    _maxPrice = maxP;
                    _page = 0;
                    _persistFilterState();
                  });
                  // If any spec filter is applied, ensure spec data is loaded
                  final hasSpec = (proc?.isNotEmpty ?? false) ||
                      (ram?.isNotEmpty ?? false) ||
                      (ssd?.isNotEmpty ?? false) ||
                      (hdd?.isNotEmpty ?? false) ||
                      (vga?.isNotEmpty ?? false) ||
                      (layar?.isNotEmpty ?? false) ||
                      (os?.isNotEmpty ?? false);
                  if (hasSpec && !_specFilterDataLoaded) {
                    _loadAllTkdnForSpecFilter();
                  } else {
                    _loadTkdn();
                  }
                },
                onDateRangeClear: () {
                  setState(() {
                    _selectedCategories = [];
                    _isTkdn = null;
                    _filterProcessor = _filterRam = _filterSsd = _filterHdd =
                        _filterVga = _filterLayar = _filterOs = null;
                    _page = 0;
                    _persistFilterState();
                  });
                  _loadTkdn();
                },
                content: RefreshIndicator(
                  onRefresh: _loadTkdn,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    _loadingMessage,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_error != null)
                          _ErrorSection(message: _error!, onRetry: _loadTkdn)
                        else if (_displayItems.isEmpty)
                          _EmptySection(onRetry: _loadTkdn)
                        else
                          _TkdnDeckView(
                              items: _displayItems, onTap: _openDetail),
                        if (!_loading &&
                            (_displayItems.isNotEmpty || _totalPages > 1)) ...[
                          const SizedBox(height: AppSpacing.md),
                          _PaginationBar(
                            page: _page,
                            totalPages: _totalPages,
                            totalElements: _totalElements,
                            categoryNames: _currentPageCategories,
                            onPrev: _totalPages > 0 && _page > 0
                                ? () {
                                    setState(() {
                                      _page--;
                                      _persistFilterState();
                                    });
                                  }
                                : null,
                            onNext: _totalPages > 0 && _page < _totalPages - 1
                                ? () {
                                    setState(() {
                                      _page++;
                                      _persistFilterState();
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris: label + TextField search untuk filter spesifikasi (Prosesor, RAM, dll.)
class _SpecSearchRow extends StatelessWidget {
  const _SpecSearchRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    required this.theme,
    required this.isDesktop,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final ThemeData theme;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 10 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(Icons.search_rounded,
                  size: isDesktop ? 18 : 16,
                  color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: isDesktop ? 10 : 8),
              isDense: true,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FiltersSection extends StatefulWidget {
  const _FiltersSection({
    required this.searchController,
    required this.searchFocus,
    required this.onSearchSubmitted,
    required this.sortBy,
    required this.direction,
    required this.size,
    required this.isTkdn,
    required this.selectedCategories,
    required this.availableKategori,
    required this.processorController,
    required this.ramController,
    required this.ssdController,
    required this.hddController,
    required this.vgaController,
    required this.layarController,
    required this.osController,
    required this.filterProcessor,
    required this.filterRam,
    required this.filterSsd,
    required this.filterHdd,
    required this.filterVga,
    required this.filterLayar,
    required this.filterOs,
    required this.minPrice,
    required this.maxPrice,
    required this.datasetMinPrice,
    required this.datasetMaxPrice,
    required this.onApply,
    required this.onDateRangeClear,
    required this.content,
  });

  final Widget content;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final String sortBy;
  final String direction;
  final int size;
  final bool? isTkdn;
  final List<String> selectedCategories;
  final List<String> availableKategori;
  final TextEditingController processorController;
  final TextEditingController ramController;
  final TextEditingController ssdController;
  final TextEditingController hddController;
  final TextEditingController vgaController;
  final TextEditingController layarController;
  final TextEditingController osController;
  final String? filterProcessor;
  final String? filterRam;
  final String? filterSsd;
  final String? filterHdd;
  final String? filterVga;
  final String? filterLayar;
  final String? filterOs;
  final double? minPrice;
  final double? maxPrice;
  final double datasetMinPrice;
  final double datasetMaxPrice;
  final void Function(
    String sortBy,
    String direction,
    int size,
    bool? isTkdn,
    List<String> categories,
    String? filterProcessor,
    String? filterRam,
    String? filterSsd,
    String? filterHdd,
    String? filterVga,
    String? filterLayar,
    String? filterOs,
    double? minPrice,
    double? maxPrice,
  ) onApply;
  final VoidCallback onDateRangeClear;

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  late String _sortBy;
  late String _direction;
  late int _size;
  bool? _isTkdn;
  List<String> _selectedCategories = [];
  String? _filterProcessor;
  String? _filterRam;
  String? _filterSsd;
  String? _filterHdd;
  String? _filterVga;
  String? _filterLayar;
  String? _filterOs;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
    _isTkdn = widget.isTkdn;
    _selectedCategories = List<String>.from(widget.selectedCategories);
    _filterProcessor = widget.filterProcessor;
    _filterRam = widget.filterRam;
    _filterSsd = widget.filterSsd;
    _filterHdd = widget.filterHdd;
    _filterVga = widget.filterVga;
    _filterLayar = widget.filterLayar;
    _filterOs = widget.filterOs;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;

    widget.processorController.text = _filterProcessor ?? '';
    widget.ramController.text = _filterRam ?? '';
    widget.ssdController.text = _filterSsd ?? '';
    widget.hddController.text = _filterHdd ?? '';
    widget.vgaController.text = _filterVga ?? '';
    widget.layarController.text = _filterLayar ?? '';
    widget.osController.text = _filterOs ?? '';
  }

  @override
  void didUpdateWidget(_FiltersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy ||
        oldWidget.direction != widget.direction ||
        oldWidget.size != widget.size ||
        oldWidget.isTkdn != widget.isTkdn ||
        oldWidget.selectedCategories != widget.selectedCategories ||
        oldWidget.filterProcessor != widget.filterProcessor ||
        oldWidget.filterRam != widget.filterRam ||
        oldWidget.filterSsd != widget.filterSsd ||
        oldWidget.filterHdd != widget.filterHdd ||
        oldWidget.filterVga != widget.filterVga ||
        oldWidget.filterLayar != widget.filterLayar ||
        oldWidget.filterOs != widget.filterOs ||
        oldWidget.minPrice != widget.minPrice ||
        oldWidget.maxPrice != widget.maxPrice) {
      _resetToCurrent();
    }
  }

  String _formatPrice(double val) {
    final s = val.toInt().toString();
    final reversed = s.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks.join('.').split('').reversed.join();
  }

  static const _sortOptions = [
    ('nama', 'Nama'),
    ('kategori', 'Kategori'),
    ('noMerek', 'No. Merek'),
    ('presentase', 'Presentase'),
    ('sertifikatTkd', 'Sertifikat TKD'),
    ('principal', 'Principal'),
    ('modal', 'Modal'),
    ('dealer', 'Dealer'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    final hasSpecFilter = (_filterProcessor?.trim().isNotEmpty ?? false) ||
        (_filterRam?.trim().isNotEmpty ?? false) ||
        (_filterSsd?.trim().isNotEmpty ?? false) ||
        (_filterHdd?.trim().isNotEmpty ?? false) ||
        (_filterVga?.trim().isNotEmpty ?? false) ||
        (_filterLayar?.trim().isNotEmpty ?? false) ||
        (_filterOs?.trim().isNotEmpty ?? false);

    final activeFilterBadges = <Widget>[];
    if (widget.isTkdn != null) {
      activeFilterBadges.add(
        FilterBadge(
          label: widget.isTkdn! ? 'TKDN: Ya' : 'TKDN: Tidak',
          onRemove: () => widget.onApply(
            widget.sortBy,
            widget.direction,
            widget.size,
            null,
            widget.selectedCategories,
            widget.filterProcessor,
            widget.filterRam,
            widget.filterSsd,
            widget.filterHdd,
            widget.filterVga,
            widget.filterLayar,
            widget.filterOs,
            widget.minPrice,
            widget.maxPrice,
          ),
        ),
      );
    }
    if (widget.selectedCategories.isNotEmpty) {
      activeFilterBadges.add(
        FilterBadge(
          label: 'Kategori: ${widget.selectedCategories.length} Terpilih',
          onRemove: () => widget.onApply(
            widget.sortBy,
            widget.direction,
            widget.size,
            widget.isTkdn,
            [],
            widget.filterProcessor,
            widget.filterRam,
            widget.filterSsd,
            widget.filterHdd,
            widget.filterVga,
            widget.filterLayar,
            widget.filterOs,
            widget.minPrice,
            widget.maxPrice,
          ),
        ),
      );
    }
    if ((widget.filterProcessor?.trim().isNotEmpty ?? false) ||
        (widget.filterRam?.trim().isNotEmpty ?? false) ||
        (widget.filterSsd?.trim().isNotEmpty ?? false) ||
        (widget.filterHdd?.trim().isNotEmpty ?? false) ||
        (widget.filterVga?.trim().isNotEmpty ?? false) ||
        (widget.filterLayar?.trim().isNotEmpty ?? false) ||
        (widget.filterOs?.trim().isNotEmpty ?? false)) {
      activeFilterBadges.add(
        FilterBadge(
          label: 'Spesifikasi',
          onRemove: () => widget.onApply(
            widget.sortBy,
            widget.direction,
            widget.size,
            widget.isTkdn,
            widget.selectedCategories,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            widget.minPrice,
            widget.maxPrice,
          ),
        ),
      );
    }
    if (widget.minPrice != null || widget.maxPrice != null) {
      activeFilterBadges.add(
        FilterBadge(
          label: 'Harga',
          onRemove: () => widget.onApply(
            widget.sortBy,
            widget.direction,
            widget.size,
            widget.isTkdn,
            widget.selectedCategories,
            widget.filterProcessor,
            widget.filterRam,
            widget.filterSsd,
            widget.filterHdd,
            widget.filterVga,
            widget.filterLayar,
            widget.filterOs,
            null,
            null,
          ),
        ),
      );
    }

    return FixedSearchFilterLayout(
      searchBar: ModernSearchBar(
        controller: widget.searchController,
        focusNode: widget.searchFocus,
        onSubmitted: widget.onSearchSubmitted,
        hintText: 'Cari nama, kategori, no. merek...',
        onChanged: (_) {},
      ),
      filterTitle: 'Filter & Urutkan',
      activeFilterBadges:
          activeFilterBadges.isNotEmpty ? activeFilterBadges : null,
      filterContentBuilder: (close, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FilterLabel('TKDN'),
                    FilterSegmentedButton<bool?>(
                      value: _isTkdn,
                      onChanged: (v) {
                        setState(() => _isTkdn = v);
                        refresh();
                      },
                      segments: const {
                        true: (
                          label: 'Ya',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        false: (
                          label: 'Tidak',
                          icon: Icons.cancel_outlined,
                        ),
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FilterLabel('Kategori'),
                    widget.availableKategori.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.md),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Memuat...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : MultiSelectSearchableDropdown<String>(
                            label: 'Kategori',
                            values: _selectedCategories,
                            options: widget.availableKategori,
                            onChanged: (v) {
                              setState(() => _selectedCategories = v);
                              refresh();
                            },
                            hintText: 'Semua Kategori',
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Spesifikasi',
            icon: Icons.computer_rounded,
            children: [
              _SpecSearchRow(
                label: 'Prosesor',
                hint: 'e.g. i5, Ryzen',
                controller: widget.processorController,
                onChanged: (v) {
                  setState(() =>
                      _filterProcessor = v.trim().isEmpty ? null : v.trim());
                  refresh();
                },
                theme: theme,
                isDesktop: isDesktop,
              ),
              _SpecSearchRow(
                label: 'RAM',
                hint: 'e.g. 8, 16',
                controller: widget.ramController,
                onChanged: (v) {
                  setState(
                      () => _filterRam = v.trim().isEmpty ? null : v.trim());
                  refresh();
                },
                theme: theme,
                isDesktop: isDesktop,
              ),
              _SpecSearchRow(
                label: 'SSD',
                hint: 'e.g. 256, 512',
                controller: widget.ssdController,
                onChanged: (v) {
                  setState(
                      () => _filterSsd = v.trim().isEmpty ? null : v.trim());
                  refresh();
                },
                theme: theme,
                isDesktop: isDesktop,
              ),
              _SpecSearchRow(
                label: 'HDD',
                hint: 'e.g. 1TB',
                controller: widget.hddController,
                onChanged: (v) {
                  setState(
                      () => _filterHdd = v.trim().isEmpty ? null : v.trim());
                  refresh();
                },
                theme: theme,
                isDesktop: isDesktop,
              ),
              _SpecSearchRow(
                label: 'VGA',
                hint: 'e.g. GTX, integrated',
                controller: widget.vgaController,
                onChanged: (v) {
                  setState(
                      () => _filterVga = v.trim().isEmpty ? null : v.trim());
                  refresh();
                },
                theme: theme,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 16),
              const FilterLabel('Harga (Modal)'),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(
                  _minPrice ?? widget.datasetMinPrice,
                  _maxPrice ?? widget.datasetMaxPrice,
                ),
                min: widget.datasetMinPrice,
                max: widget.datasetMaxPrice > widget.datasetMinPrice
                    ? widget.datasetMaxPrice
                    : widget.datasetMinPrice + 1,
                divisions: 100,
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.primary.withOpacity(0.12),
                labels: RangeLabels(
                  'Rp ${_formatPrice(_minPrice ?? widget.datasetMinPrice)}',
                  'Rp ${_formatPrice(_maxPrice ?? widget.datasetMaxPrice)}',
                ),
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                  refresh();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${_formatPrice(_minPrice ?? widget.datasetMinPrice)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(_maxPrice ?? widget.datasetMaxPrice)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          FilterFooter(
            onApply: () {
              widget.onApply(
                _sortBy,
                _direction,
                _size,
                _isTkdn,
                _selectedCategories,
                _filterProcessor,
                _filterRam,
                _filterSsd,
                _filterHdd,
                _filterVga,
                _filterLayar,
                _filterOs,
                _minPrice,
                _maxPrice,
              );
              close();
            },
            onReset: () {
              widget.onDateRangeClear();
              setState(() {
                _sortBy = 'kategori';
                _direction = 'asc';
                _size = 50;
                _isTkdn = true;
                _selectedCategories = [];
                _filterProcessor = null;
                _filterRam = null;
                _filterSsd = null;
                _filterHdd = null;
                _filterVga = null;
                _filterLayar = null;
                _filterOs = null;
                _minPrice = null;
                _maxPrice = null;
              });
              widget.onApply(
                _sortBy,
                _direction,
                _size,
                _isTkdn,
                _selectedCategories,
                _filterProcessor,
                _filterRam,
                _filterSsd,
                _filterHdd,
                _filterVga,
                _filterLayar,
                _filterOs,
                _minPrice,
                _maxPrice,
              );
              close();
            },
          ),
        ],
      ),
      child: widget.content,
    );
  }
}

class _TkdnDeckView extends StatelessWidget {
  const _TkdnDeckView({required this.items, required this.onTap});
  final List<Tkdn> items;
  final void Function(Tkdn) onTap;

  static String _rp(Object? x) {
    if (x == null) return '—';
    final n = num.tryParse(x.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
    if (n == null) return x.toString();
    final String formatted = _formatNumber(n);
    return 'Rp $formatted';
  }

  static String _formatNumber(num value) {
    if (value % 1 != 0) {
      final parts = value.toString().split('.');
      final integerPart = _addThousandSeparator(parts[0]);
      return '$integerPart,${parts[1]}';
    }
    return _addThousandSeparator(value.toInt().toString());
  }

  static String _addThousandSeparator(String number) {
    final reversed = number.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks.join('.').split('').reversed.join();
  }

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Tkdn>> groupedItems = {};
    for (var item in items) {
      String category = _v(item.kategori).toUpperCase();
      if (category == '—') category = 'LAINNYA';
      if (groupedItems[category] == null) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    // Sort items within each category by name
    for (var category in groupedItems.keys) {
      groupedItems[category]!.sort((a, b) => _v(a.nama).compareTo(_v(b.nama)));
    }

    final sortedCategories = groupedItems.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final categoryItems = groupedItems[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F6FC),
                  border: Border(
                    left: BorderSide(color: Color(0xFF1E3A8A), width: 4),
                  ),
                ),
                child: Text(
                  TkdnCategories.getDisplayName(category),
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              ...categoryItems.asMap().entries.map((entry) {
                final int itemIndex = entry.key;
                final Tkdn item = entry.value;

                return InkWell(
                  onTap: () => onTap(item),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _v(item.nama),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _v(item.spesifikasi),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _rp(item.modal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Tidak ada data TKDN',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalElements,
    this.categoryNames = const [],
    this.onPrev,
    this.onNext,
  });
  final int page;
  final int totalPages;
  final int totalElements;
  final List<String> categoryNames;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (categoryNames.isNotEmpty)
                  Text(
                    categoryNames.join(', '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Halaman ${page + 1} dari ${totalPages > 0 ? totalPages : 1} • Total $totalElements item',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton.filled(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProcessedTkdnData {
  final List<Tkdn> allItems;
  final List<Tkdn> filteredItems;
  final double datasetMinPrice;
  final double datasetMaxPrice;
  ProcessedTkdnData({
    required this.allItems,
    required this.filteredItems,
    required this.datasetMinPrice,
    required this.datasetMaxPrice,
  });
}

/// Top-level function for compute()
ProcessedTkdnData _processTkdnData(Map<String, dynamic> params) {
  final List<dynamic> rawData = params['rawData'];
  final String? fProc = params['filterProcessor'];
  final String? fRam = params['filterRam'];
  final String? fSsd = params['filterSsd'];
  final String? fHdd = params['filterHdd'];
  final String? fVga = params['filterVga'];
  final String? fLayar = params['filterLayar'];
  final String? fOs = params['filterOs'];
  final double? minP = params['minPrice'];
  final double? maxP = params['maxPrice'];

  final List<Tkdn> allItems = rawData
      .map((e) {
        if (e is Map) return Tkdn.fromJson(Map<String, dynamic>.from(e));
        return null;
      })
      .whereType<Tkdn>()
      .toList();
      
  double dataMin = double.infinity;
  double dataMax = double.negativeInfinity;
  
  for (final item in allItems) {
    if (item.modal != null) {
      final val = double.tryParse(item.modal.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
      if (val != null && val > 0) {
        if (val < dataMin) dataMin = val;
        if (val > dataMax) dataMax = val;
      }
    }
  }
  
  if (dataMin == double.infinity) dataMin = 0;
  if (dataMax == double.negativeInfinity) dataMax = 1000000;

  final filtered = allItems.where((t) {
    if (_isModalEmptyHelper(t.modal)) return false;

    if (fProc != null && fProc.trim().isNotEmpty) {
      final v = _specValHelper(t.processor);
      if (v == null || !v.toLowerCase().contains(fProc.trim().toLowerCase())) {
        return false;
      }
    }
    if (fRam != null && fRam.trim().isNotEmpty) {
      final v = _specValHelper(t.ram);
      if (v == null || !v.toLowerCase().contains(fRam.trim().toLowerCase())) {
        return false;
      }
    }
    if (fSsd != null && fSsd.trim().isNotEmpty) {
      final v = _specValHelper(t.ssd);
      if (v == null || !v.toLowerCase().contains(fSsd.trim().toLowerCase())) {
        return false;
      }
    }
    if (fHdd != null && fHdd.trim().isNotEmpty) {
      final v = _specValHelper(t.hdd);
      if (v == null || !v.toLowerCase().contains(fHdd.trim().toLowerCase())) {
        return false;
      }
    }
    if (fVga != null && fVga.trim().isNotEmpty) {
      final v = _specValHelper(t.vga);
      if (v == null || !v.toLowerCase().contains(fVga.trim().toLowerCase())) {
        return false;
      }
    }
    if (fLayar != null && fLayar.trim().isNotEmpty) {
      final v = _specValHelper(t.layar);
      if (v == null || !v.toLowerCase().contains(fLayar.trim().toLowerCase())) {
        return false;
      }
    }
    if (fOs != null && fOs.trim().isNotEmpty) {
      final v = _specValHelper(t.os);
      if (v == null || !v.toLowerCase().contains(fOs.trim().toLowerCase())) {
        return false;
      }
    }
    
    // Price range filter
    if (t.modal != null) {
      final val = double.tryParse(t.modal.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
      if (val != null) {
        if (minP != null && val < minP) return false;
        if (maxP != null && val > maxP) return false;
      }
    }
    
    return true;
  }).toList();

  return ProcessedTkdnData(
    allItems: allItems,
    filteredItems: filtered,
    datasetMinPrice: dataMin,
    datasetMaxPrice: dataMax,
  );
}

// Helpers duplicated for Isolate (since they are top-level anyway or easily replicable)
bool _isModalEmptyHelper(Object? x) {
  if (x == null) return true;
  final s = x.toString().trim();
  if (s.isEmpty) return true;
  final n = num.tryParse(s.replaceAll(RegExp(r'[^\d.-]'), ''));
  return n == null || n == 0;
}

String? _specValHelper(Object? x) {
  if (x == null) return null;
  final s = x.toString().trim();
  return s.isEmpty ? null : s;
}
