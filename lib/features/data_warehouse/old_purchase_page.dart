import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';
import '../layout/dashboard_shell.dart';
import '../shared/responsive_table.dart';
import '../shared/responsive_padding.dart';
import '../shared/item_deck_card.dart';
import '../shared/modern_filter.dart';
import '../shared/detail_row_with_copy.dart';
import '../shared/responsive_deck_grid.dart';
import '../shared/migration_sync_mixin.dart';
import '../shared/custom_pluto_grid.dart';
import '../shared/grid_helpers.dart';

class OldPurchasePage extends StatelessWidget {
  const OldPurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OldPurchaseContent();
  }
}

class _OldPurchaseContent extends StatefulWidget {
  const _OldPurchaseContent();

  @override
  State<_OldPurchaseContent> createState() => _OldPurchaseContentState();
}

class _OldPurchaseContentState extends State<_OldPurchaseContent>
    with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  int _page = 0;
  int _size = 100;
  int _totalElements = 0;
  int _totalPages = 0;
  Object? _totalGrandSum;
  Object? _totalQty;
  String _search = '';
  String _sortBy = 'docDate';
  String _direction = 'desc';
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _loadPurchase();
    _searchController.addListener(_onSearchChanged);
    fetchLastSync();
  }

  void _onSearchChanged() {
    // TEKNISI: no debounce — hanya trigger saat Enter/Submit
    final isTeknisi =
        getIt<CurrentUserStore>().userRole?.toUpperCase() == 'TEKNISI';
    if (isTeknisi) return;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      setState(() {
        _search = _searchController.text;
        _page = 0;
      });
      _loadPurchase();
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

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();
  static String _formatDateParam(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadPurchase() async {
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
    if (userRole == 'TEKNISI' && _search.trim().isEmpty) {
      setState(() {
        _items = [];
        _totalGrandSum = null;
        _totalQty = null;
        _totalElements = 0;
        _totalPages = 0;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = getIt<ApiNewEndpoints>();
      final response = await api.getOldPurchase(
        page: _page,
        size: _size,
        sortBy: _sortBy,
        direction: _direction,
        startDate: _formatDateParam(_startDate),
        endDate: _formatDateParam(_endDate),
        search: _search.trim().isEmpty ? null : _search.trim(),
      );

      if (isResponseSuccess(response['status']) && response['data'] != null) {
        final data = response['data'] as Map? ?? {};
        var rawItems = data['content'] as List? ?? [];
        // TEKNISI: exact match filter on docNoP
        if (userRole == 'TEKNISI' && _search.trim().isNotEmpty) {
          final q = _search.trim().toUpperCase();
          rawItems = rawItems
              .where((p) => (p['docNoP']?.toString().toUpperCase() ?? '') == q)
              .toList();
        }
        setState(() {
          _items = rawItems;
          _totalGrandSum = data['totalGrandSum'];
          _totalQty = data['totalQty'];
          _totalElements = (data['totalElements'] is int)
              ? data['totalElements'] as int
              : int.tryParse(data['totalElements']?.toString() ?? '0') ?? 0;
          _totalPages = (data['totalPages'] is int)
              ? data['totalPages'] as int
              : int.tryParse(data['totalPages']?.toString() ?? '0') ?? 1;
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message']?.toString() ?? 'Gagal memuat data.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    return DashboardShell(
      currentRoute: AppRoutes.dataWarehouse,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () =>
          showSyncMigrationDialog(onCustomSuccess: _loadPurchase),
      showHeaderActionInAppBar: true,
      lastSync: lastSyncFormatted,
      onNavigate: (route) {
        if (route != AppRoutes.dataWarehouse) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      onRefresh: _loading ? null : _loadPurchase,
      child: Padding(
        padding: ResponsivePadding.all(context),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop()),
            const Text('Pembelian',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Expanded(
              child: _FiltersSection(
            searchController: _searchController,
            searchFocus: _searchFocus,
            onSearchSubmitted: _loadPurchase,
            sortBy: _sortBy,
            direction: _direction,
            size: _size,
            startDate: _startDate,
            endDate: _endDate,
            onApply: (sortBy, direction, size, start, end) {
              setState(() {
                _sortBy = sortBy;
                _direction = direction;
                _size = size;
                _startDate = start;
                _endDate = end;
                _page = 0;
              });
              _loadPurchase();
            },
            onDateRangeClear: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _page = 0;
              });
              _loadPurchase();
            },
            content: RefreshIndicator(
              onRefresh: _loadPurchase,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_loading &&
                          _totalGrandSum != null &&
                          _items.isNotEmpty) ...[
                        _SummaryCard(
                            grandSum: _totalGrandSum, totalQty: _totalQty),
                        const SizedBox(height: 16),
                      ],
                      if (_loading)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator()))
                      else if (_error != null)
                        Center(child: Text(_error!))
                      else if (_items.isEmpty)
                        _EmptySection(
                            onRetry: _loadPurchase,
                            isSearchEmpty: _search.trim().isEmpty)
                      else if (isMobile)
                        _GroupedDeckView(items: _items)
                      else
                        CustomPlutoDataGrid<dynamic>(
                          data: _items,
                          totalPage: _totalPages,
                          currentPage: _page + 1,
                          totalElements: _totalElements,
                          onPageChanged: (newPage) {
                            setState(() {
                              _page = newPage - 1;
                            });
                            _loadPurchase();
                          },
                          buildColumns: (ctx) =>
                              OldPurchaseGridHelper.getColumns(ctx),
                          buildRows: (data) =>
                              OldPurchaseGridHelper.mapToRows(data),
                        ),
                      if (!_loading && _items.isNotEmpty && isMobile) ...[
                        const SizedBox(height: 16),
                        _PaginationBar(
                          page: _page,
                          totalPages: _totalPages,
                          totalElements: _totalElements,
                          onPrev: _page > 0
                              ? () {
                                  setState(() => _page--);
                                  _loadPurchase();
                                }
                              : null,
                          onNext: _page < _totalPages - 1
                              ? () {
                                  setState(() => _page++);
                                  _loadPurchase();
                                }
                              : null,
                        ),
                      ],
                    ]),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}

// Internal widgets for OldPurchasePage follows similar structures as OldSalesPage but without empCode filter
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.grandSum, this.totalQty});
  final Object? grandSum;
  final Object? totalQty;

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
    } else {
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.shopping_bag_rounded,
                  color: Colors.green.shade700)),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ringkasan Pembelian',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rp${_rp(grandSum)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                  const SizedBox(width: 24),
                ],
              ),
            ]),
          ),
        ]),
      );
}

