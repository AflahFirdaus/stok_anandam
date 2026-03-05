import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import '../../injection.dart';
import '../../token_storage.dart';
import '../layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import '../shared/responsive_table.dart';
import '../shared/responsive_padding.dart';
import '../shared/item_deck_card.dart';
import '../shared/modern_filter.dart';
import '../../core/theme/app_spacing.dart';
import '../shared/migration_sync_mixin.dart';
import '../dashboard/widgets/migration_dialog.dart';

/// Mengubah pesan error dari server/teknis jadi pesan yang mudah dipahami user.
/// Mengembalikan null jika pesan terlihat teknis (DB, constraint, exception), agar dipakai pesan default.
String? _pesanErrorUser(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw.trim().toLowerCase();
  if (t.contains('constraint') ||
      t.contains('violates') ||
      t.contains('relation') ||
      t.contains('failing row') ||
      t.contains('detail:') ||
      t.contains('exception') ||
      t.contains('dioexception') ||
      t.length > 120) return null;
  return raw.trim();
}

/// State filter Data Canvas disimpan agar saat pindah menu lalu balik, filter tetap.
class _DataCanvasFilterState {
  _DataCanvasFilterState._();
  static String search = '';
  static int page = 0;
  static int size = 20;
  static String sortBy = 'tanggal';
  static String direction = 'desc';
  static int? startDateMillis;
  static int? endDateMillis;

  static void reset() {
    search = '';
    page = 0;
    size = 20;
    sortBy = 'tanggal';
    direction = 'desc';
    startDateMillis = null;
    endDateMillis = null;
  }
}

class DataCanvasPage extends StatefulWidget {
  const DataCanvasPage({super.key});

  @override
  State<DataCanvasPage> createState() => _DataCanvasPageState();
}

class _DataCanvasPageState extends State<DataCanvasPage> {
  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_DataCanvasFilterState.reset);
  }

  @override
  Widget build(BuildContext context) {
    return const _DataCanvasContent();
  }
}

class _DataCanvasContent extends StatefulWidget {
  const _DataCanvasContent();

  @override
  State<_DataCanvasContent> createState() => _DataCanvasContentState();
}

