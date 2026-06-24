import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import '../../core/auth/current_user_store.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/api_new_endpoints.dart';
import '../../injection.dart';
import '../layout/dashboard_shell.dart';
import '../shared/modern_filter.dart';
import '../shared/responsive_padding.dart';
import '../shared/detail_row_with_copy.dart';
import '../shared/migration_sync_mixin.dart';
import '../shared/item_deck_card.dart';
import '../shared/custom_pluto_grid.dart';
import '../shared/grid_helpers.dart';
import 'package:stok_anandam/features/presence/mixins/presence_action_mixin.dart';

class _ItemSnFilterState {
  _ItemSnFilterState._();
  static String search = '';
  static String? docId;
  static String? itemName;
  static String? sn;
  static String? user;
  static String? startDate;
  static String? endDate;
  static int page = 0;
  static String sortBy = 'tanggal';
  static String direction = 'desc';
  static int size = 50;
  static bool isMasuk = true;

  static void reset() {
    search = '';
    docId = null;
    itemName = null;
    sn = null;
    user = null;
    startDate = null;
    endDate = null;
    page = 0;
    sortBy = 'tanggal';
    direction = 'desc';
    size = 20;
    isMasuk = true;
  }
}

class ItemSnPage extends StatelessWidget {
  const ItemSnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ItemSnContent();
  }
}

class _ItemSnContent extends StatefulWidget {
  const _ItemSnContent();

  @override
  State<_ItemSnContent> createState() => _ItemSnContentState();
}

