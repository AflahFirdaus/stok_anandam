import 'package:flutter/material.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/shared/responsive_table.dart';
import 'package:stok_anandam/features/memo/widgets/status_badge.dart';

class DeliveryDesktopTableView extends StatelessWidget {
  final List<MemoDetail> memos;
  final Function(MemoDetail) onTap;
  final Set<String> selectedIds;
  final ValueChanged<bool?>? onSelectAll;
  final bool isSelectionMode;

  const DeliveryDesktopTableView({
    super.key,
    required this.memos,
    required this.onTap,
    this.selectedIds = const {},
    this.onSelectAll,
    this.isSelectionMode = false,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimaryText = Color(0xFF1E293B);
    const colorSecondaryText = Color(0xFF64748B);

    return ResponsiveDataTable(
      // 1. REVISI TINGGI TABEL (Dipersempit)
      dataRowMaxHeight: 60,
      dataRowMinHeight: 52,
      headingRowHeight: 48,

      showCheckboxColumn: isSelectionMode,
      onSelectAll: onSelectAll,

      // 2. REVISI FLEX: Agar kolom pembatas lebih proporsional dan tidak terdorong ke kanan
      columnFlex: const [3, 2, 2, 2, 2, 2, 2, 2],

      horizontalMargin: 20,
      minColumnWidth: 70,
      maxColumnWidth: double.infinity,
      columns: [
        buildDataColumn('PELANGGAN', alignment: Alignment.centerLeft),
        buildDataColumn('ORDER ID', alignment: Alignment.centerLeft),
        buildDataColumn('WILAYAH / AREA', alignment: Alignment.centerLeft),
        buildDataColumn('TGL KIRIM', alignment: Alignment.centerLeft),
        buildDataColumn('MARKETING', alignment: Alignment.centerLeft),
        buildDataColumn('PENGIRIM', alignment: Alignment.centerLeft),
        buildDataColumn('TIPE', alignment: Alignment.centerLeft),
        buildDataColumn('STATUS', alignment: Alignment.centerLeft),
      ],
      rows: memos.map((memo) {
        final logisticsTasks = memo.penjadwalanHistory.where((j) => 
            j.tipeTugas == 'PENGIRIMAN' || 
            j.tipeTugas == 'PENGAMBILAN' || 
            j.tipeTugas == 'DROP_OFF_EKSPEDISI'
        ).toList();
        final jadwal = logisticsTasks.isNotEmpty ? logisticsTasks.last : null;

        final isSelected = selectedIds.contains(memo.id);

        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onTap(memo),
          cells: [
            // Pelanggan
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                // 3. PADDING DIHAPUS agar otomatis center vertikal
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.customerName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: colorPrimaryText,
                      ),
                    ),
                    if (memo.customerPhone != null &&
                        memo.customerPhone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        memo.customerPhone!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: colorSecondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            // Order ID Marketplace
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  memo.orderIdMarketplace ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: colorSecondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ((jadwal?.kabupatenKota != null &&
                                  jadwal!.kabupatenKota!.isNotEmpty)
                              ? jadwal.kabupatenKota!
                              : (memo.kabupatenKota != null &&
                                      memo.kabupatenKota!.isNotEmpty)
                                  ? memo.kabupatenKota!
                                  : (jadwal?.alamatLengkap != null &&
                                          jadwal!.alamatLengkap!.isNotEmpty)
                                      ? (jadwal.alamatLengkap!.length > 20
                                          ? jadwal.alamatLengkap!.substring(0, 20)
                                          : jadwal.alamatLengkap!)
                                      : '—')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: colorPrimaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if ((jadwal?.kecamatan != null &&
                            jadwal!.kecamatan!.isNotEmpty) ||
                        (memo.kecamatan != null && memo.kecamatan!.isNotEmpty))
                      const SizedBox(height: 2),
                    if ((jadwal?.kecamatan != null &&
                            jadwal!.kecamatan!.isNotEmpty) ||
                        (memo.kecamatan != null && memo.kecamatan!.isNotEmpty))
                      Text(
                        (jadwal?.kecamatan ?? memo.kecamatan ?? '')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: colorSecondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Tgl Kirim
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  jadwal?.updatedAt ?? jadwal?.tanggalJadwal ?? '—',
                  style: const TextStyle(
                    fontSize: 12,
                    color: colorSecondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Marketing
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  memo.marketingName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: colorPrimaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  (jadwal?.personelName != null && jadwal!.personelName!.isNotEmpty)
                      ? jadwal.personelName!
                      : (jadwal?.marketingName != null && jadwal!.marketingName!.isNotEmpty)
                          ? jadwal.marketingName!
                          : (memo.isMarketingDelivery && memo.marketingName != null && memo.marketingName!.isNotEmpty)
                              ? memo.marketingName!
                              : (memo.ekspedisi != null && memo.ekspedisi!.isNotEmpty)
                                  ? memo.ekspedisi!
                                  : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: colorPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Tipe
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: _buildTypeBadge(memo.memoType),
              ),
            ),

            // Status
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  status: memo.statusAkhir ?? MemoStatus.MENUNGGU_PENGIRIMAN,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTypeBadge(String? type) {
    Color bgColor;
    Color textColor;

    switch (type?.toUpperCase()) {
      case 'PROJECT':
        bgColor = const Color(0xFFEEF2FF);
        textColor = const Color(0xFF4338CA);
        break;
      case 'ONLINE':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        break;
      case 'DISTRIBUSI':
        bgColor = const Color(0xFFFAF5FF);
        textColor = const Color(0xFF7E22CE);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type?.toUpperCase() ?? 'BIASA',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
