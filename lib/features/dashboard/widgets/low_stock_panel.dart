import 'package:flutter/material.dart';

/// Satu item stok rendah dari API (lowStockPreview).
class LowStockItem {
  const LowStockItem({
    this.itemName,
    this.itemCode,
    this.finalStok,
    this.warehouse,
    this.grandTotal,
  });

  final String? itemName;
  final String? itemCode;
  final int? finalStok;
  final String? warehouse;
  final num? grandTotal;

  static LowStockItem? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) {
      if (json is Map) {
        final m = Map<String, dynamic>.from(json);
        return _fromMap(m);
      }
      return null;
    }
    return _fromMap(json);
  }

  static LowStockItem _fromMap(Map<String, dynamic> m) {
    final stok = m['finalStok'];
    return LowStockItem(
      itemName: m['itemName']?.toString(),
      itemCode: m['itemCode']?.toString(),
      finalStok:
          stok is int ? stok : (num.tryParse(stok?.toString() ?? '')?.toInt()),
      warehouse: m['warehouse']?.toString(),
      grandTotal: m['grandTotal'] != null
          ? num.tryParse(m['grandTotal'].toString())
          : null,
    );
  }
}

/// Panel kanan dashboard: daftar stok rendah. Template dan padding mengikuti dashboard.
class LowStockPanel extends StatelessWidget {
  const LowStockPanel({
    super.key,
    this.items = const [],
    this.maxItems = 10,
  });

  final List<LowStockItem> items;
  final int maxItems;

  static const double preferredWidth = 280;

  @override
  Widget build(BuildContext context) {
    final list = items.take(maxItems).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : (screenW > 0 ? screenW : preferredWidth);
        final w = (maxW < preferredWidth ? maxW : preferredWidth)
            .clamp(1.0, preferredWidth);
        return Container(
          width: w,
          margin:
              const EdgeInsets.only(left: 16, right: 24, top: 24, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Stok Rendah',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Tidak ada stok rendah',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              else
                ...list.map((e) => _LowStockTile(item: e)),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.item});

  final LowStockItem item;

  @override
  Widget build(BuildContext context) {
    final name = item.itemName?.trim().isEmpty ?? true
        ? item.itemCode ?? '—'
        : item.itemName!;
    final stok = item.finalStok ?? 0;
    final warehouse =
        item.warehouse?.trim().isEmpty ?? true ? null : item.warehouse;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 18, color: Colors.orange.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok: $stok',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (warehouse != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        warehouse,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