class _ItemSnContentState extends State<_ItemSnContent>
    with MigrationSyncMixin, PresenceActionMixin {
  bool _loading = true;
  String? _error;
  List<ItemSerialNumberResponse> _items = [];
  int _page = 0;
  int _size = 50;
  int _totalElements = 0;
  int _totalPages = 0;

  String _search = '';
  String _sortBy = 'tanggal';
  String _direction = 'desc';
  bool _isMasuk = true;

  String? _docId;
  String? _itemName;
  String? _sn;
  String? _user;
  String? _startDate;
  String? _endDate;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  final _docIdController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _snController = TextEditingController();
  final _userController = TextEditingController();

  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_ItemSnFilterState.reset);
    _restoreFilterState();
    _loadData();
    fetchLastSync();
    _searchController.addListener(_onSearchChanged);
  }

  void _restoreFilterState() {
    _search = _ItemSnFilterState.search;
    _searchController.text = _search;
    _docId = _ItemSnFilterState.docId;
    _docIdController.text = _docId ?? '';
    _itemName = _ItemSnFilterState.itemName;
    _itemNameController.text = _itemName ?? '';
    _sn = _ItemSnFilterState.sn;
    _snController.text = _sn ?? '';
    _user = _ItemSnFilterState.user;
    _userController.text = _user ?? '';
    _startDate = _ItemSnFilterState.startDate;
    _endDate = _ItemSnFilterState.endDate;
    _page = _ItemSnFilterState.page;
    _sortBy = _ItemSnFilterState.sortBy;
    _direction = _ItemSnFilterState.direction;
    _size = _ItemSnFilterState.size;
    _isMasuk = _ItemSnFilterState.isMasuk;
  }

  void _persistFilterState() {
    _ItemSnFilterState.search = _search;
    _ItemSnFilterState.docId = _docId;
    _ItemSnFilterState.itemName = _itemName;
    _ItemSnFilterState.sn = _sn;
    _ItemSnFilterState.user = _user;
    _ItemSnFilterState.startDate = _startDate;
    _ItemSnFilterState.endDate = _endDate;
    _ItemSnFilterState.page = _page;
    _ItemSnFilterState.sortBy = _sortBy;
    _ItemSnFilterState.direction = _direction;
    _ItemSnFilterState.size = _size;
    _ItemSnFilterState.isMasuk = _isMasuk;
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
    _docIdController.dispose();
    _itemNameController.dispose();
    _snController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
    final hasSearchQuery = _search.trim().isNotEmpty ||
        (_docId != null && _docId!.trim().isNotEmpty) ||
        (_sn != null && _sn!.trim().isNotEmpty) ||
        (_itemName != null && _itemName!.trim().isNotEmpty);

    if (userRole == 'TEKNISI' && !hasSearchQuery) {
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

      Map<String, dynamic> response;
      if (_isMasuk) {
        response = await api.getSnMasuk(
          page: _page,
          size: _size,
          sortBy: _sortBy,
          direction: _direction,
          search: _search.trim().isNotEmpty ? _search.trim() : null,
          docId: _docId?.trim().isNotEmpty == true ? _docId!.trim() : null,
          itemName:
              _itemName?.trim().isNotEmpty == true ? _itemName!.trim() : null,
          sn: _sn?.trim().isNotEmpty == true ? _sn!.trim() : null,
          user: _user?.trim().isNotEmpty == true ? _user!.trim() : null,
          startDate:
              _startDate?.trim().isNotEmpty == true ? _startDate!.trim() : null,
          endDate:
              _endDate?.trim().isNotEmpty == true ? _endDate!.trim() : null,
        );
      } else {
        response = await api.getSnKeluar(
          page: _page,
          size: _size,
          sortBy: _sortBy,
          direction: _direction,
          search: _search.trim().isNotEmpty ? _search.trim() : null,
          docId: _docId?.trim().isNotEmpty == true ? _docId!.trim() : null,
          itemName:
              _itemName?.trim().isNotEmpty == true ? _itemName!.trim() : null,
          sn: _sn?.trim().isNotEmpty == true ? _sn!.trim() : null,
          user: _user?.trim().isNotEmpty == true ? _user!.trim() : null,
          startDate:
              _startDate?.trim().isNotEmpty == true ? _startDate!.trim() : null,
          endDate:
              _endDate?.trim().isNotEmpty == true ? _endDate!.trim() : null,
        );
      }

      if (response['status'] != 200) {
        throw Exception(response['message'] ?? 'Gagal memuat data.');
      }

      final dataList = response['data'] as List?;
      var items = (dataList ?? [])
          .map((e) =>
              ItemSerialNumberResponse.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // TEKNISI: exact match filter on sn or docId
      if (userRole == 'TEKNISI') {
        final qSn = (_sn?.trim() ?? '').toUpperCase();
        final qSearch = _search.trim().toUpperCase();
        if (qSn.isNotEmpty) {
          items = items.where((i) => (i.sn ?? '').toUpperCase() == qSn).toList();
        } else if (qSearch.isNotEmpty) {
          items = items
              .where((i) =>
                  (i.sn ?? '').toUpperCase() == qSearch ||
                  (i.docId ?? '').toUpperCase() == qSearch)
              .toList();
        }
      }

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

  String _formatDate(DateTime date, {bool includeTime = false}) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    if (!includeTime) {
      return '$day/$month/$year';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  void _showDetailSheet(ItemSerialNumberResponse t) {
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
                            t.itemName ?? '—',
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
                            if (t.itemName != null && t.itemName != '—') {
                              Clipboard.setData(
                                  ClipboardData(text: t.itemName!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nama Barang disalin'),
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
                    DetailRowWithCopy(
                        label: 'Serial Number', value: t.sn, labelWidth: 120),
                    DetailRowWithCopy(
                        label: 'Doc ID', value: t.docId, labelWidth: 120),
                    DetailRowWithCopy(
                        label: 'User', value: t.user, labelWidth: 120),
                    DetailRowWithCopy(
                      label: 'Tanggal',
                      value: t.tanggal != null ? _formatDate(t.tanggal!) : null,
                      labelWidth: 120,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      (_docId?.isNotEmpty ?? false) ||
      (_itemName?.isNotEmpty ?? false) ||
      (_sn?.isNotEmpty ?? false) ||
      (_user?.isNotEmpty ?? false) ||
      (_startDate?.isNotEmpty ?? false) ||
      (_endDate?.isNotEmpty ?? false);

  List<Widget> get _activeFilterBadges {
    final badges = <Widget>[];
    if (_isMasuk == false) {
      badges.add(FilterBadge(
        label: 'Keluar',
        onRemove: () => setState(() {
          _isMasuk = true;
          _page = 0;
          _persistFilterState();
          _loadData();
        }),
      ));
    }
    if (_docId?.isNotEmpty == true) {
      badges.add(FilterBadge(
        label: 'Doc: $_docId',
        onRemove: () => setState(() {
          _docId = null;
          _docIdController.clear();
          _page = 0;
          _persistFilterState();
          _loadData();
        }),
      ));
    }
    if (_itemName?.isNotEmpty == true) {
      badges.add(FilterBadge(
        label: 'Item: $_itemName',
        onRemove: () => setState(() {
          _itemName = null;
          _itemNameController.clear();
          _page = 0;
          _persistFilterState();
          _loadData();
        }),
      ));
    }
    if (_sn?.isNotEmpty == true) {
      badges.add(FilterBadge(
        label: 'SN: $_sn',
        onRemove: () => setState(() {
          _sn = null;
          _snController.clear();
          _page = 0;
          _persistFilterState();
          _loadData();
        }),
      ));
    }
    if (_user?.isNotEmpty == true) {
      badges.add(FilterBadge(
        label: 'User: $_user',
        onRemove: () => setState(() {
          _user = null;
          _userController.clear();
          _page = 0;
          _persistFilterState();
          _loadData();
        }),
      ));
    }
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: AppRoutes.itemSn,
      onScan: () => context.pushNamed(AppRoutes.scanner),
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: _loadData),
      lastSync: lastSyncFormatted,
      showHeaderActionInAppBar: true,
      onRefresh: _loading ? null : _loadData,
      onNavigate: (route) {
        if (route != AppRoutes.itemSn) context.go(route);
      },
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      child: Builder(builder: (context) {
        final isMobile = MediaQuery.sizeOf(context).width < 720;
        return Padding(
          padding: ResponsivePadding.all(context),
          child: _FiltersSection(
            searchController: _searchController,
            searchFocus: _searchFocus,
            onSearchSubmitted: _onSearchSubmitted,
            isMasuk: _isMasuk,
            sortBy: _sortBy,
            direction: _direction,
            size: _size,
            docId: _docId,
            itemName: _itemName,
            sn: _sn,
            user: _user,
            docIdController: _docIdController,
            itemNameController: _itemNameController,
            snController: _snController,
            userController: _userController,
            onApply:
                (isMasuk, sortBy, direction, size, docId, itemName, sn, user) {
              setState(() {
                _isMasuk = isMasuk;
                _sortBy = sortBy;
                _direction = direction;
                _size = size;
                _docId = docId;
                _itemName = itemName;
                _sn = sn;
                _user = user;
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
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      _ErrorSection(message: _error!, onRetry: _loadData)
                    else if (_items.isEmpty)
                      _EmptySection(onRetry: _loadData, isSearchEmpty: !_hasActiveFilters && _search.trim().isEmpty)
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
                                setState(() {
                                  _page--;
                                  _persistFilterState();
                                });
                                _loadData();
                              }
                            : null,
                        onNext: _page < _totalPages - 1
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
        );
      }),
    );
  }

  Widget _buildContent() {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildMobileCard(_items[i]),
      );
    }

    return CustomPlutoDataGrid<ItemSerialNumberResponse>(
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
      buildColumns: (ctx) => ItemSnGridHelper.getColumns(ctx),
      buildRows: (data) => ItemSnGridHelper.mapToRows(data),
    );
  }

  Widget _buildMobileCard(ItemSerialNumberResponse t) {
    return DataDeckCard(
      onTap: () => _showDetailSheet(t),
      headerLeft: t.tanggal != null ? _formatDate(t.tanggal!) : '—',
      title: t.itemName ?? '—',
      headerRight: 'SN: ${t.sn ?? "—"}',
      rows: [
        (label: 'Doc ID', value: t.docId ?? "—"),
        (label: 'User', value: t.user ?? "—"),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: theme.textTheme.bodyMedium,
          ),
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

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.onRetry, this.isSearchEmpty = false});
  final VoidCallback onRetry;
  final bool isSearchEmpty;

  @override
  Widget build(BuildContext context) {
    final isTeknisi = getIt<CurrentUserStore>().userRole?.toUpperCase() == 'TEKNISI';
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
            isSearchEmpty && isTeknisi ? Icons.search_rounded : Icons.qr_code_2_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearchEmpty && isTeknisi
                ? 'Silakan masukkan kata kunci pencarian di atas atau filter SN / No Nota JL / BL.'
                : 'Tidak ada data Serial Number',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
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
    required this.isMasuk,
    required this.sortBy,
    required this.direction,
    required this.size,
    required this.docId,
    required this.itemName,
    required this.sn,
    required this.user,
    required this.docIdController,
    required this.itemNameController,
    required this.snController,
    required this.userController,
    required this.onApply,
    required this.child,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final bool isMasuk;
  final String sortBy;
  final String direction;
  final int size;
  final String? docId;
  final String? itemName;
  final String? sn;
  final String? user;
  final TextEditingController docIdController;
  final TextEditingController itemNameController;
  final TextEditingController snController;
  final TextEditingController userController;
  final void Function(
    bool isMasuk,
    String sortBy,
    String direction,
    int size,
    String? docId,
    String? itemName,
    String? sn,
    String? user,
  ) onApply;
  final Widget child;

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  late bool _isMasuk;
  late String _sortBy;
  late String _direction;
  late int _size;
  String? _docId;
  String? _itemName;
  String? _sn;
  String? _user;

  @override
  void initState() {
    super.initState();
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _isMasuk = widget.isMasuk;
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
    _docId = widget.docId;
    _itemName = widget.itemName;
    _sn = widget.sn;
    _user = widget.user;

    widget.docIdController.text = _docId ?? '';
    widget.itemNameController.text = _itemName ?? '';
    widget.snController.text = _sn ?? '';
    widget.userController.text = _user ?? '';
  }

  @override
  void didUpdateWidget(_FiltersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMasuk != widget.isMasuk ||
        oldWidget.sortBy != widget.sortBy ||
        oldWidget.direction != widget.direction ||
        oldWidget.size != widget.size ||
        oldWidget.docId != widget.docId ||
        oldWidget.itemName != widget.itemName ||
        oldWidget.sn != widget.sn ||
        oldWidget.user != widget.user) {
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
        hintText: 'Cari SN, Item, Doc ID...',
        onChanged: (_) {},
      ),
      filterTitle: 'Filter & Urutkan',
      filterContentBuilder: (close, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FilterLabel('Jenis Transaksi'),
              FilterSegmentedButton<bool>(
                value: _isMasuk,
                onChanged: (v) {
                  setState(() => _isMasuk = v);
                  // Apply immediately as requested: "langsung ke set"
                  widget.onApply(
                    v, // Use v directly to ensure parent gets the latest
                    _sortBy,
                    _direction,
                    _size,
                    _docId,
                    _itemName,
                    _sn,
                    _user,
                  );
                  refresh();
                },
                segments: const {
                  true: (label: 'Masuk', icon: Icons.arrow_downward_rounded),
                  false: (label: 'Keluar', icon: Icons.arrow_upward_rounded),
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

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
                        'tanggal',
                        'docId',
                        'itemName',
                        'sn',
                        'user'
                      ],
                      displayText: (v) {
                        switch (v) {
                          case 'tanggal':
                            return 'Tanggal';
                          case 'docId':
                            return 'Doc ID';
                          case 'itemName':
                            return 'Item Name';
                          case 'sn':
                            return 'Serial Number';
                          case 'user':
                            return 'User';
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
            options: const [10, 20, 50],
            displayText: (v) => '$v item',
            onChanged: (v) {
              if (v != null) {
                setState(() => _size = v);
                refresh();
              }
            },
          ),

          const SizedBox(height: 20),

          // Advanced text filters
          Row(
            children: [
              Icon(Icons.filter_alt_rounded,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Filter Lanjutan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FilterRow(
            label: 'Doc ID',
            controller: widget.docIdController,
            hint: 'cth. SN-001',
            onChanged: (v) {
              setState(() => _docId = v.trim().isEmpty ? null : v.trim());
              refresh();
            },
          ),
          _FilterRow(
            label: 'Item Name',
            controller: widget.itemNameController,
            hint: 'cth. Laptop ASUS',
            onChanged: (v) {
              setState(() => _itemName = v.trim().isEmpty ? null : v.trim());
              refresh();
            },
          ),
          _FilterRow(
            label: 'Serial Number',
            controller: widget.snController,
            hint: 'cth. SN12345',
            onChanged: (v) {
              setState(() => _sn = v.trim().isEmpty ? null : v.trim());
              refresh();
            },
          ),
          _FilterRow(
            label: 'User',
            controller: widget.userController,
            hint: 'cth. RYAN',
            onChanged: (v) {
              setState(() => _user = v.trim().isEmpty ? null : v.trim());
              refresh();
            },
          ),

          FilterFooter(
            onApply: () {
              widget.onApply(
                _isMasuk,
                _sortBy,
                _direction,
                _size,
                _docId,
                _itemName,
                _sn,
                _user,
              );
              close();
            },
            onReset: () {
              setState(() {
                _isMasuk = true;
                _sortBy = 'tanggal';
                _direction = 'desc';
                _size = 50;
                _docId = null;
                _itemName = null;
                _sn = null;
                _user = null;
              });
              widget.onApply(
                _isMasuk,
                _sortBy,
                _direction,
                _size,
                _docId,
                _itemName,
                _sn,
                _user,
              );
              close();
            },
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
