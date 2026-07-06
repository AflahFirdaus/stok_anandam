import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import '../../models/transaksi_servis.dart';
import '../../providers/klaim_provider.dart';
import '../../widgets/pagination_bar.dart';

class KlaimGaransiView extends StatefulWidget {
  const KlaimGaransiView({super.key});

  @override
  State<KlaimGaransiView> createState() => _KlaimGaransiViewState();
}

class _KlaimGaransiViewState extends State<KlaimGaransiView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KlaimProvider>().fetchKlaim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KlaimProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Toolbar ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 520;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Klaim Distributor',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${provider.klaimList.length} klaim ditemukan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCompact)
                        IconButton.outlined(
                          onPressed: provider.isLoading
                              ? null
                              : () => provider.fetchKlaim(resetPage: true),
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Refresh',
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Summary pills
              Row(
                children: [
                  _SummaryPill(
                    icon: Icons.pending_actions_rounded,
                    label: 'Menunggu Kirim',
                    value: provider.klaimList
                        .where((e) =>
                            e.statusTerkini == 'KLAIM_MENUNGGU_PENGIRIMAN')
                        .length
                        .toString(),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _SummaryPill(
                    icon: Icons.local_shipping_rounded,
                    label: 'Dalam Pengiriman',
                    value: provider.klaimList
                        .where((e) =>
                            e.statusTerkini == 'KLAIM_DIKIRIM' ||
                            e.statusTerkini == 'KLAIM_SUDAH_DIKIRIM')
                        .length
                        .toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _SummaryPill(
                    icon: Icons.check_circle_rounded,
                    label: 'Selesai',
                    value: provider.klaimList
                        .where((e) => e.statusTerkini == 'KLAIM_SUDAH_DIAMBIL')
                        .length
                        .toString(),
                    color: Colors.green,
                  ),
                ],
              ),
              // Search field — triggers debounced server-side search
              _KlaimSearchField(
                onChanged: (query) => provider.setSearchQuery(query),
              ),
              const SizedBox(height: 8),
              // Filter tabs
              _KlaimFilterTabs(
                selectedTab: provider.selectedTab,
                onTabChanged: (index) => provider.setSelectedTab(index),
                counts: _computeCounts(provider),
              ),
            ],
          ),
        ),
        Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        // ─── Body ───────────────────────────────────────────────────────────
        Expanded(
          child: _buildBody(context, provider),
        ),
        // Pagination bar
        PaginationBar(
          currentPage: provider.currentPage,
          totalPages: provider.totalPages,
          hasNext: provider.hasNext,
          isLoading: provider.isLoading,
          onPreviousPage: () => provider.goToPage(provider.currentPage - 1),
          onNextPage: () => provider.goToPage(provider.currentPage + 1),
        ),
      ],
    );
  }

  _TabCounts _computeCounts(KlaimProvider provider) {
    final all = provider.klaimList;
    return _TabCounts(
      total: all.length,
      menunggu: all
          .where((e) => e.statusTerkini == 'KLAIM_MENUNGGU_PENGIRIMAN')
          .length,
      dikirim: all
          .where((e) =>
              e.statusTerkini == 'KLAIM_DIKIRIM' ||
              e.statusTerkini == 'KLAIM_SUDAH_DIKIRIM')
          .length,
      selesai:
          all.where((e) => e.statusTerkini == 'KLAIM_SUDAH_DIAMBIL').length,
    );
  }

  Widget _buildBody(BuildContext context, KlaimProvider provider) {
    if (provider.isLoading && provider.klaimList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.klaimList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text(provider.errorMessage!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => provider.fetchKlaim(resetPage: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Filter berdasarkan tab yang dipilih
    final filteredList = _filteredByTab(provider);

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Tidak ada data klaim',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopTable(context, filteredList, provider);
        } else {
          return _buildMobileList(context, filteredList, provider);
        }
      },
    );
  }

  List<TransaksiServis> _filteredByTab(KlaimProvider provider) {
    switch (provider.selectedTab) {
      case 0:
        return provider.klaimList;
      case 1:
        return provider.klaimList
            .where((e) => e.statusTerkini == 'KLAIM_MENUNGGU_PENGIRIMAN')
            .toList();
      case 2:
        return provider.klaimList
            .where((e) =>
                e.statusTerkini == 'KLAIM_DIKIRIM' ||
                e.statusTerkini == 'KLAIM_SUDAH_DIKIRIM')
            .toList();
      case 3:
        return provider.klaimList
            .where((e) => e.statusTerkini == 'KLAIM_SUDAH_DIAMBIL')
            .toList();
      default:
        return provider.klaimList;
    }
  }

  // ─── UI DESKTOP ─────────────────────────────────────────────────────────
  Widget _buildDesktopTable(BuildContext context,
      List<TransaksiServis> displayItems, KlaimProvider provider) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor:
                WidgetStateProperty.all(theme.colorScheme.surfaceContainerLow),
            headingTextStyle: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            columnSpacing: 20,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 68,
            columns: const [
              DataColumn(
                label: Text('No Servis'),
                columnWidth: FlexColumnWidth(1.3),
              ),
              DataColumn(
                label: Text('Tanggal'),
                columnWidth: FlexColumnWidth(0.9),
              ),
              DataColumn(
                label: Text('Pelanggan'),
                columnWidth: FlexColumnWidth(1.4),
              ),
              DataColumn(
                label: Text('Barang'),
                columnWidth: FlexColumnWidth(1.2),
              ),
              DataColumn(
                label: Text('Status Klaim'),
                columnWidth: FlexColumnWidth(1.2),
              ),
              DataColumn(
                label: Text('Di Distributor'),
                columnWidth: FlexColumnWidth(0.9),
              ),
              DataColumn(
                label: Text('Est. Biaya'),
                numeric: true,
                columnWidth: FlexColumnWidth(1.1),
              ),
            ],
            rows: displayItems.map((t) {
              return DataRow(
                onSelectChanged: (selected) {
                  if (t.id != null) {
                    context
                        .push('/servis/detail/${t.id}')
                        .then((_) => provider.fetchKlaim(resetPage: true));
                  }
                },
                cells: [
                  DataCell(Text(t.noServis ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_fmtDate(t.tglTerima))),
                  DataCell(Text(t.namaPelanggan ?? '—',
                      overflow: TextOverflow.ellipsis)),
                  DataCell(Text(
                      '${t.jenisBarang ?? ''} ${t.merek ?? ''}'.trim(),
                      overflow: TextOverflow.ellipsis)),
                  DataCell(_buildStatusBadge(t.statusTerkini ?? '', theme)),
                  DataCell(_buildHariBadge(t.hariDiDistributor, theme)),
                  DataCell(Text(
                    currencyFormat.format(t.estimasiBiaya ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── UI MOBILE ────────────────────────────────────────────────────────────
  Widget _buildMobileList(BuildContext context,
      List<TransaksiServis> displayItems, KlaimProvider provider) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => provider.fetchKlaim(resetPage: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: displayItems.length,
        itemBuilder: (context, i) {
          final t = displayItems[i];
          final statusColor = _statusColor(t.statusTerkini ?? '');
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (t.id != null) {
                  context
                      .push('/servis/detail/${t.id}')
                      .then((_) => provider.fetchKlaim(resetPage: true));
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  t.noServis ?? '—',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _buildStatusBadge(
                                    t.statusTerkini ?? '', theme),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.namaPelanggan ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${t.jenisBarang ?? ''} ${t.merek ?? ''}'.trim(),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (t.hariDiDistributor != null) ...[
                                const SizedBox(width: 8),
                                _buildHariBadge(t.hariDiDistributor, theme),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── HELPER WIDGETS & METHODS ────────────────────────────────────────────

  /// Badge jumlah hari di distributor dengan warna:
  /// hijau (≤7 hari), oranye (8-14), merah (>14), abu-abu (null/selesai).
  static Widget _buildHariBadge(int? hari, ThemeData theme) {
    if (hari == null) return const Text('—');
    final Color color;
    if (hari <= 7) {
      color = Colors.green;
    } else if (hari <= 14) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$hari hari',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _statusLabel(status),
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'KLAIM_MENUNGGU_PENGIRIMAN':
        return 'MENUNGGU PENGIRIMAN';
      case 'KLAIM_DIKIRIM':
        return 'DIKIRIM';
      case 'KLAIM_SUDAH_DIKIRIM':
        return 'SUDAH DIKIRIM';
      case 'KLAIM_SUDAH_DIAMBIL':
        return 'SUDAH DIAMBIL';
      default:
        return status.replaceAll('KLAIM_', '').replaceAll('_', ' ');
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'KLAIM_MENUNGGU_PENGIRIMAN':
        return Colors.orange;
      case 'KLAIM_DIKIRIM':
        return Colors.blue;
      case 'KLAIM_SUDAH_DIKIRIM':
        return Colors.indigo;
      case 'KLAIM_SUDAH_DIAMBIL':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String _fmtDate(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.tryParse(d);
      if (dt == null) return d;
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return d;
    }
  }
}

// ─── Summary Pill ─────────────────────────────────────────────────────────────
class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Field ─────────────────────────────────────────────────────────────
class _KlaimSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _KlaimSearchField({required this.onChanged});

  @override
  State<_KlaimSearchField> createState() => _KlaimSearchFieldState();
}

class _KlaimSearchFieldState extends State<_KlaimSearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari no servis, pelanggan, atau barang...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
              IconButton(
                onPressed: () => context.pushNamed(AppRoutes.servisScanner),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Scan QR Nota Servis',
              ),
            ],
          ),
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
        style: theme.textTheme.bodyMedium,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
      ),
    );
  }
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────
class _TabCounts {
  final int total;
  final int menunggu;
  final int dikirim;
  final int selesai;
  const _TabCounts({
    required this.total,
    required this.menunggu,
    required this.dikirim,
    required this.selesai,
  });
}

class _KlaimFilterTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final _TabCounts counts;

  const _KlaimFilterTabs({
    required this.selectedTab,
    required this.onTabChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = selectedTab == i;
          String label;
          int count;
          switch (i) {
            case 0:
              label = 'Semua';
              count = counts.total;
              break;
            case 1:
              label = 'Menunggu Kirim';
              count = counts.menunggu;
              break;
            case 2:
              label = 'Dikirim';
              count = counts.dikirim;
              break;
            case 3:
              label = 'Selesai';
              count = counts.selesai;
              break;
            default:
              label = '';
              count = 0;
          }

          return FilterChip(
            label: Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onTabChanged(i),
            showCheckmark: false,
            selectedColor: theme.colorScheme.primaryContainer,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
