// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/shared/modern_filter.dart';
import 'package:stok_anandam/features/shared/responsive_padding.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import 'package:stok_anandam/core/widgets/app_feedback.dart';
import 'package:stok_anandam/features/shared/migration_sync_mixin.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';

class AssemblyItem {
  final String label;
  final String? categoryCode;
  Stock? selectedStock;
  double modalValue;
  int quantity;
  double discount;
  List<Stock> availableOptions;
  bool isLoading;
  final Map<String, double> _modalMap = {};
  String? _searchText;
  String get searchText => _searchText ?? '';
  set searchText(String value) => _searchText = value;

  AssemblyItem({
    required this.label,
    this.categoryCode,
    this.selectedStock,
    this.modalValue = 0.0,
    this.quantity = 1,
    this.discount = 0.0,
    this.availableOptions = const [],
    this.isLoading = false,
    String searchText = '',
  }) : _searchText = searchText;

  double get price =>
      double.tryParse(
          (selectedStock as dynamic)?.finalPricelist?.toString() ?? '0') ??
      0.0;
  double get total => (price - discount) * quantity;

  double get hpp =>
      double.tryParse(
          (selectedStock as dynamic)?.hargaHpp?.toString() ?? '0') ??
      0.0;
  double get modal {
    final id = selectedStock?.id?.toString() ?? '';
    return _modalMap[id] ?? 0.0;
  }
}

class AssemblyPage extends StatefulWidget {
  const AssemblyPage({super.key});

  @override
  State<AssemblyPage> createState() => _AssemblyPageState();
}

/// Global state for Assembly to persist items across navigation
class _AssemblyState {
  _AssemblyState._();
  static List<AssemblyItem> items = [
    AssemblyItem(label: 'Processor', categoryCode: 'PROC'),
    AssemblyItem(label: 'Motherboard', categoryCode: 'MB'),
    AssemblyItem(label: 'VGA', categoryCode: 'VGA'),
    AssemblyItem(label: 'RAM', categoryCode: 'RAM'),
    AssemblyItem(label: 'SSD', categoryCode: 'SSD'),
    AssemblyItem(label: 'Harddisk', categoryCode: 'HDIN3'),
    AssemblyItem(label: 'Power Supply', categoryCode: 'PSU'),
    AssemblyItem(label: 'Casing', categoryCode: 'CS'),
    AssemblyItem(label: 'CPU COOLER', categoryCode: 'CLR'),
    AssemblyItem(label: 'FAN', categoryCode: 'FAN'),
    AssemblyItem(label: 'Keyboard Mouse', categoryCode: 'KB,MS,KBM'),
    AssemblyItem(label: 'LCD', categoryCode: 'LCD'),
  ];
  static bool initialized = false;

  static void reset() {
    items = [
      AssemblyItem(label: 'Processor', categoryCode: 'PROC'),
      AssemblyItem(label: 'Motherboard', categoryCode: 'MB'),
      AssemblyItem(label: 'VGA', categoryCode: 'VGA'),
      AssemblyItem(label: 'RAM', categoryCode: 'RAM'),
      AssemblyItem(label: 'SSD', categoryCode: 'SSD'),
      AssemblyItem(label: 'Harddisk', categoryCode: 'HDIN3'),
      AssemblyItem(label: 'Power Supply', categoryCode: 'PSU'),
      AssemblyItem(label: 'Casing', categoryCode: 'CS'),
      AssemblyItem(label: 'CPU COOLER', categoryCode: 'CLR'),
      AssemblyItem(label: 'FAN', categoryCode: 'FAN'),
      AssemblyItem(label: 'Keyboard Mouse', categoryCode: 'KB,MS,KBM'),
      AssemblyItem(label: 'LCD', categoryCode: 'LCD'),
    ];
    initialized = false;
  }
}

