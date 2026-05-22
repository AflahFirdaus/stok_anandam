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
    this.showCheckboxColumn = false,
    this.onSelectAll,
    this.columnFlex,
  });

  final bool showCheckboxColumn;
  final ValueChanged<bool?>? onSelectAll;
  final List<int>? columnFlex;

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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        );

    return Container(
      decoration: containerDecoration,
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
    );
  }

  Widget _buildTable(BuildContext context, BoxConstraints constraints) {
    // 1. Ambil lebar maksimal layar/container
    final containerWidth =
        constraints.maxWidth.isFinite ? constraints.maxWidth : double.infinity;
    final columnCount = widget.columns.length;

    // Tentukan margin aktual yang konsisten
    final actualHorizontalMargin =
        widget.horizontalMargin > 0 ? widget.horizontalMargin : 16.0;

    // 2. Hitung ruang tetap (Margin Kiri+Kanan & Jarak Antar Kolom)
    final fixedSpace = (actualHorizontalMargin * 2) +
        (widget.columnSpacing * (columnCount - 1));

    // 3. Ruang bersih yang tersedia KHUSUS untuk diisi teks/kolom
    final contentWidth = containerWidth.isFinite
        ? (containerWidth - fixedSpace)
        : double.infinity;

    final low = widget.minColumnWidth <= widget.maxColumnWidth
        ? widget.minColumnWidth
        : widget.maxColumnWidth;
    final high = widget.minColumnWidth <= widget.maxColumnWidth
        ? widget.maxColumnWidth
        : widget.minColumnWidth;

    List<double> colWidths = [];
    double sumOfColWidths = 0;

    // Pembagian flex (proporsi kolom)
    if (widget.columnFlex != null &&
        widget.columnFlex!.length == columnCount &&
        contentWidth.isFinite) {
      final totalFlex = widget.columnFlex!.reduce((a, b) => a + b);
      for (int i = 0; i < columnCount; i++) {
        final w =
            (contentWidth * widget.columnFlex![i] / totalFlex).clamp(low, high);
        colWidths.add(w);
        sumOfColWidths += w;
      }
    } else {
      final colWidth = contentWidth.isFinite
          ? (contentWidth / columnCount).clamp(low, high)
          : low;
      for (int i = 0; i < columnCount; i++) {
        colWidths.add(colWidth);
        sumOfColWidths += colWidth;
      }
    }

    // Hitung total lebar yang dibutuhkan tabel
    double totalRequiredWidth = sumOfColWidths + fixedSpace;
    if (widget.showCheckboxColumn) {
      totalRequiredWidth += 48; // Padding untuk checkbox jika mode milih aktif
    }

    // --- KUNCI PERBAIKAN: Pastikan lebar tabel MINIMAL sama dengan lebar layar ---
    // Jika tidak diatur begini, tabel akan tertarik ke kiri dan menyisakan gap di kanan
    final tableWidth = totalRequiredWidth > containerWidth
        ? totalRequiredWidth
        : containerWidth;

    // Wrap kolom dengan SizedBox untuk lebar konsisten
    final wrappedColumns = widget.columns.asMap().entries.map((entry) {
      final index = entry.key;
      final col = entry.value;
      final effectiveColWidth = colWidths[index];

      AlignmentGeometry alignment = Alignment.centerLeft;
      Widget labelContent = col.label;

      if (labelContent is SizedBox) {
        if (labelContent.child is Align) {
          alignment = (labelContent.child as Align).alignment;
          labelContent = (labelContent.child as Align).child ?? labelContent;
        } else if (labelContent.child is Center) {
          alignment = Alignment.center;
          labelContent = (labelContent.child as Center).child ?? labelContent;
        }
      } else if (labelContent is Align) {
        alignment = labelContent.alignment;
        labelContent = labelContent.child ?? labelContent;
      } else if (labelContent is Center) {
        alignment = Alignment.center;
        labelContent = labelContent.child ?? labelContent;
      }

      return DataColumn(
        label: SizedBox(
          width: effectiveColWidth,
          child: Align(
            alignment: alignment,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              child: labelContent,
            ),
          ),
        ),
      );
    }).toList();

    // Wrap baris
    final wrappedRows = widget.rows.map((row) {
      return DataRow(
        key: row.key,
        selected: row.selected,
        onSelectChanged: row.onSelectChanged,
        onLongPress: row.onLongPress,
        color: row.color,
        cells: row.cells.asMap().entries.map((entry) {
          final index = entry.key;
          final cell = entry.value;
          final effectiveColWidth = colWidths[index];

          AlignmentGeometry alignment = Alignment.centerLeft;
          Widget cellContent = cell.child;

          if (cellContent is Align) {
            alignment = cellContent.alignment;
            cellContent = cellContent.child ?? cellContent;
          } else if (cellContent is Center) {
            alignment = Alignment.center;
            cellContent = cellContent.child ?? cellContent;
          } else if (cellContent is SizedBox) {
            if (cellContent.child is Align) {
              alignment = (cellContent.child as Align).alignment;
              cellContent = (cellContent.child as Align).child ?? cellContent;
            } else if (cellContent.child is Center) {
              alignment = Alignment.center;
              cellContent = (cellContent.child as Center).child ?? cellContent;
            }
          }

          return DataCell(
            SizedBox(
              width: effectiveColWidth,
              child: Align(
                alignment: alignment,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 12, // Disesuaikan agar mudah dibaca
                    color: Colors.black87,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 3,
                  child: cellContent,
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
      width: tableWidth, // Sekarang lebarnya akan mengisi penuh layar
      child: SelectionArea(
        child: DataTable(
          columns: wrappedColumns,
          rows: wrappedRows,
          columnSpacing: widget.columnSpacing,
          showCheckboxColumn: widget.showCheckboxColumn,
          onSelectAll: widget.onSelectAll,

          dividerThickness: 0.0, // Hilangkan garis putus-putus bawaan
          border: TableBorder(
            // Pakai garis solid yang merentang penuh
            horizontalInside:
                BorderSide(color: Colors.grey.shade200, width: 1.0),
            bottom: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),

          horizontalMargin:
              actualHorizontalMargin, // Margin kiri kanan sudah persis sama
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
DataColumn buildDataColumn(String label,
    {double? width, AlignmentGeometry alignment = Alignment.centerLeft}) {
  return DataColumn(
    label: Align(
      alignment: alignment,
      child: SizedBox(
        width: width,
        child: SelectableText(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    ),
  );
}

/// Helper untuk membuat DataCell dengan text yang bisa di-copy dan otomatis ellipsis
/// Dengan SelectableText, user bisa memilih beberapa cell sekaligus dengan drag
DataCell buildDataCell(
  String text, {
  AlignmentGeometry alignment = Alignment.centerLeft,
  TextStyle? style,
  VoidCallback? onTap,
}) {
  return DataCell(
    Align(
      alignment: alignment,
      child: Text(
        text,
        style: style ?? const TextStyle(fontSize: 12),
        textAlign:
            alignment == Alignment.center ? TextAlign.center : TextAlign.left,
      ),
    ),
    onTap: onTap,
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
