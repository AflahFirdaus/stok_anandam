import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaksi_servis.dart';
import '../../providers/garansi_provider.dart';
import '../../widgets/pagination_bar.dart';

class ServisGaransiView extends StatefulWidget {
  const ServisGaransiView({super.key});

  @override
  State<ServisGaransiView> createState() => _ServisGaransiViewState();
}

class _ServisGaransiViewState extends State<ServisGaransiView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<GaransiProvider>().setSelectedTab(_tabController.index);
      }
    });

    // Fetch data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GaransiProvider>();
      provider.fetchGaransi();
      provider.startCountdown();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GaransiProvider>();
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
                              'Garansi Servis',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${provider.garansiAktif.length} aktif · ${provider.garansiExpired.length} kedaluwarsa',
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
                              : () {
                                  provider.fetchGaransi(resetPage: true);
                                },
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
              Row(
                children: [
                  _SummaryPill(
                    icon: Icons.verified_rounded,
                    label: 'Garansi Aktif',
                    value: provider.garansiAktif.length.toString(),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _SummaryPill(
                    icon: Icons.timer_off_rounded,
                    label: 'Kedaluwarsa',
                    value: provider.garansiExpired.length.toString(),
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _SummaryPill(
                    icon: Icons.shield_rounded,
                    label: 'Total',
                    value: (provider.garansiAktif.length +
                            provider.garansiExpired.length)
                        .toString(),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              // Search field — triggers debounced server-side search
              _GaransiSearchField(
                onChanged: (query) => provider.setSearchQuery(query),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text('Aktif (${provider.garansiAktif.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_off_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text('Kedaluwarsa (${provider.garansiExpired.length})'),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildBody(BuildContext context, GaransiProvider provider) {
    if (provider.isLoading &&
        provider.garansiAktif.isEmpty &&
        provider.garansiExpired.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null &&
        provider.garansiAktif.isEmpty &&
        provider.garansiExpired.isEmpty) {
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
              onPressed: () {
                provider.fetchGaransi(resetPage: true);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _GaransiList(
            items: provider.garansiAktif, isAktif: true, provider: provider),
        _GaransiList(
            items: provider.garansiExpired, isAktif: false, provider: provider),
      ],
    );
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

// ─── Garansi Search Field ─────────────────────────────────────────────────────
class _GaransiSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _GaransiSearchField({required this.onChanged});

  @override
  State<_GaransiSearchField> createState() => _GaransiSearchFieldState();
}

class _GaransiSearchFieldState extends State<_GaransiSearchField> {
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
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
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

// ─── Garansi List ─────────────────────────────────────────────────────────────
class _GaransiList extends StatelessWidget {
  final List<TransaksiServis> items;
  final bool isAktif;
  final GaransiProvider provider;

  const _GaransiList({
    required this.items,
    required this.isAktif,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // No client-side filtering — search is server-side now
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAktif ? Icons.shield_outlined : Icons.timer_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isAktif
                  ? 'Tidak ada garansi aktif'
                  : 'Tidak ada garansi kedaluwarsa',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopTable(context, items);
        } else {
          return _buildMobileList(context, items);
        }
      },
    );
  }

  Widget _buildDesktopTable(
      BuildContext context, List<TransaksiServis> displayItems) {
    final theme = Theme.of(context);

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
            columns: [
              const DataColumn(
                label: Text('No Servis'),
                columnWidth: FlexColumnWidth(1.2),
              ),
              const DataColumn(
                label: Text('Pelanggan'),
                columnWidth: FlexColumnWidth(1.5),
              ),
              const DataColumn(
                label: Text('Barang'),
                columnWidth: FlexColumnWidth(1.3),
              ),
              const DataColumn(
                label: Text('Durasi Garansi'),
                columnWidth: FlexColumnWidth(1.2),
              ),
              const DataColumn(
                label: Text('Selesai Garansi'),
                columnWidth: FlexColumnWidth(1.0),
              ),
              const DataColumn(
                label: Text('Sisa Garansi'),
                columnWidth: FlexColumnWidth(1.0),
              ),
              if (isAktif)
                const DataColumn(
                  label: Text('Countdown'),
                  columnWidth: FlexColumnWidth(1.2),
                ),
            ],
            rows: displayItems.map((t) {
              return DataRow(
                onSelectChanged: (selected) {
                  if (t.id != null) {
                    context
                        .push('/servis/detail/${t.id}')
                        .then((_) => provider.fetchGaransi());
                  }
                },
                cells: [
                  DataCell(Text(t.noServis ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(t.namaPelanggan ?? '—',
                      overflow: TextOverflow.ellipsis)),
                  DataCell(Text(
                      '${t.jenisBarang ?? ''} ${t.merek ?? ''}'.trim(),
                      overflow: TextOverflow.ellipsis)),
                  DataCell(Text(t.durasiGaransi ?? '—')),
                  DataCell(Text(_fmtDate(t.tglJatuhTempo))),
                  DataCell(_buildSisaHariBadge(t.tglJatuhTempo, theme)),
                  if (isAktif)
                    DataCell(Text(
                      GaransiProvider.getCountdownString(t.tglJatuhTempo),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getCountdownColor(t.tglJatuhTempo),
                      ),
                    )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
      BuildContext context, List<TransaksiServis> displayItems) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => provider.fetchGaransi(resetPage: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: displayItems.length,
        itemBuilder: (context, i) {
          final t = displayItems[i];
          final countdownStr =
              GaransiProvider.getCountdownString(t.tglJatuhTempo);
          final countdownColor = _getCountdownColor(t.tglJatuhTempo);

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
                      .then((_) => provider.fetchGaransi());
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isAktif ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAktif
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : Colors.red.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isAktif
                                            ? Colors.green
                                                .withValues(alpha: 0.4)
                                            : Colors.red.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      isAktif ? 'Aktif' : 'Kedaluwarsa',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isAktif ? Colors.green : Colors.red,
                                      ),
                                    ),
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
                              Text(
                                '${t.jenisBarang ?? ''} ${t.merek ?? ''}'
                                    .trim(),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.timer_rounded,
                            label: 'Garansi',
                            value: t.durasiGaransi ?? '—',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.calendar_today_rounded,
                            label: 'Selesai Garansi',
                            value: _fmtDate(t.tglJatuhTempo),
                          ),
                        ),
                      ],
                    ),
                    if (isAktif) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: countdownColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: countdownColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_rounded,
                                size: 16, color: countdownColor),
                            const SizedBox(width: 6),
                            Text(
                              countdownStr,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: countdownColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSisaHariBadge(String? tglJatuhTempo, ThemeData theme) {
    final sisaHari = GaransiProvider.getSisaHari(tglJatuhTempo);
    if (sisaHari == null) return const Text('—');

    final color = _getCountdownColor(tglJatuhTempo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        sisaHari < 0 ? 'Kedaluwarsa' : '$sisaHari hari',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getCountdownColor(String? tglJatuhTempo) {
    final sisaHari = GaransiProvider.getSisaHari(tglJatuhTempo);
    if (sisaHari == null) return Colors.grey;
    if (sisaHari < 0) return Colors.red;
    if (sisaHari <= 7) return Colors.orange;
    if (sisaHari <= 30) return Colors.amber.shade700;
    return Colors.green;
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
