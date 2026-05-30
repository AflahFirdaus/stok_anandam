import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import 'package:stok_anandam/features/ijin_import/ijin_import_grid_helper.dart';
import 'package:stok_anandam/features/ijin_import/ijin_import_response.dart';
import '../../core/auth/current_user_store.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/api_new_endpoints.dart';
import '../../injection.dart';
import '../layout/dashboard_shell.dart';
import '../shared/modern_filter.dart';
import '../shared/responsive_padding.dart';
import '../shared/detail_row_with_copy.dart';
import '../shared/item_deck_card.dart';
import '../shared/custom_pluto_grid.dart';

// Pastikan import Helper dan Model Anda sesuai
// import 'ijin_import_grid_helper.dart';
// import '../../models/ijin_import_response.dart';

class _IjinImportFilterState {
  _IjinImportFilterState._();
  static String search = '';
  static int page = 0;
  static String sortBy = 'no';
  static String direction = 'asc';
  static int size = 50;

  static void reset() {
    search = '';
    page = 0;
    sortBy = 'no';
    direction = 'asc';
    size = 50;
  }
}

class IjinImportPage extends StatelessWidget {
  const IjinImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _IjinImportContent();
  }
}

class _IjinImportContent extends StatefulWidget {
  const _IjinImportContent();

  @override
  State<_IjinImportContent> createState() => _IjinImportContentState();
}

class _IjinImportContentState extends State<_IjinImportContent> {
  bool _loading = true;
  String? _error;
  List<IjinImportResponse> _items = [];
  int _page = 0;
  int _size = 50;
  int _totalElements = 0;
  int _totalPages = 0;