class _FiltersSection extends StatefulWidget {
  const _FiltersSection(
      {required this.searchController,
      required this.searchFocus,
      required this.onSearchSubmitted,
      required this.sortBy,
      required this.direction,
      required this.size,
      required this.startDate,
      required this.endDate,
      required this.onApply,
      required this.onDateRangeClear,
      required this.content});
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final String sortBy;
  final String direction;
  final int size;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String, String, int, DateTime?, DateTime?) onApply;
  final VoidCallback onDateRangeClear;
  final Widget content;
  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  late String _sortBy;
  late String _direction;
  late int _size;
  DateTime? _startDate;
  DateTime? _endDate;
  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  static String _fmt(DateTime? d) =>
      d == null ? 'Pilih' : '${d.day}/${d.month}/${d.year}';
  @override
  Widget build(BuildContext context) => FixedSearchFilterLayout(
        searchBar: ModernSearchBar(
            controller: widget.searchController,
            focusNode: widget.searchFocus,
            onSubmitted: widget.onSearchSubmitted,
            hintText: 'Cari no. dokumen, partner, barang...'),
        filterTitle: 'Filter & Urutkan',
        filterContentBuilder: (close, refresh) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 16),
          FilterGroup(
              title: 'Rentang Tanggal',
              icon: Icons.date_range_rounded,
              children: [
                ModernDateChip(
                    label: _fmt(_startDate),
                    onTap: () async {
                      final p = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (p != null) {
                        setState(() {
                          _startDate = p;
                          if (_endDate != null && _endDate!.isBefore(p)) {
                            _endDate = p;
                          }
                        });
                        refresh();
                      }
                    },
                    selected: _startDate != null),
                const SizedBox(width: 8),
                const Text('–'),
                const SizedBox(width: 8),
                ModernDateChip(
                    label: _fmt(_endDate),
                    onTap: () async {
                      final p = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (p != null) {
                        setState(() {
                          _endDate = p;
                          if (_startDate != null && _startDate!.isAfter(p)) {
                            _startDate = p;
                          }
                        });
                        refresh();
                      }
                    },
                    selected: _endDate != null),
              ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const FilterLabel('Urutkan'),
                  SearchableDropdown<String>(
                      label: 'Urutkan',
                      value: _sortBy,
                      options: const [
                        'docDate',
                        'docNoP',
                        'parName',
                        'itemName',
                        'qty',
                        'price',
                        'grandTotal'
                      ],
                      displayText: (s) => s,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _sortBy = v);
                          refresh();
                        }
                      }),
                ])),
            const SizedBox(width: 12),
            SizedBox(
                width: 120,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FilterLabel('Arah'),
                      FilterSegmentedButton<String>(
                          value: _direction,
                          onChanged: (v) {
                            setState(() => _direction = v);
                            refresh();
                          },
                          segments: const {
                            'asc': (label: 'A-Z', icon: Icons.arrow_upward),
                            'desc': (label: 'Z-A', icon: Icons.arrow_downward)
                          }),
                    ])),
          ]),
          const SizedBox(height: 20),
          FilterFooter(onApply: () {
            widget.onApply(_sortBy, _direction, _size, _startDate, _endDate);
            close();
          }, onReset: () {
            widget.onDateRangeClear();
            close();
          }),
        ]),
        child: widget.content,
      );
}

