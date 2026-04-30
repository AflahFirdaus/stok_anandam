import 'package:flutter/material.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/shared/responsive_table.dart';
import 'package:stok_anandam/features/memo/widgets/status_badge.dart';

class MemoDesktopTableView extends StatelessWidget {
  final List<MemoDetail> memos;
  final Function(MemoDetail) onTap;
  final Set<String> selectedIds;
  final ValueChanged<bool?>? onSelectAll;
  final void Function(String id, bool? selected)? onSelectionChanged;
  final bool isSelectionMode;

  const MemoDesktopTableView({
    super.key,
    required this.memos,
    required this.onTap,
    this.selectedIds = const {},
    this.onSelectAll,
    this.onSelectionChanged,
    this.isSelectionMode = false,
  });

  String _formatRupiah(num v) =>
      "Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";

  String _formatDate(DateTime dt) => "${dt.day}/${dt.month}/${dt.year}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveDataTable(
      dataRowMaxHeight: 52,
      dataRowMinHeight: 46,
      showCheckboxColumn: isSelectionMode,
      onSelectAll: onSelectAll,
      columnFlex: const [5, 4, 4, 3, 4, 3, 3],
      columns: [
        buildDataColumn('Pelanggan'),
        buildDataColumn('Kirim/Ambil'),
        buildDataColumn('Marketing'),
        buildDataColumn('Tipe', alignment: Alignment.centerLeft),
        buildDataColumn('Total Harga', alignment: Alignment.centerLeft),
        buildDataColumn('Status', alignment: Alignment.centerLeft),
        buildDataColumn('Tanggal', alignment: Alignment.centerLeft),
      ],
      rows: memos.map((memo) {
        final isSelected = selectedIds.contains(memo.id);
        return DataRow(
          selected: isSelected,
          onSelectChanged: (selected) {
            if (isSelectionMode && onSelectionChanged != null) {
              onSelectionChanged!(memo.id ?? '', selected);
            } else {
              onTap(memo);
            }
          },
          cells: [
            // PELANGGAN
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.customerName ?? '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // KIRIM/AMBIL
            DataCell(
              memo.opsiPengiriman != null
                  ? _buildOpsiBadge(memo, theme)
                  : const Text('—'),
            ),
            // Kode
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.marketingName ?? '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            // TIPE
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeIcon(memo.memoType, theme),
                    const SizedBox(width: 10),
                    Text(
                      _capitalizeType(memo.memoType),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // TOTAL HARGA
            buildDataCell(
              _formatRupiah(memo.totalHarga),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: memo.totalHarga > 50000000
                    ? const Color(0xFF1E40AF)
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              alignment: Alignment.centerLeft,
            ),
            // STATUS
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  status: memo.statusAkhir ?? MemoStatus.MENUNGGU_PERSETUJUAN,
                ),
              ),
            ),
            // TANGGAL
            buildDataCell(
              memo.tanggalMemo != null ? _formatDate(memo.tanggalMemo!) : '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade800,
              ),
              alignment: Alignment.centerLeft,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTypeIcon(String? type, ThemeData theme) {
    IconData icon;
    Color color;
    switch (type?.toUpperCase()) {
      case 'PROJECT':
        icon = Icons.business_center_rounded;
        color = Colors.indigo;
        break;
      case 'ONLINE':
        icon = Icons.shopping_cart_rounded;
        color = Colors.orange;
        break;
      case 'PENDING':
        icon = Icons.bookmark_rounded;
        color = Colors.teal;
        break;
      default:
        icon = Icons.description_rounded;
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _capitalizeType(String? type) {
    if (type == null || type.isEmpty) return '—';
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  Widget _buildOpsiBadge(MemoDetail memo, ThemeData theme) {
    final String opsi = memo.opsiPengiriman ?? '';
    final bool isDelivery = memo.isDeliveryRequired ||
        opsi.toUpperCase().contains('DELIVERY') ||
        opsi.toUpperCase().contains('KIRIM') ||
        opsi.toUpperCase().contains('DIKIRIM') ||
        opsi.toUpperCase().contains('MARKETING') ||
        opsi.toUpperCase().contains('DRIVER');

    if (!isDelivery) {
      return _createBadge(
          'AMBIL DI TOKO', Colors.deepOrange, Icons.store_rounded);
    }

    final String label = memo.deliveryMethodLabel;
    final Color color =
        label.contains('MARKETING') ? Colors.purple : Colors.blue;

    return _createBadge(label, color, Icons.local_shipping_rounded);
  }

  Widget _createBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
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
}
