import 'package:flutter/material.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import '../models/dashboard_local_models.dart';

class EmployeeSalesPanel extends StatelessWidget {
  final List<EmployeeSalesLocalData> todayItems;
  final List<EmployeeSalesLocalData> monthItems;

  const EmployeeSalesPanel({
    super.key,
    required this.todayItems,
    required this.monthItems,
  });

  String _formatRupiah(num value) {
    return 'Rp ${_addThousandSeparator(value.round().toString())}';
  }

  String _addThousandSeparator(String number) {
    final reversed = number.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks.join('.').split('').reversed.join();
  }

  List<EmployeeSalesLocalData> _getSortedTodayItems() {
    final list = List<EmployeeSalesLocalData>.from(todayItems);
    list.sort((a, b) => b.totalSales.compareTo(a.totalSales));
    return list;
  }

  List<EmployeeSalesLocalData> _getSortedMonthItems() {
    final list = List<EmployeeSalesLocalData>.from(monthItems);
    list.sort((a, b) => b.totalSales.compareTo(a.totalSales));
    return list;
  }

  Widget _buildHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 32,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Belum ada data penjualan',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemBox(BuildContext context, EmployeeSalesLocalData item) {
    final theme = Theme.of(context);
    final amount = item.totalSales;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.empName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.empCode,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRupiah(amount),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedToday = _getSortedTodayItems();
    final sortedMonth = _getSortedMonthItems();
    final maxLength = sortedToday.length > sortedMonth.length
        ? sortedToday.length
        : sortedMonth.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHeader(context, 'Penjualan Karyawan per Hari Ini',
                  Icons.today_rounded),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildHeader(context, 'Penjualan Karyawan per Bulan',
                  Icons.calendar_month_rounded),
            ),
          ],
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: sortedToday.isEmpty && sortedMonth.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: maxLength,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: index < sortedToday.length
                                ? _buildItemBox(context, sortedToday[index])
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: index < sortedMonth.length
                                ? _buildItemBox(context, sortedMonth[index])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
