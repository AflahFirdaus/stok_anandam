import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/core/widgets/deck_view.dart';
import '../../injection.dart';
import '../../token_storage.dart';
import '../layout/dashboard_shell.dart';
import '../shared/item_deck_card.dart';
import '../shared/modern_filter.dart';
import '../shared/detail_row_with_copy.dart';
import '../shared/responsive_deck_grid.dart';
import '../shared/migration_sync_mixin.dart';
import '../dashboard/widgets/migration_dialog.dart';

/// Satu baris stok: model API + field dari DB (modal, final_pricelist, spesifikasi).
class WarehouseStock {
  final String warehouse;
  final int stok;

  WarehouseStock({required this.warehouse, required this.stok});

  factory WarehouseStock.fromJson(Map<String, dynamic> json) {
    return WarehouseStock(
      warehouse: json['warehouse']?.toString() ?? 'Unknown',
      stok: int.tryParse(json['stok']?.toString() ?? '0') ?? 0,
    );
  }
}

class StockRow {
  StockRow({
    required this.stock,
    this.modal,
    this.finalPricelist,
    this.spesifikasi,
    this.warehouses = const [],
    this.totalStok,
    this.lastSalesDate,
  });

  final Stock stock;
  final Object? modal;
  final Object? finalPricelist;
  final String? spesifikasi;
  final List<WarehouseStock> warehouses;
  final int? totalStok;
  final String? lastSalesDate;

  static StockRow fromJson(Map<String, dynamic> json) {
    final stock = Stock.fromJson(json);
    final modal = json['modal'];
    final finalPricelist = json['final_pricelist'] ?? json['finalPricelist'];
    final spesifikasi = json['spesifikasi']?.toString().trim();
    final totalStok = int.tryParse(json['totalStok']?.toString() ?? '');
    final lastSalesDate = json['lastSalesDate']?.toString().trim();

    final warehouseList = <WarehouseStock>[];
    if (json['warehouses'] is List) {
      for (final w in json['warehouses']) {
        if (w is Map<String, dynamic>) {
          warehouseList.add(WarehouseStock.fromJson(w));
        }
      }
    }

    return StockRow(
      stock: stock,
      modal: modal,
      finalPricelist: finalPricelist,
      spesifikasi: spesifikasi?.isEmpty == true ? null : spesifikasi,
      warehouses: warehouseList,
      totalStok: totalStok,
      lastSalesDate: lastSalesDate?.isEmpty == true ? null : lastSalesDate,
    );
  }
}

/// State filter Stok disimpan agar saat pindah menu lalu balik, filter tetap.
class _StockFilterState {
  _StockFilterState._();
  static String search = '';
  static int page = 0;
  static int size = 20;
  static String sortBy = 'itemName';
  static String direction = 'asc';
  static String? filterKategoriCode;

  static void reset() {
    search = '';
    page = 0;
    size = 20;
    sortBy = 'itemName';
    direction = 'asc';
    filterKategoriCode = null;
  }
}

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_StockFilterState.reset);
  }

  @override
  Widget build(BuildContext context) {
    return const _StockContent();
  }
}

class _StockContent extends StatefulWidget {
  const _StockContent();

  @override
  State<_StockContent> createState() => _StockContentState();
}

