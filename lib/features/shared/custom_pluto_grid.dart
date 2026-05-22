import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';

/// Model data contoh untuk Grid.
/// Anda bisa menyesuaikan ini dengan model data asli di proyek Anda.
class TransactionDataModel {
  final String tanggal;
  final String noNota;
  final String namaUser;
  final String barang;
  final int qty;
  final double harga;
  final double total;

  TransactionDataModel({
    required this.tanggal,
    required this.noNota,
    required this.namaUser,
    required this.barang,
    required this.qty,
    required this.harga,
    required this.total,
  });
}

class CustomPlutoDataGrid<T> extends StatefulWidget {
  final List<T> data;
  final int totalPage;
  final int currentPage;
  final int totalElements;
  final Function(int) onPageChanged;
  final List<PlutoColumn> Function(BuildContext context) buildColumns;
  final List<PlutoRow> Function(List<T> data) buildRows;

  const CustomPlutoDataGrid({
    super.key,
    required this.data,
    required this.totalPage,
    required this.currentPage,
    required this.totalElements,
    required this.onPageChanged,
    required this.buildColumns,
    required this.buildRows,
  });

  @override
  State<CustomPlutoDataGrid> createState() => _CustomPlutoDataGridState<T>();
}

class _CustomPlutoDataGridState<T> extends State<CustomPlutoDataGrid<T>>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  PlutoGridStateManager? stateManager;
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    // OPTIMASI: Smart Height Calculation
    // Batasi tinggi grid agar UI Virtualization PlutoGrid tetap aktif pada data besar.
    const double rowHeight = 45.0;
    const double headerHeight = 45.0;
    final double calculatedHeight =
        headerHeight + (widget.data.length * rowHeight) + 20;

    // Batasi tinggi maksimal (misal 75% dari tinggi layar) untuk mencegah over-rendering
    final double maxHeight = size.height * 0.75;
    final double finalGridHeight = calculatedHeight.clamp(200.0, maxHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // OPTIMASI: RepaintBoundary memisahkan render grid dari widget lain
        RepaintBoundary(
          child: SizedBox(
            height: finalGridHeight,
            child: PlutoGrid(
              columns: widget.buildColumns(context),
              rows: widget.buildRows(widget.data),
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                stateManager?.setShowColumnFilter(false);
                stateManager?.setSelectingMode(PlutoGridSelectingMode.cell);
              },
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  gridBackgroundColor: theme.colorScheme.surface,
                  rowColor: theme.colorScheme.surface,
                  evenRowColor: Colors.grey.shade50,
                  activatedColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  activatedBorderColor: theme.colorScheme.primary,
                  columnTextStyle: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                  cellTextStyle: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                  gridBorderColor: Colors.grey.shade200,
                  borderColor: Colors.grey.shade200,
                  columnHeight: headerHeight,
                  rowHeight: rowHeight,
                  defaultColumnTitlePadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  defaultCellPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                ),
                columnSize: const PlutoGridColumnSizeConfig(
                  autoSizeMode: PlutoAutoSizeMode.none,
                ),
              ),
              mode: PlutoGridMode.readOnly,
            ),
          ),
        ),

        // Custom Pagination Footer
        const SizedBox(height: 16),
        _buildPagination(theme),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPagination(ThemeData theme) {
    return Container(
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
              'Halaman ${widget.currentPage} dari ${widget.totalPage > 0 ? widget.totalPage : 1} • Total ${widget.totalElements} item',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChanged(widget.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: widget.currentPage < widget.totalPage
                    ? () => widget.onPageChanged(widget.currentPage + 1)
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
    );
  }
}

/// Helper untuk membuat kolom transaksi standar sesuai permintaan USER
class TransactionGridHelper {
  static List<PlutoColumn> getTransactionColumns(BuildContext context) {
    return [
      PlutoColumn(
        title: 'Tanggal',
        field: 'tanggal',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.left,
      ),
      PlutoColumn(
        title: 'No Nota',
        field: 'noNota',
        type: PlutoColumnType.text(),
        width: 300,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.left,
      ),
      PlutoColumn(
        title: 'Nama User',
        field: 'namaUser',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.left,
      ),
      PlutoColumn(
        title: 'Barang',
        field: 'barang',
        type: PlutoColumnType.text(),
        width: 300,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.left,
      ),
      PlutoColumn(
        title: 'Qty',
        field: 'qty',
        type: PlutoColumnType.number(),
        width: 80,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Harga',
        field: 'harga',
        type: PlutoColumnType.currency(
            symbol: '', decimalDigits: 0, locale: 'id_ID'),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Total',
        field: 'total',
        type: PlutoColumnType.currency(
            symbol: '', decimalDigits: 0, locale: 'id_ID'),
        width: 150,
        enableEditingMode: false,
        enableColumnDrag: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
    ];
  }

  static List<PlutoRow> mapToRows(List<TransactionDataModel> data) {
    return data.map((item) {
      return PlutoRow(
        cells: {
          'tanggal': PlutoCell(value: item.tanggal),
          'noNota': PlutoCell(value: item.noNota),
          'namaUser': PlutoCell(value: item.namaUser),
          'barang': PlutoCell(value: item.barang),
          'qty': PlutoCell(value: item.qty),
          'harga': PlutoCell(value: item.harga),
          'total': PlutoCell(value: item.total),
        },
      );
    }).toList();
  }
}