class _AssemblyPageState extends State<AssemblyPage> with MigrationSyncMixin {
  bool _loadingAll = false;

  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_AssemblyState.reset);

    // Ensure items are populated even if reset hasn't been called
    if (_AssemblyState.items.isEmpty) {
      _AssemblyState.reset();
    }

    if (!_AssemblyState.initialized) {
      _loadAllCategories();
      _AssemblyState.initialized = true;
    }
    fetchLastSync();
  }

  Future<void> _loadAllCategories() async {
    setState(() => _loadingAll = true);
    final futures = <Future>[];
    for (var item in _AssemblyState.items) {
      futures.add(_loadCategoryOptions(item));
    }
    await Future.wait(futures);
    if (mounted) setState(() => _loadingAll = false);
  }

  Future<void> _onRefresh() async {
    await _loadAllCategories();
  }

  void _clearItems() {
    setState(() {
      _AssemblyState.items = [
        AssemblyItem(label: 'Processor', categoryCode: 'PROC'),
        AssemblyItem(label: 'Motherboard', categoryCode: 'MB'),
        AssemblyItem(label: 'VGA', categoryCode: 'VGA'),
        AssemblyItem(label: 'RAM', categoryCode: 'RAM'),
        AssemblyItem(label: 'SSD', categoryCode: 'SSD'),
        AssemblyItem(label: 'Harddisk', categoryCode: 'HDIN3'),
        AssemblyItem(label: 'Power Supply', categoryCode: 'PSU'),
        AssemblyItem(label: 'Casing', categoryCode: 'CS'),
        AssemblyItem(label: 'CPU COOLER', categoryCode: 'CLR'),
        AssemblyItem(label: 'FAN', categoryCode: 'FAN'),
        AssemblyItem(label: 'Keyboard Mouse', categoryCode: 'KB,MS,KBM'),
        AssemblyItem(label: 'LCD', categoryCode: 'LCD'),
      ];
      _loadAllCategories();
    });
  }

  Future<void> _loadCategoryOptions(AssemblyItem item) async {
    setState(() => item.isLoading = true);
    try {
      final dio = getIt<MyApiClient>().dio;
      final List<String?> categoriesToFetch =
          item.categoryCode?.split(',') ?? <String?>[null];

      final futures =
          categoriesToFetch.map((cat) => dio.get<Map<String, dynamic>>(
                '/api/v1/stock',
                queryParameters: {
                  'size': 5000,
                  if (cat != null) 'categories': [cat],
                  if (cat == null && item.label != 'Lain-lain')
                    'search': item.label,
                  'sortBy': 'itemName',
                  'direction': 'asc',
                },
              ));

      final responses = await Future.wait(futures);
      final List<dynamic> allContent = [];

      for (var response in responses) {
        final data = response.data;
        if (data != null && isResponseSuccess(data['status'])) {
          final content =
              data['data'] is List ? data['data'] : data['data']?['content'];
          if (content is List) {
            allContent.addAll(content);
          }
        }
      }

      setState(() {
        final rawOptions = allContent.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          // API returns totalStok for lists, but Stock model expects finalStok
          if (map['finalStok'] == null && map['totalStok'] != null) {
            map['finalStok'] = map['totalStok'];
          }
          final stock = Stock.fromJson(map);
          final id = stock.id?.toString() ?? '';
          if (id.isNotEmpty) {
            item._modalMap[id] =
                double.tryParse(map['modal']?.toString() ?? '0') ?? 0.0;
          }
          return stock;
        }).where((s) {
          // Strict category filtering if categoryCode is specified
          if (item.categoryCode != null) {
            final validCats = item.categoryCode!.split(',');
            return validCats.contains(s.kategoriItemcode?.toString());
          }
          return true;
        }).toList();

        // deduplicate options by id just in case
        final uniqueOptions = <String, Stock>{};
        for (var opt in rawOptions) {
          final id = opt.id?.toString() ?? '';
          if (id.isNotEmpty) {
            uniqueOptions[id] = opt;
          } else {
            // fallback if id is somehow empty
            final String code =
                opt.itemCode?.toString() ?? opt.hashCode.toString();
            uniqueOptions[code] = opt;
          }
        }

        item.availableOptions = uniqueOptions.values.toList();
        item.availableOptions.sort((a, b) => (a.itemName?.toString() ?? '')
            .compareTo(b.itemName?.toString() ?? ''));
      });
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
            context, 'Terjadi kesalahan koneksi saat memuat ${item.label}.');
      }
    } finally {
      if (mounted) setState(() => item.isLoading = false);
    }
  }

  void _copyDataToClipboard() {
    final buffer = StringBuffer();

    for (var item in _AssemblyState.items) {
      if (item.selectedStock != null) {
        final name = ((item.selectedStock?.itemName ??
                item.selectedStock?.itemCode ??
                'Unnamed') as String)
            .toUpperCase();
        final qty = item.quantity;
        final totalRow = _formatCurrency(item.total).replaceAll('Rp ', '');
        buffer.writeln('- |x$qty| $name *@$totalRow*');
      }
    }

    buffer.writeln('');
    buffer.writeln(
        'TOTAL : ${_formatCurrency(_grandTotal).replaceAll('Rp ', '')}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Data rakitan berhasil disalin!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _addItem() {
    setState(() {
      final newItem = AssemblyItem(label: 'Lain-lain');
      _AssemblyState.items.add(newItem);
      _loadCategoryOptions(newItem);
    });
  }

  double get _grandTotal =>
      _AssemblyState.items.fold(0.0, (sum, item) => sum + item.total);

  double get _baseGrandTotal => _AssemblyState.items
      .fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  double get _totalModal => _AssemblyState.items
      .fold(0.0, (sum, item) => sum + (item.modal * item.quantity));

  String _formatCurrency(double value) {
    // Basic formatting, could use intl package if available
    final String s = value.toStringAsFixed(0);
    final reversed = s.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return ' ${chunks.join('.').split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardShell(
      currentRoute: AppRoutes.rakitan,
      onScan: () => context.pushNamed(AppRoutes.scanner),
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () =>
          showSyncMigrationDialog(onCustomSuccess: _loadAllCategories),
      onRefresh: _loadingAll ? null : _onRefresh,
      lastSync: lastSyncFormatted,
      onNavigate: (route) => context.go(route),
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: ResponsivePadding.all(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rakitan PC',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_loadingAll)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ..._AssemblyState.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildCategoryRow(item, index);
                      }),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Tambah Komponen'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _clearItems,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSummarySection(theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(AssemblyItem item, int index) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.selectedStock != null
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: item.selectedStock != null
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(item.label),
                  size: 16,
                  color: item.selectedStock != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: item.selectedStock != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (item.categoryCode == null && item.label == 'Lain-lain')
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                    ),
                    onPressed: () {
                      setState(() {
                        _AssemblyState.items.removeAt(index);
                      });
                    },
                  ),
                if (item.isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (item.selectedStock != null)
                  Text(
                    _formatCurrency(item.total),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchableDropdown(item),
                if (item.selectedStock != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stok: ${item.selectedStock?.finalStok ?? 0} | ${_formatCurrency(item.modal)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _QuantitySelector(
                              value: item.quantity,
                              onChanged: (val) {
                                setState(() => item.quantity = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Potongan Harga',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDiscountInput(item),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String label) {
    switch (label.toLowerCase()) {
      case 'processor':
        return Icons.memory_rounded;
      case 'motherboard':
        return Icons.developer_board_rounded;
      case 'vga':
        return Icons.videogame_asset_rounded;
      case 'ram':
        return Icons.storage_rounded;
      case 'ssd':
      case 'harddisk':
        return Icons.save_rounded;
      case 'power supply':
        return Icons.power_rounded;
      case 'casing':
        return Icons.inventory_2_rounded;
      case 'cpu cooler':
      case 'fan':
        return Icons.air_rounded;
      case 'keyboard mouse':
      case 'keyboard':
        return Icons.keyboard_rounded;
      case 'lcd':
        return Icons.monitor_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  Widget _buildSearchableDropdown(AssemblyItem item) {
    return SearchableDropdown<Stock>(
      label: item.label,
      hintText: 'Pilih ${item.label}',
      value: item.selectedStock,
      options: item.availableOptions,
      displayText: (s) {
        final name = s.itemName ?? s.itemCode ?? 'Unnamed';
        final stok = s.finalStok ?? 0;
        final pricelist = _formatCurrency(
            double.tryParse((s as dynamic).finalPricelist?.toString() ?? '0') ??
                0);
        return '$name | $stok | $pricelist';
      },
      selectedDisplayText: (s) {
        final name = s.itemName ?? s.itemCode ?? 'Unnamed';
        final stok = s.finalStok ?? 0;
        final finalPricelist = _formatCurrency(
            double.tryParse((s as dynamic).finalPricelist?.toString() ?? '0') ??
                0);
        return '$name | $stok | $finalPricelist';
      },
      onChanged: (val) {
        setState(() {
          item.selectedStock = val;
        });
      },
      initialSearchText: item.searchText,
      onSearchChanged: (val) {
        item.searchText = val;
      },
      width: double.infinity,
    );
  }


  Widget _buildDiscountInput(AssemblyItem item) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Potongan',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        prefixText: 'Rp ',
      ),
      keyboardType: TextInputType.number,
      onChanged: (val) {
        setState(() {
          item.discount = double.tryParse(val) ?? 0.0;
        });
      },
      controller: TextEditingController(text: item.discount.toInt().toString())
        ..selection = TextSelection.collapsed(
            offset: item.discount.toInt().toString().length),
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Modal',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    _formatCurrency(_totalModal),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Harga Jual',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_baseGrandTotal > _grandTotal)
                    Text(
                      _formatCurrency(_baseGrandTotal),
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    _formatCurrency(_grandTotal),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Detail Item Rakitan:',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._AssemblyState.items
              .where((i) => i.selectedStock != null)
              .map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i.label}: ${i.selectedStock?.itemName ?? i.selectedStock?.itemCode}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          'x ${i.quantity}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _copyDataToClipboard,
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Salin Data Rakitan'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              value.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
