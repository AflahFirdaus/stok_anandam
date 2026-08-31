import 'dart:io';
import 'dart:async';
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
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/features/memo/widgets/status_badge.dart';
import 'package:stok_anandam/features/memo/widgets/memo_desktop_table_view.dart';
import 'package:stok_anandam/features/memo/utils/memo_print_utils.dart';
import 'package:stok_anandam/features/memo/widgets/chrome_tab.dart';
import 'package:stok_anandam/features/memo/utils/memo_auth_utils.dart';
import 'package:stok_anandam/features/presence/mixins/presence_action_mixin.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> with PresenceActionMixin {
  MemoStatus? _selectedStatus;
  String? _selectedKecamatan;
  final TextEditingController _kecamatanFilterController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // New Filters
  String? _selectedMemoType;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date_desc'; // date_desc, date_asc, name_asc, name_desc
  EmployeeOption? _selectedMarketingFilter;
  List<EmployeeOption> _employeeOptions = [];
  String? _selectedEkspedisi; // ANDI, REGULER, INSTANT
  int _currentPage = 1;
  static const int _pageSize = 50;

  // Hardware Scanner Logic (Windows/Desktop)
  final FocusNode _scannerFocusNode = FocusNode();
  String _scanBuffer = "";
  DateTime _lastKeyPress = DateTime.now();

  // Tab Grouping
  late final List<ChromeTabGroup<MemoStatus>> _tabGroups;
  late ChromeTabGroup<MemoStatus> _activeGroup;
  bool _isSemuaActive = false; // Track if "SEMUA" tab is active

  /// Jika role butuh filter memoType dari backend (misal MARKETING_ONLINE & SPV_MARKETING → 'ONLINE').
  /// Dikirim sebagai query param ?memoType= ke setiap LoadMemos agar backend tahu.
  String? _roleMemoTypeFilter;

  void _initTabGroups(String? role) {
    _tabGroups = [
      // SECTION "SEMUA" - ditempatkan paling kiri untuk melihat semua memo
      ChromeTabGroup(
        id: 'SEMUA',
        label: 'SEMUA',
        children: MemoStatus.values, // Semua status masuk
      ),
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
      // SEMUA tab tetap ditambahkan untuk semua role
      _tabGroups.add(ChromeTabGroup(
        id: 'SEMUA',
        label: 'SEMUA',
        children: MemoStatus.values,
      ));
      _tabGroups.add(teknisiGroup);
      _tabGroups.add(historyGroup);
      _activeGroup = _tabGroups.first;
    } else if (role == 'NOTA') {
      final gudangGroup = _tabGroups.firstWhere((g) => g.id == 'GUDANG');
      _tabGroups.clear();
      _tabGroups.add(ChromeTabGroup(
        id: 'SEMUA',
        label: 'SEMUA',
        children: MemoStatus.values,
      ));
      _tabGroups.add(gudangGroup);
      _activeGroup = _tabGroups.first;
    } else if (role == 'GUDANG' || role == 'SPV_GUDANG') {
      // Gudang should not see DRAFT
      final prosesGroup = _tabGroups.firstWhere((g) => g.id == 'PROSES');
      prosesGroup.children.remove(MemoStatus.DRAFT);

      // But they should see PENDING, DISETUJUI, DITOLAK (already in PROSES group except DRAFT)
      _activeGroup = _tabGroups[
          2]; // Default to Gudang tab (index 2 karena SEMUA di index 0)
    } else if (role == 'MARKETING_ONLINE' || role == 'SPV_MARKETING') {
      // Marketing Online & SPV Marketing: default to PROSES tab so they can
      // see DRAFT ONLINE memos they've created (which start in DRAFT status).
      // GUDANG tab only shows MENUNGGU_GUDANG/NOTA/BUFFER_ZONE, hiding new drafts.
      _activeGroup = _tabGroups[1]; // PROSES group (index 1)
    } else {
      _activeGroup = _tabGroups[2]; // Default to Gudang for others
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
    __memoBloc ??= MemoBloc(getIt())
      ..add(LoadMemos(status: _selectedStatus, memoType: _roleMemoTypeFilter));
    return __memoBloc!;
  }

  // Page & View Management
  PageController? __pageController;
  PageController get _pageController {
    __pageController ??= PageController(initialPage: _selectedStatusIndex);
    return __pageController!;
  }

  final int _selectedStatusIndex = 0;

  @override
  void initState() {
    super.initState();
    final role = getIt<CurrentUserStore>().userRole?.toUpperCase();
    _initTabGroups(role);

    // Set role-based backend memoType filter
    // MARKETING_ONLINE dan SPV_MARKETING perlu melihat SEMUA memo ONLINE
    // (termasuk yg dibuat oleh user lain), bukan hanya milik sendiri.
    if (role == 'MARKETING_ONLINE' || role == 'SPV_MARKETING') {
      _roleMemoTypeFilter = 'ONLINE';
    }

    // Pre-initialize
    _memoBloc;
    _pageController;
    _loadEmployeeOptions();
  }

  Future<void> _loadEmployeeOptions() async {
    try {
      final options = await getIt<ApiNewEndpoints>().getEmployeeCodes();
      setState(() {
        _employeeOptions = options;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    __memoBloc?.close();
    _pageController.dispose();
    _kecamatanFilterController.dispose();
    _searchController.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();

      // Scanners are extremely fast. Manual typing is slow.
      // If delay between keys is too long (> 100ms), it's probably manual typing.
      if (now.difference(_lastKeyPress).inMilliseconds > 200) {
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
      final userRole = getIt<CurrentUserStore>().userRole;
      final isUuid = code.length == 36 && code.contains('-');

      if (isUuid) {
        // Treat as memo UUID
        final detail = await getIt<MemoRepository>().getMemoDetail(code);
        if (detail != null && mounted) {
          MemoAuthUtils.guardAccess(
            context,
            role: userRole,
            status: detail.statusAkhir,
            onGranted: () {
              context.pushNamed(AppRoutes.memoDetail,
                  pathParameters: {'id': code});
            },
          );
        } else if (mounted) {
          _showScanError('Memo dengan kode tersebut tidak ditemukan');
        }
      } else {
        // Pakai smart search barcode (backend: exact resi → exact orderId → exact nomorMemo → partial resi → partial orderId)
        // Lebih cepat dan akurat daripada sequential searchByResi + searchByOrderId
        List<MemoDetail> results =
            await getIt<MemoRepository>().searchMemoByBarcode(code);

        if (results.isNotEmpty && mounted) {
          final matchedMemo = results.first;
          MemoAuthUtils.guardAccess(
            context,
            role: userRole,
            status: matchedMemo.statusAkhir,
            onGranted: () {
              context.pushNamed(AppRoutes.memoDetail,
                  pathParameters: {'id': matchedMemo.id!});
            },
          );
        } else if (mounted) {
          _showScanError('Tidak ditemukan memo untuk kode: $code');
        }
      }
    } catch (e) {
      // Tampilkan error ke user, bukan diam saja
      if (mounted) {
        _showScanError('Gagal memproses scan: ${e.toString()}');
      }
    }
  }

  void _showScanError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
          builder: (context) {
            // For mobile: swipe from right edge to open filter
            if (isMobile) {
              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  // Only trigger if swiping left (negative velocity) from right edge
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -300) {
                    _showFilterBottomSheet();
                  }
                },
                child: _buildMemoContent(
                  isMobile: isMobile,
                  theme: theme,
                  userRole: userRole,
                  userStore: userStore,
                ),
              );
            }
            return _buildMemoContent(
              isMobile: isMobile,
              theme: theme,
              userRole: userRole,
              userStore: userStore,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMemoContent({
    required bool isMobile,
    required ThemeData theme,
    required String? userRole,
    required CurrentUserStore userStore,
  }) {
    return Stack(
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
                    _memoBloc.add(LoadMemos(
                        status: _selectedStatus,
                        memoType: _roleMemoTypeFilter));
                  }
                },
          onHeaderAction: (_selectedStatus == MemoStatus.MENUNGGU_NOTA ||
                  _selectedStatus == MemoStatus.MENUNGGU_GUDANG ||
                  _activeGroup.id == 'GUDANG')
              ? () => _memoBloc.add(RetryAutoMatchJlBulkEvent())
              : null,
          headerActionLabel: 'Cari JL Massal',
          headerActionIcon: Icons.sync_rounded,
          headerActions: !isMobile
              ? [
                  HeaderAction(
                    label: 'Scan QR Memo',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () async {
                      await context.pushNamed(AppRoutes.scanner);
                      if (context.mounted) {
                        _memoBloc.add(LoadMemos(
                            status: _selectedStatus,
                            memoType: _roleMemoTypeFilter));
                      }
                    },
                  ),
                ]
              : [],
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
                      userRole == 'MANAGER' ||
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
                          _isSemuaActive = group.id == 'SEMUA';
                          break;
                        }
                      }
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green));
                } else if (state is MemoDuplicateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green));
                  context
                      .push(
                    '${AppRoutes.memoCreate}?type=${state.createdMemo.memoType ?? 'BIASA'}&isNewDuplicate=true',
                    extra: state.createdMemo,
                  )
                      .then((_) {
                    if (mounted) {
                      _memoBloc.add(LoadMemos(
                          status: _selectedStatus,
                          memoType: _roleMemoTypeFilter));
                    }
                  });
                } else if (state is MemoError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.error), backgroundColor: Colors.red));
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
                        builder: (context, state) => _buildUnifiedContentView(
                            state, isMobile, theme, userRole),
                      ),
                    )
                  else
                    BlocBuilder<MemoBloc, MemoState>(
                      builder: (context, state) => _buildUnifiedContentView(
                          state, isMobile, theme, userRole),
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
                    onPrint: () => context
                        .read<MemoBloc>()
                        .add(BulkPrintMemoEvent(selectedMemos)),
                    onChangeStatus: () =>
                        _showBulkStatusDialog(context, selectedMemos),
                    onBulkStart: () => _handleBulkStartDelivery(selectedMemos),
                    onBulkFinish: () =>
                        _handleBulkFinishDelivery(selectedMemos),
                    onBulkComplete: () =>
                        _handleBulkCompleteMemos(selectedMemos),
                    onBulkFinalize: () =>
                        _handleBulkFinalize(context, selectedMemos),
                    onPrintAlamat: () =>
                        MemoPrintUtils.printShippingAddresses(selectedMemos),
                  );
                },
              ),
            ),
          ),
      ],
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
                      _isSemuaActive = group.id == 'SEMUA';
                      _selectedStatus =
                          null; // Reset sub-status when group changes
                      _currentPage = 1;
                    });
                    _memoBloc.add(
                        LoadMemos(status: null, memoType: _roleMemoTypeFilter));
                  },
                  isParent: true,
                );
              }).toList(),
            ),
          ),
        ),

        // Row 2: Sub-Status Children (Chrome Tab Style)
        // Hanya tampilkan children bar jika bukan tab "SEMUA"
        if (!_isSemuaActive)
          Container(
            width: double.infinity,
            height: 44,
            margin: const EdgeInsets.only(top: 8),
            child: BlocBuilder<MemoBloc, MemoState>(
              builder: (context, state) {
                final Map<String, int> counts =
                    (state is MemoLoaded) ? (state.counts ?? {}) : {};

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChromeTab(
                        label: 'Semua ${_activeGroup.id}',
                        isActive: _selectedStatus == null,
                        onTap: () {
                          setState(() {
                            _selectedStatus = null;
                            _currentPage = 1;
                          });
                          _memoBloc.add(LoadMemos(
                              status: null, memoType: _roleMemoTypeFilter));
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
                            setState(() {
                              _selectedStatus = status;
                              _currentPage = 1;
                            });
                            _memoBloc.add(LoadMemos(
                                status: status, memoType: _roleMemoTypeFilter));
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

  Widget _buildUnifiedContentView(
      MemoState state, bool isMobile, ThemeData theme, String? userRole) {
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
        // Jika tab "SEMUA" aktif, tampilkan SEMUA memo tanpa filter status
        if (_isSemuaActive) {
          // Tetap terapkan filter lainnya (search, kecamatan, type, dll)
        } else {
          // If no specific status filter is active, only show memos belonging to the active Tab Group
          if (_selectedStatus == null) {
            if (!_activeGroup.children.contains(m.statusAkhir)) {
              return false;
            }
          }
        }

        bool matchesKecamatan = true;
        if (_selectedKecamatan != null && _selectedKecamatan!.isNotEmpty) {
          matchesKecamatan = m.penjadwalanHistory.any((j) =>
              j.kecamatan
                  ?.toLowerCase()
                  .contains(_selectedKecamatan!.toLowerCase()) ??
              false);
        }

        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          matchesSearch = (m.customerName?.toLowerCase().contains(query) ??
                  false) ||
              (m.orderIdMarketplace?.toLowerCase().contains(query) ?? false) ||
              (m.nomorMemo?.toLowerCase().contains(query) ?? false);
        }

        bool matchesType = true;
        if (_selectedMemoType != null && _selectedMemoType!.isNotEmpty) {
          matchesType =
              m.memoType?.toUpperCase() == _selectedMemoType?.toUpperCase();
        }

        bool matchesMarketing = true;
        if (_selectedMarketingFilter != null) {
          matchesMarketing =
              m.marketingEmpCode == _selectedMarketingFilter!.empCode;
        }

        bool matchesEkspedisi = true;
        if (_selectedEkspedisi != null && _selectedEkspedisi!.isNotEmpty) {
          if (m.ekspedisi == null || m.ekspedisi!.isEmpty) {
            matchesEkspedisi = false;
          } else {
            final eks = m.ekspedisi!.toUpperCase();
            if (_selectedEkspedisi == 'ANDI') {
              matchesEkspedisi = eks.contains('ANDI');
            } else if (_selectedEkspedisi == 'REGULER') {
              matchesEkspedisi =
                  eks.contains('REGULER') || eks.contains('REGULAR');
            } else if (_selectedEkspedisi == 'INSTANT') {
              matchesEkspedisi = eks.contains('INSTAN');
            }
          }
        }

        bool matchesDate = true;
        if (_startDate != null || _endDate != null) {
          if (m.tanggalMemo == null) {
            matchesDate = false;
          } else {
            final memoDate = DateTime(
                m.tanggalMemo!.year, m.tanggalMemo!.month, m.tanggalMemo!.day);
            if (_startDate != null) {
              final start = DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day);
              if (memoDate.isBefore(start)) {
                matchesDate = false;
              }
            }
            if (_endDate != null) {
              final end =
                  DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
              if (memoDate.isAfter(end)) {
                matchesDate = false;
              }
            }
          }
        }

        return matchesKecamatan &&
            matchesSearch &&
            matchesType &&
            matchesMarketing &&
            matchesEkspedisi &&
            matchesDate;
      }).toList();

      // Untuk tab SEMUA, sortir descending by date (terbaru di atas) secara default
      // Untuk tab lainnya, gunakan sortBy yang dipilih user
      if (_isSemuaActive) {
        memos.sort((a, b) => (b.tanggalMemo ?? DateTime(0))
            .compareTo(a.tanggalMemo ?? DateTime(0)));
      } else {
        // Apply Sorting sesuai pilihan user
        if (_sortBy == 'date_desc') {
          memos.sort((a, b) => (b.tanggalMemo ?? DateTime(0))
              .compareTo(a.tanggalMemo ?? DateTime(0)));
        } else if (_sortBy == 'date_asc') {
          memos.sort((a, b) => (a.tanggalMemo ?? DateTime(0))
              .compareTo(b.tanggalMemo ?? DateTime(0)));
        } else if (_sortBy == 'name_asc') {
          memos.sort(
              (a, b) => (a.customerName ?? '').compareTo(b.customerName ?? ''));
        } else if (_sortBy == 'name_desc') {
          memos.sort(
              (a, b) => (b.customerName ?? '').compareTo(a.customerName ?? ''));
        }
      }

      if (memos.isEmpty) {
        return _buildEmptyState(context, 'Pencarian tidak ditemukan');
      }

      // Paginate Memos
      final int totalItems = memos.length;
      final int totalPages = (totalItems / _pageSize).ceil();
      if (_currentPage > totalPages && totalPages > 0) {
        _currentPage = totalPages;
      } else if (_currentPage < 1) {
        _currentPage = 1;
      }

      final int startIndex = (_currentPage - 1) * _pageSize;
      final int endIndex = (startIndex + _pageSize < totalItems)
          ? startIndex + _pageSize
          : totalItems;
      final List<MemoDetail> paginatedMemos =
          totalItems > 0 ? memos.sublist(startIndex, endIndex) : [];

      if (isMobile) {
        return Column(
          children: [
            Expanded(child: _buildMobileDeckView(paginatedMemos, userRole)),
            _buildPaginationControls(totalPages, totalItems, theme),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MemoDesktopTableView(
              memos: paginatedMemos,
              isSelectionMode: _isSelectionMode,
              selectedIds: _selectedMemoIds,
              onInputJl: (memo) => _showJlInputDialog(context, memo),
              onDuplicate: (memo, {required isRevision}) =>
                  _handleDuplicate(memo, isRevision: isRevision),
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
                        _memoBloc.add(LoadMemos(
                            status: _selectedStatus,
                            memoType: _roleMemoTypeFilter));
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
                        _memoBloc.add(LoadMemos(
                            status: _selectedStatus,
                            memoType: _roleMemoTypeFilter));
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
                    _selectedMemoIds.addAll(
                        paginatedMemos.map((m) => m.id!).whereType<String>());
                  } else {
                    _selectedMemoIds.clear();
                  }
                });
              },
            ),
            _buildPaginationControls(totalPages, totalItems, theme),
          ],
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

  Widget _buildPaginationControls(
      int totalPages, int totalItems, ThemeData theme) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
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
                'Halaman $_currentPage dari ${totalPages > 0 ? totalPages : 1} • Total $totalItems item',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _currentPage < totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
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
      ),
    );
  }

  Widget _buildAdvancedFilters(String? userRole) {
    if (userRole != 'DELIVERY' &&
        userRole != 'TEKNISI' &&
        userRole != 'ADMIN' &&
        userRole != 'MANAGER') {
      return const SizedBox();
    }

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
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7)),
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
                      _currentPage = 1;
                    });
                  },
                )
              : null,
        ),
        onChanged: (val) {
          setState(() {
            _selectedKecamatan = val.isNotEmpty ? val : null;
            _currentPage = 1;
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _debounce?.cancel();
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _currentPage = 1;
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
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                });
              },
            ),
          ),
          if (isMobile) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showFilterBottomSheet,
                icon:
                    Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                tooltip: 'Filter & Urutkan',
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _toggleSelectionMode,
                    icon: Icon(
                      _isSelectionMode
                          ? Icons.close_rounded
                          : Icons.checklist_rtl_rounded,
                      color: _isSelectionMode
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    tooltip: _isSelectionMode ? 'Batal Pilih' : 'Pilih Banyak',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  IconButton(
                    onPressed: _showFilterBottomSheet,
                    icon: Icon(Icons.tune_rounded,
                        color: theme.colorScheme.primary),
                    tooltip: 'Filter & Urutkan',
                  ),
                ],
              ),
            ),
          ],
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
                              _selectedMarketingFilter = null;
                              _selectedEkspedisi = null;
                              _startDate = null;
                              _endDate = null;
                              _sortBy = 'date_desc';
                              _currentPage = 1;
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

                    // AKSI CEPAT (Mobile Only)
                    if (MediaQuery.sizeOf(context).width < 720) ...[
                      _buildSectionHeader(
                          theme, Icons.flash_on_rounded, 'Aksi Cepat'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          _toggleSelectionMode();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                _isSelectionMode
                                    ? Icons.close_rounded
                                    : Icons.checklist_rtl_rounded,
                                color: _isSelectionMode
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isSelectionMode
                                    ? 'Batal Pilih Banyak'
                                    : 'Pilih Banyak',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await context.pushNamed(AppRoutes.scanner);
                          if (context.mounted) {
                            _memoBloc.add(LoadMemos(
                                status: _selectedStatus,
                                memoType: _roleMemoTypeFilter));
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded,
                                  color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Scan QR Memo',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],

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
                        setModalState(() {
                          setState(() {
                            _sortBy = newSelection.first;
                            _currentPage = 1;
                          });
                        });
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
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedMemoType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Tipe Memo'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'BIASA',
                          child: Text('Memo Biasa'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'DISTRIBUSI',
                          child: Text('Memo Distribusi'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'PROJECT',
                          child: Text('Memo Projek'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'ONLINE',
                          child: Text('Memo Online'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'PENDING',
                          child: Text('Memo Pending'),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          setState(() {
                            _selectedMemoType = val;
                            _currentPage = 1;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // RENTANG TANGGAL
                    _buildSectionHeader(
                        theme, Icons.date_range_rounded, 'Rentang Tanggal'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  setState(() {
                                    _startDate = picked;
                                    if (_endDate != null &&
                                        _endDate!.isBefore(picked)) {
                                      _endDate = picked;
                                    }
                                    _currentPage = 1;
                                  });
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 16),
                            label: Text(
                              _startDate == null
                                  ? 'Mulai'
                                  : _formatDate(_startDate!),
                              style: TextStyle(
                                fontSize: 13,
                                color: _startDate != null
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade700,
                                fontWeight: _startDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: _startDate != null
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                width: _startDate != null ? 1.5 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child:
                              Text('s/d', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  setState(() {
                                    _endDate = picked;
                                    if (_startDate != null &&
                                        _startDate!.isAfter(picked)) {
                                      _startDate = picked;
                                    }
                                    _currentPage = 1;
                                  });
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 16),
                            label: Text(
                              _endDate == null
                                  ? 'Selesai'
                                  : _formatDate(_endDate!),
                              style: TextStyle(
                                fontSize: 13,
                                color: _endDate != null
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade700,
                                fontWeight: _endDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: _endDate != null
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                width: _endDate != null ? 1.5 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (_startDate != null || _endDate != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.red),
                            onPressed: () {
                              setModalState(() {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                  _currentPage = 1;
                                });
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // MARKETING FILTER
                    _buildSectionHeader(
                        theme, Icons.person_search_outlined, 'Marketing'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EmployeeOption>(
                      initialValue: _selectedMarketingFilter,
                      decoration: InputDecoration(
                        hintText: 'Pilih Marketing...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
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
                          setState(() {
                            _selectedMarketingFilter = val;
                            _currentPage = 1;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // EKSPEDISI FILTER
                    _buildSectionHeader(
                        theme, Icons.local_shipping_outlined, 'Ekspedisi'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedEkspedisi,
                      decoration: InputDecoration(
                        hintText: 'Pilih Ekspedisi...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Ekspedisi'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'ANDI',
                          child: Text('ANDI'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'REGULER',
                          child: Text('REGULER'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'INSTANT',
                          child: Text('INSTANT'),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          setState(() {
                            _selectedEkspedisi = val;
                            _currentPage = 1;
                          });
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
        Icon(icon,
            size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

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
          context
              .read<MemoBloc>()
              .add(LoadMemos(memoType: _roleMemoTypeFilter));
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
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
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
        return GestureDetector(
          onLongPressStart: (details) {
            if (_isSelectionMode || _selectedMemoIds.isNotEmpty) {
              // Selection mode: toggle this memo's selection
              setState(() {
                if (_selectedMemoIds.contains(memo.id)) {
                  _selectedMemoIds.remove(memo.id);
                } else {
                  _selectedMemoIds.add(memo.id!);
                }
              });
            } else {
              // Normal mode: show context menu (duplicate/revision)
              _showContextMenu(context, details.globalPosition, memo);
            }
          },
          child: _MemoOrderCard(
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
                        _memoBloc.add(LoadMemos(
                            status: _selectedStatus,
                            memoType: _roleMemoTypeFilter));
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
                        _memoBloc.add(LoadMemos(
                            status: _selectedStatus,
                            memoType: _roleMemoTypeFilter));
                      }
                    },
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  void _handleDuplicate(MemoDetail memo, {required bool isRevision}) {
    final cloned = MemoDetail(
      id: null,
      nomorMemo: null,
      customerId: memo.customerId,
      pelangganMybizId: memo.pelangganMybizId,
      customerPhone: memo.customerPhone,
      customerName: memo.customerName,
      tanggalMemo: DateTime.now(),
      totalHarga: isRevision ? memo.totalHarga : 0,
      deskripsi: memo.deskripsi,
      statusAkhir: MemoStatus.DRAFT,
      isTeknisRequired: memo.isTeknisRequired,
      isDeliveryRequired: memo.isDeliveryRequired,
      marketingName: memo.marketingName,
      marketingUsername: memo.marketingUsername,
      marketingEmpCode: memo.marketingEmpCode,
      metodePembayaran: memo.metodePembayaran,
      memoType: memo.memoType,
      orderIdMarketplace: memo.orderIdMarketplace != null
          ? '${memo.orderIdMarketplace}-${isRevision ? 'REV' : 'DUP'}-${DateTime.now().millisecondsSinceEpoch}'
          : null,
      resi: null,
      ekspedisi: memo.ekspedisi,
      subEkspedisi: memo.subEkspedisi,
      platform: memo.platform,
      kodePos: memo.kodePos,
      tempo: memo.tempo,
      badanUsaha: memo.badanUsaha,
      opsiPengiriman: memo.opsiPengiriman,
      items: isRevision
          ? memo.items
              .map((item) => MemoItem(
                    id: null,
                    namaBarang: item.namaBarang,
                    qty: item.qty,
                    qtyShipped: 0,
                    hargaSatuan: item.hargaSatuan,
                    subtotal: item.subtotal,
                    status: item.status,
                    catatanGudang: item.catatanGudang,
                  ))
              .toList()
          : [],
      revisedFromId: isRevision ? memo.id : null,
    );

    context
        .push(
      '${AppRoutes.memoCreate}?type=${cloned.memoType ?? 'BIASA'}',
      extra: cloned,
    )
        .then((_) {
      if (mounted) {
        _memoBloc.add(
            LoadMemos(status: _selectedStatus, memoType: _roleMemoTypeFilter));
      }
    });
  }

  void _showContextMenu(
      BuildContext context, Offset position, MemoDetail memo) {
    final theme = Theme.of(context);

    // Validasi status untuk Duplikat & Revisi Memo
    final bool canRevise = memo.statusAkhir != MemoStatus.DALAM_PENGIRIMAN &&
        memo.statusAkhir != MemoStatus.DITERIMA_USER &&
        memo.statusAkhir != MemoStatus.TERKIRIM_SEBAGIAN &&
        memo.statusAkhir != MemoStatus.SELESAI &&
        memo.statusAkhir != MemoStatus.DIBATALKAN;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'duplicate_revision',
          enabled: canRevise,
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: canRevise ? theme.colorScheme.primary : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Duplikat & Revisi Memo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: canRevise ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate_header',
          child: Row(
            children: [
              Icon(
                Icons.copy_all_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Duplikat Header Memo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == 'duplicate_revision') {
        _handleDuplicate(memo, isRevision: true);
      } else if (value == 'duplicate_header') {
        _handleDuplicate(memo, isRevision: false);
      }
    });
  }

  void _handleBulkFinalize(
      BuildContext context, List<MemoDetail> selectedMemos) {
    final draftMemos =
        selectedMemos.where((m) => m.statusAkhir == MemoStatus.DRAFT).toList();
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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

    Theme.of(context);
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
    final List<String> ids =
        selectedMemos.map((m) => m.id).whereType<String>().toList();

    if (ids.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Selesaikan Memo'),
        content: Text(
            'Apakah Anda yakin ingin menyelesaikan ${ids.length} memo terpilih?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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

  void _showJlInputDialog(BuildContext context, MemoDetail memo) {
    final controller = TextEditingController(text: 'JL-YGY-');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded,
                color: Colors.blueAccent, size: 28),
            SizedBox(width: 12),
            Text('Input Nomor JL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${memo.customerName ?? ''} - ${memo.nomorMemo ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              "Masukkan nomor JL. Format wajib diawali 'JL-'. Setelah input JL, memo langsung masuk BUFFER ZONE.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nomor JL',
                hintText: 'JL-XXX-XXXXXXX',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final jl = controller.text.trim();
              if (jl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Nomor JL tidak boleh kosong")));
                return;
              }
              if (!jl.toUpperCase().startsWith("JL-")) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text("Format JL tidak valid (harus diawali 'JL-')")));
                return;
              }
              Navigator.pop(ctx);
              _memoBloc.add(FinishInvoicingProcessEvent(
                memo.id!,
                nomorJl: jl,
                keteranganLog: noteController.text,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Input JL & Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusDialog(
      BuildContext context, List<MemoDetail> selectedMemos) {
    Theme.of(context);
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
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) => setLocalState(() => targetStatus = v),
                ),
                if (targetStatus == MemoStatus.MENUNGGU_NOTA) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: jlController,
                    decoration: const InputDecoration(
                      labelText:
                          'Nomor JL / Invoice (Opsional - Input sekarang atau nanti)',
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
                    if (targetStatus == MemoStatus.MENUNGGU_NOTA &&
                        jl.isNotEmpty) {
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
                      nomorJl: targetStatus == MemoStatus.MENUNGGU_NOTA &&
                              jl.isNotEmpty
                          ? jl
                          : null,
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
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section: Customer Name
              Text(
                memo.customerName ?? 'No Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
              // Middle Section: Data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#MEMO-${memo.nomorMemo ?? memo.id?.substring(0, 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          memo.tanggalMemo != null
                              ? _formatDate(memo.tanggalMemo!)
                              : '—',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontSize: 11,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E40AF),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${memo.totalQty.toString().replaceAll(RegExp(r'\.0$'), '')} Items',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
              // Bottom Section: Badges
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: status),
                  if (memo.opsiPengiriman != null) _buildOpsiBadge(memo, theme),
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
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
        memo.ekspedisi != null &&
        memo.ekspedisi!.isNotEmpty) {
      Color badgeColor = Colors.orange.shade700;
      final eks = memo.ekspedisi!.toUpperCase();
      if (eks.contains('INSTAN')) {
        badgeColor = Colors.green.shade700;
      } else if (eks.contains('ANDI')) {
        badgeColor = Colors.purple.shade700;
      } else if (eks.contains('REGULER') || eks.contains('REGULAR')) {
        badgeColor = Colors.blue.shade700;
      }

      return _createOpsiBadge(eks, badgeColor, Icons.local_shipping_rounded);
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
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  String _formatNumber(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } else {
      List<String> parts = value.toString().split('.');
      String intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '$intPart,${parts[1]}';
    }
  }

  String _formatRupiah(num v) => "Rp ${_formatNumber(v)}";

  String _formatDate(DateTime dt) => "${dt.day}/${dt.month}/${dt.year}";
}

class _BulkActionBar extends StatelessWidget {
  final int count;
  final String? userRole;
  final List<MemoDetail> selectedMemos;
  final VoidCallback onClear;
  final VoidCallback onPrint;
  final VoidCallback onPrintAlamat;
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
    required this.onPrintAlamat,
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
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            // If there's enough space, use Row. Otherwise use scrollable row.
            if (maxWidth > 600) {
              return Row(
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
                      label: 'Cetak Memo',
                      onTap: onPrint,
                    ),
                    _ActionIcon(
                      icon: Icons.local_shipping_rounded,
                      label: 'Cetak Alamat',
                      onTap: onPrintAlamat,
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
              );
            } else {
              // Narrow screen: use scrollable row
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '$count Terpilih',
                        style: TextStyle(
                          color: theme.colorScheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (allDraft) ...[
                      _ActionIcon(
                        icon: Icons.send_rounded,
                        label: 'Kirim ke Gudang',
                        onTap: onBulkFinalize,
                      ),
                    ] else if (userRole != 'DELIVERY') ...[
                      _ActionIcon(
                        icon: Icons.print_outlined,
                        label: 'Cetak Memo',
                        onTap: onPrint,
                      ),
                      _ActionIcon(
                        icon: Icons.local_shipping_rounded,
                        label: 'Cetak Alamat',
                        onTap: onPrintAlamat,
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
              );
            }
          },
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
