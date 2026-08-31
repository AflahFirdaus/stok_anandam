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
import 'package:stok_anandam/core/network/item_categories.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import '../../injection.dart';
import '../layout/dashboard_shell.dart';
import 'widgets/employee_sales_panel.dart';
import 'widgets/summary_card.dart';
import 'widgets/stock_category_chart.dart';
import '../shared/migration_sync_mixin.dart';
// KOMENTAR: MapPreviewCard dinonaktifkan sementara
// import '../memo/widgets/map_preview_card.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';
import 'package:stok_anandam/features/presence/mixins/presence_action_mixin.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with MigrationSyncMixin, PresenceActionMixin {
  bool _loading = true;
  String? _error;
  DashboardLocalData? _data;
  List<StockSummaryRow>? _stockHierarchy;
  bool _hierarchyLoading = false;
  String? _hierarchyError;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadStockHierarchy();
    fetchLastSync();

    // Listen to WebSocket for real-time updates
    _wsSubscription = getIt<WebSocketService>().memoUpdateStream.listen((data) {
      if (data.toUpperCase().contains('REFRESH')) {
        if (mounted) {
          refreshSummary();
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = getIt<DashboardControllerApi>();
      print('Dashboard: Loading summary data...');

      // Add timeout to prevent infinite loading
      final response = await api.getSummary().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Dashboard: Summary load timed out');
          throw TimeoutException(
              'Koneksi ke server lambat. Coba refresh kembali.');
        },
      );

      final data = response.data?.data;
      if (isResponseSuccess(response.data?.status) && data != null) {
        if (mounted) {
          setState(() {
            _data = DashboardLocalData.fromResponse(data);
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response.data?.message?.toString() ?? 'Gagal memuat data.';
            _loading = false;
          });
        }
      }
    } catch (e, st) {
      print('❌ DASHBOARD LOAD ERROR: $e');
      if (e is! TimeoutException) {
        print('❌ DASHBOARD STACKTRACE: $st');
      }
      if (mounted) {
        setState(() {
          _error = e is TimeoutException
              ? e.message
              : 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
          _loading = false;
        });
      }
    }
  }

  static List<StockSummaryRow> _groupHierarchy(
      List<StockSummaryRow> flatItems) {
    Map<String, StockSummaryRow> parentMap = {};

    // 1. Initialize parents from ItemCategories.categoryOrder
    for (final name in ItemCategories.categoryOrder) {
      parentMap[name] =
          StockSummaryRow(nama: name, stok: 0, presentase: 0, children: []);
    }

    // 2. Assign items to parents
    for (final item in flatItems) {
      if (item.nama.toUpperCase() == 'TOTAL') continue;

      final name = item.nama.toUpperCase().replaceAll(' ', '');

      // Determine parent category from ItemCategories
      String? targetParent = ItemCategories.subToParent[name];

      targetParent ??= 'LAIN-LAIN';

      if (!parentMap.containsKey(targetParent)) {
        parentMap[targetParent] = StockSummaryRow(
            nama: targetParent, stok: 0, presentase: 0, children: []);
      }

      final p = parentMap[targetParent]!;
      parentMap[targetParent] = StockSummaryRow(
        nama: p.nama,
        stok: p.stok + item.stok,
        presentase: p.presentase + item.presentase,
        children: List<StockSummaryRow>.from(p.children)..add(item),
      );
    }

    // 3. Build final list, sort children based on ItemCategories
    final result = <StockSummaryRow>[];
    for (final name in ItemCategories.categoryOrder) {
      if (parentMap.containsKey(name)) {
        final p = parentMap[name]!;
        if (p.children.isNotEmpty || p.stok > 0 || name == 'LAIN-LAIN') {
          // Sort children if order is defined
          final orderList = ItemCategories.subCategoryOrder[name];
          if (orderList != null) {
            p.children.sort((a, b) {
              int idxA =
                  orderList.indexOf(a.nama.toUpperCase().replaceAll(' ', ''));
              int idxB =
                  orderList.indexOf(b.nama.toUpperCase().replaceAll(' ', ''));
              if (idxA == -1) idxA = 999;
              if (idxB == -1) idxB = 999;
              return idxA.compareTo(idxB);
            });
          }
          result.add(p);
        }
      }
    }

    // 4. Calculate real total stok based on included items
    num totalStok = 0;
    for (final p in result) {
      totalStok += p.stok;
    }

    // 5. Recalculate percentages to be accurate against the valid total
    if (totalStok > 0) {
      for (int i = 0; i < result.length; i++) {
        final p = result[i];
        final newPct = (p.stok / totalStok) * 100;

        final newChildren = p.children
            .map((c) => StockSummaryRow(
                nama: c.nama,
                stok: c.stok,
                presentase: (c.stok / totalStok) * 100,
                children: c.children))
            .toList();

        result[i] = StockSummaryRow(
          nama: p.nama,
          stok: p.stok,
          presentase: newPct,
          children: newChildren,
        );
      }
    }

    result
        .add(StockSummaryRow(nama: 'TOTAL', stok: totalStok, presentase: 100));

    return result;
  }

  Future<void> _loadStockHierarchy() async {
    if (mounted) {
      setState(() {
        _hierarchyLoading = true;
        _hierarchyError = null;
      });
    }
    try {
      final api = getIt<ApiNewEndpoints>();
      print('Dashboard: Loading stock hierarchy...');

      // Add timeout to prevent infinite loading
      final flatList = await api.getStockSummaryByCategory().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('Dashboard: Stock hierarchy load timed out');
          throw TimeoutException('Timed out');
        },
      );

      if (mounted) {
        setState(() {
          _stockHierarchy = _groupHierarchy(flatList);
          _hierarchyLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard: Hierarchy error: $e');
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
      onHeaderAction: () =>
          showSyncMigrationDialog(onCustomSuccess: refreshSummary),
      showHeaderActionInAppBar: true,
      lastSync: lastSyncFormatted,
      onScan: () => context.pushNamed(AppRoutes.scanner),
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

    final d = _data!;
    final width = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);
    final isDesktop = width >= 900;
    final isMobileLayout = width < 720;

    if (isMobileLayout) {
      return _buildMobileDashboard(
        context: context,
        cards: [],
        onRefresh: refreshSummary,
        d: d,
      );
    }

    final penjualanCard = SummaryCard(
      title: 'Penjualan Hari Ini',
      value: _formatRupiah(d.totalSalesToday),
      subtitle: 'Update Real-time',
      icon: Icons.payments_rounded,
      iconColor: const Color(0xFF10B981),
    );
    final pembelianCard = SummaryCard(
      title: 'Pembelian Hari Ini',
      value: _formatRupiah(d.totalPurchasesToday),
      subtitle: 'Update Real-time',
      icon: Icons.shopping_cart_rounded,
      iconColor: const Color(0xFF3B82F6),
    );
    final canvasingCard = SummaryCard(
      title: 'Canvasing Hari Ini',
      value: _val(d.totalVisitsToday),
      subtitle: 'Update Real-time',
      icon: Icons.directions_car_rounded,
      iconColor: const Color(0xFFF59E0B),
    );
    final nilaiPendingCard = SummaryCard(
      title: 'Nilai Pending',
      value: _formatRupiah(d.pendingValue),
      subtitle: 'Total HPP Pending',
      icon: Icons.hourglass_empty_rounded,
      iconColor: const Color(0xFFEF4444),
    );
    final stokPendingCard = SummaryCard(
      title: 'Stok Pending',
      value: '${_formatNumber(d.pendingStock)} Unit',
      subtitle: 'Total Kuantitas Pending',
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF8B5CF6), // Violet
    );
    final nilaiStokCard = SummaryCard(
      title: 'Nilai Stok',
      value: _formatRupiah(d.totalHpp),
      subtitle: 'Nilai stok keseluruhan',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFF0891B2),
    );

    // Section 1 & 2: Responsive Summary Cards (Custom Grid 2-3-1 for Desktop)
    Widget summarySection;
    if (isDesktop) {
      summarySection = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: penjualanCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: pembelianCard),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: canvasingCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: nilaiPendingCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: stokPendingCard),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          nilaiStokCard,
        ],
      );
    } else {
      summarySection = Column(
        children: [
          penjualanCard,
          pembelianCard,
          canvasingCard,
          nilaiPendingCard,
          stokPendingCard,
          nilaiStokCard,
        ]
            .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: c))
            .toList(),
      );
    }

    final mainContent = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ringkasan Performa',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          summarySection,
          const SizedBox(height: AppSpacing.xl),

          Text('Analisis Stok & Performa',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 400,
                child: EmployeeSalesPanel(
                  todayItems: d.employeeSalesToday,
                  monthItems: d.employeeSalesMonth,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Section 4: Manajemen Inventaris per Kategori
          Text('Manajemen Inventaris per Kategori',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          DeckCard(
            title: 'Stok per Kategori',
            subtitle: 'Visualisasi distribusi stok berdasarkan kategori utama',
            child: _buildStockHierarchyTable(context),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Section 5: Geospasial
          Text('Geospasial',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          // KOMENTAR: MapPreviewCard dinonaktifkan sementara
          // const MapPreviewCard(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );

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

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      final leftCategoryNames = [
        'BRANDED',
        'NOTEBOOK',
        'KOMPONEN',
        'CTRD TINTA TONER',
        'PRINTER SCANNER',
        'PROJEKTOR',
        'UPS',
        'HP TAB'
      ];

      final leftGroup = _stockHierarchy
              ?.where((e) => leftCategoryNames.contains(e.nama.toUpperCase()))
              .toList() ??
          [];
      final rightGroup = _stockHierarchy
              ?.where((e) => !leftCategoryNames.contains(e.nama.toUpperCase()))
              .toList() ??
          [];

      final leftRows = _flattenHierarchy(leftGroup);
      final rightRows = _flattenHierarchy(rightGroup);

      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              child: _buildCategoryColumn(context, 'Kategori Stok', leftRows),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Right Column
            Expanded(
              child: _buildCategoryColumn(context, 'Kategori Stok', rightRows),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: tableMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
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

  Widget _buildCategoryColumn(BuildContext context, String title,
      List<({StockSummaryRow row, int level})> rows) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: StockCategoryChart(
            rows: rows,
            formatNumber: _formatNumber,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDashboard({
    required BuildContext context,
    required List<SummaryCard> cards, // ignore these cards, we'll build our own
    required VoidCallback onRefresh,
    required DashboardLocalData d,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isSmallMobile = width < 400;
    final paddingH = isSmallMobile ? AppSpacing.md : AppSpacing.lg;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            paddingH, AppSpacing.lg, paddingH, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Ringkasan Harian
            Text('Ringkasan Harian',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'Penjualan Hari Ini',
              value: _formatRupiah(d.totalSalesToday),
              icon: Icons.payments_rounded,
              iconColor: const Color(0xFF14B8A6), // Teal
            ),
            const SizedBox(height: 8),
            SummaryCard(
              title: 'Pembelian Hari Ini',
              value: _formatRupiah(d.totalPurchasesToday),
              icon: Icons.shopping_cart_rounded,
              iconColor: const Color(0xFF6366F1), // Indigo
            ),
            const SizedBox(height: 8),
            SummaryCard(
              title: 'Canvasing Hari Ini',
              value: _val(d.totalVisitsToday),
              icon: Icons.directions_car_rounded,
              iconColor: const Color(0xFFF59E0B), // Amber
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Informasi Keuangan & Stok
            Text('Informasi Keuangan & Stok',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'Nilai Pending',
              value: _formatRupiah(d.pendingValue),
              icon: Icons.hourglass_empty_rounded,
              iconColor: const Color(0xFFF43F5E), // Rose/Red
            ),
            const SizedBox(height: 8),
            SummaryCard(
              title: 'Stok Pending',
              value: '${_formatNumber(d.pendingStock)} Unit',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFFFF5722), // Deep Orange
            ),
            const SizedBox(height: 8),
            SummaryCard(
              title: 'Total Nilai Stok',
              value: _formatRupiah(d.totalHpp),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF0891B2), // Cyan/Teal
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. Stok Regional
            Text('Stok Regional (Full Display)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStockHierarchyTable(context),
            const SizedBox(height: AppSpacing.xl),

            // 4. Sebaran Maps
            Text('Fitur Lokasi',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // KOMENTAR: MapPreviewCard dinonaktifkan sementara
            // const MapPreviewCard(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
