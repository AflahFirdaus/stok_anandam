import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import '../../models/transaksi_servis.dart';
import '../../providers/servis_provider.dart';
import '../../widgets/pagination_bar.dart';

class ServisProsesView extends StatelessWidget {
  final ServisProvider provider;
  const ServisProsesView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ServisToolbar(provider: provider),
            Expanded(child: _ServisBody(provider: provider)),
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
      },
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────────────
class _ServisToolbar extends StatelessWidget {
  final ServisProvider provider;
  const _ServisToolbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bisaDiambil = provider.transaksiList
        .where((e) => e.statusTerkini == 'BISA_DIAMBIL')
        .length;
    final klaim = provider.transaksiList
        .where((e) => (e.statusTerkini ?? '').startsWith('KLAIM'))
        .length;
    return Container(
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
                          'Daftar Transaksi Servis',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.transaksiList.length} transaksi ditemukan',
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
                          : () => provider.fetchTransaksi(resetPage: true),
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                icon: Icons.receipt_long_rounded,
                label: 'Aktif',
                value: provider.transaksiList.length.toString(),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                icon: Icons.inventory_2_rounded,
                label: 'Bisa Diambil',
                value: bisaDiambil.toString(),
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                icon: Icons.local_shipping_rounded,
                label: 'Klaim',
                value: klaim.toString(),
                color: Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search field — triggers debounced server-side search
          _SearchField(
            onChanged: (query) => provider.setSearchQuery(query),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ServisProvider.statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final status = ServisProvider.statusOptions[i];
                final isSelected = provider.currentFilter == status;
                final color = _ServisBodyState._statusColorStr(status);
                return FilterChip(
                  label: Text(
                    status == 'SEMUA' ? 'Semua' : status.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => provider.setFilter(status),
                  showCheckmark: false,
                  selectedColor: color.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: isSelected
                        ? color.withValues(alpha: 0.6)
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

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

// ─── Search Field ────────────────────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
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
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
class _ServisBody extends StatefulWidget {
  final ServisProvider provider;
  const _ServisBody({required this.provider});

  @override
  State<_ServisBody> createState() => _ServisBodyState();
}

class _ServisBodyState extends State<_ServisBody> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    if (provider.isLoading && provider.transaksiList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.transaksiList.isEmpty) {
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
              onPressed: () => provider.fetchTransaksi(resetPage: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final list = provider.transaksiList;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_circle_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Belum ada data servis',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopTable(context, list);
        } else {
          return _buildMobileList(context, list);
        }
      },
    );
  }

  // ─── UI DESKTOP ─────────────────────────────────────────────────────────
  Widget _buildDesktopTable(BuildContext context, List<TransaksiServis> list) {
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
                columnWidth: FlexColumnWidth(1.2),
              ),
              DataColumn(
                label: Text('Tanggal'),
                columnWidth: FlexColumnWidth(0.9),
              ),
              DataColumn(
                label: Text('Pelanggan'),
                columnWidth: FlexColumnWidth(1.5),
              ),
              DataColumn(
                label: Text('Barang'),
                columnWidth: FlexColumnWidth(1.3),
              ),
              DataColumn(
                label: Text('Keluhan'),
                columnWidth: FlexColumnWidth(2.0),
              ),
              DataColumn(
                label: Text('Status'),
                columnWidth: FlexColumnWidth(1.0),
              ),
              DataColumn(
                label: Text('Biaya'),
                numeric: true,
                columnWidth: FlexColumnWidth(1.3),
              ),
            ],
            rows: list.map((t) {
              return DataRow(
                onSelectChanged: (selected) {
                  if (t.id != null) {
                    context.push('/servis/detail/${t.id}').then(
                        (_) => widget.provider.fetchTransaksi(resetPage: true));
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
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(t.kerusakan ?? '—',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(_buildStatusBadge(t.statusTerkini ?? '', theme)),
                  DataCell(Text(
                    _displayBiaya(t, currencyFormat),
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
  Widget _buildMobileList(BuildContext context, List<TransaksiServis> list) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => widget.provider.fetchTransaksi(resetPage: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final t = list[i];
          final statusColor = _statusColorStr(t.statusTerkini ?? '');
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
                  context.push('/servis/detail/${t.id}').then(
                      (_) => widget.provider.fetchTransaksi(resetPage: true));
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          Text(
                            '${t.jenisBarang ?? ''} ${t.merek ?? ''}'.trim(),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  /// Jika status BISA_DIAMBIL atau SUDAH_DIAMBIL, tampilkan biayaFinal.
  /// Selain itu tampilkan estimasiBiaya.
  String _displayBiaya(TransaksiServis t, NumberFormat fmt) {
    final useFinal =
        t.statusTerkini == 'BISA_DIAMBIL' || t.statusTerkini == 'SUDAH_DIAMBIL';
    final value = useFinal ? t.biayaFinal : t.estimasiBiaya;
    if (value == null) return '—';
    return fmt.format(value);
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    final color = _statusColorStr(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  static Color _statusColorStr(String status) {
    if (status.startsWith('KLAIM')) return Colors.deepOrange;
    switch (status) {
      case 'BELUM_CEK':
        return Colors.grey;
      case 'SEDANG_CEK':
        return Colors.blue;
      case 'SEDANG_DIKERJAKAN':
        return const Color(0xFF3949AB);
      case 'SEDANG_TES':
        return Colors.purple;
      case 'TUNGGU_KONFIRMASI':
        return const Color(0xFFB45309);
      case 'TUNGGU_SPAREPART':
        return Colors.orange;
      case 'BISA_DIAMBIL':
        return Colors.green;
      case 'BATAL':
        return Colors.red;
      case 'SUDAH DIAMBIL':
        return Colors.teal;
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