  String _search = '';
  String _sortBy = 'no';
  String _direction = 'asc';

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_IjinImportFilterState.reset);
    _restoreFilterState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _restoreFilterState() {
    _search = _IjinImportFilterState.search;
    _searchController.text = _search;
    _page = _IjinImportFilterState.page;
    _sortBy = _IjinImportFilterState.sortBy;
    _direction = _IjinImportFilterState.direction;
    _size = _IjinImportFilterState.size;
  }

  void _persistFilterState() {
    _IjinImportFilterState.search = _search;
    _IjinImportFilterState.page = _page;
    _IjinImportFilterState.sortBy = _sortBy;
    _IjinImportFilterState.direction = _direction;
    _IjinImportFilterState.size = _size;
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

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = getIt<ApiNewEndpoints>();

      final response = await api.getIjinImport(
        page: _page,
        size: _size,
        sortBy: _sortBy,
        direction: _direction,
        search: _search.trim().isNotEmpty ? _search.trim() : null,
      );

      if (response['status'] != 200) {
        throw Exception(
            response['message'] ?? 'Gagal memuat data Ijin Imp  ort.');
      }

      final dataList = response['data'] as List?;
      final items = (dataList ?? [])
          .map((e) => IjinImportResponse.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final paging = response['paging'];
      int totalElements = 0;
      int totalPages = 0;

      if (paging != null) {
        totalElements =
            int.tryParse(paging['totalItem']?.toString() ?? '0') ?? 0;
        totalPages = int.tryParse(paging['totalPage']?.toString() ?? '0') ?? 0;
      }

      if (!mounted) return;

      setState(() {
        _items = items;
        _totalElements = totalElements;
        _totalPages = totalPages;
        if (_totalPages < 1) _totalPages = 1;
        if (_page >= _totalPages) _page = _totalPages - 1;
        if (_page < 0) _page = 0;
        _loading = false;
        _persistFilterState();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Gagal memuat data. Periksa koneksi lalu coba lagi.\nError: $e';
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

  void _showDetailSheet(IjinImportResponse t) {
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
            const SizedBox(height: 12),
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
                      children: [
                        Expanded(
                          child: Text(
                            t.namaBarang ?? '—',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon:
                              const Icon(Icons.content_copy_rounded, size: 18),
                          onPressed: () {
                            if (t.namaBarang != null && t.namaBarang != '—') {
                              Clipboard.setData(
                                  ClipboardData(text: t.namaBarang!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Nama Barang disalin')),
                              );
                            }
                          },
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DetailRowWithCopy(
                        label: 'No', value: t.no?.toString(), labelWidth: 100),
                    DetailRowWithCopy(
                        label: 'Spesifikasi',
                        value: t.spesifikasi,
                        labelWidth: 100),
                    DetailRowWithCopy(
                        label: 'Keterangan',
                        value: t.keterangan,
                        labelWidth: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: AppRoutes.ijinImport,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      showHeaderActionInAppBar: false,
      onRefresh: _loading ? null : _loadData,
      onNavigate: (route) {
        if (route != AppRoutes.ijinImport) context.go(route);
      },
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
      child: Builder(builder: (context) {
        final isMobile = MediaQuery.sizeOf(context).width < 720;
        return Padding(
          padding: ResponsivePadding.all(context),
          child: _FiltersSection(
            searchController: _searchController,
            searchFocus: _searchFocus,
            onSearchSubmitted: _onSearchSubmitted,
            sortBy: _sortBy,
            direction: _direction,
            size: _size,
            onApply: (sortBy, direction, size) {
              setState(() {
                _sortBy = sortBy;
                _direction = direction;
                _size = size;
                _page = 0;
                _persistFilterState();
              });
              _loadData();
            },
            child: RefreshIndicator(
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
                              child: CircularProgressIndicator()))
                    else if (_error != null)
                      _ErrorSection(message: _error!, onRetry: _loadData)
                    else
                      _buildContent(),
                    if (!_loading && _items.isNotEmpty && isMobile) ...[
                      SizedBox(height: ResponsivePadding.spacingLarge(context)),
                      _PaginationBar(
                        page: _page,
                        totalPages: _totalPages,
                        totalElements: _totalElements,
                        onPrev: _page > 0
                            ? () {
                                setState(() => _page--);
                                _loadData();
                              }
                            : null,
                        onNext: _page < _totalPages - 1
                            ? () {
                                setState(() => _page++);
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
        );
      }),
    );
  }

  Widget _buildContent() {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildMobileCard(_items[i]),
      );
    }
    return CustomPlutoDataGrid<IjinImportResponse>(
      data: _items,
      totalPage: _totalPages,
      currentPage: _page + 1,
      totalElements: _totalElements,
      onPageChanged: (newPage) {
        setState(() {
          _page = newPage - 1;
          _persistFilterState();
        });
        _loadData();
      },
      buildColumns: (ctx) => IjinImportGridHelper.getColumns(ctx),
      buildRows: (data) => IjinImportGridHelper.mapToRows(data),
    );
  }

  Widget _buildMobileCard(IjinImportResponse t) {
    return DataDeckCard(
      onTap: () => _showDetailSheet(t),
      headerLeft: 'No: ${t.no ?? "—"}',
      title: t.namaBarang ?? '—',
      headerRight: '',
      rows: [
        (label: 'Spek', value: t.spesifikasi ?? "—"),
        (label: 'Ket', value: t.keterangan ?? "—"),
      ],
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
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
    required this.onApply,
    required this.child,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final String sortBy;
  final String direction;
  final int size;
  final void Function(String sortBy, String direction, int size) onApply;
  final Widget child;

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  late String _sortBy;
  late String _direction;
  late int _size;

  @override
  void initState() {
    super.initState();
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
  }

  @override
  void didUpdateWidget(_FiltersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy ||
        oldWidget.direction != widget.direction ||
        oldWidget.size != widget.size) {
      _resetToCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FixedSearchFilterLayout(
      searchBar: ModernSearchBar(
        controller: widget.searchController,
        focusNode: widget.searchFocus,
        onSubmitted: widget.onSearchSubmitted,
        hintText: 'Cari Nama Barang / Spek / Ket...',
        onChanged: (_) {},
      ),
      filterTitle: 'Filter & Urutkan',
      filterContentBuilder: (close, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Sort & direction
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FilterLabel('Urutkan berdasarkan'),
                    SearchableDropdown<String>(
                      value: _sortBy,
                      options: const [
                        'no',
                        'namaBarang',
                      ],
                      displayText: (v) {
                        switch (v) {
                          case 'no':
                            return 'Nomor / ID';
                          case 'namaBarang':
                            return 'Nama Barang';
                          default:
                            return v;
                        }
                      },
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

          const SizedBox(height: 20),

          // Items per page
          CompactFilterDropdown<int>(
            label: 'Item per halaman',
            value: _size,
            options: const [10, 20, 50, 100],
            displayText: (v) => '$v item',
            onChanged: (v) {
              if (v != null) {
                setState(() => _size = v);
                refresh();
              }
            },
          ),

          const SizedBox(height: 20),

          FilterFooter(
            onApply: () {
              widget.onApply(_sortBy, _direction, _size);
              close();
            },
            onReset: () {
              setState(() {
                _sortBy = 'no';
                _direction = 'asc';
                _size = 50;
              });
              widget.onApply(_sortBy, _direction, _size);
              close();
            },
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