class _GroupedDeckView extends StatelessWidget {
  const _GroupedDeckView({required this.items});
  final List<dynamic> items;
  static String _v(Object? x) => x?.toString() ?? '—';
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final grouped = <String, List<dynamic>>{};
    for (final s in items) {
      final key = _v(s['docNoP']);
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final keys = grouped.keys.toList();
    return ResponsiveDeckGrid(
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final docNo = keys[i];
          final group = grouped[docNo]!;
          final first = group.first;

          double groupTotal = 0;
          double groupQty = 0;
          for (final item in group) {
            groupTotal +=
                double.tryParse(item['grandTotal']?.toString() ?? '0') ?? 0;
            groupQty += double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
          }

          return DataDeckCard(
              headerLeft: _v(first['docDate']),
              headerRight: 'No. $docNo',
              title: _v(first['parName']),
              rows: [
                (
                  label: 'Dept',
                  value: _v(first['dept_code'] ?? first['deptCode'])
                ),
                (
                  label: 'Total Qty',
                  value: '${groupQty.toStringAsFixed(0)} Pcs'
                ),
                (label: 'Total Pembelian', value: ' ${_rp(groupTotal)}'),
              ],
              onTap: () => _showDetailSheet(context, docNo, group));
        });
  }

  static String _rp(Object? x) {
    if (x == null) return '—';
    final n = num.tryParse(x.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
    if (n == null) return x.toString();

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

  void _showDetailSheet(BuildContext context, String k, List<dynamic> g) {
    final first = g.first;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Detail Pembelian',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('No. Nota: $k',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600)),
                        Text('Partner: ${_v(first['parName'])}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                        Text(
                            'Dept: ${_v(first['dept_code'] ?? first['deptCode'])}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                      ])),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Nota',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Rp${_rp(g.fold<double>(0, (p, e) => p + (double.tryParse(e['grandTotal']?.toString() ?? '0') ?? 0)))}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        '${g.fold<double>(0, (p, e) => p + (double.tryParse(e['qty']?.toString() ?? '0') ?? 0)).toStringAsFixed(0)} Pcs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ]),
          ),
          const SizedBox(height: 16),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ResponsiveDataTable(
                    minColumnWidth: 150,
                    columns: const [
                      DataColumn(label: Text('Barang')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Harga')),
                      DataColumn(label: Text('Total'))
                    ],
                    rows: g
                        .map((s) => DataRow(cells: [
                              DataCell(
                                  CopyableTextCell(text: _v(s['itemName']))),
                              DataCell(Text(_v(s['qty']))),
                              DataCell(Text(' ${_rp(s['price'])}')),
                              DataCell(Text(' ${_rp(s['grandTotal'])}')),
                            ]))
                        .toList(),
                  ))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar(
      {required this.page,
      required this.totalPages,
      required this.totalElements,
      this.onPrev,
      this.onNext});
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

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.onRetry, this.isSearchEmpty = false});
  final VoidCallback onRetry;
  final bool isSearchEmpty;

  @override
  Widget build(BuildContext context) {
    final isTeknisi =
        getIt<CurrentUserStore>().userRole?.toUpperCase() == 'TEKNISI';
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
          Icon(
            isSearchEmpty && isTeknisi
                ? Icons.search_rounded
                : Icons.shopping_bag_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearchEmpty && isTeknisi
                ? 'Silakan masukkan kata kunci pencarian di atas untuk mencari No Nota BL atau Serial Number (SN) data lama.'
                : 'Tidak ada data pembelian',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
