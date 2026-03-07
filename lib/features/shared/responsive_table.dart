import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget tabel responsif yang otomatis menyesuaikan lebar kolom dan mendukung scroll horizontal.
///
/// Lebar kolom dibatasi antara [minColumnWidth] dan [maxColumnWidth] agar jarak antarkolom
/// tidak terlalu lebar di layar besar. Jika konten lebih lebar dari viewport, tabel bisa di-scroll horizontal.
class ResponsiveDataTable extends StatefulWidget {
  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minColumnWidth = 180.0,
    this.maxColumnWidth = 260.0,
    this.columnSpacing = 12.0,
    this.horizontalMargin = 0.0,
    this.headingRowColor,
    this.headingRowHeight,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.showScrollbar = true,
    this.decoration,
    
  });

  /// Kolom-kolom tabel
  final List<DataColumn> columns;

  /// Baris-baris data
  final List<DataRow> rows;

  /// Lebar minimum setiap kolom
  final double minColumnWidth;

  /// Lebar maksimum setiap kolom (mencegah jarak antarkolom terlalu lebar di layar besar)
  final double maxColumnWidth;

  /// Spacing antar kolom
  final double columnSpacing;

  /// Margin horizontal (untuk padding container)
  final double horizontalMargin;

  /// Warna background header row
  final Color? headingRowColor;

  /// Tinggi header row
  final double? headingRowHeight;

  /// Tinggi minimum data row
  final double? dataRowMinHeight;

  /// Tinggi maksimum data row
  final double? dataRowMaxHeight;

  /// Tampilkan scrollbar
  final bool showScrollbar;

  /// Dekorasi container (opsional)
  final BoxDecoration? decoration;

  @override
  State<ResponsiveDataTable> createState() => _ResponsiveDataTableState();
}

