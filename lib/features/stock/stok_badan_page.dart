import 'package:flutter/material.dart';
import 'package:stok_anandam/features/stock/stok_badan_models.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/token_storage.dart';

class StokBadanPage extends StatefulWidget {
  const StokBadanPage({super.key});

  @override
  State<StokBadanPage> createState() => _StokBadanPageState();
}

class _StokBadanPageState extends State<StokBadanPage> {
  List<StokBadanGroup> _groups = [];
  bool _loading = true;
  String? _expandedBadan;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await getIt<ApiNewEndpoints>().getStokPerBadan();
      if (mounted) setState(() => _groups = data);
    } catch (e) {
      debugPrint('[StokBadan] Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _badanColor(String badan) {
    switch (badan) {
      case 'ANC':
        return const Color(0xFF22C55E); // Hijau
      case 'PDB':
        return const Color(0xFFEF4444); // Merah
      case 'MGC':
        return const Color(0xFFEAB308); // Kuning
      case 'GBH':
        return const Color(0xFF166534); // Hijau tua/gelap
      case 'SSS':
        return const Color(0xFFDC2626); // Merah
      case 'SGI':
        return const Color(0xFFB91C1C); // Merah lebih gelap (beda tone dari SSS)
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  List<StokBadanItem> _filterItems(List<StokBadanItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      final nameMatch = item.itemName?.toLowerCase().contains(q) ?? false;
      final codeMatch = item.itemCode.toLowerCase().contains(q);
      final depMatch = item.depCode.toLowerCase().contains(q);
      final depNameMatch = item.depName?.toLowerCase().contains(q) ?? false;
      return nameMatch || codeMatch || depMatch || depNameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalUnits = _groups.fold<int>(0, (sum, g) => sum + g.totalQty);
    final totalDistinctItems =
        _groups.fold<int>(0, (sum, g) => sum + g.totalItems);
    final activeBadans =
        _groups.where((g) => g.totalQty > 0 || g.items.isNotEmpty).length;

    return DashboardShell(
      currentRoute: AppRoutes.stokBadan,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      onNavigate: (route) => context.go(route),
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      title: 'Stok per Badan',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- SUMMARY METRICS ---
                  _buildSummaryMetrics(
                    totalUnits: totalUnits,
                    totalItems: totalDistinctItems,
                    activeBadans: activeBadans,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  // --- SEARCH BAR ---
                  _buildSearchBar(theme),
                  const SizedBox(height: 16),

                  // --- GROUP CARDS ---
                  if (_groups.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Tidak ada data stok badan',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ..._groups.map((group) => _buildGroupCard(group)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryMetrics({
    required int totalUnits,
    required int totalItems,
    required int activeBadans,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              icon: Icons.inventory_2_rounded,
              iconColor: Colors.blue,
              label: 'Total Kuantitas',
              value: '$totalUnits Unit',
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          Expanded(
            child: _buildMetricItem(
              icon: Icons.category_rounded,
              iconColor: Colors.teal,
              label: 'Total Macam Item',
              value: '$totalItems Item',
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          Expanded(
            child: _buildMetricItem(
              icon: Icons.apartment_rounded,
              iconColor: Colors.orange,
              label: 'Badan Usaha Aktif',
              value: '$activeBadans / ${_groups.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari barang, kode barang, atau divisi...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
    );
  }

  Widget _buildGroupCard(StokBadanGroup group) {
    final isExpanded = _expandedBadan == group.badan || _searchQuery.isNotEmpty;
    final color = _badanColor(group.badan);
    final displayedItems = _filterItems(group.items);
    final displayedQty =
        displayedItems.fold<int>(0, (sum, i) => sum + i.stokQty);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: group.totalQty > 0
              ? color.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedBadan =
                    (_expandedBadan == group.badan) ? null : group.badan;
              });
            },
            child: Container(
              color: group.totalQty > 0
                  ? color.withValues(alpha: 0.04)
                  : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group.badan,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Badan Usaha ${group.badan}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Ditemukan: ${displayedItems.length} item • $displayedQty unit (Total: ${group.totalQty} unit)'
                              : '${group.totalItems} macam item • ${group.totalQty} unit',
                          style: TextStyle(
                            color: group.totalQty > 0
                                ? const Color(0xFF16A34A)
                                : Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (displayedItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Tidak ada item yang cocok dengan pencarian di badan ${group.badan}'
                      : 'Tidak ada stok pada badan usaha ini',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...displayedItems.map(_buildItemRow),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(StokBadanItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 42,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: item.stokQty > 0
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? item.itemCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.itemCode,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.depCode.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.depCode,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: item.stokQty > 0
                  ? const Color(0xFFDCFCE7)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.stokQty}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: item.stokQty > 0
                    ? const Color(0xFF15803D)
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}