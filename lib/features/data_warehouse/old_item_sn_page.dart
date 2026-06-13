import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/injection.dart';
import '../layout/dashboard_shell.dart';
import '../shared/responsive_padding.dart';
import '../shared/item_deck_card.dart';
import '../shared/modern_filter.dart';
import '../shared/responsive_deck_grid.dart';
import '../shared/detail_row_with_copy.dart';
import '../shared/migration_sync_mixin.dart';
import '../shared/custom_pluto_grid.dart';
import '../shared/grid_helpers.dart';

class OldItemSnPage extends StatefulWidget {
  const OldItemSnPage({super.key});

  @override
  State<OldItemSnPage> createState() => _OldItemSnPageState();
}

class _OldItemSnPageState extends State<OldItemSnPage> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  int _page = 0;
  final int _size = 100;
  int _totalElements = 0;
  int _totalPages = 0;
  String _search = '';
  final String _sortBy = 'tanggal';
  final String _direction = 'desc';
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
    fetchLastSync();
    _searchController.addListener(() {
      final isTeknisi =
          getIt<CurrentUserStore>().userRole?.toUpperCase() == 'TEKNISI';
      if (isTeknisi) return;

      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _search = _searchController.text;
            _page = 0;
          });
          _loadData();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
    if (userRole == 'TEKNISI' && _search.trim().isEmpty) {
      setState(() {
        _items = [];
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
      final response = await api.getOldItemSn(
        page: _page,
        size: _size,
        sortBy: _sortBy,
        direction: _direction,
        search: _search,
        type: _selectedType,
        startDate: _startDate != null
            ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
            : null,
        endDate: _endDate != null
            ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
            : null,
      );

      if (isResponseSuccess(response['status'])) {
        var data = response['data'] as List? ?? [];
        // TEKNISI: exact match filter on sn or docId
        if (userRole == 'TEKNISI' && _search.trim().isNotEmpty) {
          final q = _search.trim().toUpperCase();
          data = data
              .where((i) =>
                  (i['sn']?.toString().toUpperCase() ?? '') == q ||
                  (i['docId']?.toString().toUpperCase() ?? '') == q)
              .toList();
        }
        final paging = response['paging'];
        setState(() {
          _items = data;
          if (paging is Map) {
            _totalElements =
                int.tryParse(paging['totalItem']?.toString() ?? '0') ?? 0;
            _totalPages =
                int.tryParse(paging['totalPage']?.toString() ?? '0') ?? 1;
          }
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan';
        _loading = false;
      });
    }
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
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return DashboardShell(
      currentRoute: AppRoutes.dataWarehouse,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: _loadData),
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
      onRefresh: _loading ? null : _loadData,
      child: Padding(
        padding: ResponsivePadding.all(context),
        child: Column(children: [
          Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop()),
            const Text('Item SN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Expanded(
              child: FixedSearchFilterLayout(
            searchBar: ModernSearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              onSubmitted: () => _loadData(),
              hintText: 'Cari SN, Doc ID...',
            ),
            filterTitle: 'Filter',
            filterContentBuilder: (close, refresh) => Column(children: [
              const SizedBox(height: 16),
              FilterGroup(title: 'Tipe', icon: Icons.category, children: [
                ChoiceChip(
                    label: const Text('SEMUA'),
                    selected: _selectedType == null,
                    onSelected: (s) {
                      setState(() => _selectedType = null);
                      refresh();
                    }),
                const SizedBox(width: 8),
                ChoiceChip(
                    label: const Text('MASUK'),
                    selected: _selectedType == 'MASUK',
                    onSelected: (s) {
                      setState(() => _selectedType = 'MASUK');
                      refresh();
                    }),
                const SizedBox(width: 8),
                ChoiceChip(
                    label: const Text('KELUAR'),
                    selected: _selectedType == 'KELUAR',
                    onSelected: (s) {
                      setState(() => _selectedType = 'KELUAR');
                      refresh();
                    }),
              ]),
              const SizedBox(height: 16),
              FilterFooter(onApply: () {
                _page = 0;
                _loadData();
                close();
              }, onReset: () {
                setState(() {
                  _selectedType = null;
                  _startDate = null;
                  _endDate = null;
                });
                _loadData();
                close();
              }),
            ]),
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [
                  if (_loading)
                    const CircularProgressIndicator()
                  else if (_error != null)
                    Text(_error!)
                  else if (_items.isEmpty)
                    _EmptySection(
                        onRetry: _loadData,
                        isSearchEmpty: _search.trim().isEmpty)
                  else if (isMobile)
                    ResponsiveDeckGrid(
                        itemCount: _items.length,
                        itemBuilder: (c, i) => DataDeckCard(
                              title: _items[i]['sn'].toString(),
                              headerLeft:
                                  _items[i]['tanggal'].toString().split('T')[0],
                              headerRight: _items[i]['type'],
                              rows: [
                                (
                                  label: 'Doc ID',
                                  value: _items[i]['docId'].toString()
                                ),
                                (
                                  label: 'User',
                                  value:
                                      _items[i]['userName']?.toString() ?? '—'
                                )
                              ],
                              onTap: () => _showDetailSheet(context, _items[i]),
                            ))
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
                        _loadData();
                      },
                      buildColumns: (ctx) =>
                          OldItemSnGridHelper.getColumns(ctx),
                      buildRows: (data) => OldItemSnGridHelper.mapToRows(data),
                    ),
                  if (_items.isNotEmpty && isMobile) ...[
                    const SizedBox(height: 16),
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
                ]),
              ),
            ),
          )),
        ]),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Detail Serial Number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  DetailRowWithCopy(
                      label: 'Serial Number',
                      value: item['sn']?.toString() ?? '—'),
                  DetailRowWithCopy(
                      label: 'Item Name',
                      value: item['itemName']?.toString() ?? '—'),
                  DetailRowWithCopy(
                      label: 'Doc ID', value: item['docId']?.toString() ?? '—'),
                  DetailRowWithCopy(
                      label: 'User',
                      value: item['userName']?.toString() ?? '—'),
                  DetailRowWithCopy(
                      label: 'Tanggal',
                      value: item['tanggal']?.toString().split('T')[0] ?? '—'),
                  DetailRowWithCopy(
                      label: 'Tipe', value: item['type']?.toString() ?? '—'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
                : Icons.qr_code_2_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearchEmpty && isTeknisi
                ? 'Silakan masukkan kata kunci pencarian di atas untuk mencari Serial Number (SN) data lama.'
                : 'Tidak ada data Serial Number',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