class _ResponsiveDataTableState extends State<ResponsiveDataTable> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerDecoration = widget.decoration ??
        BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        );

    return Container(
      decoration: containerDecoration,
      child: ClipRRect(
        borderRadius: containerDecoration.borderRadius ?? BorderRadius.zero,
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final hasBoundedHeight = outerConstraints.maxHeight.isFinite;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize:
                  hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (hasBoundedHeight)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => _buildTable(
                        context,
                        constraints,
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) => _buildTable(
                      context,
                      constraints,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth - (widget.horizontalMargin * 2)
        : double.infinity;
    final columnCount = widget.columns.length;

    // Hitung lebar minimum total yang dibutuhkan untuk semua kolom
    final totalMinWidth = (widget.minColumnWidth * columnCount) +
        (widget.columnSpacing * (columnCount - 1));
    final contentWidth =
        availableWidth - (widget.columnSpacing * (columnCount - 1));
    // Kolom dibatasi min dan max agar jarak tidak "panjang banget" di layar lebar.
    // Pastikan lower <= upper agar clamp tidak throw Invalid argument(s).
    final low = widget.minColumnWidth <= widget.maxColumnWidth
        ? widget.minColumnWidth
        : widget.maxColumnWidth;
    final high = widget.minColumnWidth <= widget.maxColumnWidth
        ? widget.maxColumnWidth
        : widget.minColumnWidth;
    final colWidth = (contentWidth / columnCount).clamp(low, high);
    final tableWidthFromCols =
        (colWidth * columnCount) + (widget.columnSpacing * (columnCount - 1));
    final needsScroll = tableWidthFromCols > availableWidth;
    final tableWidth = needsScroll ? totalMinWidth : tableWidthFromCols;
    final effectiveColWidth = needsScroll ? widget.minColumnWidth : colWidth;

    // Wrap kolom dengan SizedBox untuk lebar konsisten
    final wrappedColumns = widget.columns.map((col) {
      // Jika kolom sudah memiliki SizedBox dengan width, sesuaikan jika perlu
      if (col.label is SizedBox) {
        final existingSizedBox = col.label as SizedBox;
        // Jika width sudah sesuai dengan colWidth, gunakan langsung
        if (existingSizedBox.width != null &&
            (existingSizedBox.width! - effectiveColWidth).abs() < 0.1) {
          return col;
        }
        // Jika width berbeda, wrap dengan width baru
        return DataColumn(
          label: SizedBox(
            width: effectiveColWidth,
            child: existingSizedBox.child,
          ),
        );
      }
      // Jika tidak, wrap dengan SizedBox baru
      return DataColumn(
        label: SizedBox(
          width: effectiveColWidth,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            child: col.label,
          ),
        ),
      );
    }).toList();

    // Wrap baris untuk memastikan setiap sel menghormati effectiveColWidth
    final wrappedRows = widget.rows.map((row) {
      return DataRow(
        key: row.key,
        selected: row.selected,
        onSelectChanged: row.onSelectChanged,
        onLongPress: row.onLongPress,
        color: row.color,
        cells: row.cells.map((cell) {
          return DataCell(
            SizedBox(
              width: effectiveColWidth,
              // TAMBAHKAN ALIGN DI SINI
              child: Align(
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 3,
                  child: cell.child,
                ),
              ),
            ),
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
    }).toList();

    Widget tableWidget = SizedBox(
      width: tableWidth,
      child: SelectionArea(
        child: DataTable(
          columns: wrappedColumns,
          rows: wrappedRows,
          columnSpacing: widget.columnSpacing,
          showCheckboxColumn: false,
          headingRowColor: widget.headingRowColor != null
              ? WidgetStateProperty.all(widget.headingRowColor!)
              : null,
          headingRowHeight: widget.headingRowHeight,
          dataRowMinHeight: widget.dataRowMinHeight,
          dataRowMaxHeight: widget.dataRowMaxHeight,
        ),
      ),
    );

    tableWidget = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: tableWidget,
    );

    if (widget.showScrollbar) {
      tableWidget = Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: tableWidget,
      );
    }

    return tableWidget;
  }
}

/// Helper untuk membuat DataColumn dengan text yang bisa di-copy dan otomatis ellipsis
DataColumn buildDataColumn(String label, {double? width}) {
  return DataColumn(
    label: SizedBox(
      width: width,
      child: SelectableText(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    ),
  );
}

/// Helper untuk membuat DataCell dengan text yang bisa di-copy dan otomatis ellipsis
/// Dengan SelectableText, user bisa memilih beberapa cell sekaligus dengan drag
DataCell buildDataCell(String text, {TextStyle? style}) {
  return DataCell(
    // Gunakan Align untuk kontrol posisi horizontal dan vertikal
    Align(
      alignment: Alignment
          .centerLeft, // Tengah secara vertikal, Kiri secara horizontal
      child: SelectableText(
        text,
        style: style ?? const TextStyle(fontSize: 11),
        maxLines: 3,
      ),
    ),
  );
}

/// Helper untuk membuat DataRow dengan kemampuan copy seluruh baris
/// User bisa long-press pada baris untuk copy seluruh baris sebagai tab-separated values
DataRow buildDataRowWithCopy({
  required BuildContext context,
  required List<String> cellTexts,
  List<TextStyle>? cellStyles,
  String separator = '\t',
  VoidCallback? onSelectChanged,
}) {
  // Buat string untuk copy seluruh baris (tab-separated untuk Excel compatibility)
  final rowText = cellTexts.join(separator);

  return DataRow(
    onSelectChanged: onSelectChanged != null ? (_) => onSelectChanged() : null,
    cells: cellTexts.asMap().entries.map((entry) {
      final index = entry.key;
      final text = entry.value;
      final style = cellStyles != null && index < cellStyles.length
          ? cellStyles[index]
          : null;

      return DataCell(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: rowText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Baris berhasil di-copy'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: SelectableText(
              text,
              style: style ?? const TextStyle(fontSize: 11),
              maxLines: 3,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