class _StockContentState extends State<_StockContent> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;

  /// Disimpan sebagai dynamic agar hot reload tidak memicu type error bila state lama masih List<Stock>.
  dynamic _itemsRaw = <StockRow>[];

  /// Selalu mengembalikan List<StockRow>; mengonversi dari List<Stock> bila perlu (state lama).
  List<StockRow> get _items {
    final r = _itemsRaw;
    if (r is List<StockRow>) return r;
    if (r is List<Stock>) {
      return (r)
          .map((s) => StockRow(
              stock: s, modal: null, finalPricelist: null, spesifikasi: null))
          .toList();
    }
    return <StockRow>[];
  }

  int _page = 0;
  int _size = 20;
  int _totalElements = 0;
  int _totalPages = 0;
  String _search = '';
  String _sortBy = 'itemName';
  String _direction = 'asc';
  String? _filterKategoriCode;
  List<String> _availableCategoryCodes = [];
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  void _restoreFilterState() {
    _search = _StockFilterState.search;
    _searchController.text = _search;
    _page = _StockFilterState.page;
    _size = _StockFilterState.size;
    _sortBy = _StockFilterState.sortBy;
    _direction = _StockFilterState.direction;
    _filterKategoriCode = _StockFilterState.filterKategoriCode;
  }

  void _persistFilterState() {
    _StockFilterState.search = _search;
    _StockFilterState.page = _page;
    _StockFilterState.size = _size;
    _StockFilterState.sortBy = _sortBy;
    _StockFilterState.direction = _direction;
    _StockFilterState.filterKategoriCode = _filterKategoriCode;
  }

  @override
  void initState() {
    super.initState();
    _restoreFilterState();
    fetchLastSync();
    _loadStocks();
    _loadAllCategoryCodes();
    _searchController.addListener(_onSearchChanged);
  }

  /// Memuat semua kode kategori dari seluruh halaman (bukan hanya page 1)
  /// agar dropdown filter menampilkan seluruh kategori.
  Future<void> _loadAllCategoryCodes() async {
    final dio = getIt<MyApiClient>().dio;
    const pageSize = 100;
    final allCodes = <String>{};
    int page = 0;
    int totalPages = 1;
    do {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': pageSize,
        'sortBy': 'kategoriItemcode',
        'direction': 'asc',
      };
      try {
        final response = await dio.get<Map<String, dynamic>>(
          '/api/v1/stock',
          queryParameters: queryParams,
        );
        final data = response.data;
        if (data == null) break;
        final dataPayload = data['data'];
        final pagingPayload = data['paging'];
        final status = data['status'];
        if (!isResponseSuccess(status)) break;
        List<StockRow> items = [];
        if (dataPayload is List) {
          items = _parseContent(dataPayload);
          if (pagingPayload is Map) {
            final p = Map<String, dynamic>.from(
                pagingPayload.map((k, v) => MapEntry(k?.toString() ?? '', v)));
            totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 1;
            if (totalPages < 1) totalPages = 1;
          }
        } else if (dataPayload is Map) {
          final content = dataPayload['content'];
          items = _parseContent(content);
          final te = dataPayload['totalElements'];
          final tp = dataPayload['totalPages'];
          totalPages =
              (tp is int) ? tp : (int.tryParse(tp?.toString() ?? '0') ?? 1);
          if (totalPages < 1) totalPages = 1;
        }
        for (final row in items) {
          final code = row.stock.kategoriItemcode?.toString().trim();
          if (code != null && code.isNotEmpty) allCodes.add(code);
        }
      } catch (_) {
        break;
      }
      page++;
    } while (page < totalPages && mounted);
    if (!mounted) return;
    setState(() {
      _availableCategoryCodes = allCodes.toList()..sort();
    });
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
      _loadStocks();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static List<StockRow> _parseContent(Object? content) {
    if (content == null || content is! List) return <StockRow>[];
    final result = <StockRow>[];
    for (final e in content) {
      if (e is StockRow) {
        result.add(e);
      } else if (e is Map) {
        result.add(StockRow.fromJson(Map<String, dynamic>.from(e)));
      } else if (e is Stock) {
        result.add(StockRow(
            stock: e, modal: null, finalPricelist: null, spesifikasi: null));
      }
    }
    return result;
  }

  Future<void> _loadStocks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hasKategoriFilter =
          _filterKategoriCode != null && _filterKategoriCode!.trim().isNotEmpty;
      if (hasKategoriFilter) {
        await _loadStocksWithDio();
      } else {
        await _loadStocksWithApi();
      }
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final body = e.response!.data as Map<Object?, Object?>;
        final status = body['status'];
        final data = body['data'];
        final paging = body['paging'];
        if (isResponseSuccess(status) && data is List) {
          final items = _parseContent(data);
          int totalElements = 0;
          int totalPages = 1;
          if (paging is Map) {
            final p = Map<String, dynamic>.from(
                paging.map((k, v) => MapEntry(k?.toString() ?? '', v)));
            totalElements =
                int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
            totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 1;
            if (totalPages < 1) totalPages = 1;
          }
          if (mounted) {
            setState(() {
              _itemsRaw = List<StockRow>.from(items);
              _totalElements = totalElements;
              _totalPages = totalPages;
              _loading = false;
              _persistFilterState();
            });
          }
          return;
        }
      }
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
    }
  }

  Future<void> _loadStocksWithApi() async {
    final dio = getIt<MyApiClient>().dio;
    final queryParams = <String, dynamic>{
      'page': _page,
      'size': _size,
      'sortBy': _sortBy,
      'direction': _direction,
      if (_search.trim().isNotEmpty) 'search': _search.trim(),
    };
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/stock',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) {
      setState(() {
        _error = 'Respons tidak valid';
        _loading = false;
      });
      return;
    }

    final dataPayload = data['data'];
    final pagingPayload = data['paging'];
    final status = data['status'];

    if (isResponseSuccess(status)) {
      List<StockRow> items = [];
      int totalElements = 0;
      int totalPages = 1;

      if (dataPayload is List) {
        // Format legacy: data = [items...]
        items = _parseContent(dataPayload);
        if (pagingPayload is Map) {
          final p = Map<String, dynamic>.from(
              pagingPayload.map((k, v) => MapEntry(k?.toString() ?? '', v)));
          totalElements = int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
          totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 1;
        }
      } else if (dataPayload is Map) {
        // Format standard: data = { content: [...], totalElements: ... }
        final content = dataPayload['content'];
        items = _parseContent(content);
        final te = dataPayload['totalElements'];
        final tp = dataPayload['totalPages'];
        totalElements =
            (te is int) ? te : (int.tryParse(te?.toString() ?? '0') ?? 0);
        totalPages =
            (tp is int) ? tp : (int.tryParse(tp?.toString() ?? '0') ?? 1);
      }

      if (mounted) {
        setState(() {
          _itemsRaw = List<StockRow>.from(items);
          _totalElements = totalElements;
          _totalPages = totalPages < 1 ? 1 : totalPages;
          _loading = false;
          _persistFilterState();
        });
      }
    } else {
      setState(() {
        _error = data['message']?.toString() ?? 'Gagal memuat data.';
        _loading = false;
      });
    }
  }

  Future<void> _loadStocksWithDio() async {
    final dio = getIt<MyApiClient>().dio;
    final queryParams = <String, dynamic>{
      'page': _page,
      'size': _size,
      'sortBy': _sortBy,
      'direction': _direction,
      if (_search.trim().isNotEmpty) 'search': _search.trim(),
      'kategori': _filterKategoriCode!.trim(),
    };
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/stock',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) {
      setState(() {
        _error = 'Respons tidak valid';
        _loading = false;
      });
      return;
    }
    // Backend bisa mengirim data sebagai array + paging terpisah
    final dataPayload = data['data'];
    final pagingPayload = data['paging'];
    final status = data['status'];
    if (isResponseSuccess(status) && dataPayload is List) {
      final items = _parseContent(dataPayload);
      int totalElements = 0;
      int totalPages = 1;
      if (pagingPayload is Map) {
        final p = Map<String, dynamic>.from(
            pagingPayload.map((k, v) => MapEntry(k?.toString() ?? '', v)));
        totalElements = int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
        totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 1;
        if (totalPages < 1) totalPages = 1;
      }
      setState(() {
        _itemsRaw = List<StockRow>.from(items);
        _totalElements = totalElements;
        _totalPages = totalPages;
        _loading = false;
        _persistFilterState();
      });
      return;
    }
    // Fallback: format lama (data = object dengan content)
    final parsed = WebResponsePageStock.fromJson(data);
    final pageData = parsed.data;
    if (isResponseSuccess(parsed.status) && pageData != null) {
      final items = _parseContent(pageData.content);
      setState(() {
        _itemsRaw = List<StockRow>.from(items);
        _totalElements = (pageData.totalElements is int)
            ? pageData.totalElements as int
            : int.tryParse(pageData.totalElements?.toString() ?? '0') ?? 0;
        _totalPages = (pageData.totalPages is int)
            ? pageData.totalPages as int
            : int.tryParse(pageData.totalPages?.toString() ?? '0') ?? 0;
        _loading = false;
        _persistFilterState();
      });
    } else {
      setState(() {
        _error = parsed.message?.toString() ?? 'Gagal memuat data.';
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
    _loadStocks();
  }

  void _openDetail(StockRow row) async {
    final id = row.stock.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final api = getIt<StockControllerApi>();
      final response = await api.getStockDetail(id: id);
      if (!mounted) return;
      Navigator.of(context).pop();
      final detail = response.data?.data;
      if (detail != null) {
        _showDetailSheet(
          detail,
          row: StockRow(
            stock: detail,
            modal: row.modal,
            finalPricelist: row.finalPricelist,
            spesifikasi: row.spesifikasi,
            warehouses: row.warehouses,
            totalStok: row.totalStok,
            lastSalesDate: row.lastSalesDate,
          ),
        );
      } else {
        _showDetailSheet(
          row.stock,
          row: row,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail: $e')),
      );
    }
  }

  void _showDetailSheet(Stock s, {required StockRow row}) {
    final modal = row.modal;
    final finalPricelist = row.finalPricelist;
    final spesifikasi = row.spesifikasi;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _str(s.itemName) ?? _str(s.itemCode) ?? '—',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.content_copy_rounded,
                                size: 18),
                            onPressed: () {
                              final text =
                                  _str(s.itemName) ?? _str(s.itemCode) ?? '';
                              if (text.isNotEmpty && text != '—') {
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Disalin ke clipboard'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            color: Colors.blue.shade600,
                            tooltip: 'Salin Nama Barang',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (spesifikasi != null && spesifikasi.isNotEmpty)
                        DetailRowWithCopy(
                            label: 'Spesifikasi',
                            value: spesifikasi,
                            labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Modal Awal',
                          value: _formatRupiah(s.hargaHpp),
                          labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Modal Final',
                          value: _formatRupiah(modal ?? s.hargaHpp),
                          labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Pricelist',
                          value: _formatRupiah(finalPricelist),
                          labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Kode Item',
                          value: _str(s.itemCode),
                          labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Kategori',
                          value: _str(s.kategoriNama),
                          labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Kode Kategori',
                          value: _str(s.kategoriItemcode),
                          labelWidth: 120),
                      if (row.lastSalesDate != null)
                        DetailRowWithCopy(
                            label: 'Tanggal Pembelian Terakhir',
                            value: row.lastSalesDate,
                            labelWidth: 120),
                      DetailRowWithCopy(
                          label: 'Total Stok',
                          value: _str(row.totalStok ?? s.finalStok),
                          labelWidth: 120),
                      if (row.warehouses.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'Rincian Gudang:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        ...row.warehouses.map((w) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 12, bottom: 2),
                              child: Row(
                                children: [
                                  Text(
                                    '${w.warehouse}: ',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF374151)),
                                  ),
                                  Text(
                                    '${w.stok}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937)),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 12),
                      ] else
                        DetailRowWithCopy(
                            label: 'Gudang',
                            value: _str(s.warehouse),
                            labelWidth: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _formatRupiah(Object? v) {
    if (v == null) return '—';
    final n = num.tryParse(v.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
    if (n == null) return v.toString();

    // Format angka penuh dengan pemisah ribuan (titik)
    final String formatted = _formatNumber(n);
    return ' $formatted';
  }

  static String _formatNumber(num value) {
    // Handle angka desimal
    if (value % 1 != 0) {
      // Ada desimal, tampilkan dengan desimal
      final parts = value.toString().split('.');
      final integerPart = _addThousandSeparator(parts[0]);
      return '$integerPart,${parts[1]}';
    } else {
      // Angka bulat, tampilkan tanpa desimal
      return _addThousandSeparator(value.toInt().toString());
    }
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final theme = Theme.of(context);

    return DashboardShell(
      currentRoute: AppRoutes.stok,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: _loadStocks),
      lastSync: lastSyncFormatted,
      showHeaderActionInAppBar: true,

      onRefresh: _loading ? null : _loadStocks,
      onNavigate: (route) {
        if (route != AppRoutes.stok) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      child: Container(
        color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? AppSpacing.lg : AppSpacing.xl,
            isMobile ? AppSpacing.lg : AppSpacing.xl,
            isMobile ? AppSpacing.lg : AppSpacing.xl,
            AppSpacing.xxl,
          ),
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
                  categoryCode: _filterKategoriCode,
                  availableCategoryCodes: _availableCategoryCodes,
                  onApply: (sortBy, direction, size, cat) {
                    setState(() {
                      _sortBy = sortBy;
                      _direction = direction;
                      _size = size;
                      _filterKategoriCode = cat;
                      _page = 0;
                      _persistFilterState();
                    });
                    _loadStocks();
                  },
                  onCategoryCodeChanged: (v) {
                    setState(() {
                      _filterKategoriCode = v;
                      _page = 0;
                      _persistFilterState();
                    });
                    _loadStocks();
                  },
                  content: RefreshIndicator(
                    onRefresh: _loadStocks,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_loading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_error != null)
                            _ErrorSection(
                                message: _error!, onRetry: _loadStocks)
                          else if (_items.isEmpty)
                            _EmptySection(onRetry: _loadStocks)
                          else
                            DeckCard(
                              title: 'Data Stok',
                              subtitle: '$_totalElements item',
                              child: _StockDeckView(
                                  items: _items, onTap: _openDetail),
                            ),
                          if (!_loading && _items.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _PaginationBar(
                              page: _page,
                              totalPages: _totalPages,
                              totalElements: _totalElements,
                              onPrev: (_totalPages > 0 && _page > 0)
                                  ? () {
                                      setState(() {
                                        _page--;
                                        _persistFilterState();
                                      });
                                      _loadStocks();
                                    }
                                  : null,
                              onNext:
                                  (_totalPages > 0 && _page < _totalPages - 1)
                                      ? () {
                                          setState(() {
                                            _page++;
                                            _persistFilterState();
                                          });
                                          _loadStocks();
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
    this.categoryCode,
    this.availableCategoryCodes = const [],
    required this.onApply,
    required this.onCategoryCodeChanged,
    required this.content,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final String sortBy;
  final String direction;
  final int size;
  final String? categoryCode;
  final List<String> availableCategoryCodes;
  final void Function(
    String sortBy,
    String direction,
    int size,
    String? categoryCode,
  ) onApply;
  final void Function(String?) onCategoryCodeChanged;
  final Widget content;

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  late String _sortBy;
  late String _direction;
  late int _size;
  String? _categoryCode;

  @override
  void initState() {
    super.initState();
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
    _categoryCode = widget.categoryCode;
  }

  @override
  void didUpdateWidget(_FiltersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy ||
        oldWidget.direction != widget.direction ||
        oldWidget.size != widget.size ||
        oldWidget.categoryCode != widget.categoryCode) {
      _resetToCurrent();
    }
  }

  static const _sortOptions = [
    ('itemName', 'Nama Barang'),
    ('itemCode', 'Kode Barang'),
    ('finalStok', 'Jumlah Stok'),
    ('kategoriNama', 'Kategori'),
    ('warehouse', 'Gudang'),
    ('modalFinal', 'Modal Final'),
    ('hargaHpp', 'Modal Awal'),
    ('finalPricelist', 'Pricelist'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return FixedSearchFilterLayout(
      searchBar: ModernSearchBar(
        controller: widget.searchController,
        focusNode: widget.searchFocus,
        onSubmitted: widget.onSearchSubmitted,
        hintText: 'Cari kode, nama, kategori...',
        onChanged: (_) {},
      ),
      filterTitle: 'Filter & Urutkan',
      activeFilterBadges:
          widget.categoryCode != null && widget.categoryCode!.isNotEmpty
              ? [
                  FilterBadge(
                    label: widget.categoryCode!,
                    onRemove: () => widget.onCategoryCodeChanged(null),
                  ),
                ]
              : null,
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
                    FilterLabel('Urutkan berdasarkan'),
                    SearchableDropdown<String>(
                      label: 'Urutkan berdasarkan',
                      value: _sortBy,
                      options: _sortOptions.map((e) => e.$1).toList(),
                      displayText: (s) => _sortOptions
                          .firstWhere((e) => e.$1 == s, orElse: () => (s, s))
                          .$2,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _sortBy = v);
                          refresh();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilterLabel('Arah'),
                    FilterSegmentedButton<String>(
                      value: _direction,
                      onChanged: (v) {
                        setState(() => _direction = v);
                        refresh();
                      },
                      segments: const {
                        'asc': (
                          label: 'A–Z',
                          icon: Icons.arrow_upward_rounded,
                        ),
                        'desc': (
                          label: 'Z–A',
                          icon: Icons.arrow_downward_rounded,
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Kategori
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilterLabel('Kategori'),
              widget.availableCategoryCodes.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Memuat kategori...',
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
                  : SearchableDropdown<String>(
                      label: 'Kategori',
                      hintText: 'Semua Kategori',
                      value: _categoryCode,
                      options: widget.availableCategoryCodes,
                      onChanged: (v) {
                        setState(() => _categoryCode = v);
                        refresh();
                      },
                    ),
            ],
          ),

          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilterLabel('Item per halaman'),
              CompactFilterDropdown<int>(
                label: 'Item per halaman',
                value: _size,
                options: const [10, 20, 50, 100],
                displayText: (s) => '$s item',
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _size = v);
                    refresh();
                  }
                },
              ),
            ],
          ),

          FilterFooter(
            onApply: () {
              widget.onApply(
                _sortBy,
                _direction,
                _size,
                _categoryCode,
              );
              close();
            },
            onReset: () {
              widget.onCategoryCodeChanged(null);
              setState(() {
                _sortBy = 'itemName';
                _direction = 'asc';
                _size = 20;
                _categoryCode = null;
              });
              widget.onApply(
                _sortBy,
                _direction,
                _size,
                _categoryCode,
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

class _StockDeckView extends StatelessWidget {
  const _StockDeckView({required this.items, required this.onTap});

  final List<StockRow> items;
  final void Function(StockRow) onTap;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  static String _rp(Object? x) {
    if (x == null) return '—';
    final n = num.tryParse(x.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
    if (n == null) return x.toString();
    final String formatted = _formatNumber(n);
    return ' $formatted';
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveDeckGrid(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final row = items[i];
        final s = row.stock;
        final modalStr = _rp(row.modal ?? s.hargaHpp);
        final pricelistStr = _rp(row.finalPricelist);
        return DataDeckCard(
          title: _v(s.itemName),
          subtitle: _v(row.spesifikasi),
          rows: [
            (label: 'Stok', value: _v(row.totalStok ?? s.finalStok)),
            (label: 'Modal Final', value: modalStr),
            (label: 'Pricelist', value: pricelistStr),
          ],
          onTap: () => onTap(row),
          highlightLastValue: true,
        );
      },
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
          Icon(Icons.inventory_2_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Tidak ada data stok',
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
    this.onPrev,
    this.onNext,
  });
  final int page;
  final int totalPages;
  final int totalElements;
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
            child: Text(
              'Halaman ${page + 1} dari ${totalPages > 0 ? totalPages : 1} • Total $totalElements item',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade800),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
