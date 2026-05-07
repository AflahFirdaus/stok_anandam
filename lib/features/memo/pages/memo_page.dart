import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stok_anandam/data/repositories/memo_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/features/shared/widgets/camera_screen.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/core/widgets/deck_view.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/data/models/penjadwalan.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/features/memo/widgets/status_badge.dart';
import 'package:stok_anandam/features/memo/widgets/memo_desktop_table_view.dart';
import 'package:stok_anandam/features/memo/utils/memo_print_utils.dart';
import 'package:stok_anandam/features/memo/widgets/chrome_tab.dart';
import 'package:stok_anandam/features/memo/utils/memo_auth_utils.dart';
import 'package:stok_anandam/features/memo/utils/memo_auth_utils.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  MemoStatus? _selectedStatus;
  String? _selectedKecamatan;
  final TextEditingController _kecamatanFilterController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // New Filters
  String? _selectedMemoType;
  final TextEditingController _kodePostFilterController =
      TextEditingController();
  String? _selectedKodePost;
  String _sortBy = 'date_desc'; // date_desc, date_asc, name_asc, name_desc
  EmployeeOption? _selectedMarketingFilter;
  List<EmployeeOption> _employeeOptions = [];
  bool _isLoadingEmployees = false;
  
  // Hardware Scanner Logic (Windows/Desktop)
  final FocusNode _scannerFocusNode = FocusNode();
  String _scanBuffer = "";
  DateTime _lastKeyPress = DateTime.now();

  // Tab Grouping
  late final List<ChromeTabGroup<MemoStatus>> _tabGroups;
  late ChromeTabGroup<MemoStatus> _activeGroup;
  
  void _initTabGroups(String? role) {
    _tabGroups = [
      ChromeTabGroup(
        id: 'PROSES',
        label: 'PROSES (PENDING)',
        children: [
          MemoStatus.DRAFT,
          MemoStatus.PENDING,
          MemoStatus.MENUNGGU_PERSETUJUAN,
          MemoStatus.DISETUJUI,
          MemoStatus.DITOLAK,
        ],
      ),
      ChromeTabGroup(
        id: 'GUDANG',
        label: 'PROSES GUDANG (ORDERAN)',
        children: [
          MemoStatus.MENUNGGU_GUDANG,
          MemoStatus.MENUNGGU_NOTA,
          MemoStatus.DIBUAT_NOTA,
          MemoStatus.BUFFER_ZONE,
        ],
      ),
      ChromeTabGroup(
        id: 'TEKNISI',
        label: 'PROSES TEKNISI',
        children: [
          MemoStatus.MENUNGGU_TEKNISI,
          MemoStatus.PROSES_TEKNISI,
          MemoStatus.BUFFER_ZONE,
        ],
      ),
      ChromeTabGroup(
        id: 'PENGIRIMAN',
        label: 'PROSES PENGIRIMAN',
        children: [
          MemoStatus.MENUNGGU_PENGIRIMAN,
          MemoStatus.DALAM_PENGIRIMAN,
          MemoStatus.DITERIMA_USER,
          MemoStatus.TERKIRIM_SEBAGIAN,
          MemoStatus.KENDALA_BARANG,
        ],
      ),
      ChromeTabGroup(
        id: 'LAINNYA',
        label: 'LAINNYA',
        children: [
          MemoStatus.SELESAI,
          MemoStatus.DIBATALKAN,
        ],
      ),
    ];

    // RBAC: Role based tab restrictions
    if (role == 'TEKNISI' || role == 'SPV_TEKNISI') {
      final teknisiGroup = _tabGroups.firstWhere((g) => g.id == 'TEKNISI');
      final historyGroup = _tabGroups.firstWhere((g) => g.id == 'LAINNYA');
      _tabGroups.clear();
      _tabGroups.add(teknisiGroup);
      _tabGroups.add(historyGroup);
      _activeGroup = _tabGroups.first;
    } else if (role == 'NOTA') {
      final gudangGroup = _tabGroups.firstWhere((g) => g.id == 'GUDANG');
      _tabGroups.clear();
      _tabGroups.add(gudangGroup);
      _activeGroup = _tabGroups.first;
    } else if (role == 'GUDANG' || role == 'SPV_GUDANG') {
      // Gudang should not see DRAFT
      final prosesGroup = _tabGroups.firstWhere((g) => g.id == 'PROSES');
      prosesGroup.children.remove(MemoStatus.DRAFT);
      
      // But they should see PENDING, DISETUJUI, DITOLAK (already in PROSES group except DRAFT)
      _activeGroup = _tabGroups[1]; // Default to Gudang tab
    } else {
      _activeGroup = _tabGroups[1]; // Default to Gudang for others
    }
  }

  // Bulk Selection
  bool _isSelectionMode = false;
  final Set<String> _selectedMemoIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMemoIds.clear();
      }
    });
  }

  // Bloc Management
  MemoBloc? __memoBloc;
  MemoBloc get _memoBloc {
    if (__memoBloc == null) {
      __memoBloc = MemoBloc(getIt())..add(LoadMemos(status: _selectedStatus));
    }
    return __memoBloc!;
  }
  // Page & View Management
  PageController? __pageController;
  PageController get _pageController {
    if (__pageController == null) {
      __pageController = PageController(initialPage: _selectedStatusIndex);
    }
    return __pageController!;
  }
  int _selectedStatusIndex = 0;

  @override
  void initState() {
    super.initState();
    final role = getIt<CurrentUserStore>().userRole?.toUpperCase();
    _initTabGroups(role);
    // Pre-initialize
    _memoBloc;
    _pageController;
    _loadEmployeeOptions();
  }

  Future<void> _loadEmployeeOptions() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final options = await getIt<ApiNewEndpoints>().getEmployeeCodes();
      setState(() {
        _employeeOptions = options;
        _isLoadingEmployees = false;
      });
    } catch (_) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    __memoBloc?.close();
    _pageController.dispose();
    _kecamatanFilterController.dispose();
    _searchController.dispose();
    _kodePostFilterController.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();

      // Scanners are extremely fast. Manual typing is slow.
      // If delay between keys is too long (> 100ms), it's probably manual typing.
      if (now.difference(_lastKeyPress).inMilliseconds > 100) {
        _scanBuffer = "";
      }
      _lastKeyPress = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scanBuffer.isNotEmpty) {
          final code = _scanBuffer.trim();
          _scanBuffer = ""; // Reset immediately
          _processScannedCode(code);
        }
      } else {
        // Collect visible characters
        final char = event.character;
        if (char != null) {
          _scanBuffer += char;
        }
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    try {
      // Show loading indicator or just try fetching
      final detail = await getIt<MemoRepository>().getMemoDetail(code);
      
      if (detail != null && mounted) {
        MemoAuthUtils.guardAccess(
          context,
          role: getIt<CurrentUserStore>().userRole,
          status: detail.statusAkhir,
          onGranted: () {
            context.pushNamed(AppRoutes.memoDetail, pathParameters: {'id': code});
          },
        );
      }
    } catch (_) {
      // Ignore errors for global background listener
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    final userRole = userStore.userRole?.toUpperCase();
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return BlocProvider.value(
      value: _memoBloc,
      child: KeyboardListener(
        focusNode: _scannerFocusNode,
        autofocus: true,
        onKeyEvent: _handleHardwareKey,
        child: Builder(
          builder: (context) => Stack(
            children: [
            DashboardShell(
              currentRoute: AppRoutes.memo,
              userName: userStore.displayName,
              userRole: userStore.userRole,
              title: 'Memo Orderan',
              onNavigate: (route) => context.go(route),
              onScan: isMobile
                  ? null
                  : () async {
                      await context.pushNamed(AppRoutes.scanner);
                      if (context.mounted) {
                        _memoBloc.add(LoadMemos(status: _selectedStatus));
                      }
                    },
              headerActions: !isMobile ? [
                HeaderAction(
                  label: 'Scan QR Memo',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () async {
                    await context.pushNamed(AppRoutes.scanner);
                    if (context.mounted) {
                      _memoBloc.add(LoadMemos(status: _selectedStatus));
                    }
                  },
                ),
              ] : [],
              onLogout: () async {
                await getIt<AuthService>().logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              floatingActionButton: isMobile
                  ? FloatingActionButton.extended(
                      onPressed: () => _showCreateMemoTypeSelector(context),
                      label: const Text('Buat Memo'),
                      icon: const Icon(Icons.add_rounded),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: DeckView(
                title: 'Memo Orderan',
                useScrollView: !isMobile,
                actions: [
                    if (!isMobile &&
                        ((userRole != null && userRole.startsWith('MARKETING')) ||
                            userRole == 'ADMIN' ||
                            userRole == 'SPV_MARKETING'))
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () => _showCreateMemoTypeSelector(context),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Buat Memo'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                ],
                child: BlocListener<MemoBloc, MemoState>(
                  listener: (context, state) {
                    if (state is MemoOperationSuccess) {
                      setState(() {
                        _selectedMemoIds.clear();
                        if (state.targetStatus != null) {
                          _selectedStatus = state.targetStatus;
                          // Automatically switch to the tab group containing the new status
                          for (final group in _tabGroups) {
                            if (group.children.contains(state.targetStatus)) {
                              _activeGroup = group;
                              break;
                            }
                          }
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green));
                    } else if (state is MemoError) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red));
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      _buildGroupingTabs(theme, isMobile),
                      const SizedBox(height: 12),
                      _buildSearchField(isMobile),
                      const SizedBox(height: AppSpacing.md),
                      if (!isMobile) ...[
                        _buildAdvancedFilters(userRole),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (isMobile)
                        Expanded(
                          child: BlocBuilder<MemoBloc, MemoState>(
                            builder: (context, state) => _buildUnifiedContentView(state, isMobile, theme, userRole),
                          ),
                        )
                      else
                        BlocBuilder<MemoBloc, MemoState>(
                          builder: (context, state) => _buildUnifiedContentView(state, isMobile, theme, userRole),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedMemoIds.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: BlocBuilder<MemoBloc, MemoState>(
                    builder: (context, state) {
                      List<MemoDetail> selectedMemos = [];
                      if (state is MemoLoaded) {
                        selectedMemos = state.memos
                            .where((m) => _selectedMemoIds.contains(m.id))
                            .toList();
                      }
                      return _BulkActionBar(
                        count: _selectedMemoIds.length,
                        userRole: userRole,
                        selectedMemos: selectedMemos,
                        onClear: _toggleSelectionMode,
                        onPrint: () => context.read<MemoBloc>().add(BulkPrintMemoEvent(selectedMemos)),
                        onChangeStatus: () => _showBulkStatusDialog(context, selectedMemos),
                        onBulkStart: () => _handleBulkStartDelivery(selectedMemos),
                        onBulkFinish: () => _handleBulkFinishDelivery(selectedMemos),
                        onBulkComplete: () => _handleBulkCompleteMemos(selectedMemos),
                        onBulkFinalize: () => _handleBulkFinalize(context, selectedMemos),
                      );
                    },
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  void _showCreateMemoTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pilih Tipe Memo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildMemoTypeButton(
                  context,
                  'Memo Distribusi',
                  'DISTRIBUSI',
                  Icons.local_shipping_outlined,
                  'Pengiriman antar gudang/cabang',
                ),
                const SizedBox(height: 12),
                _buildMemoTypeButton(
                  context,
                  'Memo Biasa',
                  'BIASA',
                  Icons.description_outlined,
                  'Standar transaksi harian',
                ),
                const SizedBox(height: 12),
                _buildMemoTypeButton(
                  context,
                  'Memo Project',
                  'PROJECT',
                  Icons.business_center_outlined,
                  'Transaksi skala besar/tender',
                ),
                const SizedBox(height: 12),
                _buildMemoTypeButton(
                  context,
                  'Memo Online',
                  'ONLINE',
                  Icons.shopping_cart_outlined,
                  'Pesanan dari marketplace',
                ),
                const SizedBox(height: 12),
                _buildMemoTypeButton(
                  context,
                  'Memo Pending',
                  'PENDING',
                  Icons.bookmark_border_rounded,
                  'Booking stok sementara',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupingTabs(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Parent Groups (Chrome Tab Style)
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabGroups.map((group) {
                final bool isActive = _activeGroup.id == group.id;
                return ChromeTab(
                  label: group.label,
                  isActive: isActive,
                  onTap: () {
                    setState(() {
                      _activeGroup = group;
                      _selectedStatus = null; // Reset sub-status when group changes
                    });
                    _memoBloc.add(LoadMemos(status: null));
                  },
                  isParent: true,
                );
              }).toList(),
            ),
          ),
        ),
        
        // Row 2: Sub-Status Children (Chrome Tab Style)
        Container(
          width: double.infinity,
          height: 44,
          margin: const EdgeInsets.only(top: 8),
          child: BlocBuilder<MemoBloc, MemoState>(
            builder: (context, state) {
              final Map<String, int> counts = (state is MemoLoaded) ? (state.counts ?? {}) : {};
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChromeTab(
                      label: 'Semua ${_activeGroup.id}',
                      isActive: _selectedStatus == null,
                      onTap: () {
                        setState(() => _selectedStatus = null);
                        _memoBloc.add(LoadMemos(status: null));
                      },
                      isParent: false,
                    ),
                    ..._activeGroup.children.map((status) {
                      final bool isActive = _selectedStatus == status;
                      final int count = counts[status.name] ?? 0;
                      return ChromeTab(
                        label: status.label,
                        isActive: isActive,
                        count: count,
                        onTap: () {
                          setState(() => _selectedStatus = status);
                          _memoBloc.add(LoadMemos(status: status));
                        },
                        isParent: false,
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedContentView(MemoState state, bool isMobile, ThemeData theme, String? userRole) {
    if (state is MemoLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Memuat memo...',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (state is MemoLoaded) {
      final List<MemoDetail> allMemos = [...state.memos];

      if (allMemos.isEmpty) {
        return _buildEmptyState(context, 'Tidak ada memo ditemukan');
      }
      
      final memos = allMemos.where((m) {
        // If no specific status filter is active, only show memos belonging to the active Tab Group
        if (_selectedStatus == null) {
          if (!_activeGroup.children.contains(m.statusAkhir)) {
            return false;
          }
        }

        bool matchesKecamatan = true;
        if (_selectedKecamatan != null && _selectedKecamatan!.isNotEmpty) {
          matchesKecamatan = m.penjadwalanHistory.any((j) =>
              j.kecamatan?.toLowerCase().contains(_selectedKecamatan!.toLowerCase()) ??
              false);
        }

        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          matchesSearch = (m.customerName?.toLowerCase().contains(query) ?? false) ||
                         (m.orderIdMarketplace?.toLowerCase().contains(query) ?? false) ||
                         (m.nomorMemo?.toLowerCase().contains(query) ?? false);
        }

        bool matchesType = true;
        if (_selectedMemoType != null && _selectedMemoType!.isNotEmpty) {
          matchesType = m.memoType?.toUpperCase() == _selectedMemoType?.toUpperCase();
        }

        bool matchesKodePost = true;
        if (_selectedKodePost != null && _selectedKodePost!.isNotEmpty) {
          matchesKodePost = m.kodePos
                  ?.toLowerCase()
                  .contains(_selectedKodePost!.toLowerCase()) ??
              false;
        }

        bool matchesMarketing = true;
        if (_selectedMarketingFilter != null) {
          matchesMarketing = m.marketingEmpCode == _selectedMarketingFilter!.empCode;
        }

        return matchesKecamatan && matchesSearch && matchesType && matchesKodePost && matchesMarketing;
      }).toList();

      // Apply Sorting
      if (_sortBy == 'date_desc') {
        memos.sort((a, b) => (b.tanggalMemo ?? DateTime(0)).compareTo(a.tanggalMemo ?? DateTime(0)));
      } else if (_sortBy == 'date_asc') {
        memos.sort((a, b) => (a.tanggalMemo ?? DateTime(0)).compareTo(b.tanggalMemo ?? DateTime(0)));
      } else if (_sortBy == 'name_asc') {
        memos.sort((a, b) => (a.customerName ?? '').compareTo(b.customerName ?? ''));
      } else if (_sortBy == 'name_desc') {
        memos.sort((a, b) => (b.customerName ?? '').compareTo(a.customerName ?? ''));
      }

      if (memos.isEmpty) {
        return _buildEmptyState(context, 'Pencarian tidak ditemukan');
      }

      if (isMobile) {
        return _buildMobileDeckView(memos, userRole);
      } else {
        return MemoDesktopTableView(
          memos: memos,
          isSelectionMode: _isSelectionMode,
          selectedIds: _selectedMemoIds,
          onTap: (memo) async {
            if (memo.id!.startsWith('task-')) {
              final taskId = memo.id!.replaceFirst('task-', '');
              MemoAuthUtils.guardManualTaskAccess(
                context,
                role: userRole,
                statusJadwal: memo.statusAkhir?.name,
                onGranted: () async {
                  await context.pushNamed(AppRoutes.manualTaskDetail,
                      pathParameters: {'id': taskId});
                  // Refresh saat kembali dari detail
                  if (context.mounted) {
                    _memoBloc.add(LoadMemos(status: _selectedStatus));
                  }
                },
              );
            } else {
              MemoAuthUtils.guardAccess(
                context,
                role: userRole,
                status: memo.statusAkhir,
                onGranted: () async {
                  await context.pushNamed(AppRoutes.memoDetail,
                      pathParameters: {'id': memo.id!});
                  // Refresh saat kembali dari detail untuk memastikan data paling update
                  if (context.mounted) {
                    _memoBloc.add(LoadMemos(status: _selectedStatus));
                  }
                },
              );
            }
          },
          onSelectionChanged: (id, selected) {
            setState(() {
              if (selected == true) {
                _selectedMemoIds.add(id);
              } else {
                _selectedMemoIds.remove(id);
              }
            });
          },
          onSelectAll: (selected) {
            setState(() {
              if (selected == true) {
                _selectedMemoIds
                    .addAll(memos.map((m) => m.id!).whereType<String>());
              } else {
                _selectedMemoIds.clear();
              }
            });
          },
        );
      }
    } else if (state is MemoError) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(state.error, style: const TextStyle(color: Colors.red)),
      ));
    }
    return const SizedBox();
  }

  MemoStatus _mapJadwalStatusToMemoStatus(String status) {
    switch (status) {
      case 'MENUNGGU_KONFIRMASI':
        return MemoStatus.MENUNGGU_PENGIRIMAN;
      case 'DIJADWALKAN':
        return MemoStatus.DALAM_PENGIRIMAN;
      case 'SELESAI':
        return MemoStatus.DITERIMA_USER;
      default:
        return MemoStatus.MENUNGGU_PENGIRIMAN;
    }
  }


  Widget _buildFilters() {
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
    return BlocBuilder<MemoBloc, MemoState>(
      builder: (context, state) {
        List<MemoStatus> visibleStatuses = MemoStatus.values;
        if (userRole == 'GUDANG' || userRole == 'SPV_GUDANG') {
          visibleStatuses = [
            MemoStatus.PENDING,
            MemoStatus.MENUNGGU_PERSETUJUAN,
            MemoStatus.DISETUJUI,
            MemoStatus.DITOLAK,
            MemoStatus.MENUNGGU_GUDANG,
            MemoStatus.MENUNGGU_NOTA,
            MemoStatus.DIBUAT_NOTA,
            MemoStatus.MENUNGGU_TEKNISI,
            MemoStatus.PROSES_TEKNISI,
            MemoStatus.BUFFER_ZONE,
            MemoStatus.MENUNGGU_PENGIRIMAN,
            MemoStatus.DALAM_PENGIRIMAN,
            MemoStatus.DITERIMA_USER,
            MemoStatus.KENDALA_BARANG,
            MemoStatus.SELESAI
          ];
        } else if (userRole == 'NOTA') {
          visibleStatuses = [
            MemoStatus.MENUNGGU_NOTA,
            MemoStatus.DIBUAT_NOTA
          ];
        } else if (userRole == 'TEKNISI') {
          visibleStatuses = [
            MemoStatus.MENUNGGU_TEKNISI,
            MemoStatus.PROSES_TEKNISI
          ];
        } else if (userRole == 'DELIVERY') {
          visibleStatuses = [
            MemoStatus.MENUNGGU_PENGIRIMAN,
            MemoStatus.DALAM_PENGIRIMAN,
            MemoStatus.DITERIMA_USER,
            MemoStatus.SELESAI
          ];
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  isSelected: _selectedStatus == null,
                  onSelected: () => setState(() {
                    _selectedStatus = null;
                    context.read<MemoBloc>().add(LoadMemos());
                  }),
                ),
                ...visibleStatuses.map((status) {
                  return _FilterChip(
                    label: status.label,
                    isSelected: _selectedStatus == status,
                    onSelected: () => setState(() {
                      _selectedStatus = status;
                      context.read<MemoBloc>().add(LoadMemos(status: status));
                    }),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedFilters(String? userRole) {
    if (userRole != 'DELIVERY' && userRole != 'TEKNISI' && userRole != 'ADMIN')
      return const SizedBox();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: _kecamatanFilterController,
        decoration: InputDecoration(
          hintText: 'Filter Kecamatan...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.location_city_rounded,
              size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: theme.colorScheme.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          suffixIcon: _selectedKecamatan != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedKecamatan = null;
                      _kecamatanFilterController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (val) {
          setState(() {
            _selectedKecamatan = val.isNotEmpty ? val : null;
          });
        },
      ),
    );
  }

  Widget _buildSearchField(bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Nama Pelanggan...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.colorScheme.primary.withOpacity(0.7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMobile) ...[
                  IconButton(
                    onPressed: () async {
                     await context.pushNamed(AppRoutes.scanner);
                     if (context.mounted) {
                       _memoBloc.add(LoadMemos(status: _selectedStatus));
                     }
                   },
                    icon: Icon(Icons.qr_code_scanner_rounded, color: theme.colorScheme.primary),
                    tooltip: 'Scan QR Memo',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ],
                if (!isMobile) ...[
                  IconButton(
                    onPressed: _toggleSelectionMode,
                    icon: Icon(
                      _isSelectionMode ? Icons.close_rounded : Icons.checklist_rtl_rounded,
                      color: _isSelectionMode ? Colors.red : theme.colorScheme.primary,
                    ),
                    tooltip: _isSelectionMode ? 'Batal Pilih' : 'Pilih Banyak',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ],
                IconButton(
                  onPressed: _showFilterBottomSheet,
                  icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                  tooltip: 'Filter & Urutkan',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter & Urutkan',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMemoType = null;
                              _selectedKodePost = null;
                              _selectedMarketingFilter = null;
                              _kodePostFilterController.clear();
                              _sortBy = 'date_desc';
                            });
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Reset Filter',
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // SORTING
                    _buildSectionHeader(theme, Icons.sort_rounded, 'Urutkan'),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'date_desc',
                            label: Text('Terbaru'),
                            icon: Icon(Icons.new_releases_outlined)),
                        ButtonSegment(
                            value: 'date_asc',
                            label: Text('Terlama'),
                            icon: Icon(Icons.history_outlined)),
                        ButtonSegment(
                            value: 'name_asc',
                            label: Text('A-Z'),
                            icon: Icon(Icons.sort_by_alpha_outlined)),
                      ],
                      selected: {_sortBy},
                      onSelectionChanged: (newSelection) {
                        setModalState(
                            () => setState(() => _sortBy = newSelection.first));
                      },
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.comfortable,
                        selectedBackgroundColor: theme.colorScheme.primary,
                        selectedForegroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // MEMO TYPE
                    _buildSectionHeader(
                        theme, Icons.category_outlined, 'Tipe Memo'),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('Semua')),
                          ButtonSegment(value: 'BIASA', label: Text('Biasa')),
                          ButtonSegment(
                              value: 'PROJECT', label: Text('Project')),
                          ButtonSegment(value: 'ONLINE', label: Text('Online')),
                          ButtonSegment(
                              value: 'PENDING', label: Text('Pending')),
                        ],
                        selected: {_selectedMemoType},
                        onSelectionChanged: (newSelection) {
                          setModalState(() => setState(
                              () => _selectedMemoType = newSelection.first));
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          selectedBackgroundColor: theme.colorScheme.primary,
                          selectedForegroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // KODE POST
                    _buildSectionHeader(
                        theme, Icons.local_post_office_outlined, 'Kode Pos'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _kodePostFilterController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Cari Kode Pos...',
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _selectedKodePost != null
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedKodePost = null;
                                    _kodePostFilterController.clear();
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selectedKodePost = val.isNotEmpty ? val : null;
                        });
                      },
                    ),
                    // MARKETING FILTER
                    _buildSectionHeader(
                        theme, Icons.person_search_outlined, 'Marketing'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EmployeeOption>(
                      value: _selectedMarketingFilter,
                      decoration: InputDecoration(
                        hintText: 'Pilih Marketing...',
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<EmployeeOption>(
                          value: null,
                          child: Text('Semua Marketing'),
                        ),
                        ..._employeeOptions.map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.empName),
                            )),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          setState(() => _selectedMarketingFilter = val);
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Terapkan Filter',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(num v) =>
      "Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";

  String _formatDate(DateTime dt) => "${dt.day}/${dt.month}/${dt.year}";

  Widget _buildMemoTypeButton(
    BuildContext context,
    String title,
    String type,
    IconData icon,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await context.push('${AppRoutes.memoCreate}?type=$type');
        if (context.mounted) {
          context.read<MemoBloc>().add(LoadMemos());
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDeckView(List<MemoDetail> memos, String? userRole) {
    return ListView.separated(
      itemCount: memos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final memo = memos[index];
        return _MemoOrderCard(
          memo: memo,
          userRole: userRole,
          isSelected: _selectedMemoIds.contains(memo.id),
          onSelect: (selected) {
            setState(() {
              if (selected) {
                _selectedMemoIds.add(memo.id!);
              } else {
                _selectedMemoIds.remove(memo.id);
              }
            });
          },
          onTap: () async {
            if (_isSelectionMode || _selectedMemoIds.isNotEmpty) {
              setState(() {
                if (_selectedMemoIds.contains(memo.id)) {
                  _selectedMemoIds.remove(memo.id);
                } else {
                  _selectedMemoIds.add(memo.id!);
                }
              });
            } else {
              if (memo.id!.startsWith('task-')) {
                final taskId = memo.id!.replaceFirst('task-', '');
                MemoAuthUtils.guardManualTaskAccess(
                  context,
                  role: userRole,
                  statusJadwal: memo.statusAkhir?.name,
                  onGranted: () async {
                    await context.pushNamed(AppRoutes.manualTaskDetail,
                        pathParameters: {'id': taskId});
                    if (context.mounted) {
                      _memoBloc.add(LoadMemos(status: _selectedStatus));
                    }
                  },
                );
              } else {
                MemoAuthUtils.guardAccess(
                  context,
                  role: userRole,
                  status: memo.statusAkhir,
                  onGranted: () async {
                    await context.pushNamed(AppRoutes.memoDetail,
                        pathParameters: {'id': memo.id!});
                    if (context.mounted) {
                      _memoBloc.add(LoadMemos(status: _selectedStatus));
                    }
                  },
                );
              }
            }
          },
        );
      },
    );
  }

  void _handleBulkFinalize(BuildContext context, List<MemoDetail> selectedMemos) {
    final draftMemos = selectedMemos.where((m) => m.statusAkhir == MemoStatus.DRAFT).toList();
    if (draftMemos.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: Colors.teal),
            SizedBox(width: 12),
            Text('Kirim ke Gudang'),
          ],
        ),
        content: Text(
          'Kirim ${draftMemos.length} memo dari Draft ke Menunggu Gudang?\nPastikan semua data sudah benar.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final memo in draftMemos) {
                context.read<MemoBloc>().add(FinalizeMemoEvent(memo.id!));
              }
              _toggleSelectionMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Kirim Sekarang'),
          ),
        ],
      ),
    );
  }

  void _handleBulkStartDelivery(List<MemoDetail> selectedMemos) {
    final List<int> penjadwalanIds = selectedMemos
        .map((m) => m.penjadwalanHistory.lastOrNull?.id)
        .whereType<int>()
        .toList();

    if (penjadwalanIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada jadwal aktif pada memo yang dipilih'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    _memoBloc.add(BulkMulaiDeliveryEvent(penjadwalanIds));
    _toggleSelectionMode();
  }

  Future<void> _handleBulkFinishDelivery(List<MemoDetail> selectedMemos) async {
    final List<int> penjadwalanIds = selectedMemos
        .map((m) => m.penjadwalanHistory.lastOrNull?.id)
        .whereType<int>()
        .toList();

    if (penjadwalanIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada jadwal aktif pada memo yang dipilih'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final theme = Theme.of(context);
    XFile? photo;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Selesaikan Kirim Massal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Akan menyelesaikan ${penjadwalanIds.length} pengiriman.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await Navigator.push<XFile>(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    );
                    if (picked != null) {
                      setModalState(() => photo = picked);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: photo == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Ambil Foto Bukti (Wajib)',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(photo!.path),
                                fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima (Wajib)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (photo == null || nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Foto dan Nama Penerima wajib diisi'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                _memoBloc.add(BulkSelesaikanDeliveryEvent(
                      penjadwalanIds: penjadwalanIds,
                      photo: photo!,
                      namaPenerima: nameController.text.trim(),
                      catatan: notesController.text.trim(),
                    ));
                Navigator.pop(ctx);
                _toggleSelectionMode();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBulkCompleteMemos(List<MemoDetail> selectedMemos) {
    final List<String> ids = selectedMemos
        .map((m) => m.id)
        .whereType<String>()
        .toList();

    if (ids.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Selesaikan Memo'),
        content: Text('Apakah Anda yakin ingin menyelesaikan ${ids.length} memo terpilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              _memoBloc.add(BulkCompleteMemoEvent(ids));
              Navigator.pop(ctx);
              _toggleSelectionMode();
            },
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusDialog(
      BuildContext context, List<MemoDetail> selectedMemos) {
    final theme = Theme.of(context);
    MemoStatus? targetStatus;
    final TextEditingController keteranganController = TextEditingController();

    // Calculate possible next statuses based on selected items
    final Set<MemoStatus> possibleStatuses = {};
    for (var m in selectedMemos) {
      if (m.statusAkhir != null) {
        possibleStatuses.addAll(m.statusAkhir!.nextPossibleStatuses);
      }
    }

    final List<MemoStatus> displayStatuses = possibleStatuses.isEmpty
        ? MemoStatus.values
            .where((s) => ![MemoStatus.DELETED, MemoStatus.DRAFT].contains(s))
            .toList()
        : possibleStatuses.toList();

    // Sort for consistency
    displayStatuses.sort((a, b) => a.index.compareTo(b.index));

    final TextEditingController jlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Ubah Status Massal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Akan mengubah ${selectedMemos.length} memo.',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                DropdownButtonFormField<MemoStatus>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Status Baru',
                    border: OutlineInputBorder(),
                  ),
                  items: displayStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) => setLocalState(() => targetStatus = v),
                ),
                if (targetStatus == MemoStatus.DIBUAT_NOTA) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: jlController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor JL / Invoice',
                      hintText: 'JL-XXX-XXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: keteranganController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (targetStatus != null) {
                    final jl = jlController.text.trim();
                    if (targetStatus == MemoStatus.DIBUAT_NOTA) {
                      if (jl.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Nomor JL tidak boleh kosong")));
                        return;
                      }
                      if (!jl.toUpperCase().startsWith("JL-")) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "Format JL tidak valid (harus diawali 'JL-')")));
                        return;
                      }
                    }

                    _memoBloc.add(BulkUpdateMemoStatusEvent(
                      _selectedMemoIds.toList(),
                      targetStatus!,
                      keteranganController.text,
                      nomorJl: targetStatus == MemoStatus.DIBUAT_NOTA ? jl : null,
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Ubah Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.note_alt_outlined,
                  size: 64, color: Colors.blue.shade200),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan coba filter atau pencarian lain',
              style: TextStyle(fontSize: 14, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final memoBloc = context.read<MemoBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: memoBloc,
        child: Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter Memo',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('Status', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildFilters(), // Reuse the existing Chip filter
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tampilkan Hasil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoOrderCard extends StatelessWidget {
  final MemoDetail memo;
  final String? userRole;
  final VoidCallback onTap;
  final bool isSelected;
  final Function(bool) onSelect;

  const _MemoOrderCard({
    required this.memo,
    this.userRole,
    required this.onTap,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = memo.statusAkhir ?? MemoStatus.MENUNGGU_PERSETUJUAN;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => onSelect(true),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Info & Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _toTitleCase(memo.customerName ?? 'No Name'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#MEMO-${memo.nomorMemo ?? memo.id?.substring(0, 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatRupiah(memo.totalHarga),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E40AF),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memo.tanggalMemo != null
                            ? _formatDate(memo.tanggalMemo!)
                            : '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(thickness: 1, color: Color(0xFFF1F5F9)),
              ),
              // Bottom Section: Status & Type
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: status),
                    if (memo.opsiPengiriman != null)
                      _buildOpsiBadge(memo, theme),
                    _buildTypeBadge(memo.memoType, theme),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String? type, ThemeData theme) {
    String label = type?.toUpperCase() ?? 'BIASA';
    Color color = Colors.grey;
    if (label == 'PROJECT') color = Colors.indigo;
    if (label == 'ONLINE') color = Colors.orange;
    if (label == 'PENDING') color = Colors.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOpsiBadge(MemoDetail memo, ThemeData theme) {
    // Kebutuhan Marketing Online: Tampilkan Ekspedisi jika ada
    if ((memo.memoType == 'ONLINE' || userRole == 'MARKETING_ONLINE') && 
        memo.ekspedisi != null && memo.ekspedisi!.isNotEmpty) {
      
      Color badgeColor = Colors.orange.shade700;
      final eks = memo.ekspedisi!.toUpperCase();
      if (eks.contains('INSTAN')) {
        badgeColor = Colors.green.shade700;
      } else if (eks.contains('ANDI')) {
        badgeColor = Colors.purple.shade700;
      } else if (eks.contains('REGULER') || eks.contains('REGULAR')) {
        badgeColor = Colors.blue.shade700;
      }

      return _createOpsiBadge(
        eks, 
        badgeColor, 
        Icons.local_shipping_rounded
      );
    }

    final String opsi = memo.opsiPengiriman ?? '';
    final bool isDelivery = memo.isDeliveryRequired ||
        opsi.toUpperCase().contains('DELIVERY') ||
        opsi.toUpperCase().contains('KIRIM') ||
        opsi.toUpperCase().contains('DIKIRIM') ||
        opsi.toUpperCase().contains('MARKETING') ||
        opsi.toUpperCase().contains('DRIVER');

    if (!isDelivery) {
      return _createOpsiBadge(
          'AMBIL DI TOKO', Colors.deepOrange, Icons.store_rounded);
    }

    // Check if any delivery task is assigned to MARKETING
    final isMarketingDelivery = memo.isMarketingDelivery;

    final String label =
        isMarketingDelivery ? 'DIKIRIM (MARKETING)' : 'DIKIRIM (DELIVERY)';
    final Color color = isMarketingDelivery ? Colors.purple : Colors.blue;

    return _createOpsiBadge(label, color, Icons.local_shipping_rounded);
  }

  Widget _createOpsiBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _infoIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatRupiah(num v) =>
      "Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";

  String _formatDate(DateTime dt) => "${dt.day}/${dt.month}/${dt.year}";
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
          ),
        ),
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int count;
  final String? userRole;
  final List<MemoDetail> selectedMemos;
  final VoidCallback onClear;
  final VoidCallback onPrint;
  final VoidCallback onChangeStatus;
  final VoidCallback onBulkStart;
  final VoidCallback onBulkFinish;
  final VoidCallback onBulkComplete;
  final VoidCallback onBulkFinalize;

  const _BulkActionBar({
    required this.count,
    this.userRole,
    required this.selectedMemos,
    required this.onClear,
    required this.onPrint,
    required this.onChangeStatus,
    required this.onBulkStart,
    required this.onBulkFinish,
    required this.onBulkComplete,
    required this.onBulkFinalize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Check if ALL selected memos are DRAFT
    final allDraft = selectedMemos.isNotEmpty &&
        selectedMemos.every((m) => m.statusAkhir == MemoStatus.DRAFT);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count Terpilih',
              style: TextStyle(
                color: theme.colorScheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (allDraft) ...[
              // DRAFT mode: show Finalize instead of Print & Status
              _ActionIcon(
                icon: Icons.send_rounded,
                label: 'Kirim ke Gudang',
                onTap: onBulkFinalize,
              ),
            ] else if (userRole != 'DELIVERY') ...[
              _ActionIcon(
                icon: Icons.print_outlined,
                label: 'Cetak',
                onTap: onPrint,
              ),
              _ActionIcon(
                icon: Icons.edit_note_outlined,
                label: 'Status',
                onTap: onChangeStatus,
              ),
            ] else ...[
              _ActionIcon(
                icon: Icons.local_shipping_outlined,
                label: 'Mulai Kirim',
                onTap: onBulkStart,
              ),
              _ActionIcon(
                icon: Icons.check_circle_outline_rounded,
                label: 'Selesai Kirim',
                onTap: onBulkFinish,
              ),
            ],
            if (!allDraft && userRole != 'DELIVERY') ...[
              _ActionIcon(
                icon: Icons.verified_rounded,
                label: 'Selesaikan',
                onTap: onBulkComplete,
              ),
            ],
            const SizedBox(
              height: 24,
              child: VerticalDivider(color: Colors.white24, width: 24),
            ),
            _ActionIcon(
              icon: Icons.close_rounded,
              label: 'Batal',
              onTap: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

