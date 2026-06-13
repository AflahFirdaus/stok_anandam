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
import '../../core/theme/app_spacing.dart';
import '../shared/migration_sync_mixin.dart';
import '../shared/custom_pluto_grid.dart';
import '../shared/grid_helpers.dart';

class OldSalesPage extends StatelessWidget {
  const OldSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OldSalesContent();
  }
}

class _OldSalesContent extends StatefulWidget {
  const _OldSalesContent();

  @override
  State<_OldSalesContent> createState() => _OldSalesContentState();
}

class _OldSalesContentState extends State<_OldSalesContent>
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
  String? _selectedEmpCode;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  final Set<String> _allEmpCodes = {};

  List<String> get _availableEmpCodes {
    return _allEmpCodes.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadAllEmpCodes();
    _loadSales();
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
      _loadSales();
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

  static String _formatDateParam(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAllEmpCodes() async {
    try {
      final api = getIt<ApiNewEndpoints>();
      final codes = await api.getOldEmployeeCodes();
      if (mounted) {
        setState(() {
          _allEmpCodes.clear();
          _allEmpCodes.addAll(codes);
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadSales() async {
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
      final startStr = _formatDateParam(_startDate);
      final endStr = _formatDateParam(_endDate);

      final response = await api.getOldSales(
        page: _page,
        size: _size,
        sortBy: _sortBy,
        direction: _direction,
        startDate: startStr.isEmpty ? null : startStr,
        endDate: endStr.isEmpty ? null : endStr,
        empCode: _selectedEmpCode?.trim().isEmpty ?? true
            ? null
            : _selectedEmpCode?.trim(),
        search: _search.trim().isEmpty ? null : _search.trim(),
      );

      final status = response['status'];
      final bodyData = response['data'];
      final paging = response['paging'];

      if (isResponseSuccess(response['status'])) {
        final data = response['data'] as Map? ?? {};
        final paging = response['paging'];
        var rawItems = data['content'] as List? ?? [];
        // TEKNISI: exact match filter on docNo
        if (userRole == 'TEKNISI' && _search.trim().isNotEmpty) {
          final q = _search.trim().toUpperCase();
          rawItems = rawItems
              .where((s) => (s['docNo']?.toString().toUpperCase() ?? '') == q)
              .toList();
        }
        setState(() {
          _items = rawItems;
          _totalElements = (data['totalElements'] is int)
              ? data['totalElements'] as int
              : int.tryParse(data['totalElements']?.toString() ?? '0') ?? 0;
          _totalPages = (data['totalPages'] is int)
              ? data['totalPages'] as int
              : int.tryParse(data['totalPages']?.toString() ?? '0') ?? 1;
          _totalGrandSum = data['totalGrandSum'];
          _totalQty = data['totalQty'];
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

  void _onSearchSubmitted() {
    _search = _searchController.text;
    setState(() {
      _page = 0;
    });
    _loadSales();
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
          showSyncMigrationDialog(onCustomSuccess: _loadSales),
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
      onRefresh: _loading ? null : _loadSales,
      child: Padding(
        padding: ResponsivePadding.all(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                const Text(
                  'Penjualan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _FiltersSection(
                searchController: _searchController,
                searchFocus: _searchFocus,
                onSearchSubmitted: _onSearchSubmitted,
                sortBy: _sortBy,
                direction: _direction,
                size: _size,
                startDate: _startDate,
                endDate: _endDate,
                selectedEmpCode: _selectedEmpCode,
                availableEmpCodes: _availableEmpCodes,
                onApply: (sortBy, direction, size, start, end, empCode) {
                  setState(() {
                    _sortBy = sortBy;
                    _direction = direction;
                    _size = size;
                    _startDate = start;
                    _endDate = end;
                    _selectedEmpCode = empCode;
                    _page = 0;
                  });
                  _loadSales();
                },
                onDateRangeClear: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _page = 0;
                  });
                  _loadSales();
                },
                content: RefreshIndicator(
                  onRefresh: _loadSales,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_loading &&
                            _totalGrandSum != null &&
                            _items.isNotEmpty) ...[
                          _SummaryCard(grandSum: _totalGrandSum),
                          const SizedBox(height: 16),
                        ],
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          _ErrorSection(message: _error!, onRetry: _loadSales)
                        else if (_items.isEmpty)
                          _EmptySection(
                              onRetry: _loadSales,
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
                              _loadSales();
                            },
                            buildColumns: (ctx) =>
                                OldSalesGridHelper.getColumns(ctx),
                            buildRows: (data) =>
                                OldSalesGridHelper.mapToRows(data),
                          ),
                        if (!_loading && _items.isNotEmpty && isMobile) ...[
                          const SizedBox(height: AppSpacing.md),
                          _PaginationBar(
                            page: _page,
                            totalPages: _totalPages,
                            totalElements: _totalElements,
                            onPrev: _totalPages > 0 && _page > 0
                                ? () {
                                    setState(() => _page--);
                                    _loadSales();
                                  }
                                : null,
                            onNext: _totalPages > 0 && _page < _totalPages - 1
                                ? () {
                                    setState(() => _page++);
                                    _loadSales();
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

// ... internal widgets like _SummaryCard, _FiltersSection, _DesktopTableView, _GroupedDeckView follow the same pattern as SalesPage but use Map for items ...

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.grandSum});
  final Object? grandSum;

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_cart_rounded,
                color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Grand Sum',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Rp${_rp(grandSum)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
              ],
            ),
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
    required this.startDate,
    required this.endDate,
    required this.selectedEmpCode,
    required this.availableEmpCodes,
    required this.onApply,
    required this.onDateRangeClear,
    required this.content,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final String sortBy;
  final String direction;
  final int size;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedEmpCode;
  final List<String> availableEmpCodes;
  final void Function(String sortBy, String direction, int size,
      DateTime? startDate, DateTime? endDate, String? selectedEmpCode) onApply;
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
  String? _selectedEmpCode;

  @override
  void initState() {
    super.initState();
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedEmpCode = widget.selectedEmpCode;
  }

  static String _fmt(DateTime? d) {
    if (d == null) return 'Pilih';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilterBadges = <Widget>[];

    if (widget.startDate != null || widget.endDate != null) {
      activeFilterBadges.add(
        FilterBadge(
          label: '${_fmt(widget.startDate)} - ${_fmt(widget.endDate)}',
          onRemove: widget.onDateRangeClear,
        ),
      );
    }
    if (widget.selectedEmpCode != null && widget.selectedEmpCode!.isNotEmpty) {
      activeFilterBadges.add(
        FilterBadge(
          label: 'Kode Karyawan: ${widget.selectedEmpCode}',
          onRemove: () => widget.onApply(widget.sortBy, widget.direction,
              widget.size, widget.startDate, widget.endDate, null),
        ),
      );
    }

    return FixedSearchFilterLayout(
      searchBar: ModernSearchBar(
        controller: widget.searchController,
        focusNode: widget.searchFocus,
        onSubmitted: widget.onSearchSubmitted,
        hintText: 'Cari no. dokumen, partner, barang...',
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
          FilterGroup(
              title: 'Rentang Tanggal',
              icon: Icons.date_range_rounded,
              children: [
                ModernDateChip(
                    label: _fmt(_startDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate != null && _endDate!.isBefore(picked)) {
                            _endDate = picked;
                          }
                        });
                        refresh();
                      }
                    },
                    selected: _startDate != null),
                const SizedBox(width: 8),
                Text('–', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                ModernDateChip(
                    label: _fmt(_endDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                          if (_startDate != null && _startDate!.isAfter(picked)) {
                            _startDate = picked;
                          }
                        });
                        refresh();
                      }
                    },
                    selected: _endDate != null),
              ]),
          const SizedBox(height: 20),
          const FilterLabel('Kode Karyawan'),
          SearchableDropdown<String>(
              label: 'Kode Karyawan',
              value: _selectedEmpCode,
              options: widget.availableEmpCodes,
              onChanged: (v) {
                setState(() => _selectedEmpCode = v);
                refresh();
              },
              hintText: 'Semua Karyawan'),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const FilterLabel('Urutkan berdasarkan'),
                  SearchableDropdown<String>(
                      label: 'Urutkan berdasarkan',
                      value: _sortBy,
                      options: const [
                        'docDate',
                        'docNo',
                        'code',
                        'parName',
                        'itemName',
                        'qty',
                        'price',
                        'grandTotal',
                        'empCode'
                      ],
                      displayText: (s) => s == 'docDate'
                          ? 'Tanggal'
                          : s == 'docNo'
                              ? 'No. Dokumen'
                              : s == 'parName'
                                  ? 'Nama Partner'
                                  : s == 'itemName'
                                      ? 'Nama Barang'
                                      : s,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FilterLabel('Arah'),
                      FilterSegmentedButton<String>(
                          value: _direction,
                          onChanged: (v) {
                            setState(() => _direction = v);
                            refresh();
                          },
                          segments: const {
                            'asc': (
                              label: 'A–Z',
                              icon: Icons.arrow_upward_rounded
                            ),
                            'desc': (
                              label: 'Z–A',
                              icon: Icons.arrow_downward_rounded
                            )
                          }),
                    ])),
          ]),
          const SizedBox(height: 20),
          FilterFooter(onApply: () {
            widget.onApply(_sortBy, _direction, _size, _startDate, _endDate,
                _selectedEmpCode);
            close();
          }, onReset: () {
            widget.onDateRangeClear();
            setState(() {
              _sortBy = 'docDate';
              _direction = 'desc';
              _size = 50;
              _startDate = null;
              _endDate = null;
              _selectedEmpCode = null;
            });
            widget.onApply(_sortBy, _direction, _size, _startDate, _endDate,
                _selectedEmpCode);
            close();
          }),
        ],
      ),
      child: widget.content,
    );
  }
}

