import 'package:flutter/material.dart';
import 'package:stok_anandam/core/network/stock_summary_row.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';

/// Tampilan stok per kategori: NAMA (parent/child), Stok, %. Tanpa scroll, muat di lebar yang ada.
class StockCategoryChart extends StatelessWidget {
  const StockCategoryChart({
    super.key,
    required this.rows,
    required this.formatNumber,
  });

  final List<({StockSummaryRow row, int level})> rows;
  final String Function(num) formatNumber;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Belum ada data stok per kategori.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < 500;

    final headerFooterColor = colorScheme.surfaceContainerHighest;
    final parentColor = colorScheme.surfaceContainerHigh;
    final childColor = colorScheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderRow(theme, colorScheme, isNarrow),
          ...rows.map((e) {
            final isTotal = (e.row.nama.toUpperCase()) == 'TOTAL';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
                _buildDataRow(
                  theme: theme,
                  colorScheme: colorScheme,
                  left: e.row.nama,
                  right: null,
                  stok: e.row.stok,
                  presentase: e.row.presentase,
                  bgColor: isTotal
                      ? headerFooterColor
                      : (e.level == 0 ? parentColor : childColor),
                  isParent: e.level == 0,
                  isTotal: isTotal,
                  level: e.level,
                  isNarrow: isNarrow,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(
      ThemeData theme, ColorScheme colorScheme, bool isNarrow) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? AppSpacing.sm : AppSpacing.md,
        vertical: isNarrow ? 6 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 4,
              child: _headerCell(theme, colorScheme, 'NAMA', isNarrow)),
          _vDivider(colorScheme),
          Expanded(
              flex: 3,
              child: _headerCell(theme, colorScheme, 'NILAI STOK', isNarrow,
                  alignRight: true)),
          _vDivider(colorScheme),
          Expanded(
              flex: 2,
              child: _headerCell(theme, colorScheme, 'PROSENTASE', isNarrow,
                  alignRight: true)),
        ],
      ),
    );
  }

  Widget _headerCell(
      ThemeData theme, ColorScheme colorScheme, String text, bool isNarrow,
      {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        fontSize: isNarrow ? 8 : 11,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _vDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildDataRow({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String? left,
    required String? right,
    required num stok,
    required num presentase,
    required Color bgColor,
    bool isParent = false,
    bool isTotal = false,
    int level = 0,
    required bool isNarrow,
  }) {
    final displayName = left ?? right ?? '';
    final indent = level * 16.0;

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? AppSpacing.sm : AppSpacing.md,
        vertical: isNarrow ? 6 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(left: indent),
              child: Text(
                displayName.toUpperCase(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isParent || isTotal ? FontWeight.w700 : FontWeight.normal,
                  fontSize: isNarrow ? 10 : 11,
                  fontStyle:
                      isParent || isTotal ? FontStyle.italic : FontStyle.normal,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _vDivider(colorScheme),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stok == 0 && !isTotal ? '-' : formatNumber(stok.toDouble()),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isNarrow ? 8.5 : 12,
                      fontWeight: isParent || isTotal
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _vDivider(colorScheme),
          Expanded(
            flex: 2,
            child: Text(
              '${presentase.toStringAsFixed(2)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight:
                    isParent || isTotal ? FontWeight.w700 : FontWeight.normal,
                fontSize: isNarrow ? 10 : 11,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
