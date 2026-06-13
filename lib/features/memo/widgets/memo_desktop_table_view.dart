import 'package:flutter/material.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/shared/responsive_table.dart';
import 'package:stok_anandam/features/memo/widgets/status_badge.dart';
import 'package:stok_anandam/features/memo/widgets/memo_hover_card.dart';

class MemoDesktopTableView extends StatelessWidget {
  final List<MemoDetail> memos;
  final Function(MemoDetail) onTap;
  final Set<String> selectedIds;
  final ValueChanged<bool?>? onSelectAll;
  final void Function(String id, bool? selected)? onSelectionChanged;
  final bool isSelectionMode;
  final void Function(MemoDetail memo)? onInputJl;
  final void Function(MemoDetail memo, {required bool isRevision})? onDuplicate;

  const MemoDesktopTableView({
    super.key,
    required this.memos,
    required this.onTap,
    this.selectedIds = const {},
    this.onSelectAll,
    this.onSelectionChanged,
    this.isSelectionMode = false,
    this.onInputJl,
    this.onDuplicate,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveDataTable(
      dataRowMaxHeight: 64,
      dataRowMinHeight: 46,
      showCheckboxColumn: isSelectionMode,
      onSelectAll: onSelectAll,
      columnFlex: const [5, 4, 4, 3, 4, 3, 3],
      columns: [
        buildDataColumn('Pelanggan'),
        buildDataColumn('Kirim/Ambil'),
        buildDataColumn('Marketing'),
        buildDataColumn('Input JL', alignment: Alignment.centerLeft),
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
              MemoHoverCard(
                memo: memo,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.customerName ?? '—',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
            // INPUT JL
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: _buildInputJlCell(memo, Theme.of(context)),
              ),
            ),
            // TOTAL HARGA
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatRupiah(memo.totalHarga),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: memo.totalHarga > 50000000
                          ? const Color(0xFF1E40AF)
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${memo.totalQty.toString().replaceAll(RegExp(r'\.0$'), '')} Items',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
          ].map((cell) {
            return DataCell(
              _wrapWithContextMenu(context, cell.child, memo),
              placeholder: cell.placeholder,
              showEditIcon: cell.showEditIcon,
              onTap: cell.onTap,
              onLongPress: cell.onLongPress,
              onDoubleTap: cell.onDoubleTap,
              onTapDown: cell.onTapDown,
              onTapCancel: cell.onTapCancel,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildInputJlCell(MemoDetail memo, ThemeData theme) {
    // Jika ada JL, tampilkan badge nomor JL
    if (memo.nomorJl != null && memo.nomorJl!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 12, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              memo.nomorJl!,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Jika status MENUNGGU_NOTA dan belum ada JL, tampilkan button input
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
    final canInputJl = userRole == 'NOTA' ||
        userRole == 'GUDANG' ||
        userRole == 'SPV_GUDANG' ||
        userRole == 'ADMIN';

    if (memo.statusAkhir == MemoStatus.MENUNGGU_NOTA &&
        canInputJl &&
        onInputJl != null) {
      return TextButton.icon(
        onPressed: () => onInputJl!(memo),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
        label: const Text('Input JL', style: TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // Default: tampilkan dash
    return Text('—',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
  }

  Widget _buildOpsiBadge(MemoDetail memo, ThemeData theme) {
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();

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

      return _createBadge(eks, badgeColor, Icons.local_shipping_rounded);
    }

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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _wrapWithContextMenu(
      BuildContext context, Widget child, MemoDetail memo) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition, memo);
      },
      child: child,
    );
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
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'duplicate_revision',
          enabled: canRevise,
          child: Tooltip(
            message: canRevise
                ? ''
                : 'Memo yang sudah dalam pengiriman tidak dapat direvisi',
            child: Row(
              children: [
                Icon(
                  Icons.edit_document,
                  color: canRevise ? theme.colorScheme.primary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Duplikat & Revisi Memo',
                  style: TextStyle(
                    color: canRevise ? null : Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
      if (onDuplicate != null) {
        if (value == 'duplicate_revision') {
          onDuplicate!(memo, isRevision: true);
        } else if (value == 'duplicate_header') {
          onDuplicate!(memo, isRevision: false);
        }
      }
    });
  }
}
