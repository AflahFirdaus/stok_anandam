import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import '../../data/api_new_endpoints.dart';
import '../../injection.dart';
import '../layout/dashboard_shell.dart';
import '../shared/responsive_table.dart';
import '../shared/migration_sync_mixin.dart';
import '../shared/responsive_padding.dart';
import '../shared/modern_filter.dart';

class _ActivityLogFilterState {
  _ActivityLogFilterState._();
  static String username = '';
  static String action = '';
  static int page = 0;
  static int size = 50;
  static String sortBy = 'timestamp';
  static String direction = 'desc';

  static void reset() {
    username = '';
    action = '';
    page = 0;
    size = 20;
    sortBy = 'timestamp';
    direction = 'desc';
  }
}

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  List<ActivityLog> _items = [];
  int _page = 0;
  int _size = 50;
  String _sortBy = 'timestamp';
  String _direction = 'desc';
  int _totalElements = 0;
  int _totalPages = 0;

  String _username = '';
  String _action = '';
  final String _ipAddress = '';

  final _usernameController = TextEditingController();
  final _actionController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_ActivityLogFilterState.reset);
    _restoreFilterState();
    _loadLogs();
    fetchLastSync();
  }

  void _restoreFilterState() {
    _username = _ActivityLogFilterState.username;
    _usernameController.text = _username;
    _action = _ActivityLogFilterState.action;
    _actionController.text = _action;
    _page = _ActivityLogFilterState.page;
    _size = _ActivityLogFilterState.size;
    _sortBy = _ActivityLogFilterState.sortBy;
    _direction = _ActivityLogFilterState.direction;
  }

  void _persistFilterState() {
    _ActivityLogFilterState.username = _username;
    _ActivityLogFilterState.action = _action;
    _ActivityLogFilterState.page = _page;
    _ActivityLogFilterState.size = _size;
    _ActivityLogFilterState.sortBy = _sortBy;
    _ActivityLogFilterState.direction = _direction;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _usernameController.dispose();
    _actionController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = getIt<ApiNewEndpoints>();
      final response = await api.getActivityLogs(
        page: _page,
        size: _size,
        sortBy: _sortBy,
        direction: _direction,
        username: _username,
        action: _action,
      );

      if (mounted) {
        final dataPayload = response['data'];
        final pagingPayload = response['paging'];

        List<ActivityLog> items = [];
        int totalElements = 0;
        int totalPages = 1;

        if (dataPayload is List) {
          items = dataPayload
              .map((e) => ActivityLog.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        if (pagingPayload is Map) {
          final p = Map<String, dynamic>.from(pagingPayload);
          totalElements = int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
          totalPages = int.tryParse(p['totalPage']?.toString() ?? '1') ?? 1;
        }

        setState(() {
          _items = items;
          _totalElements = totalElements;
          _totalPages = totalPages < 1 ? 1 : totalPages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat log aktivitas. Periksa koneksi Anda.';
          _loading = false;
        });
      }
    }
  }

  void _onFilterChanged(VoidCallback refresh) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _username = _usernameController.text;
        _action = _actionController.text;
        _page = 0;
        _persistFilterState();
      });
      _loadLogs();
      refresh();
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$d/$mo ${local.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    final activeFilterBadges = <Widget>[];
    if (_username.isNotEmpty) {
      activeFilterBadges.add(
        FilterBadge(
          label: 'User: $_username',
          onRemove: () {
            setState(() {
              _username = '';
              _usernameController.clear();
              _page = 0;
            });
            _loadLogs();
          },
        ),
      );
    }
    if (_action.isNotEmpty) {
      activeFilterBadges.add(
        FilterBadge(
          label: 'Aksi: $_action',
          onRemove: () {
            setState(() {
              _action = '';
              _actionController.clear();
              _page = 0;
            });
            _loadLogs();
          },
        ),
      );
    }

    return DashboardShell(
      currentRoute: AppRoutes.activityLog,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: _loadLogs),
      lastSync: lastSyncFormatted,
      showHeaderActionInAppBar: true,
      onRefresh: _loading ? null : _loadLogs,

      onNavigate: (route) {
        if (route != AppRoutes.activityLog) context.go(route);
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
            Expanded(
              child: FixedSearchFilterLayout(
                searchBar: ModernSearchBar(
                  controller: _actionController,
                  focusNode: _searchFocus,
                  hintText: 'Cari aksi atau detail...',
                  onChanged: (_) => _onFilterChanged(() {}),
                  onSubmitted: () => _loadLogs(),
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
                      title: 'Pencarian & Filter',
                      icon: Icons.search_rounded,
                      children: [
                        const FilterLabel('Username'),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Filter by username',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _onFilterChanged(refresh),
                        ),
                        const SizedBox(height: 16),
                        const FilterLabel('Aksi'),
                        TextField(
                          controller: _actionController,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Filter by action name',
                            prefixIcon: Icon(Icons.history_rounded, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _onFilterChanged(refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilterGroup(
                      title: 'Pengurutan',
                      icon: Icons.sort_rounded,
                      children: [
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
                                      'timestamp',
                                      'action',
                                      'username'
                                    ],
                                    displayText: (s) {
                                      switch (s) {
                                        case 'timestamp':
                                          return 'Waktu';
                                        case 'action':
                                          return 'Aksi';
                                        case 'username':
                                          return 'User';
                                        default:
                                          return s;
                                      }
                                    },
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _sortBy = v);
                                        _persistFilterState();
                                        _loadLogs();
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
                                      _persistFilterState();
                                      _loadLogs();
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilterGroup(
                      title: 'Pengaturan Tampilan',
                      icon: Icons.settings_rounded,
                      children: [
                        const FilterLabel('Item per halaman'),
                        CompactFilterDropdown<int>(
                          label: 'Item per halaman',
                          value: _size,
                          options: const [10, 20, 50, 100],
                          displayText: (s) => '$s item',
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _size = v;
                                _page = 0;
                              });
                              _persistFilterState();
                              _loadLogs();
                              refresh();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilterFooter(
                      onApply: close,
                      onReset: () {
                        setState(() {
                          _usernameController.clear();
                          _actionController.clear();
                          _username = '';
                          _action = '';
                          _sortBy = 'timestamp';
                          _direction = 'desc';
                          _size = 50;
                          _page = 0;
                          _persistFilterState();
                        });
                        _loadLogs();
                        refresh();
                      },
                    ),
                  ],
                ),
                child: RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Log Aktivitas',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (!isDesktop) ...[
                              Text(
                                '$_totalElements logs',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          Center(
                            child: Column(
                              children: [
                                Text(_error!,
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadLogs,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        else if (_items.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('Tidak ada log aktivitas.'),
                            ),
                          )
                        else ...[
                          _buildTable(),
                          const SizedBox(height: 24),
                          _PaginationBar(
                            page: _page,
                            totalPages: _totalPages,
                            totalElements: _totalElements,
                            onPrev: _page > 0
                                ? () {
                                    setState(() => _page--);
                                    _persistFilterState();
                                    _loadLogs();
                                  }
                                : null,
                            onNext: _page < _totalPages - 1
                                ? () {
                                    setState(() => _page++);
                                    _persistFilterState();
                                    _loadLogs();
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

  Widget _buildTable() {
    return ResponsiveDataTable(
      columns: const [
        DataColumn(label: Text('Waktu')),
        DataColumn(label: Text('User')),
        DataColumn(label: Text('Aksi')),
        DataColumn(label: Text('Detail')),
        DataColumn(label: Text('IP Address')),
      ],
      rows: _items.map((log) {
        return DataRow(
          cells: [
            DataCell(Text(_formatDate(log.timestamp),
                style: const TextStyle(fontSize: 12))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(log.username ?? '—',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            DataCell(Text(log.action ?? '—',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold))),
            DataCell(Text(log.details ?? '—',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
            DataCell(Text(log.ipAddress ?? '—',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          ],
        );
      }).toList(),
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
