import 'package:flutter/material.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import '../models/dashboard_local_models.dart';

class CombinedEmployeeSales {
  final String empName;
  final String empCode;
  final double todaySales;
  final double monthSales;

  CombinedEmployeeSales({
    required this.empName,
    required this.empCode,
    required this.todaySales,
    required this.monthSales,
  });
}

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

  List<CombinedEmployeeSales> _getCombinedList() {
    final map = <String, CombinedEmployeeSales>{};

    for (final item in todayItems) {
      final key = '${item.empCode}_${item.empName}';
      map[key] = CombinedEmployeeSales(
        empName: item.empName,
        empCode: item.empCode,
        todaySales: item.totalSales,
        monthSales: 0,
      );
    }

    for (final item in monthItems) {
      final key = '${item.empCode}_${item.empName}';
      if (map.containsKey(key)) {
        map[key] = CombinedEmployeeSales(
          empName: map[key]!.empName,
          empCode: map[key]!.empCode,
          todaySales: map[key]!.todaySales,
          monthSales: item.totalSales,
        );
      } else {
        map[key] = CombinedEmployeeSales(
          empName: item.empName,
          empCode: item.empCode,
          todaySales: 0,
          monthSales: item.totalSales,
        );
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => a.empName.toLowerCase().compareTo(b.empName.toLowerCase()));
    return list;
  }

  Widget _buildHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
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

  Widget _buildItemBox(BuildContext context, CombinedEmployeeSales item, bool isToday) {
    final theme = Theme.of(context);
    final amount = isToday ? item.todaySales : item.monthSales;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
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
    final combinedItems = _getCombinedList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHeader(context, 'Penjualan Karyawan per Hari Ini', Icons.today_rounded),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildHeader(context, 'Penjualan Karyawan per Bulan', Icons.calendar_month_rounded),
            ),
          ],
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: combinedItems.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: combinedItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = combinedItems[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildItemBox(context, item, true),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: _buildItemBox(context, item, false),
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
