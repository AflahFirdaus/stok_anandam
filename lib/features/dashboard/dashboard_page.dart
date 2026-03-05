import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart'
    hide DashboardResponse, EmployeeSalesResponse;
import 'models/dashboard_local_models.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/network/stock_summary_row.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/core/widgets/deck_view.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import '../../injection.dart';
import '../../token_storage.dart';
import '../layout/dashboard_shell.dart';
import 'widgets/employee_sales_panel.dart';
import 'widgets/low_stock_panel.dart';
import 'widgets/migration_dialog.dart';
import 'widgets/summary_card.dart';
import 'widgets/stock_category_chart.dart';
import '../shared/migration_sync_mixin.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  DashboardLocalData? _data;
  List<StockSummaryRow>? _stockHierarchy;
  bool _hierarchyLoading = false;
  String? _hierarchyError;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadStockHierarchy();
    fetchLastSync();
  }


  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = getIt<DashboardControllerApi>();
      final response = await api.getSummary();
      final data = response.data?.data;
      if (isResponseSuccess(response.data?.status) && data != null) {
        setState(() {
          _data = DashboardLocalData.fromDynamic(data.toJson());
          _loading = false;
        });
      } else {
        setState(() {
          _error = response.data?.message?.toString() ?? 'Gagal memuat data.';
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

  static const List<String> _categoryOrder = [
    '2ND',
    'PROJEKTOR',
    'UPS',
    'BRANDED',
    'NETWORK',
    'NOTEBOOK',
    'MONITOR',
    'KOMPONEN',
    'CTRD TINTA TONER',
    'PRINTER SCANNER',
    'ACC',
    'HPTB',
    'LAIN-LAIN',
  ];

  static const Map<String, String> _subToParent = {
    'PCAIO': 'BRANDED',
    'PCBU': 'BRANDED',
    'PCMINI': 'BRANDED',
    'PROJEKTOR': 'PROJEKTOR',
    'PROJ': 'PROJEKTOR',
    'PROJECTOR': 'PROJEKTOR',
    'PJT': 'PROJEKTOR',
    'NETWORK': 'NETWORK',
    'NET': 'NETWORK',
    'NWK': 'NETWORK',
    'NOTEBOOK': 'NOTEBOOK',
    'NB': 'NOTEBOOK',
    'MONITOR': 'MONITOR',
    'MON': 'MONITOR',
    'LCD': 'MONITOR',
    'PROC': 'KOMPONEN',
    'MB': 'KOMPONEN',
    'VGA': 'KOMPONEN',
    'RAM': 'KOMPONEN',
    'SSD': 'KOMPONEN',
    'SSDEX': 'KOMPONEN',
    'HDIN3': 'KOMPONEN',
    'HDIN2': 'KOMPONEN',
    'HDEX3': 'KOMPONEN',
    'HDEX2': 'KOMPONEN',
    'CS': 'KOMPONEN',
    'PSU': 'KOMPONEN',
    'CLR': 'KOMPONEN',
    'FAN': 'KOMPONEN',
    'TINTA': 'CTRD TINTA TONER',
    'CARTD': 'CTRD TINTA TONER',
    'PRINT': 'PRINTER SCANNER',
    'SCAN': 'PRINTER SCANNER',
    'ACS': 'ACC',
    'AL': 'ACC',
    'ATK': 'ACC',
    'BRKT': 'ACC',
    'CCTV': 'ACC',
    'FP': 'ACC',
    'KAS': 'ACC',
    'KB': 'ACC',
    'KBL': 'ACC',
    'KBM': 'ACC',
    'MC': 'ACC',
    'MU': 'ACC',
    'MM': 'ACC',
    'MS': 'ACC',
    'MSN': 'ACC',
    'PP': 'ACC',
    'SCR': 'ACC',
    'SOFT': 'ACC',
    'SP': 'ACC',
    'STAB': 'ACC',
    'UPD': 'ACC',
    'HPTAB': 'HPTAB',
    'HP': 'HPTB',
    'TAB': 'HPTB',
  };

  static const Map<String, List<String>> _subCategoryOrder = {
    'BRANDED': ['PCAIO', 'PCBU', 'PCMINI'],
    'KOMPONEN': [
      'PROC',
      'MB',
      'VGA',
      'RAM',
      'SSD',
      'SSDEX',
      'HDIN3',
      'HDIN2',
      'HDEX3',
      'HDEX2',
      'CS',
      'PSU',
      'CLR',
      'FAN'
    ],
    'CTRD TINTA TONER': ['TINTA', 'CARTD'],
    'PRINTER SCANNER': ['PRINT', 'SCAN'],
    'ACC': [
      'ACS',
      'AL',
      'ATK',
      'BRKT',
      'CCTV',
      'FP',
      'KAS',
      'KB',
      'KBL',
      'KBM',
      'MC',
      'MU',
      'MM',
      'MS',
      'MSN',
      'PP',
      'SCR',
      'SOFT',
      'SP',
      'STAB',
      'UPD'
    ],
  };

  static List<StockSummaryRow> _groupHierarchy(
      List<StockSummaryRow> flatItems) {
    // 1. Initialize parents from _categoryOrder
    Map<String, StockSummaryRow> parentMap = {};
    for (final name in _categoryOrder) {
      parentMap[name] =
          StockSummaryRow(nama: name, stok: 0, presentase: 0, children: []);
    }

    // 2. Assign items to parents or children
    for (final item in flatItems) {
      if (item.nama.toUpperCase() == 'TOTAL') continue;

      final name = item.nama.toUpperCase().replaceAll(' ', '');

      // Check if it's a top-level category itself
      if (parentMap.containsKey(name)) {
        final p = parentMap[name]!;
        parentMap[name] = StockSummaryRow(
          nama: p.nama,
          stok: p.stok + item.stok,
          presentase: p.presentase + item.presentase,
          children: p.children,
        );
        continue;
      }

      final parentName = _subToParent[name];
      if (parentName != null) {
        // It's a sub-category according to our map
        final p = parentMap[parentName];
        if (p != null) {
          final newChildren = List<StockSummaryRow>.from(p.children)..add(item);
          parentMap[parentName] = StockSummaryRow(
            nama: p.nama,
            stok: p.stok + item.stok,
            presentase: p.presentase + item.presentase,
            children: newChildren,
          );
          continue;
        }
      }

      // If we reach here, it's unknown or uncategorized -> add to LAIN-LAIN
      final other = parentMap['LAIN-LAIN'];
      if (other != null) {
        parentMap['LAIN-LAIN'] = StockSummaryRow(
          nama: other.nama,
          stok: other.stok + item.stok,
          presentase: other.presentase + item.presentase,
          children: other.children,
        );
      }
    }

    // 3. Sort children and build final list
    final result = <StockSummaryRow>[];
    for (final name in _categoryOrder) {
      final p = parentMap[name]!;

      final subs = _subCategoryOrder[name];
      final filteredChildren = subs == null
          ? <StockSummaryRow>[]
          : p.children.where((c) {
              final childName = c.nama.toUpperCase().replaceAll(' ', '');
              return subs.contains(childName);
            }).toList();

      final sortedChildren = List<StockSummaryRow>.from(filteredChildren)
        ..sort((a, b) {
          if (subs != null) {
            final idxA = subs.indexOf(a.nama.toUpperCase().replaceAll(' ', ''));
            final idxB = subs.indexOf(b.nama.toUpperCase().replaceAll(' ', ''));
            if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
            if (idxA != -1) return -1;
            if (idxB != -1) return 1;
          }
          return a.nama.compareTo(b.nama);
        });

      result.add(StockSummaryRow(
        nama: p.nama,
        stok: p.stok,
        presentase: p.presentase,
        children: sortedChildren,
      ));
    }

    // 4. Calculate or find TOTAL
    final totalRowMaybe =
        flatItems.where((e) => e.nama.toUpperCase() == 'TOTAL').toList();
    if (totalRowMaybe.isNotEmpty) {
      final t = totalRowMaybe.first;
      // Force 100% for the total row
      result.add(StockSummaryRow(nama: 'TOTAL', stok: t.stok, presentase: 100));
    } else {
      num totalStok = 0;
      for (final p in result) {
        totalStok += p.stok;
      }
      // Force 100% for the calculated total row
      result.add(
          StockSummaryRow(nama: 'TOTAL', stok: totalStok, presentase: 100));
    }

    return result;
  }

  Future<void> _loadStockHierarchy() async {
    setState(() {
      _hierarchyLoading = true;
      _hierarchyError = null;
    });
    try {
      final api = getIt<ApiNewEndpoints>();
      // Use the flat endpoint to get all raw data, then group it manually
      final flatList = await api.getStockSummaryByCategory();
      if (mounted) {
        setState(() {
          _stockHierarchy = _groupHierarchy(flatList);
          _hierarchyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hierarchyError = 'Gagal memuat ringkasan stok';
          _hierarchyLoading = false;
        });
      }
    }
  }

  void refreshSummary() {
    _loadSummary();
    _loadStockHierarchy();
    fetchLastSync();
  }

  static String _val(Object? v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  static String _formatRupiah(Object? v) {
    if (v == null) return '—';
    final num? n = _toNum(v);
    if (n == null) return _val(v);

    // Format angka penuh dengan pemisah ribuan (titik)
    final String formatted = _formatNumber(n);
    return 'Rp $formatted';
  }

  static String _formatNumber(num value) {
    // Selalu tampilkan angka bulat tanpa desimal (permintaan user)
    return _addThousandSeparator(value.round().toString());
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

  static num? _toNum(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
  }

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    
    return DashboardShell(
      currentRoute: AppRoutes.dashboard,
      userName: userStore.displayName,
      userRole: userStore.userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () => showSyncMigrationDialog(onCustomSuccess: refreshSummary),
      showHeaderActionInAppBar: true,
      lastSync: lastSyncFormatted,
      onNavigate: (route) {
        if (route != AppRoutes.dashboard) context.go(route);
      },
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },

      onRefresh: _loading ? null : refreshSummary,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadSummary,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;
    final isMobileLayout = width < 720;
    final isSmallMobile = width < 600;

    int crossAxisCount = 4;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 900) {
      crossAxisCount = 2;
    } else if (width < 1200) {
      crossAxisCount = 3;
    }

    final d = _data!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showLowStockPanel = screenWidth >= 720;
    final lowStockItems = _parseLowStockPreview(d.lowStockPreview);

    final cards = [
      SummaryCard(
        title: 'Penjualan Hari Ini',
        value: _formatRupiah(d.totalSalesToday),
        subtitle: 'Hari ini',
        icon: Icons.shopping_cart_rounded,
        iconColor: const Color(0xFFF59E0B),
      ),
      SummaryCard(
        title: 'Pembelian Hari Ini',
        value: _formatRupiah(d.totalPurchasesToday),
        subtitle: 'Hari ini',
        icon: Icons.shopping_bag_rounded,
        iconColor: const Color(0xFF10B981),
      ),
      SummaryCard(
        title: 'Kunjungan Canvasing',
        value: _val(d.totalVisitsToday),
        subtitle: 'Hari ini',
        icon: Icons.place_rounded,
        iconColor: const Color(0xFFEC4899),
      ),
      SummaryCard(
        title: 'Stok Rendah',
        value: _val(d.totalLowStockItems),
        subtitle: 'Perlu restock',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFEF4444),
      ),
      SummaryCard(
        title: 'Total HPP Stok',
        value: _formatRupiah(d.totalHpp),
        subtitle: 'Berdasarkan grand total',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF6366F1),
      ),
    ];

    if (isMobileLayout) {
      return _buildMobileDashboard(
        context: context,
        cards: cards,
        onRefresh: refreshSummary,
        d: d,
      );
    }

    final mainContent = DeckView(
      title: 'Ringkasan',
      actions: const [],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeckCard(
            title: 'Overview',
            subtitle: 'Ringkasan aktivitas hari ini',
            child: isMobile
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: cards
                        .map((card) => Padding(
                              padding: EdgeInsets.only(
                                  bottom: isSmallMobile
                                      ? AppSpacing.md
                                      : AppSpacing.lg),
                              child: card,
                            ))
                        .toList(),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 1.2,
                    children: cards,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DeckCard(
            title: 'Stok per Kategori',
            subtitle: 'Ringkasan stok berdasarkan kategori (hierarchy)',
            child: _buildStockHierarchyTable(context),
          ),
        ],
      ),
    );

    if (showLowStockPanel) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: mainContent),
          EmployeeSalesPanel(items: d.employeeSalesToday ?? [], maxItems: 12),
        ],
      );
    }
    return mainContent;
  }

  static List<({StockSummaryRow row, int level})> _flattenHierarchy(
      List<StockSummaryRow> list) {
    List<({StockSummaryRow row, int level})> out = [];
    void add(StockSummaryRow r, int level) {
      out.add((row: r, level: level));
      for (final c in r.children) {
        add(c, level + 1);
      }
    }

    for (final r in list) {
      add(r, 0);
    }
    return out;
  }

  Widget _buildStockHierarchyTable(BuildContext context) {
    const tableMaxWidth = 420.0;
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 500;

    if (_hierarchyLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }
    if (_hierarchyError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: tableMaxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hierarchyError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: _loadStockHierarchy,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = _stockHierarchy != null && _stockHierarchy!.isNotEmpty
        ? _flattenHierarchy(_stockHierarchy!)
        : <({StockSummaryRow row, int level})>[];

    // Added a "TOTAL" row at the end if not present in the list, or just ensure it's there.
    // Usually the API might provide it or we can calculate it.
    // The current code trusts _flattenHierarchy to include everything.

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: tableMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: theme.colorScheme.surfaceContainerLow.withOpacity(0.5),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 12 : 16),
              child: StockCategoryChart(
                rows: rows,
                formatNumber: _formatNumber,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDashboard({
    required BuildContext context,
    required List<SummaryCard> cards,
    required VoidCallback onRefresh,
    required DashboardLocalData d,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isSmallMobile = width < 400;
    final paddingH = isSmallMobile ? AppSpacing.md : AppSpacing.lg;
    const paddingV = AppSpacing.lg;
    const gap = AppSpacing.md;

    return Container(
      color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              EdgeInsets.fromLTRB(paddingH, paddingV, paddingH, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ringkasan Hari Ini',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: gap),
              LayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 1;
                  const itemGap = AppSpacing.sm;
                  const totalSpacing = itemGap * (crossAxisCount - 1);
                  final itemWidth =
                      (constraints.maxWidth - totalSpacing) / crossAxisCount;
                  const double minCardHeight = 60;
                  final itemHeight = 92.0; // Increased to allow 2-line title
                  final firstFour = cards.take(4).toList();
                  final lastCard = cards.length > 4 ? cards[4] : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: itemGap,
                        runSpacing: itemGap,
                        children: firstFour
                            .map((card) => SizedBox(
                                  width: itemWidth,
                                  height: itemHeight,
                                  child: card,
                                ))
                            .toList(),
                      ),
                      if (lastCard != null) ...[
                        const SizedBox(height: gap),
                        SizedBox(
                          width: double.infinity,
                          height: itemHeight,
                          child: lastCard,
                        ),
                      ],
                      const SizedBox(height: gap),
                      Text(
                        'Stok per Kategori',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStockHierarchyTable(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<LowStockItem> _parseLowStockPreview(Object? raw) {
    final list = <LowStockItem>[];
    if (raw is! List) return list;
    for (final e in raw) {
      final item = LowStockItem.fromJson(e);
      if (item != null) list.add(item);
    }
    return list;
  }
}