class _GroupedDeckView extends StatelessWidget {
  const _GroupedDeckView({required this.items});
  final List<dynamic> items;

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

  static String _fmtDate(Object? d) {
    if (d == null) return '—';
    final str = d.toString();
    try {
      final date = DateTime.tryParse(str);
      if (date != null) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (_) {}
    return str;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final grouped = <String, List<dynamic>>{};
    for (final s in items) {
      final key = _v(s['docNo']);
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
        for (final s in group) {
          groupTotal +=
              double.tryParse(s['grandTotal']?.toString() ?? '0') ?? 0;
          groupQty += double.tryParse(s['qty']?.toString() ?? '0') ?? 0;
        }

        return DataDeckCard(
          headerLeft: _fmtDate(first['docDate']),
          headerRight: 'No. $docNo',
          title: _v(first['parName']),
          rows: [
            (label: 'Kode', value: _v(first['code'])),
            (label: 'Dept', value: _v(first['dept_code'] ?? first['deptCode'])),
            (label: 'Total Qty', value: '${groupQty.toStringAsFixed(0)} Pcs'),
            (label: 'Total Penjualan', value: ' ${_rp(groupTotal)}'),
            (label: 'Marketing', value: _v(first['empCode'])),
          ],
          onTap: () => _showDetailSheet(context, docNo, group),
        );
      },
    );
  }