class _DataCanvasContentState extends State<_DataCanvasContent> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  List<DataCanvasing> _items = [];
  int _page = 0;
  int _size = 20;
  int _totalElements = 0;
  int _totalPages = 0;
  String _search = '';
  String _sortBy = 'tanggal';
  String _direction = 'desc';
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  void _restoreFilterState() {
    _search = _DataCanvasFilterState.search;
    _searchController.text = _search;
    _page = _DataCanvasFilterState.page;
    _size = _DataCanvasFilterState.size;
    _sortBy = _DataCanvasFilterState.sortBy;
    _direction = _DataCanvasFilterState.direction;
    _startDate = _DataCanvasFilterState.startDateMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(_DataCanvasFilterState.startDateMillis!)
        : null;
    _endDate = _DataCanvasFilterState.endDateMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(_DataCanvasFilterState.endDateMillis!)
        : null;
  }

  void _persistFilterState() {
    _DataCanvasFilterState.search = _search;
    _DataCanvasFilterState.page = _page;
    _DataCanvasFilterState.size = _size;
    _DataCanvasFilterState.sortBy = _sortBy;
    _DataCanvasFilterState.direction = _direction;
    _DataCanvasFilterState.startDateMillis = _startDate?.millisecondsSinceEpoch;
    _DataCanvasFilterState.endDateMillis = _endDate?.millisecondsSinceEpoch;
  }

  @override
  void initState() {
    super.initState();
    _restoreFilterState();
    fetchLastSync();
    _loadData();
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
      _loadData();
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

  static List<DataCanvasing> _parseContent(Object? content) {
    if (content == null) return [];
    if (content is List) {
      return content
          .map((e) {
            if (e is DataCanvasing) return e;
            if (e is Map) return DataCanvasing.fromJson(Map<String, dynamic>.from(e));
            return null;
          })
          .whereType<DataCanvasing>()
          .toList();
    }
    return [];
  }

  static String _formatDateParam(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = getIt<DataCanvasingControllerApi>();
      final startStr = _formatDateParam(_startDate);
      final endStr = _formatDateParam(_endDate);
      final response = await api.getAll(
        page: _page,
        size: _size,
        sortBy: _sortBy,
        direction: _direction,
        startDate: startStr.isEmpty ? null : startStr,
        endDate: endStr.isEmpty ? null : endStr,
        search: _search.trim().isEmpty ? null : _search.trim(),
      );
      final pageData = response.data?.data;
      if (isResponseSuccess(response.data?.status) && pageData != null) {
        setState(() {
          _items = _parseContent(pageData.content);
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
          _error = _pesanErrorUser(response.data?.message?.toString()) ?? 'Gagal memuat data.';
          _loading = false;
        });
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
          int totalPages = 0;
          if (paging is Map) {
            final p = Map<String, dynamic>.from(paging.map((k, v) => MapEntry(k?.toString() ?? '', v)));
            totalElements = int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
            totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 0;
          }
          if (mounted) {
            setState(() {
              _items = items;
              _totalElements = totalElements;
              _totalPages = totalPages > 0 ? totalPages : 1;
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

  void _onSearchSubmitted() {
    _search = _searchController.text;
    setState(() {
      _page = 0;
      _persistFilterState();
    });
    _loadData();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        if (_startDate != null && _startDate!.isAfter(picked)) _startDate = picked;
      }
      _page = 0;
      _persistFilterState();
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    return DashboardShell(
      currentRoute: AppRoutes.dataCanvas,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: _loadData),
      lastSync: lastSyncFormatted,
      showHeaderActionInAppBar: true,

      onRefresh: _loading ? null : _loadData,
      onNavigate: (route) {
        if (route != AppRoutes.dataCanvas) context.go(route);
      },
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      child: Padding(
        padding: ResponsivePadding.all(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) SizedBox(height: ResponsivePadding.spacing(context)),
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
                onApply: (sortBy, direction, size, start, end) {
                  setState(() {
                    _sortBy = sortBy;
                    _direction = direction;
                    _size = size;
                    _startDate = start;
                    _endDate = end;
                    _page = 0;
                    _persistFilterState();
                  });
                  _loadData();
                },
                onDateRangeClear: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _page = 0;
                    _persistFilterState();
                  });
                  _loadData();
                },
                content: RefreshIndicator(
                  onRefresh: _loadData,
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
                          _ErrorSection(message: _error!, onRetry: _loadData)
                        else if (_items.isEmpty)
                          _EmptySection(onRetry: _loadData)
                        else
                          isMobile
                              ? _DataCanvasDeckList(items: _items)
                              : _DataCanvasTable(items: _items),
                        if (!_loading && _items.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _PaginationBar(
                            page: _page,
                            totalPages: _totalPages,
                            totalElements: _totalElements,
                            onPrev: _totalPages > 0 && _page > 0
                                ? () {
                                    setState(() {
                                      _page--;
                                      _persistFilterState();
                                    });
                                    _loadData();
                                  }
                                : null,
                            onNext: _totalPages > 0 && _page < _totalPages - 1
                                ? () {
                                    setState(() {
                                      _page++;
                                      _persistFilterState();
                                    });
                                    _loadData();
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
  final void Function(
    String sortBy,
    String direction,
    int size,
    DateTime? startDate,
    DateTime? endDate,
  ) onApply;
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
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(_FiltersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy ||
        oldWidget.direction != widget.direction ||
        oldWidget.size != widget.size ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _resetToCurrent();
    }
  }

  static const _sortOptions = [
    ('tanggal', 'Tanggal'),
    ('canvasVisit', 'Kunjungan Canvas'),
    ('keterangan', 'Keterangan'),
    ('catatan', 'Catatan'),
  ];

  static String _fmt(DateTime? d) {
    if (d == null) return 'Pilih';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        if (_startDate != null && _startDate!.isAfter(picked)) _startDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;
    final hasActiveFilters = widget.startDate != null || widget.endDate != null;
    
    return FixedSearchFilterLayout(
      searchBar: ModernSearchBar(
        controller: widget.searchController,
        focusNode: widget.searchFocus,
        onSubmitted: widget.onSearchSubmitted,
        hintText: 'Cari instansi, keterangan, catatan...',
        onChanged: (_) {},
      ),
      filterTitle: 'Filter & Urutkan',
      activeFilterBadges: hasActiveFilters
          ? [
              FilterBadge(
                label: '${_fmt(widget.startDate)} - ${_fmt(widget.endDate)}',
                onRemove: widget.onDateRangeClear,
              ),
            ]
          : null,
      filterContentBuilder: (close, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Rentang Tanggal',
            icon: Icons.date_range_rounded,
            children: [
              ModernDateChip(
                label: _fmt(_startDate),
                onTap: () async {
                  await _pickDate(true);
                  refresh();
                },
                selected: _startDate != null,
              ),
              const SizedBox(width: 8),
              Text('–', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              ModernDateChip(
                label: _fmt(_endDate),
                onTap: () async {
                  await _pickDate(false);
                  refresh();
                },
                selected: _endDate != null,
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Urutkan berdasarkan',
            icon: Icons.sort_rounded,
            children: _sortOptions.map<Widget>((option) {
              return CustomFilterChip(
                label: option.$2,
                selected: _sortBy == option.$1,
                onTap: () {
                  setState(() => _sortBy = option.$1);
                  refresh();
                },
              );
            }).toList(),
          ),
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Arah urutan',
            icon: Icons.swap_vert_rounded,
            children: [
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
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Per halaman',
            icon: Icons.view_list_rounded,
            children: [10, 20, 50, 100].map<Widget>((s) {
              return CustomFilterChip(
                label: '$s',
                selected: _size == s,
                onTap: () {
                  setState(() => _size = s);
                  refresh();
                },
              );
            }).toList(),
          ),
          FilterFooter(
            onApply: () {
              widget.onApply(_sortBy, _direction, _size, _startDate, _endDate);
              close();
            },
            onReset: () {
              setState(() {
                _sortBy = 'tanggal';
                _direction = 'desc';
                _size = 20;
                _startDate = null;
                _endDate = null;
              });
              widget.onDateRangeClear();
              widget.onApply(_sortBy, _direction, _size, _startDate, _endDate);
              close();
            },
          ),
        ],
      ),
      child: widget.content,
    );
  }
}

class _DataCanvasTable extends StatelessWidget {
  const _DataCanvasTable({required this.items});
  final List<DataCanvasing> items;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  static String _instansi(Canvasing? c) {
    if (c == null) return '—';
    final n = c.namaInstansi?.toString().trim();
    return n == null || n.isEmpty ? '—' : n;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable(
      minColumnWidth: 180.0,
      columnSpacing: 12.0,
      headingRowColor: Colors.grey.shade50,
      columns: [
        buildDataColumn('Instansi'),
        buildDataColumn('Tanggal'),
        buildDataColumn('Kunjungan'),
        buildDataColumn('Keterangan'),
        buildDataColumn('Catatan'),
      ],
      rows: items.map((d) {
        return DataRow(
          cells: [
            buildDataCell(_instansi(d.canvasing)),
            buildDataCell(_v(d.tanggal)),
            buildDataCell(_v(d.canvasVisit)),
            buildDataCell(_v(d.keterangan)),
            buildDataCell(_v(d.catatan)),
          ],
        );
      }).toList(),
    );
  }
}

class _DataCanvasDeckList extends StatelessWidget {
  const _DataCanvasDeckList({required this.items});
  final List<DataCanvasing> items;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  static String _instansi(Canvasing? c) {
    if (c == null) return '—';
    final n = c.namaInstansi?.toString().trim();
    return n == null || n.isEmpty ? '—' : n;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = items[i];
        return DataDeckCard(
          title: _instansi(d.canvasing),
          subtitle: _v(d.tanggal),
          rows: [
            (label: 'Kunjungan', value: _v(d.canvasVisit)),
            (label: 'Keterangan', value: _v(d.keterangan)),
            (label: 'Catatan', value: _v(d.catatan)),
          ],
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
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
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
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Belum ada data canvas', style: TextStyle(color: Colors.grey.shade600)),
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