  void _showDetailSheet(
      BuildContext context, String docNo, List<dynamic> group) {
    final first = group.first;
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
                        const Text('Detail Penjualan',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('No. Nota: $docNo',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600)),
                        Text('Partner: ${_v(first['parName'])}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                        Text('Kode: ${_v(first['code'])}',
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
                        'Rp${_rp(group.fold<double>(0, (p, e) => p + (double.tryParse(e['grandTotal']?.toString() ?? '0') ?? 0)))}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        '${group.fold<double>(0, (p, e) => p + (double.tryParse(e['qty']?.toString() ?? '0') ?? 0)).toStringAsFixed(0)} Pcs',
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
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Marketing'))
                    ],
                    rows: group
                        .map((s) => DataRow(cells: [
                              DataCell(
                                  CopyableTextCell(text: _v(s['itemName']))),
                              DataCell(Text(_v(s['qty']))),
                              DataCell(Text(' ${_rp(s['price'])}')),
                              DataCell(Text(' ${_rp(s['grandTotal'])}')),
                              DataCell(Text(_v(s['empCode']))),
                            ]))
                        .toList(),
                  ))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(children: [
        Text(message),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
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
                : Icons.shopping_cart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearchEmpty && isTeknisi
                ? 'Silakan masukkan kata kunci pencarian di atas untuk mencari No Nota JL atau Serial Number (SN) data lama.'
                : 'Tidak ada data penjualan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
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
